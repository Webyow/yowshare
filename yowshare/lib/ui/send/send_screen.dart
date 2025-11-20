import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  bool _filePickerOpened = false;
  List<PlatformFile> selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _openFilePicker();
  }

  // Automatically open file picker
  Future<void> _openFilePicker() async {
    if (_filePickerOpened) return;
    _filePickerOpened = true;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );

    if (!mounted) return;

    if (result != null && result.files.isNotEmpty) {
      selectedFiles = result.files;

      // Navigate to File Preview screen
      Navigator.pushNamed(
        context,
        '/filePreview',
        arguments: selectedFiles,
      );
    } else {
      // User cancelled → show fallback
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // If user cancelled → fallback UI
    if (selectedFiles.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          title: const Text("Send Files"),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _circleButton(
                icon: Icons.upload_file_outlined,
                label: "Choose Files",
                onTap: _openFilePicker,
              ),
              const SizedBox(height: 25),
              const Text(
                "Select one or more files to send",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Rare edge case fallback
    return const Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 110,
            width: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
