import 'package:flutter/material.dart';

class ReceivingProgressScreen extends StatefulWidget {
  const ReceivingProgressScreen({super.key});

  @override
  State<ReceivingProgressScreen> createState() =>
      _ReceivingProgressScreenState();
}

class _ReceivingProgressScreenState extends State<ReceivingProgressScreen>
    with SingleTickerProviderStateMixin {
  double progress = 0; // Updated later by backend
  String fileName = "Receiving file...";

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    // Reverse direction of rotation (counterclockwise)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Placeholder logic (will be replaced by backend callbacks)
    _simulateProgress();
  }

  void _simulateProgress() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;

      setState(() {
        progress += 0.7;
        if (progress < 100) _simulateProgress();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Receiving..."),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
        child: Column(
          children: [
            // Rotating animation
            RotationTransition(
              turns: Tween(begin: 1.0, end: 0.0).animate(_controller),
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.download_rounded,
                  color: Colors.white,
                  size: 55,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // File Name
            Text(
              fileName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 15),

            // Progress Bar
            LinearProgressIndicator(
              value: progress / 100,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),

            const SizedBox(height: 20),

            // Progress %
            Text(
              "${progress.toStringAsFixed(0)}%",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // Speed + ETA placeholders
            const Text(
              "Speed: -- MB/s",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              "Time Left: -- s",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const Spacer(),

            // Cancel button
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
