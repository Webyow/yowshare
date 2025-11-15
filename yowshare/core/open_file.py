import os
import platform
import subprocess
import webbrowser

from app_config import RECEIVED_DIR, SENT_DIR


def open_file(path):
    """
    Open a file using the default app of the OS.
    """

    if not os.path.exists(path):
        print(f"[YowShare] File does not exist: {path}")
        return

    system = platform.system()

    # ---- WINDOWS ----
    if system == "Windows":
        os.startfile(path)

    # ---- MAC ----
    elif system == "Darwin":
        subprocess.call(["open", path])

    # ---- LINUX ----
    elif system == "Linux":
        subprocess.call(["xdg-open", path])

    # ---- ANDROID ----
    elif system == "Java":  # Kivy on Android = 'Java'
        try:
            # Import jnius dynamically to avoid static analysis errors in non-Android environments
            try:
                jnius = __import__("jnius")
                autoclass = jnius.autoclass
                cast = jnius.cast
            except Exception:
                # Let the outer exception handler report the error
                raise

            PythonActivity = autoclass("org.kivy.android.PythonActivity")
            Intent = autoclass("android.content.Intent")
            File = autoclass("java.io.File")
            Uri = autoclass("android.net.Uri")

            file_obj = File(path)
            uri = Uri.fromFile(file_obj)

            intent = Intent()
            intent.setAction(Intent.ACTION_VIEW)

            # Let Android detect MIME type automatically
            intent.setDataAndType(uri, "*/*")
            intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)

            current_activity = PythonActivity.mActivity
            current_activity.startActivity(intent)

        except Exception as e:
            print(f"[YowShare] Android open error: {e}")

    else:
        webbrowser.open(path)



def open_folder(folder_path):
    """
    Open a folder using system file explorer.
    """

    if not os.path.exists(folder_path):
        print("[YowShare] Folder does not exist:", folder_path)
        return

    system = platform.system()

    if system == "Windows":
        os.startfile(folder_path)

    elif system == "Darwin":
        subprocess.call(["open", folder_path])

    elif system == "Linux":
        subprocess.call(["xdg-open", folder_path])

    elif system == "Java":
        # Android: open file manager in folder view
        print("[YowShare] Folder open on Android is limited; opening via intent.")
        open_file(folder_path)
