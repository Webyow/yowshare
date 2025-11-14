# YowShare — LAN File Share (Kivy) — Dark theme only, no emoji icons
# Python 3.9+ | Kivy
# If your OS firewall prompts, allow for Private/LAN network.

import os
import sys
import json
import shutil
import socket
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path

from kivy.app import App
from kivy.clock import Clock, mainthread
from kivy.core.window import Window
from kivy.metrics import dp
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.filechooser import FileChooserIconView
from kivy.uix.gridlayout import GridLayout
from kivy.uix.label import Label
from kivy.uix.popup import Popup
from kivy.uix.progressbar import ProgressBar
from kivy.uix.scrollview import ScrollView
from kivy.uix.screenmanager import ScreenManager, Screen, FadeTransition
from kivy.uix.textinput import TextInput
from kivy.uix.widget import Widget
from kivy.graphics import Color, RoundedRectangle, Ellipse, InstructionGroup

# -----------------------------
# App constants & persistence
# -----------------------------
Window.size = (420, 800)

HOME = str(Path.home())
APP_DIR = os.path.join(HOME, "YowShare")
RECEIVED_DIR = os.path.join(APP_DIR, "Received")
SENT_DIR = os.path.join(APP_DIR, "Sent")
CFG_PATH = os.path.join(APP_DIR, "config.json")
HISTORY_PATH = os.path.join(APP_DIR, "history.json")

os.makedirs(RECEIVED_DIR, exist_ok=True)
os.makedirs(SENT_DIR, exist_ok=True)
os.makedirs(APP_DIR, exist_ok=True)

def load_json(path, fallback):
    try:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                return json.load(f)
    except Exception:
        pass
    return fallback

def save_json(path, data):
    try:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2)
    except Exception as e:
        print("Failed to save json:", e)

# ---------------
# Single DARK theme
# ---------------
THEME = {
    "bg": (0.08, 0.09, 0.12, 1),
    "card": (0.12, 0.13, 0.17, 1),
    "ink": (0.97, 0.98, 0.99, 1),
    "muted": (0.66, 0.68, 0.74, 1),
    "primary": (0.58, 0.36, 0.98, 1),  # purple
    "accent": (1.0, 0.62, 0.28, 1),    # orange (kept for emphasis)
    "stroke": (0.2, 0.22, 0.28, 1),
}

def with_bg(widget, color, radius=dp(18)):
    class Card(BoxLayout):
        def __init__(self, **kw):
            super().__init__(**kw)
            self.padding = dp(12)
            self.radius = radius
            with self.canvas.before:
                Color(*color)
                self._rect = RoundedRectangle(radius=[(self.radius, self.radius)]*4)
            self.bind(pos=self._update, size=self._update)
        def _update(self, *args):
            self._rect.pos = self.pos
            self._rect.size = self.size
    card = Card(orientation="vertical")
    card.add_widget(widget)
    return card

def draw_header_bg(layout, color):
    with layout.canvas.before:
        Color(*color)
        layout._hdr_rect = RoundedRectangle(radius=[(0,0)]*4)
    layout.bind(pos=lambda *_: setattr(layout._hdr_rect, "pos", layout.pos),
                size=lambda *_: setattr(layout._hdr_rect, "size", layout.size))

# --------------------------------
# Networking (Discovery & Transfer)
# --------------------------------
DISCOVERY_PORT = 50554
TRANSFER_PORT = 50555
BROADCAST_ADDR = "<broadcast>"
HEARTBEAT_SEC = 2.0
DEVICE_TTL_SEC = 7.0
CHUNK = 64 * 1024

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip

class DeviceRegistry:
    def __init__(self):
        self._lock = threading.Lock()
        self._devices = {}  # ip -> dict(name, ip, port, last_seen)

    def upsert(self, name, ip, port):
        with self._lock:
            self._devices[ip] = {
                "name": name,
                "ip": ip,
                "port": port,
                "last_seen": time.time(),
            }

    def list_alive(self):
        now = time.time()
        with self._lock:
            for ip, d in list(self._devices.items()):
                if now - d["last_seen"] > DEVICE_TTL_SEC:
                    del self._devices[ip]
            return sorted(self._devices.values(), key=lambda d: d["name"].lower())

