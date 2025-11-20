import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../backend/local_server.dart';
import '../utils/glass_widget.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool waiting = true;
  StreamSubscription? _incomingSub;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _startServer();
  }

  @override
  void dispose() {
    _controller.dispose();
    _incomingSub?.cancel();
    super.dispose();
  }

  void _initAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  Future<void> _startServer() async {
    // Start HTTP server for receiving files
    await LocalServer.start();

    // Listen for incoming send-request events
    _incomingSub = LocalServer.onIncomingRequest.listen((senderInfo) {
      _showAcceptDialog(senderInfo);
    });
  }

  void _showAcceptDialog(SenderInfo info) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return GlassCard(
          radius: 22,
          opacity: 0.15,
          blur: 12,
          child: AlertDialog(
            backgroundColor: Colors.transparent,
            title: Text(
              "Incoming Files",
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(
              "${info.deviceName} wants to send files.\nAccept?",
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  LocalServer.rejectRequest(info);
                },
                child: const Text("Reject",
                    style: TextStyle(color: Colors.redAccent)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  LocalServer.acceptRequest(info);

                  Navigator.pushReplacementNamed(
                    context,
                    "/receive-progress",
                    arguments: info,
                  );
                },
                child: Text(
                  "Accept",
                  style: TextStyle(color: YowTheme.neonBlue),
                ),
              ),
            ],
          ),
        );
      },
    );
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
          "Receive Files",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 60),

            // Wave animation circle
            SizedBox(
              width: 220,
              height: 220,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: WavePainter(_controller.value),
                  );
                },
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 30),

            Text(
              "Waiting for sender...",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 10),

            GlassCard(
              radius: 20,
              opacity: 0.12,
              blur: 14,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                child: Text(
                  "Keep this screen open",
                  style: const TextStyle(color: Colors.white60),
                ),
              ),
            ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }
}

// Neon Wave Painter
class WavePainter extends CustomPainter {
  final double progress;
  WavePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * 0.3 +
        (progress * size.width * 0.2); // wave expansion

    final paint = Paint()
      ..color = YowTheme.neonBlue.withOpacity(1 - progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}
