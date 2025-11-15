from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.widget import Widget
from kivy.properties import NumericProperty, ListProperty, StringProperty
from kivy.graphics import Color, RoundedRectangle, Rectangle
from kivy.clock import Clock
from kivy.animation import Animation
from kivy.graphics import Color, RoundedRectangle
from core.open_file import open_file
from ui.theme_manager import ThemeManager
import os


# =========================================================
#   YowShare Rounded Button
# =========================================================
class YButton(Button):
    bg_color = ListProperty(ThemeManager.get_color("button"))
    radius = NumericProperty(20)
    animation_scale = NumericProperty(1)   # <--- use scale, not size!

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.bind(pos=self.draw, size=self.draw, animation_scale=self.draw)
        self.bind(on_press=self.shrink_effect)

    def shrink_effect(self, *args):
        Animation(animation_scale=0.95, duration=0.05).start(self)
        Animation(animation_scale=1.0, duration=0.1).start(self)

    def draw(self, *args):
        self.canvas.before.clear()
        with self.canvas.before:
            s = self.animation_scale
            x = self.x + (self.width * (1 - s)) / 2
            y = self.y + (self.height * (1 - s)) / 2
            w = self.width * s
            h = self.height * s

            Color(*self.bg_color)
            RoundedRectangle(pos=(x, y), size=(w, h), radius=[self.radius])

# =========================================================
#   YowShare Card Container
# =========================================================
class YCard(BoxLayout):
    bg_color = ListProperty(ThemeManager.get_color("card"))
    radius = NumericProperty(20)
    animation_scale = NumericProperty(1)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.bind(pos=self.draw, size=self.draw, animation_scale=self.draw)
        self.bind(on_touch_down=self.card_down, on_touch_up=self.card_up)

    def card_down(self, widget, touch):
        if self.collide_point(*touch.pos):
            Animation(animation_scale=0.97, duration=0.05).start(self)

    def card_up(self, widget, touch):
        Animation(animation_scale=1.0, duration=0.1).start(self)

    def draw(self, *args):
        self.canvas.before.clear()
        with self.canvas.before:
            s = self.animation_scale
            x = self.x + (self.width * (1 - s)) / 2
            y = self.y + (self.height * (1 - s)) / 2
            w = self.width * s
            h = self.height * s

            Color(*self.bg_color)
            RoundedRectangle(pos=(x, y), size=(w, h), radius=[self.radius])


# =========================================================
#   Section Title
# =========================================================
class SectionTitle(Label):
    """
    A clean section title used in screens like SEND, RECEIVE, SCAN.
    """

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.font_size = kwargs.get("font_size", 24)
        self.size_hint_y = None
        self.height = 50
        self.bold = True
        self.color = [0.15, 0.15, 0.15, 1]


# =========================================================
#   Spacer (For Layout)
# =========================================================
class YSpacer(Widget):
    """
    Simple invisible widget for spacing.
    """
    pass


# =========================================================
#   Progress Bar (Custom Drawn)
# =========================================================
class YProgressBar(Widget):
    """
    A clean rectangle progress bar drawn manually.
    """

    progress = NumericProperty(0)  # 0.0 → 1.0

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.height = kwargs.get("height", 18)
        self.size_hint_y = None
        self.bind(pos=self.draw, size=self.draw, progress=self.draw)

    def draw(self, *args):
        self.canvas.clear()
        with self.canvas:
            # Background bar
            Color(0.85, 0.85, 0.85, 1)
            Rectangle(pos=self.pos, size=self.size)

            # Progress bar
            Color(0.1, 0.5, 1, 1)
            Rectangle(
                pos=self.pos,
                size=(self.width * self.progress, self.height)
            )


# =========================================================
#   Device Tile Component
# =========================================================
class DeviceTile(YCard):
    """
    A card representing a nearby YowShare device.
    """

    title = StringProperty("Unknown Device")
    ip = StringProperty("0.0.0.0")

    def __init__(self, **kwargs):
        super().__init__(orientation="horizontal", **kwargs)
        name_lbl = Label(text=self.title, font_size=20, color = ThemeManager.get_color("text"))
        ip_lbl = Label(text=self.ip, font_size=16, color=[0.3, 0.3, 0.3, 1])

        self.add_widget(name_lbl)
        self.add_widget(ip_lbl)


# =========================================================
#   File Item Component
# =========================================================
class FileItem(YCard):
    """
    A card representing a file to send or file received.
    """

    file_name = StringProperty("")
    file_size = StringProperty("")

    def __init__(self, **kwargs):
        super().__init__(orientation="vertical", **kwargs)

        name_lbl = Label(text=self.file_name, font_size=20, color=[0, 0, 0, 1])
        size_lbl = Label(text=f"{self.file_size} KB", font_size=16, color=[0.4, 0.4, 0.4, 1])

        self.add_widget(name_lbl)
        self.add_widget(size_lbl)

class ReceiveProgressBox(YCard):
    def __init__(self, **kwargs):
        super().__init__(orientation="vertical", **kwargs)

        self.label = Label(
            text="Receiving…",
            font_size=20,
            color=[0, 0, 0, 1],
            size_hint_y=None,
            height=40
        )
        self.bar = YProgressBar(height=20)

        self.add_widget(self.label)
        self.add_widget(self.bar)

    def update(self, name, progress):
        self.label.text = f"{name}   {int(progress*100)}%"
        self.bar.progress = progress
# =========================================================

class FileItem(YCard):
    file_name = StringProperty("")
    file_size = StringProperty("")

    def __init__(self, **kwargs):
        super().__init__(orientation="horizontal", **kwargs)

        left = BoxLayout(orientation="vertical")
        name_lbl = Label(text=self.file_name, font_size=20, color=[0, 0, 0, 1])
        size_lbl = Label(text=f"{self.file_size} KB", font_size=16, color=[0.4, 0.4, 0.4, 1])
        left.add_widget(name_lbl)
        left.add_widget(size_lbl)

        open_btn = YButton(
            text="Open",
            font_size=16,
            height=40,
            size_hint=(None, None),
            width=100,
            bg_color=[0.1, 0.7, 0.1, 1],
            on_release=self.open_item
        )

        self.add_widget(left)
        self.add_widget(open_btn)

    def open_item(self, *args):
        # resolve full path
        from app_config import RECEIVED_DIR, SENT_DIR

        # guess folder based on existence
        recv_path = os.path.join(RECEIVED_DIR, self.file_name)
        sent_path = os.path.join(SENT_DIR, self.file_name)

        if os.path.exists(recv_path):
            open_file(recv_path)
        elif os.path.exists(sent_path):
            open_file(sent_path)
        else:
            print("[YowShare] File not found!")