import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class MindurTheme {
  // ======================
  // TEXT BASE
  // ======================
  static final _baseTextTheme = GoogleFonts.manropeTextTheme();

  // ======================
  // LIGHT THEME
  // ======================
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.transparent,

      // ----------------------
      // COLOR SCHEME
      // ----------------------
      colorScheme: const ColorScheme.light(
        primary: MindurColors.primary,
        onPrimary: MindurColors.onPrimary,
        secondary: MindurColors.secondary,
        onSecondary: MindurColors.onSecondary,
        tertiary: MindurColors.tertiary,
        onTertiary: MindurColors.onTertiary,
        error: MindurColors.error,
        onError: MindurColors.onError,
        surface: MindurColors.lightSurface,
        onSurface: MindurColors.lightTextPrimary,
        outline: MindurColors.outlineLight,
        outlineVariant: MindurColors.lightSurfaceStrong,
      ),

      // ----------------------
      // APP BAR
      // ----------------------
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      // ----------------------
      // TEXT THEME (FULL SCALE)
      // ----------------------
      textTheme: _baseTextTheme.copyWith(
        displayLarge: _ts(34, 700, MindurColors.lightTextPrimary),
        displayMedium: _ts(30, 700, MindurColors.lightTextPrimary),
        displaySmall: _ts(26, 700, MindurColors.lightTextPrimary),

        headlineLarge: _ts(28, 600, MindurColors.lightTextPrimary),
        headlineMedium: _ts(24, 600, MindurColors.lightTextPrimary),
        headlineSmall: _ts(20, 600, MindurColors.lightTextPrimary),

        titleLarge: _ts(20, 600, MindurColors.lightTextPrimary),
        titleMedium: _ts(18, 500, MindurColors.lightTextPrimary),
        titleSmall: _ts(16, 500, MindurColors.lightTextPrimary),

        bodyLarge: _ts(16, 400, MindurColors.lightTextPrimary),
        bodyMedium: _ts(15, 400, MindurColors.lightTextSecondary),
        bodySmall: _ts(14, 400, MindurColors.lightTextMuted),

        labelLarge: _ts(15, 500, MindurColors.lightTextPrimary),
        labelMedium: _ts(13, 400, MindurColors.lightTextMuted),
        labelSmall: _ts(11, 400, MindurColors.lightTextMuted),
      ),

      // ----------------------
      // CARD
      // ----------------------
      cardTheme: const CardThemeData(
        color: MindurColors.lightSurfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // ----------------------
      // BUTTONS
      // ----------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MindurColors.primary,
          foregroundColor: MindurColors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: _ts(15, 500, MindurColors.onPrimary),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MindurColors.primary,
          textStyle: _ts(14, 500, MindurColors.primary),
        ),
      ),

      // ----------------------
      // INPUTS
      // ----------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MindurColors.lightSurfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: MindurColors.primary,
            width: 1.5,
          ),
        ),
      ),

      // ----------------------
      // LIST TILE
      // ----------------------
      listTileTheme: const ListTileThemeData(
        iconColor: MindurColors.lightTextMuted,
        textColor: MindurColors.lightTextPrimary,
      ),

      // ----------------------
      // DIVIDER
      // ----------------------
      dividerTheme: const DividerThemeData(
        color: MindurColors.outlineLight,
        thickness: 1,
        space: 24,
      ),

      // ----------------------
      // ICONS
      // ----------------------
      iconTheme: const IconThemeData(
        color: MindurColors.lightTextSecondary,
        size: 22,
      ),

      // ----------------------
      // CHIPS
      // ----------------------
      chipTheme: ChipThemeData(
        backgroundColor: MindurColors.lightSurfaceContainerHigh,
        selectedColor: MindurColors.primarySoft,
        labelStyle: _ts(13, 500, MindurColors.lightTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ----------------------
      // PROGRESS
      // ----------------------
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MindurColors.primary,
        linearTrackColor: MindurColors.lightSurfaceContainerHigh,
      ),
    );
  }

  // ======================
  // DARK THEME
  // ======================
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,

      colorScheme: const ColorScheme.dark(
        primary: MindurColors.primary,
        onPrimary: Colors.black,
        secondary: MindurColors.secondary,
        tertiary: MindurColors.tertiary,
        error: MindurColors.error,
        onError: MindurColors.onError,
        surface: MindurColors.darkSurface,
        onSurface: MindurColors.darkTextPrimary,
        outline: MindurColors.outlineDark,
        outlineVariant: MindurColors.outlineVariantDark,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),

      textTheme: _baseTextTheme.copyWith(
        displayLarge: _ts(34, 700, MindurColors.darkTextPrimary),
        displayMedium: _ts(30, 700, MindurColors.darkTextPrimary),
        displaySmall: _ts(26, 700, MindurColors.darkTextPrimary),

        headlineLarge: _ts(28, 600, MindurColors.darkTextPrimary),
        headlineMedium: _ts(24, 600, MindurColors.darkTextPrimary),
        headlineSmall: _ts(20, 600, MindurColors.darkTextPrimary),

        titleLarge: _ts(20, 600, MindurColors.darkTextPrimary),
        titleMedium: _ts(18, 500, MindurColors.darkTextPrimary),
        titleSmall: _ts(16, 500, MindurColors.darkTextPrimary),

        bodyLarge: _ts(16, 400, MindurColors.darkTextPrimary),
        bodyMedium: _ts(15, 400, MindurColors.darkTextSecondary),
        bodySmall: _ts(14, 400, MindurColors.darkTextMuted),

        labelLarge: _ts(15, 500, MindurColors.darkTextPrimary),
        labelMedium: _ts(13, 400, MindurColors.darkTextMuted),
        labelSmall: _ts(11, 400, MindurColors.darkTextMuted),
      ),

      cardTheme: const CardThemeData(
        color: MindurColors.darkSurfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MindurColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: _ts(15, 500, Colors.black),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MindurColors.darkSurfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: MindurColors.primary,
            width: 1.5,
          ),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: MindurColors.outlineDark,
        thickness: 1,
        space: 24,
      ),

      iconTheme: const IconThemeData(
        color: MindurColors.darkTextSecondary,
        size: 22,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MindurColors.primary,
        linearTrackColor: MindurColors.darkSurfaceContainerHigh,
      ),
    );
  }

  // ======================
  // HELPER
  // ======================
  static TextStyle _ts(double size, int weight, Color color) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: FontWeight.values[weight ~/ 100 - 1],
      color: color,
    );
  }
}
