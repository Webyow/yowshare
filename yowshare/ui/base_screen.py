from kivy.uix.screenmanager import Screen
from kivy.animation import Animation
from kivy.graphics import Color, Rectangle
from ui.theme_manager import ThemeManager


class BaseScreen(Screen):

    def on_enter(self, *args):
        # Fade animation
        self.opacity = 0
        Animation(opacity=1, duration=0.25).start(self)
        self.update_theme()

    def update_theme(self):
        """
        Draw background on the FIRST CHILD of the screen,
        NOT on the screen itself (ScreenManager stencil-safe)
        """
        if len(self.children) == 0:
            return

        root = self.children[0]   # MUST be a layout widget, not the screen

        # Clear background safely on the layout, NOT screen
        root.canvas.before.clear()
        with root.canvas.before:
            Color(*ThemeManager.get_color("background"))
            Rectangle(pos=root.pos, size=root.size)

        # Redraw when layout changes size or pos
        root.bind(pos=self._redraw_bg, size=self._redraw_bg)

        # Update theme for every child widget
        for child in root.walk():
            if hasattr(child, "apply_theme"):
                child.apply_theme()

    def _redraw_bg(self, root, *args):
        root.canvas.before.clear()
        with root.canvas.before:
            Color(*ThemeManager.get_color("background"))
            Rectangle(pos=root.pos, size=root.size)
