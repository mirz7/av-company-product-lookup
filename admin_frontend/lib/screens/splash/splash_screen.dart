import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/route_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pulse;
  late AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _progress = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500))..forward();
    _check();
  }

  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (!mounted) return;
    context.go(token != null && token.isNotEmpty ? RouteConstants.dashboard : RouteConstants.login);
  }

  @override
  void dispose() { _pulse.dispose(); _progress.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF2A0D0D)] : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFE8D0C8)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final subTextColor = isDark ? Colors.white54 : AppTheme.lightSubText;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2A0D0D) : const Color(0xFFE8D0C8),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: bg, begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.5, 1.0])),
        child: Stack(children: [
          Positioned(top: -80, right: -60, child: AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.crimson.withOpacity(0.08 + _pulse.value * 0.06))))),
          Positioned(bottom: -100, left: -80, child: AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.silver.withOpacity(0.05 + _pulse.value * 0.04))))),
          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: AppTheme.crimson.withOpacity(0.4), blurRadius: 40, offset: const Offset(0, 12))]),
              child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset('assets/images/logo.png', width: 100, height: 100, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.business, size: 100, color: AppTheme.crimson))),
            ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text('AV & Company', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 2.5)).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            Text('ADMIN PORTAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subTextColor.withOpacity(0.55), letterSpacing: 3.0)).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.crimson.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.crimson.withOpacity(0.3))),
              child: const Text('WORKFORCE MANAGEMENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.crimsonGlow, letterSpacing: 1.5)),
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 52),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 60), child: Column(children: [
              ClipRRect(borderRadius: BorderRadius.circular(4), child: SizedBox(height: 3, child: AnimatedBuilder(animation: _progress, builder: (_, __) => LinearProgressIndicator(value: _progress.value, backgroundColor: (isDark ? Colors.white : AppTheme.silverDark).withOpacity(0.12), valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.crimsonGlow))))),
              const SizedBox(height: 12),
              Text('LOADING...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: (isDark ? Colors.white : AppTheme.silverDark).withOpacity(0.35), letterSpacing: 2.0)).animate().fadeIn(delay: 600.ms),
            ])),
          ])),
        ]),
      ),
    );
  }
}
