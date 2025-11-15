# ui/theme_manager.py

class ThemeManager:
    """
    Global theme system for YowShare.
    """

    mode = "light"

    light_theme = {
        "background": [1, 1, 1, 1],
        "text": [0, 0, 0, 1],
        "subtext": [0.3, 0.3, 0.3, 1],      # ADDED
        "card": [1, 1, 1, 1],
        "button": [0.1, 0.5, 1, 1],
        "secondary": [0.8, 0.8, 0.8, 1]
    }

    dark_theme = {
        "background": [0.06, 0.06, 0.06, 1],
        "text": [1, 1, 1, 1],
        "subtext": [0.7, 0.7, 0.7, 1],       # ADDED
        "card": [0.12, 0.12, 0.12, 1],
        "button": [0.2, 0.6, 1, 1],
        "secondary": [0.25, 0.25, 0.25, 1]
    }

    @classmethod
    def get_color(cls, key):
        return (cls.light_theme if cls.mode == "light" else cls.dark_theme).get(key, [1, 0, 0, 1])

    @classmethod
    def toggle(cls):
        cls.mode = "dark" if cls.mode == "light" else "light"
        print(f"[YowShare] Theme changed → {cls.mode}")
