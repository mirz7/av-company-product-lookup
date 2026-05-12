import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  static const Color crimson      = Color(0xFF9E2016);
  static const Color crimsonLight = Color(0xFFBF3328);
  static const Color crimsonGlow  = Color(0xFFFF6B6B);
  static const Color silver       = Color(0xFF8B9BAE);
  static const Color silverDark   = Color(0xFF5A6A78);

  static const Color darkBg1     = Color(0xFF0F0F1A);
  static const Color darkBg2     = Color(0xFF1A0A08);
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color darkCard    = Color(0xFF252535);
  static const Color darkBorder  = Color(0xFF2E2E42);

  static const Color lightBg1     = Color(0xFFF5F0EB);
  static const Color lightBg2     = Color(0xFFEDE5DC);
  static const Color lightBg3     = Color(0xFFDFD5C8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder  = Color(0xFFE0D5C8);
  static const Color lightText    = Color(0xFF1A0A08);
  static const Color lightSubText = Color(0xFF5A4A40);
}

class ThemeProvider extends ChangeNotifier {
  static const _key = 'admin_theme_mode';
  bool _isDark = true;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? true;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
    notifyListeners();
  }
}
