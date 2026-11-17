import 'package:flutter/material.dart';

class AppColors {
  // ZieSocial Plus Jakarta Sans & Indigo-Surface Design System (Sesuai Referensi Dashboard)
  static const Color surface = Color(0xFFF9F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF1F3FF);
  static const Color surfaceContainer = Color(0xFFE9EDFF);
  static const Color surfaceContainerHigh = Color(0xFFE1E8FD);
  static const Color surfaceContainerHighest = Color(0xFFDCE2F7);

  static const Color onSurface = Color(0xFF141B2B);
  static const Color onSurfaceVariant = Color(0xFF464555);
  static const Color outline = Color(0xFF777587);
  static const Color outlineVariant = Color(0xFFC7C4D8);

  static const Color primary = Color(0xFF3525CD);
  static const Color primaryContainer = Color(0xFF4F46E5);
  static const Color primaryFixed = Color(0xFFE2DFFF);

  static const Color secondary = Color(0xFFB90538);
  static const Color secondaryContainer = Color(0xFFDC2C4F);

  static const Color tertiary = Color(0xFF571AC0);
  static const Color tertiaryContainer = Color(0xFF6F3DD9);
  static const Color tertiaryFixedDim = Color(0xFFD0BCFF);

  static const Color inverseSurface = Color(0xFF293040);
  static const Color inverseOnSurface = Color(0xFFEDF0FF);

  // Backward-compatible semantic aliases used across other views
  static const Color pureWhite = surfaceContainerLowest; // #FFFFFF
  static const Color warmIvory = surfaceContainerLow; // #F1F3FF
  static const Color mistGray = surfaceContainer; // #E9EDFF
  static const Color border = surfaceContainerHighest; // #DCE2F7
  static const Color primaryText = onSurface; // #141B2B
  static const Color secondaryText = onSurfaceVariant; // #464555
  static const Color deepForest = primary; // #3525CD
  static const Color sageGreen = primaryContainer; // #4F46E5
  static const Color softBeige = tertiaryContainer; // #6F3DD9
  static const Color error = secondaryContainer; // #DC2C4F

  static const Color primaryDark = Color(0xFF23169E);
  static const Color accent = primaryContainer;
  static const Color buttonDisabled = surfaceContainerHighest;
  static const Color likeRed = secondaryContainer;
  static const Color background = surface;
  static const Color canvas = surface;
  static const Color surfaceSubtle = surfaceContainer;
  static const Color borderLight = surfaceContainerHighest;
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textSubtle = outline;

  // Story Unseen Gradient (from-primary via-primary-container to-secondary)
  static const Color storyUnseenBorderStart = primary;
  static const Color storyUnseenBorderMid = primaryContainer;
  static const Color storyUnseenBorderEnd = secondary;

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
  static const List<String> _fontFallback = [
    'Plus Jakarta Sans',
    'Inter',
    'Segoe UI',
    'Roboto',
    'sans-serif',
  ];

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme.apply(
          bodyColor: AppColors.onSurface,
          displayColor: AppColors.onSurface,
          fontFamily: 'Plus Jakarta Sans',
          fontFamilyFallback: _fontFallback,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surface,
      fontFamily: 'Plus Jakarta Sans',
      fontFamilyFallback: _fontFallback,
      textTheme: baseTextTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondaryContainer,
        onSecondary: Colors.white,
        tertiary: AppColors.tertiary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.outline,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          fontFamily: 'Plus Jakarta Sans',
          fontFamilyFallback: _fontFallback,
        ),
        iconTheme: IconThemeData(
          color: AppColors.onSurface,
          size: 22,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceVariant,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceContainerHighest,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.inverseSurface,
        contentTextStyle: const TextStyle(
          color: AppColors.inverseOnSurface,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          fontFamily: 'Plus Jakarta Sans',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceContainerHighest,
          disabledForegroundColor: AppColors.outline,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.surfaceContainerHighest, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          color: AppColors.outline,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.onSurfaceVariant,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.surfaceContainer, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.surfaceContainer, width: 1),
        ),
      ),
    );
  }
}
