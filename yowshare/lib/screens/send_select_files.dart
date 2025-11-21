import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/share_file.dart';
import 'send_devices.dart';

class SendSelectFilesScreen extends StatefulWidget {
  const SendSelectFilesScreen({super.key});

  @override
  State<SendSelectFilesScreen> createState() => _SendSelectFilesScreenState();
}

class _SendSelectFilesScreenState extends State<SendSelectFilesScreen> {
  List<ShareFile> selectedFiles = [];

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        selectedFiles = result.files.map((f) {
          return ShareFile(
            name: f.name,
            path: f.path!,
            size: f.size,
          );
        }).toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    pickFiles(); // auto-open picker on screen load
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Files"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          if (selectedFiles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "No files selected",
                style: TextStyle(color: Colors.white70),
              ),
            ),

          if (selectedFiles.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: selectedFiles.length,
                itemBuilder: (context, index) {
                  final file = selectedFiles[index];
                  return ListTile(
                    leading: const Icon(Icons.insert_drive_file, color: Colors.white),
                    title: Text(file.name, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      "${(file.size / 1024).toStringAsFixed(2)} KB",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      onPressed: () {
                        setState(() {
                          selectedFiles.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),

          if (selectedFiles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SendDevicesScreen(files: selectedFiles),
                    ),
                  );
                },
                child: const Text("CONTINUE"),
              ),
            ),
        ],
      ),
    );
  }
}
