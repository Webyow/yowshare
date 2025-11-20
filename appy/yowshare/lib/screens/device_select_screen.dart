import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../utils/glass_widget.dart';
import '../backend/device_discovery.dart';
import 'package:file_picker/file_picker.dart';

class DeviceSelectScreen extends StatefulWidget {
  final List<PlatformFile> files;
  const DeviceSelectScreen({super.key, required this.files});

  @override
  State<DeviceSelectScreen> createState() => _DeviceSelectScreenState();
}

class _DeviceSelectScreenState extends State<DeviceSelectScreen> {
  List<DeviceInfo> devices = [];
  List<DeviceInfo> selected = [];

  String? selfIp;

  @override
  void initState() {
    super.initState();
    _loadSelfIP();
    startDiscovery();
  }

  Future<void> _loadSelfIP() async {
    selfIp = await _getLocalIPSafe();
  }

  void startDiscovery() {
    DeviceDiscovery.startListening((device) {
      // Do not add yourself
      if (device.ip == selfIp) return;

      // Prevent duplicates
      if (!devices.any((d) => d.ip == device.ip)) {
        setState(() {
          devices.add(device);
        });
      }
    });
  }

  void toggleSelect(DeviceInfo device) {
    setState(() {
      final exists = selected.any((d) => d.ip == device.ip);
      if (exists) {
        selected.removeWhere((d) => d.ip == device.ip);
      } else {
        selected.add(device);
      }
    });
  }

  @override
  void dispose() {
    DeviceDiscovery.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YowTheme.matteBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Select Devices",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Found Devices",
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium!
                  .copyWith(color: Colors.white),
            ).animate().fadeIn(),

            const SizedBox(height: 10),

            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Text(
                        "Searching...",
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      )
                          .animate()
                          .fadeIn()
                          .shimmer(duration: 1800.ms),
                    )
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final bool isSelected = selected.any(
                          (d) => d.ip == device.ip,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: GestureDetector(
                            onTap: () => toggleSelect(device),
                            child: GlassCard(
                              radius: 20,
                              opacity: 0.12,
                              blur: 14,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 8),
                                leading: Icon(
                                  Icons.devices_other_rounded,
                                  size: 34,
                                  color: isSelected
                                      ? YowTheme.neonBlue
                                      : Colors.white,
                                ),
                                title: Text(
                                  device.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  device.ip,
                                  style: const TextStyle(
                                      color: Colors.white54),
                                ),
                                trailing: Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  size: 30,
                                  color: isSelected
                                      ? YowTheme.neonBlue
                                      : Colors.white54,
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(duration: 300.ms);
                      },
                    ),
            ),

            const SizedBox(height: 10),

            // Send Button
            GestureDetector(
              onTap: selected.isEmpty
                  ? null
                  : () {
                      Navigator.pushNamed(
                        context,
                        "/progress",
                        arguments: {
                          "files": widget.files,
                          "devices": selected,
                        },
                      );
                    },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: selected.isEmpty
                      ? Colors.white12
                      : YowTheme.neonBlue.withOpacity(0.25),
                  border: Border.all(
                    color: selected.isEmpty
                        ? Colors.white24
                        : YowTheme.neonBlue,
                    width: 2,
                  ),
                  boxShadow: selected.isEmpty
                      ? []
                      : [
                          BoxShadow(
                            color: YowTheme.neonBlue.withOpacity(0.4),
                            blurRadius: 20,
                          ),
                        ],
                ),
                alignment: Alignment.center,
                child: Text(
                  "Send Files (${selected.length})",
                  style: TextStyle(
                    color:
                        selected.isEmpty ? Colors.white38 : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------
// SAFE IP FUNCTION: used by this screen
// -----------------------------------------
Future<String?> _getLocalIPSafe() async {
  try {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );

    for (var iface in interfaces) {
      for (var addr in iface.addresses) {
        if (addr.address.startsWith("192.") ||
            addr.address.startsWith("10.") ||
            addr.address.startsWith("172.")) {
          return addr.address;
        }
      }
    }
  } catch (_) {}
  return null;
}
