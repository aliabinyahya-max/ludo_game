import 'package:flutter/material.dart';

abstract final class LudoTheme {
  static const Color background = Color(0xFF071711);
  static const Color surface = Color(0xFF10251D);
  static const Color surfaceElevated = Color(0xFF173328);
  static const Color emerald = Color(0xFF16A36A);
  static const Color emeraldLight = Color(0xFF35D394);
  static const Color gold = Color(0xFFE4BD70);
  static const Color textPrimary = Color(0xFFF4F7F2);
  static const Color textSecondary = Color(0xFFABC0B4);
  static const Color outline = Color(0xFF2B493B);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: emerald,
      brightness: Brightness.dark,
      primary: emeraldLight,
      secondary: gold,
      surface: surface,
      error: const Color(0xFFFF6B6B),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: outline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emerald,
          foregroundColor: Colors.white,
          disabledBackgroundColor: surfaceElevated,
          disabledForegroundColor: textSecondary,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceElevated,
        selectedColor: emerald.withValues(alpha: 0.22),
        side: const BorderSide(color: outline),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      dividerColor: outline,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary, fontSize: 28, fontWeight: FontWeight.w800, height: 1.2,
        ),
        titleLarge: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: textPrimary, fontSize: 15, height: 1.5),
        bodyMedium: TextStyle(color: textSecondary, fontSize: 13, height: 1.5),
      ),
    );
  }
}
