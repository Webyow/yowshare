import 'package:flutter/material.dart';

class YowTheme {
  static const Color neonBlue = Color(0xFF00AFFF);
  static const Color matteBlack = Color(0xFF0D0D0D);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: matteBlack,
    primaryColor: neonBlue,
    splashColor: neonBlue.withOpacity(0.2),
    highlightColor: neonBlue.withOpacity(0.1),
    colorScheme: const ColorScheme.dark(
      primary: neonBlue,
      secondary: neonBlue,
      background: matteBlack,
    ),
    iconTheme: const IconThemeData(
      color: Colors.white,
      size: 28,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(
        color: Colors.white,
        fontSize: 16,
      ),
    ),
  );
}
