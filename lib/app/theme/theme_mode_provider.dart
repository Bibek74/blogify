import 'package:blogify/core/services/storage/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeKey = 'app_theme_mode';

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._prefs) : super(_readInitialMode(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _readInitialMode(SharedPreferences prefs) {
    final value = prefs.getString(_themeModeKey);
    if (value == ThemeMode.dark.name) return ThemeMode.dark;
    return ThemeMode.light;
  }

  Future<void> setDarkMode(bool isDark) async {
    final mode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = mode;
    await _prefs.setString(_themeModeKey, mode.name);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    final prefs = ref.read(sharedPreferencesProvider);
    return ThemeModeController(prefs);
  },
);