class DiscoveryService(threading.Thread):
    daemon = True
    def __init__(self, device_name, registry):
        super().__init__()
        self.device_name = device_name
        self.registry = registry
        self.running = True
        self.ip = get_local_ip()

    def run(self):
        tx = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        tx.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        tx.settimeout(1.0)

        rx = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        rx.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            rx.bind(("", DISCOVERY_PORT))
        except OSError:
            pass
        rx.settimeout(1.0)

        last_heartbeat = 0.0

        while self.running:
            now = time.time()
            if now - last_heartbeat >= HEARTBEAT_SEC:
                last_heartbeat = now
                payload = {
                    "t": "alive",
                    "name": self.device_name,
                    "ip": self.ip,
                    "port": TRANSFER_PORT,
                }
                try:
                    tx.sendto(json.dumps(payload).encode("utf-8"), (BROADCAST_ADDR, DISCOVERY_PORT))
                except Exception:
                    pass

            try:
                data, addr = rx.recvfrom(4096)
                if not data:
                    continue
                msg = json.loads(data.decode("utf-8"))
                if msg.get("t") == "alive":
                    if msg.get("ip") == self.ip and int(msg.get("port", TRANSFER_PORT)) == TRANSFER_PORT and msg.get("name") == self.device_name:
                        continue
                    name = msg.get("name", "Device")
                    ip = msg.get("ip") or addr[0]
                    port = int(msg.get("port") or TRANSFER_PORT)
                    self.registry.upsert(name, ip, port)
            except socket.timeout:
                pass
            except Exception:
                pass

        try:
            tx.close()
            rx.close()
        except Exception:
            pass

    def stop(self):
        self.running = False

class TransferServer(threading.Thread):
    """TCP server that receives files and asks UI to accept/reject."""
    daemon = True
    def __init__(self, on_offer, on_progress, on_done, on_error):
        super().__init__()
        self.on_offer = on_offer
        self.on_progress = on_progress
        self.on_done = on_done
        self.on_error = on_error
        self.running = True
        self.sock = None

    def run(self):
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            s.bind(("", TRANSFER_PORT))
            s.listen(5)
            self.sock = s
        except Exception as e:
            self.on_error(f"Receiver bind failed: {e}")
            return

        while self.running:
            try:
                s.settimeout(1.0)
                try:
                    conn, addr = s.accept()
                except socket.timeout:
                    continue
                threading.Thread(target=self._handle_client, args=(conn, addr), daemon=True).start()
            except Exception as e:
                self.on_error(f"Receiver error: {e}")
                break

        try:
            s.close()
        except Exception:
            pass

    def stop(self):
        self.running = False
        try:
            if self.sock:
                self.sock.close()
        except Exception:
            pass

    def _recv_json(self, conn):
        buf = b""
        while b"\n" not in buf:
            chunk = conn.recv(4096)
            if not chunk:
                raise ConnectionError("Disconnected before header")
            buf += chunk
        line, rest = buf.split(b"\n", 1)
        hdr = json.loads(line.decode("utf-8"))
        return hdr, rest

    def _handle_client(self, conn, addr):
        try:
            hdr, rest = self._recv_json(conn)
            if hdr.get("t") != "offer":
                conn.close()
                return

            offer = {
                "sender": hdr.get("sender") or f"{addr[0]}",
                "filename": hdr.get("filename") or "file.bin",
                "size": int(hdr.get("size") or 0),
                "count": int(hdr.get("count") or 1),
                "index": int(hdr.get("index") or 1),
            }

            accepted, save_path = self.on_offer(offer)
            if accepted:
                conn.sendall(b"ACCEPT\n")
            else:
                conn.sendall(b"REJECT\n")
                conn.close()
                return

            received = len(rest)
            if rest:
                with open(save_path, "wb") as f:
                    f.write(rest)
            else:
                open(save_path, "wb").close()

            with open(save_path, "ab") as f:
                while received < offer["size"]:
                    chunk = conn.recv(min(CHUNK, offer["size"] - received))
                    if not chunk:
                        raise ConnectionError("Sender disconnected")
                    f.write(chunk)
                    received += len(chunk)
                    self.on_progress(offer, received, offer["size"])

            self.on_done(offer, save_path, addr[0])
            conn.close()
        except Exception as e:
            try:
                conn.close()
            except Exception:
                pass
            self.on_error(f"Receive failed: {e}")

