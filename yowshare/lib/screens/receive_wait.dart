import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'receive_progress.dart';
import '../services/notification_service.dart';
class ReceiveWaitScreen extends StatefulWidget {
  const ReceiveWaitScreen({super.key});

  @override
  State<ReceiveWaitScreen> createState() => _ReceiveWaitScreenState();
}

class _ReceiveWaitScreenState extends State<ReceiveWaitScreen> {
  HttpServer? _server;
  int? senderPort;
  String? sessionToken;
  String senderIp = "";

  @override
  void initState() {
    super.initState();
    startReceiverServer();
  }

  Future<void> startReceiverServer() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);

    _server!.listen((HttpRequest request) async {
      if (request.uri.path == "/handshake") {
        final body = await utf8.decoder.bind(request).join();
        final data = jsonDecode(body);

        sessionToken = data["sessionToken"];
        senderPort = data["senderPort"];
        senderIp = request.connectionInfo!.remoteAddress.address;

        // SEND ACCEPT
        request.response.statusCode = 200;
        await request.response.close();

        // Navigate to progress screen
        await Future.delayed(const Duration(milliseconds: 300));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReceiveProgressScreen(
              senderIp: senderIp,
              senderPort: senderPort!,
              token: sessionToken!,
            ),
          ),
        );
        NotificationService.showSimple(
          id: 1,
          title: "Incoming Files",
          body: "A device wants to send files",
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.waves, color: Colors.white, size: 80),
            SizedBox(height: 20),
            Text(
              "Waiting for sender...",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
