from ui.base_screen import BaseScreen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.scrollview import ScrollView
from kivy.uix.gridlayout import GridLayout
from kivy.clock import Clock
from ui.components import YButton, ReceiveProgressBox
from core.receiver import get_incoming_files, accept_file, reject_file


class ReceiveScreen(BaseScreen):
    """
    Safe version: uses BaseScreen + YButtons.
    """

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        main = BoxLayout(orientation="vertical", spacing=15, padding=20)
        self.add_widget(main)

        # Title
        main.add_widget(Label(
            text="Receive Files",
            font_size=32,
            size_hint=(1, 0.1)
        ))

        # Progress box
        self.progress_box = ReceiveProgressBox(size_hint_y=None, height=100)
        main.add_widget(self.progress_box)

        # Timer
        self.progress_event = Clock.schedule_interval(self.update_progress_loop, 0.2)

        # Instruction
        main.add_widget(Label(
            text="Waiting for incoming files...",
            font_size=20,
            size_hint=(1, 0.1)
        ))

        # Incoming list
        scroll = ScrollView(size_hint=(1, 0.7))
        self.list_layout = GridLayout(cols=1, spacing=10, size_hint_y=None)
        self.list_layout.bind(minimum_height=self.list_layout.setter("height"))
        scroll.add_widget(self.list_layout)
        main.add_widget(scroll)

        # Refresh
        main.add_widget(YButton(
            text="Refresh Incoming Files",
            font_size=20,
            size_hint=(1, 0.1),
            on_release=self.refresh_list
        ))


    # ================================
    # List refresh
    # ================================
    def refresh_list(self, *args):
        self.incoming_files = get_incoming_files()
        self.list_layout.clear_widgets()

        if not self.incoming_files:
            self.list_layout.add_widget(
                Label(text="No incoming files", font_size=18, size_hint_y=None, height=40)
            )
            return

        for file_data in self.incoming_files:
            file_name = file_data["name"]
            file_size = file_data["size"]
            file_id = file_data["id"]

            row = BoxLayout(orientation="horizontal", size_hint_y=None, height=60, spacing=10)

            row.add_widget(Label(
                text=f"{file_name} ({file_size} KB)",
                font_size=18,
                size_hint_x=0.5
            ))

            row.add_widget(YButton(
                text="Accept",
                font_size=16,
                size_hint_x=0.25,
                height=50,
                on_release=lambda b, fid=file_id: self.accept_incoming(fid)
            ))

            row.add_widget(YButton(
                text="Reject",
                font_size=16,
                size_hint_x=0.25,
                height=50,
                on_release=lambda b, fid=file_id: self.reject_incoming(fid)
            ))

            self.list_layout.add_widget(row)

    def accept_incoming(self, file_id):
        accept_file(file_id)
        self.refresh_list()

    def reject_incoming(self, file_id):
        reject_file(file_id)
        self.refresh_list()

    def update_progress_loop(self, dt):
        files = get_incoming_files()
        if not files:
            self.progress_box.update("Waiting…", 0)
            return

        latest = files[-1]
        name = latest["name"]
        progress = latest.get("progress", 0)
        self.progress_box.update(name, progress)
