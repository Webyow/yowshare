import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class FilePreviewScreen extends StatelessWidget {
  const FilePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Map args =
        ModalRoute.of(context)!.settings.arguments as Map? ?? {};

    final List<PlatformFile> files = List.from(args["files"] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Selected Files"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (_, i) {
                return ListTile(
                  leading: const Icon(Icons.insert_drive_file,
                      color: Colors.white),
                  title: Text(
                    files[i].name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "${(files[i].size / 1024).toStringAsFixed(1)} KB",
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  "/devices",
                  arguments: {
                    "files": files,
                  },
                );
              },
              child: const Text(
                "Continue",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
