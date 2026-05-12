import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/theme_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();

    _checkLoginState();
  }

  Future<void> _checkLoginState() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    final token = await _apiService.storage.read(key: 'access_token');
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Token exists — check if admin has approved this employee
      final profile = await _apiService.getProfile(forceRefresh: true);
      if (!mounted) return;
      if (profile != null && profile['is_approved'] == true) {
        Navigator.pushReplacementNamed(context, '/search');
      } else {
        Navigator.pushReplacementNamed(context, '/pending');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;

    final gradientColors = isDark
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF2A0D0D)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFE8D0C8)];

    final orbColor = isDark
        ? AppTheme.crimson.withOpacity(0.08 + _pulseController.value * 0.06)
        : AppTheme.crimson.withOpacity(0.10 + _pulseController.value * 0.06);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2A0D0D) : const Color(0xFFE8D0C8),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Glowing orb — top right
            Positioned(
              top: -80,
              right: -60,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.crimson
                        .withOpacity(0.08 + _pulseController.value * 0.06),
                  ),
                ),
              ),
            ),
            // Glowing orb — bottom left
            Positioned(
              bottom: -100,
              left: -80,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.silver
                        .withOpacity(0.05 + _pulseController.value * 0.04),
                  ),
                ),
              ),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(
                          Icons.business,
                          size: 100,
                          color: AppTheme.crimson),
                    ),
                  ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 24),
                  Text(
                    'AV & Company',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppTheme.lightText,
                      letterSpacing: 2.5,
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    'WORKFORCE PORTAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (isDark ? Colors.white : AppTheme.lightSubText).withOpacity(0.55),
                      letterSpacing: 3.0,
                    ),
                  ).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 48),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 3,
                            child: AnimatedBuilder(
                              animation: _progressController,
                              builder: (_, __) {
                                return LinearProgressIndicator(
                                  value: _progressController.value,
                                  backgroundColor: (isDark ? Colors.white : AppTheme.silverDark).withOpacity(0.12),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.crimsonGlow),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'LOADING...',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: (isDark ? Colors.white : AppTheme.silverDark).withOpacity(0.35),
                            letterSpacing: 2.0,
                          ),
                        ).animate().fadeIn(delay: 600.ms),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
