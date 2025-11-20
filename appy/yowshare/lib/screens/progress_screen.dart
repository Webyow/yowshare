import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../utils/glass_widget.dart';
import '../backend/file_sender.dart';
import '../backend/device_discovery.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';

class ProgressScreen extends StatefulWidget {
  final List<PlatformFile> files;
  final List<DeviceInfo> devices;

  const ProgressScreen({
    super.key,
    required this.files,
    required this.devices,
  });

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final Map<String, double> progress = {}; // device IP -> %
  final Map<String, String> speed = {}; // device IP -> "5.2 MB/s"
  final Map<String, String> eta = {}; // device IP -> "10s remaining"
  bool sending = true;
  bool completed = false;

  @override
  void initState() {
    super.initState();
    startSending();
  }

  Future<void> startSending() async {
    for (var device in widget.devices) {
      FileSender.sendFiles(
        files: widget.files,
        ip: device.ip,
        port: device.port,
        onProgress: (percent) {
          setState(() {
            progress[device.ip] = percent;
          });
        },
        onSpeed: (sp) {
          setState(() {
            speed[device.ip] = sp;
          });
        },
        onETA: (remaining) {
          setState(() {
            eta[device.ip] = remaining;
          });
        },
        onComplete: () {
          if (progress.values.every((p) => p == 100)) {
            setState(() {
              completed = true;
            });
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YowTheme.matteBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Sending Files", style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Sending ${widget.files.length} files to ${widget.devices.length} device(s)",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: widget.devices.length,
                itemBuilder: (context, index) {
                  final device = widget.devices[index];
                  final percent = progress[device.ip] ?? 0;
                  final sp = speed[device.ip] ?? "--";
                  final et = eta[device.ip] ?? "--";

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassCard(
                      radius: 20,
                      opacity: 0.12,
                      blur: 14,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.devices_other_rounded,
                                    color: YowTheme.neonBlue, size: 30),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    device.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${percent.toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // Neon Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                minHeight: 10,
                                backgroundColor:
                                    Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  YowTheme.neonBlue,
                                ),
                                value: percent / 100,
                              ),
                            ),
                            const SizedBox(height: 10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Speed: $sp",
                                  style: const TextStyle(
                                      color: Colors.white70),
                                ),
                                Text(
                                  "ETA: $et",
                                  style: const TextStyle(
                                      color: Colors.white70),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms);
                },
              ),
            ),

            const SizedBox(height: 10),

            // Cancel OR Completed Button
            GestureDetector(
              onTap: () {
                if (completed) {
                  Navigator.pushReplacementNamed(context, "/success");
                } else {
                  FileSender.stopAll();
                  Navigator.pop(context);
                }
              },
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: completed
                      ? Colors.greenAccent.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  border: Border.all(
                    color: completed
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  completed ? "Done" : "Cancel",
                  style: const TextStyle(
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
