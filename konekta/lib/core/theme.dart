import 'package:flutter/material.dart';

class KonektaColors {
  static const primary = Color(0xFF2196F3);
  static const primaryDark = Color(0xFF0E5FCB);
  static const primaryGradientStart = Color(0xFF4FB6FF);
  static const primaryGradientEnd = Color(0xFF1F6FE5);
  static const background = Color(0xFFF3F7FF);
  static const bg = Color(0xFFF7F8FA);
  static const surface = Colors.white;
  static const textPrimary = Color(0xFF0E1B33);
  static const textSecondary = Color(0xFF6B7791);
  static const textMuted = Color(0xFF98A3B8);
  static const textDark = Color(0xFF0F172A);
  static const border = Color(0xFFE3E9F2);
  static const softBlue = Color(0xFFEFF5FF);
  static const success = Color(0xFF1FB76A);
  static const warning = Color(0xFFF6A623);
  static const danger = Color(0xFFE5484D);
  static const chatBlue = Color(0xFF7FB8FF);

  // Extra colors used by explore/landing screens
  static const navActive = Color(0xFF1A73E8);
  static const navInactive = Color(0xFF9AA0A6);
  static const softRed = Color(0xFFE5484D);
  static const gradientStart = Color(0xFF2FA2EE);
  static const gradientEnd = Color(0xFF3B7CE5);
  static const bannerGradientStart = Color(0xFF2FA2EE);
  static const bannerGradientEnd = Color(0xFF408CFF);
  static const cardGradientStart = Color(0xFF4A9FFF);
  static const cardGradientEnd = Color(0xFF3581E1);
  static const proPillBg = Color(0x3FFF80FF); // rgba(255,128,255,0.25)
  static const proPillText = Color(0xFFE0A0FF);
  static const proCardBg = Color(0xFFF5F0FF);
  static const proCardText = Color(0xFF7C3AED);

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGradientStart, primaryGradientEnd],
  );
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGradientStart, primaryGradientEnd],
  );
  static const softCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEFF7FF), Color(0xFFE7F0FB)],
  );
}

class KonektaTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: KonektaColors.background,
      primaryColor: KonektaColors.primary,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: KonektaColors.primary,
        primary: KonektaColors.primary,
        surface: KonektaColors.surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: KonektaColors.textPrimary,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: KonektaColors.textPrimary),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: KonektaColors.textPrimary),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: KonektaColors.textPrimary),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: KonektaColors.textPrimary),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: KonektaColors.textPrimary),
        bodyLarge: TextStyle(fontSize: 15, color: KonektaColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: KonektaColors.textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: KonektaColors.textSecondary),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: KonektaColors.softBlue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: KonektaColors.primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: KonektaColors.textMuted, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KonektaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class KonektaGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [KonektaColors.primaryGradientStart, KonektaColors.primaryGradientEnd],
  );
  static const softCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEFF7FF), Color(0xFFE7F0FB)],
  );
  static const orange = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFC371), Color(0xFFFF5F6D)],
  );
  static const pillBlue = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF60A9FF), Color(0xFF246FE0)],
  );
  static const success = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6FE0A1), Color(0xFF1FB76A)],
  );
  static const purple = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB898FF), Color(0xFF7A5BFF)],
  );
}
