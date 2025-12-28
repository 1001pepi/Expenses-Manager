import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF14B8A6), // Teal
        secondary: Color(0xFF84CC16), // Lime Green
        tertiary: Color(0xFFFBBF24), // Amber
        surface: Color(0xFFFDFDFD), // Off-White
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: Color(0xFF111827), // Dark Gray
      ),
      scaffoldBackgroundColor: const Color(0xFFFDFDFD),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF14B8A6),
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF0D7879), // Teal
        secondary: Color(0xFF65A30D), // Lime Green
        tertiary: Color(0xFFD97706), // Amber
        surface: Color(0xFF1F2937), // Dark Gray
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onSurface: Color(0xFFE5E7EB), // Light Gray
      ),
      scaffoldBackgroundColor: const Color(0xFF1F2937),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0D7879),
        foregroundColor: Colors.white,
      ),
    );
  }
}
