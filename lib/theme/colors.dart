import 'package:flutter/material.dart';

class MindurColors {
  // ======================
  // BASE
  // ======================
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const transparent = Colors.transparent;

  // ======================
  // BRAND (SAGE MINT)
  // ======================
  static const sageMint = Color(0xFF5FB3A2);
  static const sageMintSoft = Color(0xFF9ED6C9);
  static const sageMintDeep = Color(0xFF3E8F7E);

  // ======================
  // MATERIAL SEMANTIC
  // ======================
  static const primary = sageMint;
  static const primarySoft = sageMintSoft;
  static const onPrimary = white;

  static const secondary = sageMintSoft;
  static const onSecondary = black;

  static const tertiary = sageMintDeep;
  static const onTertiary = white;

  // ======================
  // STATUS COLORS (CALM)
  // ======================
  static const success = Color(0xFF6FBF9B);
  static const successSoft = Color(0x336FBF9B);

  static const warning = Color(0xFFE0B26F);
  static const warningSoft = Color(0x33E0B26F);

  static const error = Color(0xFFD17A7A);
  static const errorSoft = Color(0x33D17A7A);
  static const onError = white;

  static const info = Color(0xFF7BA7D1);
  static const infoSoft = Color(0x337BA7D1);

  // =========================================================
  // LIGHT MODE — SURFACES (DO NOT TOUCH, THESE WERE FINE)
  // =========================================================
  static const lightBg = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFF5F6FA);
  static const lightSurfaceStrong = Color(0xFFECEEF3);

  static const lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const lightSurfaceContainerLow = Color(0xFFF8F9FC);
  static const lightSurfaceContainer = Color(0xFFF2F4F9);
  static const lightSurfaceContainerHigh = Color(0xFFECEEF3);
  static const lightSurfaceContainerHighest = Color(0xFFE6E9F0);

  // ======================
  // LIGHT MODE — TEXT
  // ======================
  static const lightTextPrimary = Color(0xFF0D0D0D);
  static const lightTextSecondary = Color(0xFF4D4D4D);
  static const lightTextMuted = Color(0xFF808080);
  static const lightTextDisabled = Color(0xFFB0B0B0);

  // =========================================================
  // DARK MODE — FIXED SURFACES (THIS IS THE IMPORTANT PART)
  // =========================================================
  static const darkBg = Color(0xFF0E0E0E);

  static const darkSurface = Color(0xFF161616);

  static const darkSurfaceContainerLowest = Color(0xFF121212);
  static const darkSurfaceContainerLow = Color(0xFF1A1A1A);
  static const darkSurfaceContainer = Color(0xFF202020);
  static const darkSurfaceContainerHigh = Color(0xFF262626);
  static const darkSurfaceContainerHighest = Color(0xFF2D2D2D);

  // ======================
  // DARK MODE — TEXT
  // ======================
  static const darkTextPrimary = Color(0xFFF2F2F2);
  static const darkTextSecondary = Color(0xFFB3B3B3);
  static const darkTextMuted = Color(0xFF8A8A8A);
  static const darkTextDisabled = Color(0xFF5C5C5C);

  // ======================
  // OUTLINES / DIVIDERS / TRACKS
  // ======================
  static const outlineLight = Color(0xFFDADDE5);
  static const outlineVariantLight = Color(0xFFCDD1DA);

  static const outlineDark = Color(0xFF2F2F2F);
  static const outlineVariantDark = Color(0xFF3A3A3A);

  // ======================
  // INTERACTION STATES
  // ======================
  static const focusRing = Color(0xFF7BCBB9);
  static const hoverOverlay = Color(0x145FB3A2);
  static const pressedOverlay = Color(0x245FB3A2);
  static const selectionOverlay = Color(0x335FB3A2);

  // ======================
  // DISABLED
  // ======================
  static const disabledLight = lightTextDisabled;
  static const disabledDark = darkTextDisabled;

  // ======================
  // BACKGROUND GRADIENTS
  // ======================
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkBg, darkSurface],
  );

  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightBg, lightSurface],
  );
}
