import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeController {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.system);

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('theme_mode');

    switch (value) {
      case 'light':
        themeMode.value = ThemeMode.light;
        break;
      case 'dark':
        themeMode.value = ThemeMode.dark;
        break;
      default:
        themeMode.value = ThemeMode.system;
    }
  }

  static Future<void> setTheme(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();

    if (mode == ThemeMode.system) {
      await prefs.remove('theme_mode');
    } else {
      await prefs.setString(
        'theme_mode',
        mode == ThemeMode.light ? 'light' : 'dark',
      );
    }
  }
}
