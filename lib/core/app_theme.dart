import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF0095F6);
  static const Color primaryDark = Color(0xFF1877F2);
  static const Color buttonDisabled = Color(0xFFB2DFFC);
  static const Color likeRed = Color(0xFFED4956);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color border = Color(0xFFDBDBDB);
  static const Color borderLight = Color(0xFFEFEFEF);
  static const Color textPrimary = Color(0xFF262626);
  static const Color textSecondary = Color(0xFF8E8E8E);
  static const Color textSubtle = Color(0xFFC7C7C7);
  static const Color storyUnseenBorderStart = Color(0xFFFBAA47);
  static const Color storyUnseenBorderMid = Color(0xFFD91A46);
  static const Color storyUnseenBorderEnd = Color(0xFFA60F93);

  static const LinearGradient storyGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      storyUnseenBorderStart,
      storyUnseenBorderMid,
      storyUnseenBorderEnd,
    ],
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'sans-serif',
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        surface: AppColors.background,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textSecondary,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 0.8,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: AppColors.textSecondary, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
      ),
    );
  }
}