def send_file(remote_ip, remote_port, sender_name, src_path, total_count, index, on_progress):
    size = os.path.getsize(src_path)
    filename = os.path.basename(src_path)
    hdr = {"t": "offer", "sender": sender_name, "filename": filename, "size": size, "count": total_count, "index": index}

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(8)
    s.connect((remote_ip, remote_port))
    s.sendall((json.dumps(hdr) + "\n").encode("utf-8"))

    line = b""
    while b"\n" not in line:
        chunk = s.recv(16)
        if not chunk:
            raise ConnectionError("No response from receiver")
        line += chunk
    decision = line.strip().decode("utf-8")
    if decision != "ACCEPT":
        s.close()
        raise PermissionError("Receiver rejected the transfer")

    sent = 0
    with open(src_path, "rb") as f:
        while True:
            buf = f.read(CHUNK)
            if not buf:
                break
            s.sendall(buf)
            sent += len(buf)
            on_progress(filename, sent, size, index, total_count)
    s.close()

# ---------------
# UI Elements
# ---------------
class PrimaryButton(Button):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.background_normal = ""
        self.background_down = ""
        self.size_hint_y = None
        self.height = dp(48)
        self.font_size = dp(16)
        self.bold = True
        self.color = (1, 1, 1, 1)
        self.radius = dp(12)
        self.padding = (dp(14), dp(12))
        self.halign = "center"
        self.valign = "middle"
        self.text_size = (None, None)
        self.background_color = THEME["primary"]

class SecondaryButton(Button):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.background_normal = ""
        self.background_down = ""
        self.size_hint_y = None
        self.height = dp(48)
        self.font_size = dp(16)
        self.color = THEME["ink"]
        self.radius = dp(12)
        self.padding = (dp(14), dp(12))
        self.background_color = THEME["stroke"]

class Header(BoxLayout):
    def __init__(self, title, on_back=None, right_button=None, **kwargs):
        super().__init__(**kwargs)
        self.orientation = "horizontal"
        self.size_hint_y = None
        self.height = dp(60)
        self.padding = [dp(12), dp(10), dp(12), dp(10)]
        draw_header_bg(self, THEME["card"])

        if on_back:
            back = Button(text="<",
                          size_hint=(None, None), height=dp(40), width=dp(44),
                          background_normal="", background_down="",
                          background_color=(0, 0, 0, 0),
                          color=THEME["ink"], font_size=dp(20))
            back.bind(on_release=on_back)
        else:
            back = Widget(size_hint=(None, None), size=(dp(44), dp(40)))

        lbl = Label(text=title, color=THEME["ink"], font_size=dp(19),
                    halign="left", valign="middle")
        lbl.bind(size=lambda l, *_: setattr(l, "text_size", l.size))

        right = right_button if right_button else Widget(size_hint=(None, None), size=(dp(44), dp(40)))
        self.add_widget(back)
        self.add_widget(lbl)
        self.add_widget(right)

class Wave(Widget):
    """‘Waiting’ pulse. Safe init to avoid race (on_size firing early)."""
    def __init__(self, **kwargs):
        self._grp = None
        self._t = 0.0
        self._event = None
        super().__init__(**kwargs)
        Clock.schedule_once(self._init_graphics, 0)

    def _init_graphics(self, *_):
        if self._grp is None:
            self._grp = InstructionGroup()
            self.canvas.add(self._grp)
        if self._event is None:
            self._event = Clock.schedule_interval(self._tick, 1/60)
        self._redraw(self._t)

    def on_size(self, *_):
        if not self._grp:
            return
        self._redraw(self._t)

    def on_pos(self, *_):
        if not self._grp:
            return
        self._redraw(self._t)

    def _tick(self, dt):
        self._t += dt
        if not self._grp:
            return
        self._redraw(self._t)

    def on_parent(self, instance, parent):
        if parent is None and self._event is not None:
            self._event.cancel()
            self._event = None

    def _redraw(self, t):
        if not self._grp:
            return
        self._grp.clear()
        cx = self.x + self.width/2
        cy = self.y + self.height/2
        max_r = max(0, min(self.width, self.height)/2 - dp(6))
        rings = 3
        r, g, b, _ = THEME["primary"]
        for i in range(rings):
            phase = (t*0.8 + i*0.33) % 1.0
            radius = (0.2 + 0.8*phase) * max_r
            alpha = 0.23 * (1.0 - phase)
            self._grp.add(Color(r, g, b, alpha))
            self._grp.add(Ellipse(pos=(cx - radius, cy - radius), size=(radius*2, radius*2)))

