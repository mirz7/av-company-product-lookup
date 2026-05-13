import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  // ── Primary accent (matched to Staff App crimson) ─────────────────────
  static const Color primary       = Color(0xFF9E2016);   // Logo red
  static const Color primaryLight  = Color(0xFFBF3328);   // brighter red
  static const Color primaryGlow   = Color(0xFFFF6B6B);   // accent/glow red

  // ── Legacy aliases (keep existing references working) ─────────────────
  static const Color crimson      = primary;
  static const Color crimsonLight = primaryLight;
  static const Color crimsonGlow  = primaryGlow;
  static const Color silver       = Color(0xFF8B9BAE);   // Logo silver
  static const Color silverDark   = Color(0xFF5A6A78);   // deeper silver
  static const Color accent       = Color(0xFF00D9A6);   // Teal accent (status)
  static const Color accentGlow   = Color(0xFF5BFFCF);

  // ── Dark mode (matched to Staff App) ──────────────────────────────────
  static const Color darkBg1     = Color(0xFF0F0F1A);   // near black
  static const Color darkBg2     = Color(0xFF1A0A08);   // dark red-black
  static const Color darkBg3     = Color(0xFF2D1010);   // muted dark red
  static const Color darkSurface = Color(0xFF1E1E2E);   // card surface
  static const Color darkCard    = Color(0xFF252535);
  static const Color darkBorder  = Color(0xFF2E2E42);

  // ── Light mode (matched to Staff App) ────────────────────────────────
  static const Color lightBg1     = Color(0xFFF5F0EB);   // warm cream
  static const Color lightBg2     = Color(0xFFEDE5DC);
  static const Color lightBg3     = Color(0xFFDFD5C8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard    = Color(0xFFF8F4F0);
  static const Color lightBorder  = Color(0xFFE0D5C8);
  static const Color lightText    = Color(0xFF1A0A08);
  static const Color lightSubText = Color(0xFF5A4A40);

  // ── Status colors ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF00D9A6);
  static const Color warning = Color(0xFFFFB74D);
  static const Color danger  = Color(0xFFFF5252);
}

class ThemeProvider extends ChangeNotifier {
  static const _key = 'admin_theme_mode';
  bool _isDark = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() { _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDark);
    notifyListeners();
  }
}
