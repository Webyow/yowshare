import socket
import http.client
import json
import threading


def get_local_ip():
    """
    Returns the local IP address of this device.
    Works on Windows, Linux, macOS, Android.
    """
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))  # fake connection to detect local IP
        ip = s.getsockname()[0]
    except Exception:
        ip = "127.0.0.1"
    finally:
        s.close()
    return ip


def check_device(ip, port=9000):
    """
    Try pinging a YowShare device at /ping endpoint.
    Returns device info or None.
    """
    try:
        conn = http.client.HTTPConnection(ip, port, timeout=0.5)
        conn.request("GET", "/ping")
        response = conn.getresponse()

        if response.status == 200:
            data = response.read().decode()
            info = json.loads(data)

            if info.get("app") == "YowShare":
                return {
                    "name": info.get("device_name", "Unknown Device"),
                    "ip": ip,
                    "port": port
                }

    except:
        return None
    return None


def scan_devices():
    """
    Scan local subnet for YowShare devices.
    Returns a list of dictionaries:
    [{"name": "...", "ip": "...", "port": 9000}, ...]
    """
    local_ip = get_local_ip()
    subnet = ".".join(local_ip.split(".")[:3]) + "."

    found_devices = []
    threads = []
    results = []

    def worker(ip_addr):
        info = check_device(ip_addr)
        if info:
            results.append(info)

    # Scan x.x.x.1 → x.x.x.254
    for i in range(1, 255):
        ip = subnet + str(i)
        t = threading.Thread(target=worker, args=(ip,), daemon=True)
        threads.append(t)
        t.start()

    # Wait for all threads
    for t in threads:
        t.join()

    return results
