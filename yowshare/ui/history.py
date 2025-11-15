from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.gridlayout import GridLayout
from kivy.uix.label import Label
from ui.base_screen import BaseScreen
from core.file_manager import list_sent, list_received, get_file_size_kb, RECEIVED_DIR, SENT_DIR
from ui.components import SectionTitle, FileItem, YSpacer


class HistoryScreen(BaseScreen):
    """
    Shows transfer history:
    - Sent files
    - Received files
    Pure Python UI with YCard + FileItem components.
    """

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        main = BoxLayout(orientation="vertical", spacing=15, padding=20)

        #
        # Page Title
        #
        main.add_widget(Label(
            text="Transfer History",
            font_size=32,
            size_hint=(1, 0.15)
        ))

        #
        # SENT FILES SECTION
        #
        main.add_widget(SectionTitle(text="Sent Files"))

        scroll_sent = ScrollView(size_hint=(1, 0.35))
        self.sent_layout = GridLayout(cols=1, spacing=10, size_hint_y=None)
        self.sent_layout.bind(minimum_height=self.sent_layout.setter("height"))
        scroll_sent.add_widget(self.sent_layout)

        main.add_widget(scroll_sent)

        #
        # RECEIVED FILES SECTION
        #
        main.add_widget(SectionTitle(text="Received Files"))

        scroll_received = ScrollView(size_hint=(1, 0.35))
        self.recv_layout = GridLayout(cols=1, spacing=10, size_hint_y=None)
        self.recv_layout.bind(minimum_height=self.recv_layout.setter("height"))
        scroll_received.add_widget(self.recv_layout)

        main.add_widget(scroll_received)

        self.add_widget(main)

        # Reload history whenever screen is entered
        self.bind(on_enter=lambda *a: self.load_history())

    # ============================================================
    #   Load sent and received file lists
    # ============================================================
    def load_history(self):
        self.load_sent()
        self.load_received()

    # ============================================================
    #   SENT FILES
    # ============================================================
    def load_sent(self):
        self.sent_layout.clear_widgets()

        files = list_sent()

        if not files:
            self.sent_layout.add_widget(Label(
                text="No sent files yet",
                font_size=18,
                size_hint_y=None,
                height=40
            ))
            return

        for file_name in files:
            full_path = f"{SENT_DIR}/{file_name}"
            size = get_file_size_kb(full_path)

            item = FileItem(
                file_name=file_name,
                file_size=size,
                size_hint_y=None,
                height=90
            )

            self.sent_layout.add_widget(item)

        # Add small bottom spacer
        self.sent_layout.add_widget(YSpacer(size_hint_y=None, height=20))

    # ============================================================
    #   RECEIVED FILES
    # ============================================================
    def load_received(self):
        self.recv_layout.clear_widgets()

        files = list_received()

        if not files:
            self.recv_layout.add_widget(Label(
                text="No received files yet",
                font_size=18,
                size_hint_y=None,
                height=40
            ))
            return

        for file_name in files:
            full_path = f"{RECEIVED_DIR}/{file_name}"
            size = get_file_size_kb(full_path)

            item = FileItem(
                file_name=file_name,
                file_size=size,
                size_hint_y=None,
                height=90
            )

            self.recv_layout.add_widget(item)

        # Add small bottom spacer
        self.recv_layout.add_widget(YSpacer(size_hint_y=None, height=20))
