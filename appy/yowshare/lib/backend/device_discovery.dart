import 'dart:async';
import 'dart:convert';
import 'dart:io';

class DeviceInfo {
  final String name;
  final String ip;
  final int port;

  DeviceInfo({
    required this.name,
    required this.ip,
    required this.port,
  });
}

class DeviceDiscovery {
  static const int discoveryPort = 54321;
  static const int serverPort = 8888;

  static RawDatagramSocket? _udpSocket;
  static Timer? _broadcastTimer;

  static final StreamController<DeviceInfo> _deviceStreamController =
      StreamController<DeviceInfo>.broadcast();

  static Stream<DeviceInfo> get onDeviceFound =>
      _deviceStreamController.stream;

  // ------------------------------------------------------------
  // PUBLIC API
  // ------------------------------------------------------------
  static Future<void> startListening(
      void Function(DeviceInfo) onDeviceFound) async {
    stop();

    // Web does not support UDP
    if (_isWeb) return;

    try {
      if (_isMobile) {
        return _startMobileListening(onDeviceFound);
      } else if (_isDesktop) {
        return _startDesktopListening(onDeviceFound);
      }
    } catch (e) {
      print("DeviceDiscovery startListening ERROR: $e");
    }
  }

  static Future<void> startBroadcasting() async {
    stop();

    // Web does not support UDP
    if (_isWeb) return;

    try {
      if (_isMobile) {
        return _startMobileBroadcasting();
      } else if (_isDesktop) {
        return _startDesktopBroadcasting();
      }
    } catch (e) {
      print("DeviceDiscovery startBroadcasting ERROR: $e");
    }
  }

  static void stop() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;

    try {
      _udpSocket?.close();
    } catch (_) {}

    _udpSocket = null;
  }

  // ------------------------------------------------------------
  // PLATFORM DETECTION
  // ------------------------------------------------------------
  static bool get _isWeb {
    try {
      return false; // Dart VM throws on web
    } catch (_) {
      return true;
    }
  }

  static bool get _isMobile {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static bool get _isDesktop {
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  // ------------------------------------------------------------
  // MOBILE BROADCASTING (local subnet only)
  // ------------------------------------------------------------
  static Future<void> _startMobileBroadcasting() async {
    final ip = await _getLocalIP();
    if (ip == null) return;

    final hostname = Platform.localHostname;

    final broadcastIP = _getBroadcastIP(ip);
    if (broadcastIP == null) return;

    _udpSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
      reuseAddress: true,
    );

    _udpSocket!.broadcastEnabled = true;

    _broadcastTimer =
        Timer.periodic(const Duration(milliseconds: 1500), (_) {
      final data = jsonEncode({
        "deviceName": hostname,
        "ip": ip,
        "port": serverPort,
      });

      _udpSocket!.send(
        utf8.encode(data),
        InternetAddress(broadcastIP),
        discoveryPort,
      );
    });
  }

  static Future<void> _startMobileListening(
      void Function(DeviceInfo) onDeviceFound) async {
    _udpSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
      reuseAddress: true,
    );

    _udpSocket!.broadcastEnabled = true;

    _udpSocket!.listen((event) {
      if (event != RawSocketEvent.read) return;

      final packet = _udpSocket!.receive();
      if (packet == null) return;

      try {
        final data = utf8.decode(packet.data);
        final json = jsonDecode(data);

        onDeviceFound(DeviceInfo(
          name: json["deviceName"],
          ip: json["ip"],
          port: json["port"],
        ));
      } catch (_) {}
    });
  }

  // ------------------------------------------------------------
  // DESKTOP MULTICAST
  // ------------------------------------------------------------
  static const multicastGroup = "239.255.255.250";

  static Future<void> _startDesktopBroadcasting() async {
    final ip = await _getLocalIP();
    if (ip == null) return;

    final hostname = Platform.localHostname;

    final group = InternetAddress(multicastGroup);

    _udpSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      0,
      reuseAddress: true,
    );

    try {
      _udpSocket!.joinMulticast(group);
    } catch (_) {}

    _broadcastTimer =
        Timer.periodic(const Duration(milliseconds: 2000), (_) {
      final data = jsonEncode({
        "deviceName": hostname,
        "ip": ip,
        "port": serverPort,
      });

      try {
        _udpSocket!.send(utf8.encode(data), group, discoveryPort);
      } catch (_) {}
    });
  }

  static Future<void> _startDesktopListening(
      void Function(DeviceInfo) onDeviceFound) async {
    final group = InternetAddress(multicastGroup);

    _udpSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
      reuseAddress: true,
    );

    try {
      _udpSocket!.joinMulticast(group);
    } catch (_) {}

    _udpSocket!.listen((event) {
      if (event != RawSocketEvent.read) return;

      final packet = _udpSocket!.receive();
      if (packet == null) return;

      try {
        final data = utf8.decode(packet.data);
        final json = jsonDecode(data);

        onDeviceFound(DeviceInfo(
          name: json["deviceName"],
          ip: json["ip"],
          port: json["port"],
        ));
      } catch (_) {}
    });
  }

  // ------------------------------------------------------------
  // GET LOCAL IP + BROADCAST IP
  // ------------------------------------------------------------
  static Future<String?> _getLocalIP() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLinkLocal: false,
        type: InternetAddressType.IPv4,
      );

      for (var iface in interfaces) {
        for (var addr in iface.addresses) {
          final ip = addr.address;

          if (ip.startsWith("192.") ||
              ip.startsWith("10.") ||
              ip.startsWith("172.")) {
            return ip;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  static String? _getBroadcastIP(String localIP) {
    try {
      final parts = localIP.split('.');
      parts[3] = "255";
      return parts.join('.');
    } catch (_) {
      return null;
    }
  }
}