# ---------------
# Screens
# ---------------
class HomeScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        root = BoxLayout(orientation="vertical", spacing=dp(12), padding=dp(12))
        root.add_widget(Header("YowShare", right_button=None))

        hero_box = BoxLayout(orientation="vertical", spacing=dp(8))
        hero_box.add_widget(Label(
            text="Fast local file sharing.\nPick files to send or wait to receive.",
            color=THEME["muted"], font_size=dp(16),
            halign="center", valign="middle", size_hint_y=None, height=dp(64)
        ))
        actions = BoxLayout(orientation="vertical", spacing=dp(10), size_hint_y=None, height=dp(120))
        send = PrimaryButton(text="Send Files  >")
        recv = SecondaryButton(text="Receive  <")
        send.bind(on_release=lambda *_: setattr(self.manager, "current", "filepicker"))
        recv.bind(on_release=lambda *_: setattr(self.manager, "current", "receive"))
        actions.add_widget(send)
        actions.add_widget(recv)
        root.add_widget(with_bg(hero_box, THEME["card"]))
        root.add_widget(actions)

        quick = GridLayout(cols=2, spacing=dp(10), size_hint_y=None, height=dp(110))
        hist = SecondaryButton(text="History")
        hist.bind(on_release=lambda *_: setattr(self.manager, "current", "history"))
        devices = SecondaryButton(text="Devices")
        devices.bind(on_release=lambda *_: setattr(self.manager, "current", "devices"))
        quick.add_widget(hist)
        quick.add_widget(devices)
        root.add_widget(quick)
        self.add_widget(root)

class FilePickerScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        root = BoxLayout(orientation="vertical", spacing=dp(8), padding=dp(8))
        root.add_widget(Header("Select Files", on_back=lambda *_: setattr(self.manager, "current", "home")))
        self.filechooser = FileChooserIconView(multiselect=True, path=HOME)
        root.add_widget(self.filechooser)

        row = BoxLayout(spacing=dp(10), size_hint_y=None, height=dp(56))
        back = SecondaryButton(text="Back")
        nextb = PrimaryButton(text="Next >")
        back.bind(on_release=lambda *_: setattr(self.manager, "current", "home"))
        nextb.bind(on_release=self._go_devices)
        row.add_widget(back)
        row.add_widget(nextb)
        root.add_widget(row)
        self.add_widget(root)

    def _go_devices(self, *_):
        sel = self.filechooser.selection
        if sel:
            self.manager.get_screen("transfer").set_files(sel)
            self.manager.current = "devices"

class DevicesScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self._refresh_ev = None
        self.root_box = BoxLayout(orientation="vertical", spacing=dp(8), padding=dp(8))
        self.root_box.add_widget(Header("Nearby Devices", on_back=lambda *_: setattr(self.manager, "current", "filepicker")))
        self.devices_box = GridLayout(cols=1, spacing=dp(10), size_hint_y=None, padding=(0, dp(4)))
        self.devices_box.bind(minimum_height=self.devices_box.setter("height"))
        scroll = ScrollView()
        scroll.add_widget(self.devices_box)
        self.root_box.add_widget(scroll)

        row = BoxLayout(spacing=dp(10), size_hint_y=None, height=dp(56))
        proceed = PrimaryButton(text="Continue >")
        proceed.bind(on_release=self._continue)
        row.add_widget(proceed)
        self.root_box.add_widget(row)
        self.add_widget(self.root_box)

    def on_pre_enter(self, *_):
        self._refresh_list()
        if not self._refresh_ev:
            self._refresh_ev = Clock.schedule_interval(lambda dt: self._refresh_list(), 1.5)

    def on_leave(self, *_):
        if self._refresh_ev:
            self._refresh_ev.cancel()
            self._refresh_ev = None

    def _refresh_list(self):
        self.devices_box.clear_widgets()
        devices = App.get_running_app().registry.list_alive()
        if not devices:
            self.devices_box.add_widget(Label(
                text="No devices yet.\nOpen YowShare on another device in the same Wi-Fi.",
                color=THEME["muted"], size_hint_y=None, height=dp(64)
            ))
            return
        for d in devices:
            btn = SecondaryButton(text=f"{d['name']}  ({d['ip']})")
            btn.bind(on_release=lambda inst, dev=d: self._pick(dev))
            self.devices_box.add_widget(btn)

    def _pick(self, device):
        self.manager.get_screen("transfer").set_device(device)

    def _continue(self, *_):
        self.manager.current = "transfer"

class TransferScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.selected_files = []
        self.selected_device = None
        self._sending = False
        self._cancel = False

        self.root_box = BoxLayout(orientation="vertical", spacing=dp(10), padding=dp(10))
        self.root_box.add_widget(Header("Transfer", on_back=lambda *_: setattr(self.manager, "current", "devices")))

        status_col = BoxLayout(orientation="vertical", spacing=dp(6), size_hint_y=None)
        status_col.height = dp(110)
        self.status = Label(text="Pick files and a device.", color=THEME["ink"], font_size=dp(16))
        self.detail = Label(text="", color=THEME["muted"], font_size=dp(14))
        status_col.add_widget(self.status)
        status_col.add_widget(self.detail)
        self.root_box.add_widget(with_bg(status_col, THEME["card"]))

        self.progress = ProgressBar(max=100, value=0, size_hint_y=None, height=dp(8))
        self.info = Label(text="", color=THEME["muted"], font_size=dp(13), size_hint_y=None, height=dp(20))
        self.root_box.add_widget(self.progress)
        self.root_box.add_widget(self.info)

        row = BoxLayout(spacing=dp(10), size_hint_y=None, height=dp(56))
        self.btn_start = PrimaryButton(text="Start")
        self.btn_cancel = SecondaryButton(text="Cancel")
        self.btn_start.bind(on_release=self.start_transfer)
        self.btn_cancel.bind(on_release=self.cancel_transfer)
        row.add_widget(self.btn_start)
        row.add_widget(self.btn_cancel)
        self.root_box.add_widget(row)
        self.add_widget(self.root_box)

    def set_files(self, files):
        self.selected_files = files
        self.status.text = f"Selected {len(files)} file(s)."
        self.detail.text = "\n".join([os.path.basename(p) for p in files[:3]]) + ("\n…" if len(files) > 3 else "")

    def set_device(self, device):
        self.selected_device = device
        self.status.text = f"Ready to send to {device['name']} ({device['ip']})"

    def _on_progress(self, filename, sent, size, index, total):
        if size > 0:
            self.progress.value = int(100 * sent / size)
        self.info.text = f"Sending {index}/{total}: {filename}  {sent//1024} KiB / {size//1024} KiB"

    def start_transfer(self, *_):
        if not self.selected_files:
            self.info.text = "No files selected."
            return
        if not self.selected_device:
            self.info.text = "No device selected."
            return

        self._sending = True
        self._cancel = False
        self.progress.value = 0
        self.btn_start.disabled = True
        dev = self.selected_device
        cfg = App.get_running_app().cfg
        sender_name = cfg.get("device_name", "YowDevice")

        def worker():
            try:
                for idx, path in enumerate(self.selected_files, start=1):
                    if self._cancel:
                        break
                    send_file(dev["ip"], dev["port"], sender_name, path,
                              total_count=len(self.selected_files), index=idx,
                              on_progress=lambda fn, snt, sz, i, t:
                                  Clock.schedule_once(lambda *_: self._on_progress(fn, snt, sz, i, t), 0))
                    # Visual Sent copy + history
                    try:
                        dst = os.path.join(SENT_DIR, os.path.basename(path))
                        if os.path.abspath(path) != os.path.abspath(dst):
                            shutil.copy2(path, dst)
                        self._record_history("sent", os.path.basename(path), f"{dev['name']}@{dev['ip']}")
                    except Exception:
                        pass
                Clock.schedule_once(lambda *_: self._wrap_transfer(cancelled=self._cancel), 0)
            except PermissionError as e:
                Clock.schedule_once(lambda *_: self._error(str(e)), 0)
            except Exception as e:
                Clock.schedule_once(lambda *_: self._error(f"Send failed: {e}"), 0)

        threading.Thread(target=worker, daemon=True).start()

    def cancel_transfer(self, *_):
        if self._sending:
            self._cancel = True
            self.info.text = "Cancelling…"

    def _wrap_transfer(self, cancelled=False):
        self._sending = False
        self.btn_start.disabled = False
        self.progress.value = 0 if cancelled else 100
        self.info.text = "Transfer cancelled." if cancelled else "All files transferred!"

    def _error(self, msg):
        self._sending = False
        self.btn_start.disabled = False
        self.info.text = f"{msg}"

    def _record_history(self, kind, filename, peer):
        hist = load_json(HISTORY_PATH, [])
        hist.insert(0, {
            "ts": datetime.now().isoformat(timespec="seconds"),
            "type": kind,
            "file": filename,
            "peer": peer
        })
        hist = hist[:200]
        save_json(HISTORY_PATH, hist)

