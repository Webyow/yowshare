import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../backend/permissions.dart';
import '../backend/device_discovery.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> startApp() async {
    try {
      // Request permissions only on mobile
      if (Platform.isAndroid || Platform.isIOS) {
        await Permissions.requestAll();
      }
    } catch (_) {
      // Prevent platform errors (web/desktop)
    }

    // Device discovery only on mobile
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        DeviceDiscovery.startListening((d) {});
      }
    } catch (_) {}

    // Splash delay
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, "/home");
  }

  @override
  void initState() {
    super.initState();
    startApp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YowTheme.matteBlack,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              "assets/logo.svg",
              width: 140,
              color: Colors.white,
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scaleXY(begin: 0.8, end: 1.0),

            const SizedBox(height: 25),

            Text(
              "YowShare",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ).animate().fadeIn(duration: 900.ms),
          ],
        ),
      ),
    );
  }
}
