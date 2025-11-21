import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/share_file.dart';
import '../services/transfer_service.dart';
import '../services/notification_service.dart';

class SendProgressScreen extends StatefulWidget {
  final List<ShareFile> files;
  final List<Device> receivers;

  const SendProgressScreen({
    super.key,
    required this.files,
    required this.receivers,
  });

  @override
  State<SendProgressScreen> createState() => _SendProgressScreenState();
}

class _SendProgressScreenState extends State<SendProgressScreen> {
  double progress = 0;
  late TransferService transfer;

  @override
  void initState() {
    super.initState();
    startSending();
  }

  Future<void> startSending() async {
    // Initial notification
    NotificationService.showSimple(
      id: 3,
      title: "Sending Files",
      body: "Sending... ${(progress * 100).toStringAsFixed(0)}%",
    );

    transfer = TransferService(
      files: widget.files,
      receivers: widget.receivers,
    );

    // 1) START SERVER
    final serverPort = await transfer.startServer();

    // 2) SEND HANDSHAKES TO ALL RECEIVERS
    int completed = 0;

    for (final device in widget.receivers) {
      final ok = await transfer.sendHandshake(device, serverPort);

      if (ok) {
        completed++;

        setState(() {
          progress = completed / widget.receivers.length;
        });

        // Update notification
        NotificationService.showSimple(
          id: 3,
          title: "Sending Files",
          body: "Sent ${(progress * 100).toStringAsFixed(0)}%",
        );
      }
    }

    // 3) WAIT A MOMENT FOR RECEIVERS TO START DOWNLOADING
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      progress = 1.0;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toStringAsFixed(0);

    return Scaffold(
      body: Center(
        child: Text(
          "Sending... $percent%",
          style: const TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }
}