class ReceiveScreen(Screen):
    """Waiting screen with wave, proper accept/reject, optional trust-window."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self._trusted = {}  # sender -> expiry datetime

        self.root_box = BoxLayout(orientation="vertical", spacing=dp(10), padding=dp(10))
        self.root_box.add_widget(Header("Receive", on_back=lambda *_: setattr(self.manager, "current", "home")))
        self.add_widget(self.root_box)

        card = BoxLayout(orientation="vertical", spacing=dp(8), size_hint_y=None)
        card.height = dp(230)
        self.title = Label(text="Waiting for sender…", color=THEME["ink"], font_size=dp(18))
        self.subtitle = Label(text=f"Incoming folder:\n{RECEIVED_DIR}",
                              color=THEME["muted"], font_size=dp(14))
        self.wave = Wave(size_hint_y=None, height=dp(120))
        card.add_widget(self.title)
        card.add_widget(self.subtitle)
        card.add_widget(self.wave)
        self.root_box.add_widget(with_bg(card, THEME["card"]))

        row = BoxLayout(spacing=dp(10), size_hint_y=None, height=dp(56))
        open_btn = SecondaryButton(text="Open Received Folder")
        open_btn.bind(on_release=lambda *_: self._open_folder(RECEIVED_DIR))
        row.add_widget(open_btn)
        self.root_box.add_widget(row)

    # ---- server callbacks
    def on_offer(self, offer):
        """Return (accepted: bool, save_path: str). Blocks server thread until choice."""
        sender_key = offer["sender"]
        # Auto-accept if sender is temporary trusted
        if sender_key in self._trusted and self._trusted[sender_key] > datetime.now():
            dst = self._dedupe_path(offer["filename"])
            return True, dst

        ev = threading.Event()
        result = {"accepted": False, "save_path": None}

        @mainthread
        def ask():
            fn = offer["filename"]
            size_mb = offer["size"] / (1024*1024) if offer["size"] else 0
            cnt = offer["count"]; idx = offer["index"]

            content = BoxLayout(orientation="vertical", spacing=dp(10), padding=dp(10))
            content.add_widget(Label(text=f"Sender: {sender_key}", color=THEME["ink"]))
            content.add_widget(Label(text=f"File: {fn}  ({size_mb:.2f} MB)\nItem {idx}/{cnt}", color=THEME["muted"]))

            # Trust checkbox: simple toggle using a button state
            trust_state = {"val": False}
            trust_btn = SecondaryButton(text="Auto-accept this sender for 2 minutes: OFF")
            def toggle(*_):
                trust_state["val"] = not trust_state["val"]
                trust_btn.text = "Auto-accept this sender for 2 minutes: ON" if trust_state["val"] else \
                                 "Auto-accept this sender for 2 minutes: OFF"
            trust_btn.bind(on_release=toggle)
            content.add_widget(trust_btn)

            btns = BoxLayout(spacing=dp(10), size_hint_y=None, height=dp(48))
            accept = PrimaryButton(text="Accept")
            reject = SecondaryButton(text="Reject")
            btns.add_widget(reject)
            btns.add_widget(accept)
            content.add_widget(btns)

            popup = Popup(title="Incoming file", content=content, size_hint=(0.88, 0.55), auto_dismiss=False)

            def do_accept(*_):
                dst = self._dedupe_path(fn)
                result["accepted"] = True
                result["save_path"] = dst
                if trust_state["val"]:
                    self._trusted[sender_key] = datetime.now() + timedelta(minutes=2)
                popup.dismiss(); ev.set()

            def do_reject(*_):
                result["accepted"] = False
                result["save_path"] = None
                popup.dismiss(); ev.set()

            accept.bind(on_release=do_accept)
            reject.bind(on_release=do_reject)
            popup.open()

        ask()
        ev.wait()
        return result["accepted"], result["save_path"]

    @mainthread
    def on_progress(self, offer, got, total):
        self.title.text = f"Receiving {offer['index']}/{offer['count']}: {offer['filename']}  {got//1024} KiB / {total//1024} KiB"

    @mainthread
    def on_done(self, offer, save_path, sender_ip):
        self.title.text = "Received."
        self._record_history("received", offer["filename"], f"{offer['sender']}@{sender_ip}")
        self.manager.current = "history"

    @mainthread
    def on_error(self, msg):
        self.title.text = f"{msg}"

    def _dedupe_path(self, filename):
        dst = os.path.join(RECEIVED_DIR, filename)
        if not os.path.exists(dst):
            return dst
        name_no, ext = os.path.splitext(filename)
        return os.path.join(RECEIVED_DIR, f"{name_no}_{int(time.time())}{ext}")

    def _open_folder(self, path):
        try:
            if os.name == "nt":
                os.startfile(path)
            elif sys.platform == "darwin":
                os.system(f'open "{path}"')
            else:
                os.system(f'xdg-open "{path}"')
        except Exception as e:
            print("Open folder error:", e)

    def _record_history(self, kind, filename, peer):
        hist = load_json(HISTORY_PATH, [])
        hist.insert(0, {"ts": datetime.now().isoformat(timespec="seconds"), "type": kind, "file": filename, "peer": peer})
        hist = hist[:200]
        save_json(HISTORY_PATH, hist)

class HistoryScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.root_box = BoxLayout(orientation="vertical", spacing=dp(8), padding=dp(8))
        self.root_box.add_widget(Header("History", on_back=lambda *_: setattr(self.manager, "current", "home")))
        self.list_box = GridLayout(cols=1, spacing=dp(6), size_hint_y=None)
        self.list_box.bind(minimum_height=self.list_box.setter("height"))
        scr = ScrollView(); scr.add_widget(self.list_box)
        self.root_box.add_widget(scr)

        action_row = GridLayout(cols=2, spacing=dp(10), size_hint_y=None, height=dp(56))
        btn_clear = SecondaryButton(text="Clear")
        btn_open = SecondaryButton(text="Open Received")
        btn_clear.bind(on_release=self._clear)
        btn_open.bind(on_release=lambda *_: self._open_folder(RECEIVED_DIR))
        action_row.add_widget(btn_clear); action_row.add_widget(btn_open)
        self.root_box.add_widget(action_row)
        self.add_widget(self.root_box)

    def on_pre_enter(self, *_):
        self._refresh()

    def _refresh(self):
        self.list_box.clear_widgets()
        hist = load_json(HISTORY_PATH, [])
        if not hist:
            self.list_box.add_widget(Label(
                text="No transfers yet.", color=THEME["muted"],
                size_hint_y=None, height=dp(40)
            ))
            return
        for h in hist[:200]:
            row = BoxLayout(spacing=dp(8), size_hint_y=None, height=dp(56))
            kind = h["type"]
            left = "SENT" if kind == "sent" else "RECV"
            lbl = Label(text=f"{left}  {h['file']}  —  {h['peer']}\n{h['ts']}",
                        color=THEME["ink"], halign="left", valign="middle", font_size=dp(14))
            lbl.bind(size=lambda l, *_: setattr(l, "text_size", l.size))
            self.list_box.add_widget(with_bg(row, THEME["card"], radius=dp(12)))
            row.add_widget(lbl)

    def _clear(self, *_):
        save_json(HISTORY_PATH, [])
        self._refresh()

    def _open_folder(self, path):
        try:
            if os.name == "nt":
                os.startfile(path)
            elif sys.platform == "darwin":
                os.system(f'open "{path}"')
            else:
                os.system(f'xdg-open "{path}"')
        except Exception as e:
            print("Open folder error:", e)

class SettingsScreen(Screen):
    """Keep only device name (dark theme fixed)."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.root_box = BoxLayout(orientation="vertical", spacing=dp(10), padding=dp(10))
        self.root_box.add_widget(Header("Settings", on_back=lambda *_: setattr(self.manager, "current", "home")))
        cfg = load_json(CFG_PATH, {"device_name": f"Yow-{socket.gethostname()}"})

        form = GridLayout(cols=1, spacing=dp(10), size_hint_y=None)
        form.bind(minimum_height=form.setter("height"))

        form.add_widget(Label(text="Device Name", color=THEME["muted"]))
        self.input_name = TextInput(text=cfg.get("device_name", f"Yow-{socket.gethostname()}"),
                                    size_hint_y=None, height=dp(48), multiline=False)
        form.add_widget(self.input_name)
        self.root_box.add_widget(with_bg(form, THEME["card"]))

        row = BoxLayout(spacing=dp(10), size_hint_y=None, height=dp(56))
        back = SecondaryButton(text="Back")
        save = PrimaryButton(text="Save")
        back.bind(on_release=lambda *_: setattr(self.manager, "current", "home"))
        save.bind(on_release=self._save)
        row.add_widget(back); row.add_widget(save)
        self.root_box.add_widget(row)
        self.add_widget(self.root_box)

    def _save(self, *_):
        cfg = load_json(CFG_PATH, {"device_name": f"Yow-{socket.gethostname()}"})
        cfg["device_name"] = self.input_name.text.strip() or f"Yow-{socket.gethostname()}"
        save_json(CFG_PATH, cfg)
        print("Settings saved")
        self.manager.current = "home"

