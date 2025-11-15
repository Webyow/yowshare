from http.server import SimpleHTTPRequestHandler, HTTPServer
import threading
import os
import json

from app_config import RECEIVED_DIR, TEMP_DIR, SERVER_PORT


class YowShareHandler(SimpleHTTPRequestHandler):
    """
    HTTP server handler for YowShare.
    Supports:
    - POST /upload      : Receive file
    - GET  /download    : Download a file
    - GET  /ping        : Identify device
    """

    # Disable logging spam
    def log_message(self, format, *args):
        return

    # ===================================================
    #   GET REQUESTS
    # ===================================================
    def do_GET(self):
        if self.path == "/ping":
            # Device identification response
            info = {
                "app": "YowShare",
                "device_name": (
                    os.uname().nodename if hasattr(os, "uname") else "YowShare-Device"
                ),
            }

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps(info).encode())
            return

        # Basic file server for downloading files later
        if self.path.startswith("/download/"):
            filename = self.path.replace("/download/", "")
            file_path = os.path.join(RECEIVED_DIR, filename)

            if os.path.exists(file_path):
                self.send_response(200)
                self.send_header("Content-Type", "application/octet-stream")
                self.send_header(
                    "Content-Disposition", f"attachment; filename={filename}"
                )
                self.end_headers()

                with open(file_path, "rb") as f:
                    self.wfile.write(f.read())
                return

            self.send_error(404, "File not found")
            return

        # Any other request = 404
        self.send_error(404, "Invalid endpoint")

    # ===================================================
    #   POST REQUESTS
    # ===================================================
    def do_POST(self):
        if self.path == "/upload":

            # ------------- Extract Headers -------------
            content_length = int(self.headers.get("Content-Length", 0))
            content_type = self.headers.get("Content-Type", "")

            if "boundary=" not in content_type:
                self.send_error(400, "Invalid upload format")
                return

            boundary = content_type.split("boundary=")[1].encode()

            # ------------- Read Request Body Stream -------------
            remaining = content_length
            data = b""

            # Read header block
            while True:
                chunk = self.rfile.readline()
                remaining -= len(chunk)
                data += chunk
                if chunk.strip().startswith(b"Content-Type:"):
                    break

            # Skip empty line
            blank = self.rfile.readline()
            remaining -= len(blank)

            # Extract filename
            header_block = data.decode(errors="ignore")
            filename = ""
            if "filename=" in header_block:
                filename = (
                    header_block.split("filename=")[1].split("\r\n")[0].replace('"', "")
                )

            if not filename:
                self.send_error(400, "Missing filename")
                return

            temp_path = os.path.join(TEMP_DIR, filename)

            # ------------ Start Writing File ---------------
            from core.receiver import (
                start_receive_progress,
                update_receive_progress,
                finish_receive_file,
            )

            file_id = start_receive_progress(filename)

            written = 0
            with open(temp_path, "wb") as f:
                while remaining > 0:
                    chunk = self.rfile.read(1024 * 64)  # 64 KB chunks
                    remaining -= len(chunk)

                    # Check for final boundary
                    if boundary in chunk:
                        chunk = chunk.split(boundary)[0]

                    f.write(chunk)
                    written += len(chunk)

                    update_receive_progress(file_id, written)

                    if remaining <= 0:
                        break

            finish_receive_file(file_id, temp_path)

            # Reply to client
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"OK")

            return

        self.send_error(404, "Invalid POST endpoint")


# ===================================================
#   SERVER START FUNCTIONS
# ===================================================
def start_server():
    """
    Start YowShare local server.
    """
    print(f"[YowShare] Local server running on port {SERVER_PORT}...")
    server = HTTPServer(("0.0.0.0", SERVER_PORT), YowShareHandler)
    server.serve_forever()


def run_server_in_background():
    """
    Launch server in background thread so UI stays responsive.
    """
    thread = threading.Thread(target=start_server, daemon=True)
    thread.start()
