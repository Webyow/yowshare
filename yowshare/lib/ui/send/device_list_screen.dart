import 'package:flutter/material.dart';
import '../../backend/discovery.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  List<DiscoveredDevice> devices = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _scanDevices();
  }

  Future<void> _scanDevices() async {
    setState(() => loading = true);

    final results = await DiscoveryService.scanNetwork();

    if (!mounted) return;

    setState(() {
      devices = results;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Select Device"),
        actions: [
          IconButton(
            onPressed: _scanDevices,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : devices.isEmpty
          ? const Center(
              child: Text(
                "No devices found",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final d = devices[index];
                return _deviceTile(
                  name: d.name,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/sendProgress',
                      arguments: {
                        "ip": d.ip,
                        "files":
                            (ModalRoute.of(context)!.settings.arguments
                                as Map?)?["files"] ??
                            [],
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _deviceTile({required String name, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.devices_other, color: Colors.white, size: 32),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
        onTap: onTap,
      ),
    );
  }
}
