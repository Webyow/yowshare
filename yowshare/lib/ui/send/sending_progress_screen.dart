import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../backend/sender.dart';

class SendingProgressScreen extends ConsumerStatefulWidget {
  const SendingProgressScreen({super.key});

  @override
  ConsumerState<SendingProgressScreen> createState() =>
      _SendingProgressScreenState();
}

class _SendingProgressScreenState
    extends ConsumerState<SendingProgressScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  double progress = 0;
  String speed = "-- MB/s";
  String eta = "-- s";
  bool sendingStarted = false;

  String receiverIP = "";
  List files = [];

  @override
  void initState() {
    super.initState();

    // Rotating icon animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Listen to progress streams
    Sender.progressStream.stream.listen((p) {
      if (!mounted) return;
      setState(() => progress = p);

      if (p >= 100) {
        Future.delayed(const Duration(milliseconds: 400), () {
          Navigator.pushNamed(
            context,
            '/complete',
            arguments: {
              "message": "Sent Successfully",
              "fileCount": files.length,
            },
          );
        });
      }
    });

    Sender.speedStream.stream.listen((s) {
      if (!mounted) return;
      setState(() => speed = s);
    });

    Sender.etaStream.stream.listen((e) {
      if (!mounted) return;
      setState(() => eta = e);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!sendingStarted) {
      sendingStarted = true;

      final args = ModalRoute.of(context)!.settings.arguments as Map?;
      receiverIP = args?["ip"] ?? "";
      files = args?["files"] ?? [];

      _startSending();
    }
  }

  Future<void> _startSending() async {
    await Sender.sendFiles(
      receiverIP: receiverIP,
      files: List.from(files),
    );
  }

  @override
  void dispose() {
    Sender.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Sending..."),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 55,
                ),
              ),
            ),

            const SizedBox(height: 40),

            LinearProgressIndicator(
              value: progress / 100,
              minHeight: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),

            const SizedBox(height: 20),

            Text(
              "${progress.toStringAsFixed(0)}%",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Speed: $speed",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const SizedBox(height: 4),

            Text(
              "Time Left: $eta",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),

            const Spacer(),

            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent, width: 1.5),
                padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Sender.stop();
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
