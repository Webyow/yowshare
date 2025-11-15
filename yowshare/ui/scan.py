from ui.base_screen import BaseScreen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.gridlayout import GridLayout
from kivy.uix.label import Label
from ui.components import DeviceTile, SectionTitle, YButton
from core.scanner import scan_devices


class ScanScreen(BaseScreen):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        main = BoxLayout(orientation="vertical", spacing=15, padding=20)
        self.add_widget(main)

        # Title
        main.add_widget(Label(
            text="Nearby Devices",
            font_size=32,
            size_hint=(1, 0.15)
        ))

        # Refresh Button
        main.add_widget(YButton(
            text="Scan Again",
            font_size=22,
            size_hint_y=None,
            height=60,
            on_release=self.refresh_scan
        ))

        # Section Title
        main.add_widget(SectionTitle(text="Devices Found", font_size=24))

        # Scroll area
        scroll = ScrollView(size_hint=(1, 0.7))
        self.device_layout = GridLayout(cols=1, spacing=10, size_hint_y=None)
        self.device_layout.bind(minimum_height=self.device_layout.setter("height"))
        scroll.add_widget(self.device_layout)
        main.add_widget(scroll)

        self.bind(on_enter=lambda *a: self.refresh_scan())

    # ==========================================================
    #   SCAN LOGIC
    # ==========================================================
    def refresh_scan(self, *args):
        self.device_layout.clear_widgets()
        devices = scan_devices()

        if not devices:
            self.device_layout.add_widget(Label(
                text="No devices found",
                font_size=18,
                size_hint_y=None,
                height=50
            ))
            return

        for dev in devices:
            tile = DeviceTile(
                title=dev["name"],
                ip=dev["ip"],
                size_hint_y=None,
                height=80
            )

            # Instead of on_touch_down — safe button-type callback
            tile.bind(on_release=lambda t, d=dev: self.select_device(d))

            self.device_layout.add_widget(tile)

    # ==========================================================
    #   DEVICE SELECTION
    # ==========================================================
    def select_device(self, device):
        print(f"[YowShare] Selected device: {device}")
        self.manager.selected_device = device
        self.manager.current = "send"
