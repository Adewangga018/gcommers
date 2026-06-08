import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF38804B);
  static const Color primaryDark = Color(0xFF2F6C3F);
  static const Color navy = Color(0xFF0F261F);
  static const Color gold = Color(0xFFDAA628);
  static const Color background = Color(0xFFF4FAF5);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF0F261F);
  static const Color muted = Color(0xFF5E7D66);
  static const Color border = Color(0xFFB5D4BC);

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
        hintStyle: const TextStyle(color: Color(0xFFA0C4A8)),
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
