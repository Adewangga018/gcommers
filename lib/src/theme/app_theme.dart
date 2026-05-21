import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF534AB7);
  static const Color primaryDark = Color(0xFF3C3489);
  static const Color navy = Color(0xFF1C1B33);
  static const Color background = Color(0xFFFAF8FF);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF242333);
  static const Color muted = Color(0xFF78738D);
  static const Color border = Color(0xFFC7C0E2);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: primaryDark,
        surface: card,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: text,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: Color(0xFFB5AFC7)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
      ),
    );
  }
}
