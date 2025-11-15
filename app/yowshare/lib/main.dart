import 'dart:io';
import 'package:flutter/material.dart';
import 'theme.dart';
import 'package:file_picker/file_picker.dart';

import 'backend/permissions.dart';
import 'backend/notifications.dart';
import 'backend/share_intent_handler.dart';
import 'backend/device_discovery.dart';

import 'screens/home_screen.dart';
import 'screens/send_screen.dart';
import 'screens/device_select_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/receive_screen.dart';
import 'screens/receive_progress_screen.dart';
import 'screens/success_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init notifications safely
  await Notify.init();

  // Only load share intent on mobile (avoids Windows freeze)
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      await ShareIntentHandler.init();
    } catch (_) {}
  }

  runApp(const YowShareApp());
}

class YowShareApp extends StatelessWidget {
  const YowShareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "YowShare",
      debugShowCheckedModeBanner: false,
      theme: YowTheme.darkTheme,
      home: const SplashScreen(),
      routes: {
        "/home": (context) => const HomeScreen(),

        // ✅ FIXED: handles 1 file OR list of files
        "/send": (context) {
          final args = ModalRoute.of(context)!.settings.arguments;

          List<PlatformFile> files = [];

          if (args is PlatformFile) {
            files = [args];
          } else if (args is List<PlatformFile>) {
            files = args;
          }

          return SendScreen(initialFiles: files);
        },

        "/device-select": (context) {
          final args = ModalRoute.of(context)!.settings.arguments;

          List<PlatformFile> files = [];

          if (args is PlatformFile) {
            files = [args];
          } else if (args is List<PlatformFile>) {
            files = args;
          } else if (args is List<dynamic>) {
            files = args.whereType<PlatformFile>().toList();
          }

          return DeviceSelectScreen(files: files);
        },

        "/progress": (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return ProgressScreen(
            files: args["files"],
            devices: args["devices"],
          );
        },

        "/receive": (context) => const ReceiveScreen(),

        "/receive-progress": (context) {
          final info = ModalRoute.of(context)!.settings.arguments;
          return ReceiveProgressScreen(info: info);
        },

        "/success": (context) => const SuccessScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        await Permissions.requestAll();
        DeviceDiscovery.startListening((d) {});
      } catch (_) {}
    }

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/home");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YowTheme.matteBlack,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 20),
            Text(
              "YowShare",
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}
