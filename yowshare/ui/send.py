from ui.base_screen import BaseScreen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.scrollview import ScrollView
from kivy.uix.gridlayout import GridLayout
from kivy.uix.filechooser import FileChooserIconView
from ui.components import YButton, YCard
from core.scanner import scan_devices
from core.sender import send_files_to_device_with_progress


class SendScreen(BaseScreen):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.selected_files = []
        self.available_devices = []
        self.selected_device = None

        main = BoxLayout(orientation="vertical", spacing=15, padding=20)
        self.add_widget(main)

        # Title
        main.add_widget(Label(
            text="Send Files",
            font_size=32,
            size_hint=(1, 0.15)
        ))

        # File chooser
        self.file_chooser = FileChooserIconView(multiselect=True)
        self.file_chooser.bind(selection=self.on_file_select)
        main.add_widget(self.file_chooser)

        # Selected files label
        main.add_widget(Label(
            text="Selected Files:",
            font_size=22,
            size_hint=(1, 0.1)
        ))

        # Selected files list
        scroll_files = ScrollView(size_hint=(1, 0.3))
        self.file_list = GridLayout(cols=1, spacing=10, size_hint_y=None)
        self.file_list.bind(minimum_height=self.file_list.setter("height"))
        scroll_files.add_widget(self.file_list)
        main.add_widget(scroll_files)

        # Scan devices button
        main.add_widget(YButton(
            text="Scan Nearby Devices",
            font_size=20,
            size_hint=(1, 0.15),
            height=60,
            on_release=self.scan_for_devices
        ))

        # Devices label
        self.device_list_label = Label(
            text="Devices:",
            font_size=22,
            size_hint=(1, 0.1)
        )
        main.add_widget(self.device_list_label)

        # Devices list
        scroll_devices = ScrollView(size_hint=(1, 0.3))
        self.device_list = GridLayout(cols=1, spacing=10, size_hint_y=None)
        self.device_list.bind(minimum_height=self.device_list.setter("height"))
        scroll_devices.add_widget(self.device_list)
        main.add_widget(scroll_devices)

        # Send button
        main.add_widget(YButton(
            text="Send",
            font_size=24,
            size_hint=(1, 0.2),
            height=70,
            on_release=self.send_selected_files
        ))

    # ======================================================
    # FILE SELECTION
    # ======================================================
    def on_file_select(self, chooser, selection):
        self.selected_files = selection
        self.update_file_list_ui()

    def update_file_list_ui(self):
        self.file_list.clear_widgets()
        for path in self.selected_files:
            name = path.split("/")[-1]
            card = YCard(size_hint_y=None, height=60)
            card.add_widget(Label(text=name, font_size=18))
            self.file_list.add_widget(card)

    # ======================================================
    # DEVICE SCAN
    # ======================================================
    def scan_for_devices(self, *args):
        self.device_list.clear_widgets()
        self.available_devices = scan_devices()

        if not self.available_devices:
            self.device_list.add_widget(Label(text="No devices found", font_size=18))
            return

        for dev in self.available_devices:
            btn = YButton(
                text=f"{dev['name']} ({dev['ip']})",
                size_hint_y=None,
                height=60,
                on_release=lambda b, d=dev: self.select_device(d)
            )
            self.device_list.add_widget(btn)

    def select_device(self, device):
        self.selected_device = device
        self.device_list_label.text = f"Selected Device: {device['name']} ({device['ip']})"

    # ======================================================
    # SEND FILES
    # ======================================================
    def send_selected_files(self, *args):
        if not self.selected_files:
            print("[YowShare] No files selected.")
            return

        if not self.selected_device:
            print("[YowShare] No device selected.")
            return

        device = self.selected_device
        files = self.selected_files.copy()

        print(f"[YowShare] Sending {len(files)} files to {device['ip']}...")

        send_files_to_device_with_progress(
            device,
            files,
            on_progress=lambda p, f: print(f"[YowShare] {f}: {p*100:.1f}%"),
            on_file_done=lambda f: print(f"[YowShare] Finished {f}"),
            on_all_done=lambda: print("[YowShare] All sent.")
        )
