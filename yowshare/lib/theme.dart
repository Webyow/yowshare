import 'package:flutter/material.dart';

const Color primaryBlack = Color(0xFF212121);
const Color pureWhite = Colors.white;

final ThemeData yowTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: primaryBlack,
  primaryColor: pureWhite,
  fontFamily: 'Roboto',
  textTheme: const TextTheme(
    headlineSmall: TextStyle(color: pureWhite, fontSize: 24, fontWeight: FontWeight.w600),
    bodyMedium: TextStyle(color: pureWhite, fontSize: 16),
    labelLarge: TextStyle(color: pureWhite, fontSize: 18, fontWeight: FontWeight.w500),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: pureWhite,
      foregroundColor: primaryBlack,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);