# ---------------
# App
# ---------------
class YowShareApp(App):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.cfg = load_json(CFG_PATH, {"device_name": f"Yow-{socket.gethostname()}"})
        if "device_name" not in self.cfg:
            self.cfg["device_name"] = f"Yow-{socket.gethostname()}"
            save_json(CFG_PATH, self.cfg)

        self.registry = DeviceRegistry()
        self.discovery = DiscoveryService(self.cfg["device_name"], self.registry)
        self.transfer_server = TransferServer(
            on_offer=self._on_offer_proxy,
            on_progress=self._on_progress_proxy,
            on_done=self._on_done_proxy,
            on_error=self._on_error_proxy,
        )

    def build(self):
        Window.clearcolor = THEME["bg"]
        sm = ScreenManager(transition=FadeTransition())
        sm.add_widget(HomeScreen(name="home"))
        sm.add_widget(FilePickerScreen(name="filepicker"))
        sm.add_widget(DevicesScreen(name="devices"))
        sm.add_widget(TransferScreen(name="transfer"))
        sm.add_widget(ReceiveScreen(name="receive"))
        sm.add_widget(HistoryScreen(name="history"))
        sm.add_widget(SettingsScreen(name="settings"))

        self.discovery.start()
        self.transfer_server.start()
        return sm

    # Proxies to ReceiveScreen for server callbacks
    def _get_receive(self):
        try:
            return self.root.get_screen("receive")
        except Exception:
            return None

    def _on_offer_proxy(self, offer):
        scr = self._get_receive()
        if scr: return scr.on_offer(offer)
        return False, None

    def _on_progress_proxy(self, offer, got, total):
        scr = self._get_receive()
        if scr: scr.on_progress(offer, got, total)

    def _on_done_proxy(self, offer, save_path, sender_ip):
        scr = self._get_receive()
        if scr: scr.on_done(offer, save_path, sender_ip)

    def _on_error_proxy(self, msg):
        scr = self._get_receive()
        if scr: scr.on_error(msg)
        else: print(msg)

    def on_stop(self):
        try:
            self.discovery.stop()
            self.transfer_server.stop()
        except Exception:
            pass

if __name__ == "__main__":
    YowShareApp().run()
