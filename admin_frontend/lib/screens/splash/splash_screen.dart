import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/route_constants.dart';
import '../../data/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    print("DEBUG: SplashScreen initState()");
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _check();
  }

  Future<void> _check() async {
    print("DEBUG: SplashScreen _check() started");
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    
    print("DEBUG: Calling authService.isAdminSetupNeeded()");
    final authService = AuthService();
    final setupNeeded = await authService.isAdminSetupNeeded();
    print("DEBUG: authService.isAdminSetupNeeded() completed. Result: $setupNeeded");
    
    if (!mounted) return;
    
    if (setupNeeded) {
      print("DEBUG: Navigating to register");
      context.go(RouteConstants.register);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    print("DEBUG: Access token from SharedPreferences: $token");
    if (!mounted) return;
    final destination = token != null && token.isNotEmpty ? RouteConstants.dashboard : RouteConstants.login;
    print("DEBUG: Navigating to destination: $destination");
    context.go(destination);
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF2D1010)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFCFBBAA)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final subTextColor = isDark ? Colors.white54 : AppTheme.lightSubText;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2D1010) : const Color(0xFFCFBBAA),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: bg, begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.5, 1.0])),
        child: Stack(children: [
          Positioned(top: -80, right: -60, child: AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.06 + _pulse.value * 0.04))))),
          Positioned(bottom: -100, left: -80, child: AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent.withOpacity(0.04 + _pulse.value * 0.03))))),
          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              height: 100, width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 12))],
              ),
              child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset('assets/images/logo.png', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Text('AV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32))))),
            ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text('AV ADMIN PORTAL', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 8),
            Text('SECURE ACCESS HUB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subTextColor.withOpacity(0.55), letterSpacing: 3.0)).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 8),
            const SizedBox(height: 52),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 60), child: Column(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 3,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return LinearProgressIndicator(
                        value: value,
                        backgroundColor: (isDark ? Colors.white : AppTheme.silverDark).withOpacity(0.12),
                        color: AppTheme.primaryGlow,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('LOADING...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: (isDark ? Colors.white : AppTheme.silverDark).withOpacity(0.35), letterSpacing: 2.0)).animate().fadeIn(delay: 600.ms),
            ])),
          ])),
        ]),
      ),
    );
  }
}
