from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.scrollview import ScrollView
from kivy.uix.gridlayout import GridLayout
from ui.base_screen import BaseScreen
from core.file_manager import clear_temp, list_received, list_sent, RECEIVED_DIR, SENT_DIR
from ui.components import YButton, SectionTitle, YCard
from core.open_file import open_folder
from app_config import SERVER_PORT
from ui.theme_manager import ThemeManager


class SettingsScreen(BaseScreen):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.main = BoxLayout(orientation="vertical", spacing=20, padding=20)
        self.add_widget(self.main)

        self.build_ui()

    # ---------------------------------------------------------
    # BUILD UI
    # ---------------------------------------------------------
    def build_ui(self):
        main = self.main
        main.clear_widgets()

        # Title
        main.add_widget(Label(
            text="Settings",
            font_size=32,
            size_hint=(1, 0.15),
            color=ThemeManager.get_color("text")
        ))

        # Scroll container
        scroll = ScrollView(size_hint=(1, 0.85))
        container = GridLayout(cols=1, spacing=20, size_hint_y=None)
        container.bind(minimum_height=container.setter("height"))
        scroll.add_widget(container)
        main.add_widget(scroll)

        # --------------- CLEANUP SECTION ---------------
        container.add_widget(SectionTitle(text="Cleanup"))

        container.add_widget(YButton(
            text="Clear Temp Folder",
            bg_color=[0.9, 0.3, 0.3, 1],
            height=60,
            on_release=lambda x: self.clear_temp_action()
        ))

        container.add_widget(YButton(
            text="Clear Sent History",
            bg_color=[0.9, 0.5, 0.3, 1],
            height=60,
            on_release=lambda x: self.clear_sent()
        ))

        container.add_widget(YButton(
            text="Clear Received History",
            bg_color=[0.3, 0.7, 0.3, 1],
            height=60,
            on_release=lambda x: self.clear_received()
        ))

        # --------------- OPEN FOLDERS ---------------
        container.add_widget(SectionTitle(text="Open Folders"))

        container.add_widget(YButton(
            text="Open Sent Folder",
            bg_color=[0.3, 0.6, 1, 1],
            height=60,
            on_release=lambda x: open_folder(SENT_DIR)
        ))

        container.add_widget(YButton(
            text="Open Received Folder",
            bg_color=[0.3, 0.4, 1, 1],
            height=60,
            on_release=lambda x: open_folder(RECEIVED_DIR)
        ))

        # --------------- THEME SWITCH ---------------
        container.add_widget(YButton(
            text="Toggle Light / Dark Mode",
            bg_color=[0.2, 0.2, 0.2, 1],
            height=60,
            on_release=lambda x: self.toggle_theme()
        ))

        # --------------- SERVER INFO ---------------
        container.add_widget(SectionTitle(text="Server Info"))

        server_card = YCard(size_hint_y=None, height=120)
        server_card.add_widget(Label(
            text=f"Server Port: {SERVER_PORT}",
            font_size=18,
            color=ThemeManager.get_color("text")
        ))
        server_card.add_widget(Label(
            text="(Port change will be added soon)",
            font_size=14,
            color=ThemeManager.get_color("subtext")
        ))
        container.add_widget(server_card)

        # --------------- ABOUT ---------------
        container.add_widget(SectionTitle(text="About YowShare"))

        about_card = YCard(size_hint_y=None, height=160)
        about_card.add_widget(Label(
            text="YowShare v1.0",
            font_size=22,
            color=ThemeManager.get_color("text")
        ))
        about_card.add_widget(Label(
            text="A multi-platform file sharing app\nBuilt with Kivy & Python",
            font_size=16,
            color=ThemeManager.get_color("subtext")
        ))
        container.add_widget(about_card)

    # ---------------------------------------------------------
    # ACTIONS
    # ---------------------------------------------------------
    def clear_temp_action(self):
        clear_temp()
        print("[YowShare] Temp folder cleared")

    def clear_sent(self):
        from os import remove
        from os.path import join

        for f in list_sent():
            remove(join(SENT_DIR, f))
        print("[YowShare] Sent history cleared")

    def clear_received(self):
        from os import remove
        from os.path import join

        for f in list_received():
            remove(join(RECEIVED_DIR, f))
        print("[YowShare] Received history cleared")

    def toggle_theme(self):
        ThemeManager.toggle()
        self.update_theme()          # Rebuild this screen
        self.manager.current_screen.update_theme()  # Update active screen
