import os
import sys

#
# ========== YowShare Global Configuration ==========
#

APP_NAME = "YowShare"
VERSION = "1.0.0"

# Default server port for file sharing
SERVER_PORT = 9000

# Base storage directory for app data
BASE_DIR = os.path.join(os.getcwd(), "data")

# Subdirectories for received, sent, and temp files
RECEIVED_DIR = os.path.join(BASE_DIR, "received")
SENT_DIR = os.path.join(BASE_DIR, "sent")
TEMP_DIR = os.path.join(BASE_DIR, "temp")

def create_directories():
    """
    Auto-create required directory structure for YowShare.
    Runs on startup from main.py.
    """
    for folder in [BASE_DIR, RECEIVED_DIR, SENT_DIR, TEMP_DIR]:
        if not os.path.exists(folder):
            os.makedirs(folder)

def is_android():
    """
    Detect if running on Android platform.
    """
    return "ANDROID_ARGUMENT" in os.environ

def is_windows():
    return sys.platform.startswith("win")

def is_linux():
    return sys.platform.startswith("linux")

def is_mac():
    return sys.platform.startswith("darwin")
