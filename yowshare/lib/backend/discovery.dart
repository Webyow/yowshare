import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

class DiscoveredDevice {
  final String name;
  final String ip;
  final int port;

  DiscoveredDevice(this.name, this.ip, this.port);
}

class DiscoveryService {
  static const int serverPort = 9753; // YOWShare default port

  /// Fast HTTP-Ping discovery
  static Future<List<DiscoveredDevice>> scanNetwork() async {
    List<DiscoveredDevice> devices = [];
    String? subnet = await _getSubnet();

    if (subnet == null) return devices;

    List<Future> futures = [];

    for (int i = 1; i < 255; i++) {
      final String host = "$subnet.$i";

      futures.add(
        _checkHost(host).then((device) {
          if (device != null) devices.add(device);
        }),
      );
    }

    await Future.wait(futures);
    return devices;
  }

  /// Check single IP
  static Future<DiscoveredDevice?> _checkHost(String host) async {
    try {
      final socket = await Socket.connect(
        host,
        serverPort,
        timeout: const Duration(milliseconds: 200),
      );

      socket.write("HELLO");
      await socket.flush();

      final response = await socket
          .timeout(
            const Duration(milliseconds: 200),
            onTimeout: (EventSink<Uint8List> sink) {
              sink.add(Uint8List(0)); // return empty bytes
              sink.close();
            },
          )
          .first;

      socket.destroy();

      if (response == null) return null;

      final message = utf8.decode(response).trim();

      if (!message.startsWith("YOWSHARE:")) return null;

      final deviceName = message.replaceFirst("YOWSHARE:", "");

      return DiscoveredDevice(deviceName, host, serverPort);
    } catch (_) {
      return null;
    }
  }

  /// Detect local subnet like 192.168.1
  static Future<String?> _getSubnet() async {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );

    for (var iface in interfaces) {
      for (var addr in iface.addresses) {
        final ip = addr.address;
        if (ip.startsWith("192.") ||
            ip.startsWith("10.") ||
            ip.startsWith("172.")) {
          final parts = ip.split(".");
          return "${parts[0]}.${parts[1]}.${parts[2]}";
        }
      }
    }
    return null;
  }
}
