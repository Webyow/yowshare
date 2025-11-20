import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../utils/glass_widget.dart';

class SendScreen extends StatefulWidget {
  final List<PlatformFile>? initialFiles;

  const SendScreen({super.key, this.initialFiles});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  List<PlatformFile> selectedFiles = [];

  @override
  void initState() {
    super.initState();

    if (widget.initialFiles != null) {
      selectedFiles = List<PlatformFile>.from(widget.initialFiles!);
    }
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        selectedFiles = result.files;
      });
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
        title: const Text("Send Files", style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              GestureDetector(
                onTap: pickFiles,
                child: GlassCard(
                  radius: 22,
                  opacity: 0.12,
                  blur: 16,
                  child: Container(
                    height: 70,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open_rounded,
                            color: YowTheme.neonBlue, size: 32),
                        const SizedBox(width: 14),
                        Text(
                          "Select Files",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn().slideY(begin: 0.2),
              const SizedBox(height: 30),
              if (selectedFiles.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: selectedFiles.length,
                    itemBuilder: (context, index) {
                      final file = selectedFiles[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          radius: 18,
                          opacity: 0.12,
                          blur: 14,
                          child: ListTile(
                            leading: Icon(Icons.insert_drive_file_rounded,
                                color: YowTheme.neonBlue, size: 30),
                            title: Text(
                              file.name,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "${(file.size / 1024).toStringAsFixed(1)} KB",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  selectedFiles.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms);
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      "No files selected",
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ).animate().fadeIn(),
                  ),
                ),
              const SizedBox(height: 20),
              if (selectedFiles.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      "/device-select",
                      arguments: selectedFiles,
                    );
                  },
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: YowTheme.neonBlue.withOpacity(0.2),
                      border: Border.all(
                        color: YowTheme.neonBlue.withOpacity(0.8),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: YowTheme.neonBlue.withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "Continue",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}
