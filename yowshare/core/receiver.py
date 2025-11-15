import os
import uuid
from app_config import TEMP_DIR, RECEIVED_DIR
import shutil

incoming_files = {}
receiving_progress = {}   # file_id → progress (0.0–1.0)
receiving_sizes = {}      # file_id → total size in bytes (coming from client)
current_written = {}      # file_id → written bytes so far

#
# ========== START RECEIVING ==========
#
def start_receive_progress(filename):
    file_id = str(uuid.uuid4())

    incoming_files[file_id] = {
        "id": file_id,
        "name": filename,
        "size": 0,           # filled on finish
        "temp_path": "",
        "progress": 0.0
    }

    receiving_progress[file_id] = 0.0
    current_written[file_id] = 0

    print(f"[YowShare] Starting receive: {filename}")
    return file_id


#
# ========== UPDATE PROGRESS ==========
#
def update_receive_progress(file_id, written_bytes):
    current_written[file_id] = written_bytes
    incoming_files[file_id]["progress"] = written_bytes  # temp store


#
# ========== FINISH RECEIVE ==========
#
def finish_receive_file(file_id, temp_path):
    incoming_files[file_id]["temp_path"] = temp_path
    incoming_files[file_id]["size"] = os.path.getsize(temp_path) // 1024

    print(f"[YowShare] Finished receiving: {incoming_files[file_id]['name']}")

    # Reset internal temp trackers
    receiving_progress[file_id] = 1.0
    incoming_files[file_id]["progress"] = 1.0


#
# ========== FETCH PROGRESS FROM UI ==========
#
def get_progress(file_id):
    if file_id not in incoming_files:
        return 0
    return incoming_files[file_id].get("progress", 0.0)


#
# ========== EXISTING FUNCTIONS UNCHANGED ==========
#
def get_incoming_files():
    return list(incoming_files.values())


def accept_file(file_id):
    info = incoming_files[file_id]
    src = info["temp_path"]
    dst = os.path.join(RECEIVED_DIR, info["name"])
    shutil.move(src, dst)
    del incoming_files[file_id]
    return True


def reject_file(file_id):
    info = incoming_files[file_id]
    os.remove(info["temp_path"])
    del incoming_files[file_id]
    return True
