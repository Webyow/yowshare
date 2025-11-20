import 'package:flutter/material.dart';

class IncomingRequestPopup extends StatelessWidget {
  const IncomingRequestPopup({super.key});

  @override
  Widget build(BuildContext context) {
    final Map args =
        ModalRoute.of(context)!.settings.arguments as Map? ?? {};

    final String deviceName = args['deviceName'] ?? "Unknown Device";
    final int fileCount = args['fileCount'] ?? 1;

    return Scaffold(
      backgroundColor: const Color(0x99000000), // dim background
      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.file_present_outlined,
                size: 55,
                color: Colors.white,
              ),

              const SizedBox(height: 12),

              Text(
                deviceName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "$fileCount file(s) wants to send",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 25),

              // Accept Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 40,
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text(
                  "Accept",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Reject Button
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text(
                  "Reject",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
