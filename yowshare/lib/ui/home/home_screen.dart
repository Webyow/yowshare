import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circleButton(
              icon: Icons.send_rounded,
              label: "Send",
              onTap: () async {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: true,
                );

                if (result != null && result.files.isNotEmpty) {
                  Navigator.pushNamed(
                    context,
                    '/filePreview',
                    arguments: {
                      "files": result.files,
                    },
                  );
                }
              },
            ),

            const SizedBox(height: 50),

            _circleButton(
              icon: Icons.download_rounded,
              label: "Receive",
              onTap: () {
                Navigator.pushNamed(context, "/receive");
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }
}
