import os
import threading
import http.client
from mimetypes import guess_type


CHUNK_SIZE = 1024 * 64   # 64 KB per upload chunk (smooth progress)


def send_file_with_progress(ip, port, file_path, on_progress=None):
    """
    Sends a file to the YowShare server in chunks (progress friendly).
    """

    file_name = os.path.basename(file_path)
    file_type = guess_type(file_name)[0] or "application/octet-stream"
    boundary = "----YowShareChunkBoundary123"
    conn = http.client.HTTPConnection(ip, port, timeout=30)

    file_size = os.path.getsize(file_path)

    # Multipart header (before file body)
    header_top = (
        f"--{boundary}\r\n"
        f"Content-Disposition: form-data; name=\"file\"; filename=\"{file_name}\"\r\n"
        f"Content-Type: {file_type}\r\n\r\n"
    ).encode()

    header_bottom = f"\r\n--{boundary}--\r\n".encode()

    total_body_length = len(header_top) + file_size + len(header_bottom)

    # Start POST request
    conn.putrequest("POST", "/upload")
    conn.putheader("Content-Type", f"multipart/form-data; boundary={boundary}")
    conn.putheader("Content-Length", str(total_body_length))
    conn.endheaders()

    # Send header
    conn.send(header_top)

    sent_bytes = 0

    # Send file chunks
    with open(file_path, "rb") as f:
        while True:
            chunk = f.read(CHUNK_SIZE)
            if not chunk:
                break

            conn.send(chunk)
            sent_bytes += len(chunk)

            # Progress callback
            if on_progress:
                progress = sent_bytes / file_size
                on_progress(progress, file_name)

    # Send footer
    conn.send(header_bottom)

    # Get server response
    response = conn.getresponse()
    result = response.read().decode()

    print(f"[YowShare] Uploaded {file_name} → {result}")

    conn.close()
    return True


def send_files_to_device_with_progress(device, file_list, on_progress=None, on_file_done=None, on_all_done=None):
    """
    Upload multiple files in sequence, each with its own progress.
    """

    ip = device["ip"]
    port = device.get("port", 9000)

    def background_worker():
        total_files = len(file_list)
        count = 0

        for file_path in file_list:
            file_name = os.path.basename(file_path)
            count += 1

            print(f"[YowShare] Sending {file_name} ({count}/{total_files})")

            send_file_with_progress(
                ip, port, file_path,
                on_progress=on_progress
            )

            if on_file_done:
                on_file_done(file_name)

        if on_all_done:
            on_all_done()

    # Run in background thread
    threading.Thread(target=background_worker, daemon=True).start()
