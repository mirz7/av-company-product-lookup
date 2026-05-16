import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppTheme {
  static bool hasSeenInitialAnimations = false;
  // ── Logo-extracted brand colors ──────────────────────────────────────
  static const Color crimson        = Color(0xFF9E2016); // Logo red
  static const Color crimsonLight   = Color(0xFFBF3328); // brighter red
  static const Color crimsonGlow    = Color(0xFFFF6B6B); // accent/glow red
  static const Color silver         = Color(0xFF8B9BAE); // Logo silver
  static const Color silverDark     = Color(0xFF5A6A78); // deeper silver

  // ── Dark theme palette ───────────────────────────────────────────────
  static const Color darkBg1        = Color(0xFF0F0F1A); // near black
  static const Color darkBg2        = Color(0xFF1A0A08); // dark red-black
  static const Color darkBg3        = Color(0xFF2D1010); // muted dark red
  static const Color darkSurface    = Color(0xFF1E1E2E); // card surface
  static const Color darkCard       = Color(0xFF252535);
  static const Color darkBorder     = Color(0xFF2E2E42);

  // ── Light theme palette ──────────────────────────────────────────────
  static const Color lightBg1       = Color(0xFFF5F0EB); // warm cream (logo bg)
  static const Color lightBg2       = Color(0xFFEDE5DC);
  static const Color lightBg3       = Color(0xFFDFD5C8);
  static const Color lightSurface   = Color(0xFFFFFFFF);
  static const Color lightCard      = Color(0xFFF8F4F0);
  static const Color lightBorder    = Color(0xFFE0D5C8);
  static const Color lightText      = Color(0xFF1A0A08);
  static const Color lightSubText   = Color(0xFF5A4A40);

  // ── Gradient helpers ─────────────────────────────────────────────────
  static List<Color> darkBgGradient = [darkBg1, darkBg2, crimson];
  static List<Color> lightBgGradient = [lightBg1, lightBg2, Color(0xFFCFBBAA)];

  static List<Color> darkPageGradient = [darkSurface, darkBg2, Color(0xFFB22A1A)];
  static List<Color> lightPageGradient = [lightBg1, Color(0xFFE8D8CC), Color(0xFFCFAA99)];
}

class ThemeProvider extends ChangeNotifier {
  static const _storageKey = 'theme_mode';
  final _storage = const FlutterSecureStorage();

  bool _isDark = false;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final saved = await _storage.read(key: _storageKey);
    _isDark = saved == 'dark';
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    await _storage.write(key: _storageKey, value: _isDark ? 'dark' : 'light');
    notifyListeners();
  }
}
