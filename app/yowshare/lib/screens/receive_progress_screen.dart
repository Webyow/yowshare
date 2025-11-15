import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../utils/glass_widget.dart';
import '../backend/local_server.dart';

class ReceiveProgressScreen extends StatefulWidget {
  final dynamic info;
  const ReceiveProgressScreen({super.key, required this.info});

  @override
  State<ReceiveProgressScreen> createState() => _ReceiveProgressScreenState();
}

class _ReceiveProgressScreenState extends State<ReceiveProgressScreen> {
  double progress = 0;
  String speed = "--";
  String eta = "--";

  StreamSubscription<double>? _progressSub;

  @override
  void initState() {
    super.initState();

    // Listen to progress from backend
    _progressSub = LocalServer.onProgress.listen((p) {
      setState(() {
        progress = p;
        speed = _calcSpeed(p);
        eta = _calcETA(p);
      });
    });
  }

  String _calcSpeed(double p) {
    // UI-only mock speed (actual speed is inside engine)
    double mb = (p / 100) * 20; // fake 20MB max
    return "${mb.toStringAsFixed(1)} MB";
  }

  String _calcETA(double p) {
    int seconds = ((100 - p) / 4).toInt(); // estimated finish
    return "${seconds}s";
  }

  @override
  void dispose() {
    _progressSub?.cancel();
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
        title:
            const Text("Receiving Files", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GlassCard(
              radius: 22,
              opacity: 0.12,
              blur: 14,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.info.deviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sending ${widget.info.fileCount} file(s)",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.2),

            const SizedBox(height: 35),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                minHeight: 12,
                value: progress / 100,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(YowTheme.neonBlue),
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 20),

            // Info rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Speed: $speed/s",
                    style: const TextStyle(color: Colors.white70)),
                Text("ETA: $eta", style: const TextStyle(color: Colors.white70))
              ],
            ),

            const SizedBox(height: 30),

            // Percent number
            Text(
              "${progress.toStringAsFixed(0)}%",
              style: TextStyle(
                fontSize: 50,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 20,
                    color: YowTheme.neonBlue.withOpacity(0.6),
                  ),
                ],
              ),
            ).animate().scale(begin: const Offset(0.9, 0.9), end: const Offset(1.0, 1.0)),

            const Spacer(),

            // Completed button
            if (progress >= 100)
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, "/success");
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.greenAccent.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.greenAccent,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Open Folder",
                    style: TextStyle(
                      color: Colors.white,
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
