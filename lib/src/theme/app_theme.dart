import 'package:flutter/material.dart';

class AppTheme {
  // Main palette: white + dark ink dominate backgrounds, surfaces and text.
  static const Color primary = Color(0xFF2F6C3F);
  static const Color primaryDark = Color(0xFF0F261F);
  static const Color navy = Color(0xFF0F261F);
  static const Color gold = Color(0xFFDAA628);
  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF0F261F);
  static const Color muted = Color(0xFF5E7D66);
  static const Color border = Color(0xFFB5D4BC);

  // Semantic aliases matching the brand brief: main = white/ink, tertiary = green/gold accents.
  static const Color ink = Color(0xFF0F261F);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color tertiaryGreen = Color(0xFF2F6C3F);
  static const Color tertiaryGold = Color(0xFFDAA628);
  static const Color tertiaryGreenSoft = Color(0xFFE6F0E8);
  static const Color tertiaryGoldSoft = Color(0xFFFBF0DA);

  // Typography roles. Subtitle/body sit on 'Montserrat' until the licensed
  // Creato Display files land in assets/fonts/CreatoDisplay/ — swap the two
  // family names below and they propagate everywhere.
  static const String fontTitle = 'Montserrat';
  static const String fontSubtitle = 'Montserrat';
  static const String fontBody = 'Montserrat';

  static TextStyle title({double size = 22, Color color = ink, double? height}) {
    return TextStyle(
      fontFamily: fontTitle,
      fontSize: size,
      fontWeight: FontWeight.w900,
      color: color,
      height: height,
      letterSpacing: -0.2,
    );
  }

  static TextStyle subtitle({double size = 15, Color color = ink, double? height}) {
    return TextStyle(
      fontFamily: fontSubtitle,
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
      height: height,
    );
  }

  static TextStyle body({double size = 13, Color color = ink, double? height, FontWeight weight = FontWeight.w400}) {
    return TextStyle(
      fontFamily: fontBody,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

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
        fontFamily: fontBody,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: subtitle(size: 18),
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
