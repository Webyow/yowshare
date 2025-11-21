import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/storage_paths.dart';
import '../services/notification_service.dart';

class ReceiveProgressScreen extends StatefulWidget {
  final String senderIp;
  final int senderPort;
  final String token;

  const ReceiveProgressScreen({
    super.key,
    required this.senderIp,
    required this.senderPort,
    required this.token,
  });

  @override
  State<ReceiveProgressScreen> createState() => _ReceiveProgressScreenState();
}

class _ReceiveProgressScreenState extends State<ReceiveProgressScreen> {
  List<Map<String, dynamic>> manifest = [];
  double progress = 0;

  @override
  void initState() {
    super.initState();
    startDownload();
  }

  Future<void> startDownload() async {
    NotificationService.showSimple(
      id: 2,
      title: "Receiving Files",
      body: "Downloaded ${(progress * 100).toStringAsFixed(0)}%",
    );

    final manifestUrl = Uri.parse(
      "http://${widget.senderIp}:${widget.senderPort}/manifest.json?token=${widget.token}",
    );

    final http = HttpClient();
    final req = await http.getUrl(manifestUrl);
    final res = await req.close();

    final body = await res.transform(utf8.decoder).join();
    manifest = List<Map<String, dynamic>>.from(jsonDecode(body));

    await downloadFiles();
  }

  Future<void> downloadFiles() async {
    final saveDir = await StoragePaths.getDownloadFolder();

    for (int i = 0; i < manifest.length; i++) {
      final fileName = manifest[i]["name"];

      final fileUrl = Uri.parse(
        "http://${widget.senderIp}:${widget.senderPort}/files/$fileName?token=${widget.token}",
      );

      final http = HttpClient();
      final req = await http.getUrl(fileUrl);
      final res = await req.close();

      final saveFile = File("${saveDir.path}/$fileName");
      final fileSink = saveFile.openWrite();

      await res.forEach((chunk) {
        fileSink.add(chunk);
      });

      await fileSink.close();

      setState(() {
        progress = (i + 1) / manifest.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).toStringAsFixed(1);

    return Scaffold(
      body: Center(
        child: Text(
          "Receiving... $percent%",
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
      ),
    );
  }
}
