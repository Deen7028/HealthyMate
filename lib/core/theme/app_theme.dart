import 'package:flutter/material.dart';

class AppTheme {
  // Primary & Brand Colors (Vitality Logic)
  static const Color primaryGreen = Color(0xFF2E6339); // Forest Vitality Green
  static const Color primaryGreenLight = Color(0xFFE8F3EB);
  static const Color accentGreen = Color(0xFF3F824E);
  static const Color sageGreen = Color(0xFF659B70);
  static const Color activeTabGreen = Color(0xFF5B9E66);

  // Background & Surface
  static const Color scaffoldBackground = Color(0xFFFCFCF9); // Warm soft off-white
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color subtleSurface = Color(0xFFF7F8F4);
  static const Color borderLight = Color(0xFFE2E7DF);
  static const Color borderSelected = Color(0xFF437A4F);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E2822);
  static const Color textSecondary = Color(0xFF6F7A72);
  static const Color textTertiary = Color(0xFF9BA49E);

  // Health Status Colors for BMI
  static const Color bmiUnderweight = Color(0xFFDFCC9B); // Yellow/Sand
  static const Color bmiNormal = Color(0xFF346B41);      // Deep Green
  static const Color bmiOverweight = Color(0xFFBA9E7E);  // Earth Tan
  static const Color bmiObese = Color(0xFFE5A19B);       // Soft Rose Coral

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: accentGreen,
        surface: cardBackground,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkBg = Color(0xFF131915);
    const darkSurface = Color(0xFF1E2822);
    const darkBorder = Color(0xFF2E3D34);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
        primary: const Color(0xFF5B9E66),
        secondary: accentGreen,
        surface: darkSurface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3F824E),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
