import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../utils/glass_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YowTheme.matteBlack,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Title
              Text(
                "YowShare",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              )
                  .animate()
                  .fadeIn(duration: 700.ms)
                  .slideY(begin: -0.2, end: 0),

              const SizedBox(height: 60),

              // SEND CARD
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, "/send");
                },
                child: GlassCard(
                  radius: 28,
                  opacity: 0.12,
                  blur: 14,
                  child: Container(
                    width: 260,
                    height: 120,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_rounded,
                            color: YowTheme.neonBlue, size: 40),
                        const SizedBox(width: 14),
                        Text(
                          "Send",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: -0.2, end: 0),

              const SizedBox(height: 35),

              // RECEIVE CARD
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, "/receive");
                },
                child: GlassCard(
                  radius: 28,
                  opacity: 0.12,
                  blur: 14,
                  child: Container(
                    width: 260,
                    height: 120,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.download_rounded,
                            color: YowTheme.neonBlue, size: 40),
                        const SizedBox(width: 14),
                        Text(
                          "Receive",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: 0.2, end: 0),

              const SizedBox(height: 80),

              Text(
                "Share anything. Anytime.",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                  letterSpacing: 0.7,
                ),
              ).animate().fadeIn(duration: 1200.ms),
            ],
          ),
        ),
      ),
    );
  }
}
