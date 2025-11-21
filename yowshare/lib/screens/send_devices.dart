import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/share_file.dart';
import '../services/mdns_service.dart';
import '../utils/platform_helper.dart';
import 'send_progress.dart';

class SendDevicesScreen extends StatefulWidget {
  final List<ShareFile> files;
  const SendDevicesScreen({super.key, required this.files});

  @override
  State<SendDevicesScreen> createState() => _SendDevicesScreenState();
}

class _SendDevicesScreenState extends State<SendDevicesScreen> {
  final MdnsService mdns = MdnsService();
  final List<Device> devices = [];
  final List<Device> selectedDevices = [];

  @override
  void initState() {
    super.initState();
    if (PlatformHelper.supportsMdns()) {
      startDiscovery();
    }
  }

  void startDiscovery() async {
    await mdns.start();
    mdns.discoverDevices().listen((device) {
      if (!devices.any((d) => d.ip == device.ip)) {
        setState(() {
          devices.add(device);
        });
      }
    });
  }

  @override
  void dispose() {
    mdns.stop();
    super.dispose();
  }

  void toggleSelect(Device d) {
    setState(() {
      if (selectedDevices.contains(d)) {
        selectedDevices.remove(d);
      } else {
        selectedDevices.add(d);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformHelper.supportsMdns()) {
      return Scaffold(
        appBar: AppBar(title: const Text("Select Devices")),
        body: const Center(
          child: Text(
            "Device auto-discovery is not supported on Windows.\n"
            "Use an Android/iOS receiver.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Select Devices")),
      body: Column(
        children: [
          const SizedBox(height: 10),

          Expanded(
            child: devices.isEmpty
                ? const Center(
                    child: Text("Searching devices...",
                        style: TextStyle(color: Colors.white70)),
                  )
                : ListView.builder(
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final d = devices[index];
                      final isSelected = selectedDevices.contains(d);

                      return ListTile(
                        leading: const Icon(Icons.devices, color: Colors.white),
                        title: Text(d.name,
                            style: const TextStyle(color: Colors.white)),
                        subtitle: Text(d.ip,
                            style: const TextStyle(color: Colors.white70)),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: (_) => toggleSelect(d),
                          activeColor: Colors.white,
                          checkColor: Colors.black,
                        ),
                      );
                    },
                  ),
          ),

          if (selectedDevices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SendProgressScreen(
                        files: widget.files,
                        receivers: selectedDevices,
                      ),
                    ),
                  );
                },
                child: const Text("CONTINUE"),
              ),
            ),
        ],
      ),
    );
  }
}
