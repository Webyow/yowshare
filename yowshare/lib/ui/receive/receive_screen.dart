import 'dart:async';
import 'package:flutter/material.dart';
import '../../backend/receiver.dart';
import '../../backend/server.dart';

import 'package:flutter/material.dart';
import '../../backend/receiver.dart';
import '../../backend/server.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  StreamSubscription? requestSub;
  StreamSubscription? progressSub;

  double progress = 0;

  @override
  void initState() {
    super.initState();

    // Wave animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Start server once
    Receiver.startServer();

    // Listen for handshake requests
    requestSub = Receiver.onIncomingRequest.listen((req) {
      Receiver.handleIncomingRequest(context, req);
    });

    // Listen for file receiving progress
    progressSub = Receiver.onProgress.listen((p) {
      setState(() => progress = p);

      if (p >= 100) {
        Future.delayed(const Duration(milliseconds: 500), () {
          Receiver.notifyCompletion(context, reqFileCount);
        });
      }
    });
  }

  int reqFileCount = 0;

  @override
  void dispose() {
    requestSub?.cancel();
    progressSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Ready to Receive"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulse animation similar to AirDrop
            AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                double scale = 1 + (0.2 * _controller.value);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.wifi_tethering_rounded,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            const Text(
              "Waiting for sender...",
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),

            const SizedBox(height: 20),

            progress > 0
                ? Column(
                    children: [
                      LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "${progress.toStringAsFixed(0)}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
