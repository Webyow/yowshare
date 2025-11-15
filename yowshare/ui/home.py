from ui.base_screen import BaseScreen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from ui.components import YButton

class HomeScreen(BaseScreen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        main = BoxLayout(orientation="vertical", padding=40, spacing=20)
        self.add_widget(main)

        main.add_widget(Label(
            text="YowShare",
            font_size=40
        ))

        send_btn = YButton(text="Send Files", font_size=24, height=60)
        receive_btn = YButton(text="Receive Files", font_size=24, height=60)

        send_btn.bind(on_release=lambda x: self.manager.go("send"))
        receive_btn.bind(on_release=lambda x: self.manager.go("receive"))

        main.add_widget(send_btn)
        main.add_widget(receive_btn)
