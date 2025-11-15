from kivy.app import App
from kivy.uix.screenmanager import ScreenManager, NoTransition
from kivy.core.window import Window

from ui.theme_manager import ThemeManager
from app_config import APP_NAME, create_directories
from core.server import run_server_in_background

from ui.home import HomeScreen
from ui.send import SendScreen
from ui.receive import ReceiveScreen
from ui.scan import ScanScreen
from ui.history import HistoryScreen
from ui.settings import SettingsScreen


class YowShareManager(ScreenManager):
    """Centralized screen navigation"""

    selected_device = None

    def go(self, name):
        if name in self.screen_names:
            self.current = name
        else:
            print(f"[YowShare] Screen '{name}' does not exist.")


class YowShareApp(App):
    def build(self):

        Window.size = (420, 720)  # desktop preview safe size
        self.title = APP_NAME

        create_directories()
        run_server_in_background()

        sm = YowShareManager(transition=NoTransition())

        # Add screens
        sm.add_widget(HomeScreen(name="home"))
        sm.add_widget(SendScreen(name="send"))
        sm.add_widget(ReceiveScreen(name="receive"))
        sm.add_widget(ScanScreen(name="scan"))
        sm.add_widget(HistoryScreen(name="history"))
        sm.add_widget(SettingsScreen(name="settings"))

        sm.current = "home"

        return sm

    def on_start(self):
        # Apply theme on startup
        Window.clearcolor = ThemeManager.get_color("background")


if __name__ == "__main__":
    YowShareApp().run()
