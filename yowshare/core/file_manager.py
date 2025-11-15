import os
import shutil
import time
from app_config import BASE_DIR, RECEIVED_DIR, SENT_DIR, TEMP_DIR, create_directories


# ===========================================================
#   ENSURE DIRECTORIES EXIST
# ===========================================================
def ensure_dirs():
    """
    Make sure /received, /sent, /temp exist.
    """
    create_directories()


# ===========================================================
#   SAFE FILENAME GENERATOR
# ===========================================================
def safe_filename(directory, filename):
    """
    If a file already exists, auto-rename:
    example.jpg → example(1).jpg → example(2).jpg
    """

    base, ext = os.path.splitext(filename)
    new_name = filename
    counter = 1

    while os.path.exists(os.path.join(directory, new_name)):
        new_name = f"{base}({counter}){ext}"
        counter += 1

    return new_name


# ===========================================================
#   MOVE TEMP FILE TO RECEIVED
# ===========================================================
def save_received_file(temp_path):
    """
    Moves a file from temp folder to received folder safely.
    Returns the final saved path.
    """

    ensure_dirs()

    filename = os.path.basename(temp_path)
    final_name = safe_filename(RECEIVED_DIR, filename)
    final_path = os.path.join(RECEIVED_DIR, final_name)

    shutil.move(temp_path, final_path)
    return final_path


# ===========================================================
#   SAVE SENT FILE TO HISTORY
# ===========================================================
def log_sent_file(file_path):
    """
    Copy file to /sent folder for history.
    """
    ensure_dirs()

    filename = os.path.basename(file_path)
    final_name = safe_filename(SENT_DIR, filename)
    dst_path = os.path.join(SENT_DIR, final_name)

    shutil.copy(file_path, dst_path)
    return dst_path


# ===========================================================
#   LIST FILES IN DIRECTORY
# ===========================================================
def list_files(directory):
    """
    Return list of file names in directory.
    """
    if not os.path.exists(directory):
        return []

    return [f for f in os.listdir(directory) if os.path.isfile(os.path.join(directory, f))]


def list_received():
    return list_files(RECEIVED_DIR)


def list_sent():
    return list_files(SENT_DIR)


# ===========================================================
#   CLEAR TEMP FOLDER
# ===========================================================
def clear_temp():
    """
    Delete all leftover files in TEMP_DIR.
    Useful on startup or after accept/reject.
    """
    if not os.path.exists(TEMP_DIR):
        return

    for f in os.listdir(TEMP_DIR):
        try:
            os.remove(os.path.join(TEMP_DIR, f))
        except:
            pass


# ===========================================================
#   STORAGE SIZE HELPERS
# ===========================================================
def get_file_size_kb(path):
    try:
        return os.path.getsize(path) // 1024
    except:
        return 0


def get_folder_size_kb(directory):
    total = 0
    for root, dirs, files in os.walk(directory):
        for f in files:
            try:
                total += os.path.getsize(os.path.join(root, f))
            except:
                pass
    return total // 1024
