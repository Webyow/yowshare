import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme.dart';
import '../utils/glass_widget.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YowTheme.matteBlack,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(26.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Neon glowing success check
              Icon(
                Icons.check_circle_rounded,
                size: 140,
                color: YowTheme.neonBlue,
              )
                  .animate()
                  .fadeIn(duration: 700.ms)
                  .scale(begin: const Offset(0.6, 0.6), end: const Offset(1.0, 1.0))
                  .shimmer(
                    colors: [
                      Colors.white.withOpacity(0.2),
                      YowTheme.neonBlue.withOpacity(0.4)
                    ],
                    duration: 2.seconds,
                  ),

              const SizedBox(height: 30),

              Text(
                "Transfer Complete!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 900.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: 15),

              Text(
                "Your files have been successfully transferred.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 1200.ms),

              const SizedBox(height: 60),

              // Send Again Button
              GestureDetector(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/send", (route) => route.isFirst);
                },
                child: GlassCard(
                  radius: 20,
                  opacity: 0.12,
                  blur: 16,
                  child: Container(
                    height: 60,
                    alignment: Alignment.center,
                    child: Text(
                      "Send More Files",
                      style: TextStyle(
                        color: YowTheme.neonBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 1300.ms),

              const SizedBox(height: 20),

              // Back to Home Button
              GestureDetector(
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                      context, "/home", (route) => false);
                },
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: YowTheme.neonBlue.withOpacity(0.15),
                    border: Border.all(
                      color: YowTheme.neonBlue,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: YowTheme.neonBlue.withOpacity(0.4),
                        blurRadius: 22,
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "Back to Home",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 1500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
