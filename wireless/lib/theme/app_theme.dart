import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryLight = Color(0xFF1565C0);
  static const Color accent = Color(0xFF00BCD4);
  static const Color background = Color(0xFF0A1628);
  static const Color surface = Color(0xFF132337);
  static const Color surfaceLight = Color(0xFF1A2F4A);
  static const Color cardBorder = Color(0xFF2A4060);
  static const Color textPrimary = Color(0xFFE8EDF5);
  static const Color textSecondary = Color(0xFF8BA4C0);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color critical = Color(0xFFF44336);
  static const Color info = Color(0xFF29B6F6);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: critical,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: cardBorder),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: const TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
