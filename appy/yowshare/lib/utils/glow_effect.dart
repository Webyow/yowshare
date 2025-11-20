import 'package:flutter/material.dart';
import '../theme.dart';

/// Glow wrapper: applies a soft neon outer glow and optional inner overlay.
/// Use this to give icons, cards, and other widgets the neon-blue glow.
class Glow extends StatelessWidget {
  final Widget child;
  final double blurRadius;
  final Color color;
  final Offset offset;
  final double spread;
  final bool inner;

  const Glow({
    super.key,
    required this.child,
    this.blurRadius = 20.0,
    this.color = YowTheme.neonBlue,
    this.offset = const Offset(0, 0),
    this.spread = 0.0,
    this.inner = false,
  });

  @override
  Widget build(BuildContext context) {
    // Outer glow via BoxShadow
    final boxShadow = [
      BoxShadow(
        color: color.withOpacity(0.45),
        blurRadius: blurRadius,
        spreadRadius: spread,
        offset: offset,
      ),
      BoxShadow(
        color: color.withOpacity(0.18),
        blurRadius: blurRadius * 2,
        spreadRadius: spread * 2,
        offset: offset,
      ),
    ];

    // If inner glow is requested, we stack a semi-transparent overlay
    if (inner) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(boxShadow: boxShadow),
            child: child,
          ),
          // subtle inner glow using a gradient mask
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: RadialGradient(
                  colors: [
                    color.withOpacity(0.08),
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(boxShadow: boxShadow),
      child: child,
    );
  }
}
