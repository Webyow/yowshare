import 'package:flutter/material.dart';

class YowShareTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,

    // Matte Black Background
    scaffoldBackgroundColor: const Color(0xFF0D0D0D),

    // AppBar Style
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Text Colors
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white),
    ),

    // Icon Colors
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),

    // Button Theme (Used Later)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.white),
        foregroundColor: WidgetStatePropertyAll(Colors.black),
        textStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}
