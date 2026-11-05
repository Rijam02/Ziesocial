import 'package:flutter/material.dart';

class AppColors {
  // Core Editorial Palette
  static const Color warmIvory = Color(0xFFF8F7F2);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color sageGreen = Color(0xFF829687);
  static const Color deepForest = Color(0xFF35443C);
  static const Color softBeige = Color(0xFFD8C9B6);
  static const Color mistGray = Color(0xFFE8EAE4);
  static const Color primaryText = Color(0xFF252925);
  static const Color secondaryText = Color(0xFF858B85);
  static const Color border = Color(0xFFE9EBE6);
  static const Color error = Color(0xFFD96B6B);

  // Semantic Mappings (for consistent component usage)
  static const Color primary = deepForest;
  static const Color primaryDark = Color(0xFF26322C);
  static const Color accent = sageGreen;
  static const Color buttonDisabled = Color(0xFFC5CDC7);
  static const Color likeRed = error;
  static const Color background = pureWhite;
  static const Color canvas = warmIvory;
  static const Color surface = warmIvory;
  static const Color surfaceSubtle = mistGray;
  static const Color borderLight = Color(0xFFE9EBE6);
  static const Color textPrimary = primaryText;
  static const Color textSecondary = secondaryText;
  static const Color textSubtle = Color(0xFFB4B9B4);

  // Editorial Unseen Story Ring (Deep Forest -> Sage Green -> Soft Beige)
  static const Color storyUnseenBorderStart = deepForest;
  static const Color storyUnseenBorderMid = sageGreen;
  static const Color storyUnseenBorderEnd = softBeige;

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
  static const List<String> _editorialFontFallback = [
    'Plus Jakarta Sans',
    'Inter',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme.apply(
          bodyColor: AppColors.primaryText,
          displayColor: AppColors.primaryText,
          fontFamily: 'Inter',
          fontFamilyFallback: _editorialFontFallback,
        );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.pureWhite,
      fontFamily: 'Inter',
      fontFamilyFallback: _editorialFontFallback,
      textTheme: baseTextTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.deepForest,
        onPrimary: AppColors.pureWhite,
        secondary: AppColors.sageGreen,
        onSecondary: AppColors.pureWhite,
        tertiary: AppColors.softBeige,
        surface: AppColors.pureWhite,
        onSurface: AppColors.primaryText,
        error: AppColors.error,
        onError: AppColors.pureWhite,
        outline: AppColors.border,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.pureWhite,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          fontFamily: 'Inter',
          fontFamilyFallback: _editorialFontFallback,
        ),
        iconTheme: IconThemeData(
          color: AppColors.primaryText,
          size: 22,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.pureWhite,
        selectedItemColor: AppColors.deepForest,
        unselectedItemColor: AppColors.secondaryText,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.deepForest,
        contentTextStyle: const TextStyle(
          color: AppColors.pureWhite,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepForest,
          foregroundColor: AppColors.pureWhite,
          disabledBackgroundColor: AppColors.mistGray,
          disabledForegroundColor: AppColors.secondaryText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          side: const BorderSide(color: AppColors.border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.warmIvory,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.deepForest,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.sageGreen, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.pureWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
    );
  }
}
