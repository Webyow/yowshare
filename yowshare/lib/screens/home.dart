import 'package:flutter/material.dart';
import 'send_select_files.dart';
import 'receive_wait.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Temporary YowShare title until you upload your logo
            const Text(
              "YowShare",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 60),

            // SEND BUTTON
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SendSelectFilesScreen()),
                );
              },
              child: const Text("SEND"),
            ),

            const SizedBox(height: 20),

            // RECEIVE BUTTON
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReceiveWaitScreen()),
                );
              },
              child: const Text("RECEIVE"),
            ),

            const Spacer(),

            const Text(
              "Offline • Fast • Secure",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
