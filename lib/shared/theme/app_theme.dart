import 'package:flutter/material.dart';

/// Centralized Design Tokens & Color System for HealthyMate
class AppTheme {
  AppTheme._();

  // Primary & Brand Colors
  static const Color primaryGreen = Color(0xFF2E6339);
  static const Color primaryGreenDark = Color(0xFF2E5327);
  static const Color primaryGreenLight = Color(0xFFE8F3EB);
  static const Color accentGreen = Color(0xFF3F824E);
  static const Color sageGreen = Color(0xFF659B70);
  static const Color activeTabGreen = Color(0xFF5B9E66);
  static const Color mapGreen = Color(0xFF90DB89);

  // Background & Surfaces
  static const Color scaffoldBackground = Color(0xFFFCFCF9);
  static const Color scaffoldBackgroundDark = Color(0xFF131915);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF1E2822);
  static const Color surfaceLight = Color(0xFFF7F8F4);
  static const Color subtleSurface = Color(0xFFF7F8F4);
  static const Color surfaceDark = Color(0xFF2E3D34);

  // Borders
  static const Color borderLight = Color(0xFFE2E7DF);
  static const Color borderDark = Color(0xFF2E3D34);
  static const Color borderSelected = Color(0xFF437A4F);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E2822);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF6F7A72);
  static const Color textSecondaryDark = Color(0xFFA0ACA0);
  static const Color textTertiary = Color(0xFF9BA49E);
  static const Color textTertiaryDark = Color(0xFF8C968E);

  // Status & Utility Colors
  static const Color statusRed = Color(0xFFD32F2F);
  static const Color statusRedBg = Color(0xFFFEE6E6);
  static const Color deleteRed = Color(0xFFD93838);
  static const Color deleteRedBg = Color(0xFFFFEBEE);

  static const Color infoBlue = Color(0xFF3F77B0);
  static const Color infoBlueBg = Color(0xFFD7E5F5);

  static const Color warningOrange = Color(0xFFF57C00);
  static const Color warningOrangeBg = Color(0xFFFFF3E0);

  static const Color successGreen = Color(0xFF388E3C);
  static const Color successGreenBg = Color(0xFFE2F0D9);

  // Health Status Colors for BMI
  static const Color bmiUnderweight = Color(0xFFDFCC9B);
  static const Color bmiNormal = Color(0xFF346B41);
  static const Color bmiOverweight = Color(0xFFBA9E7E);
  static const Color bmiObese = Color(0xFFE5A19B);

  // Helper Methods for Centralized Color Selection
  static Color getBackgroundColor(bool isDark) => isDark ? cardBackgroundDark : cardBackground;
  static Color getScaffoldColor(bool isDark) => isDark ? scaffoldBackgroundDark : scaffoldBackground;
  static Color getTextPrimaryColor(bool isDark) => isDark ? textPrimaryDark : textPrimary;
  static Color getTextSecondaryColor(bool isDark) => isDark ? textSecondaryDark : textSecondary;
  static Color getBorderColor(bool isDark) => isDark ? borderDark : borderLight;
  static Color getSurfaceColor(bool isDark) => isDark ? surfaceDark : surfaceLight;

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
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBackgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.dark,
        primary: activeTabGreen,
        secondary: accentGreen,
        surface: cardBackgroundDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: scaffoldBackgroundDark,
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
        color: cardBackgroundDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderDark, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGreen,
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
