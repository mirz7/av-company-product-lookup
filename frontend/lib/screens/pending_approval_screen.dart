import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  bool _checking = false;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    final profile = await _api.getProfile(forceRefresh: true);
    if (!mounted) return;
    setState(() => _checking = false);

    if (profile != null && profile['is_approved'] == true) {
      Navigator.pushReplacementNamed(context, '/search');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.hourglass_empty_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Still pending — please wait for admin approval.',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: const Color(0xFF9E2016),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF12121F)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFDED8D0)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final card = isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.7);
    final border = isDark ? Colors.white.withOpacity(0.10) : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF12121F) : const Color(0xFFDED8D0),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: bg, begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.5, 1.0]),
        ),
        child: Stack(children: [
          // Glowing orbs
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Positioned(
              top: -80, right: -60,
              child: Container(
                width: 260, height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? const Color(0xFF8B9BAE) : const Color(0xFF9E2016)).withOpacity(0.05 + _pulseController.value * 0.03),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Positioned(
              bottom: -100, left: -80,
              child: Container(
                width: 320, height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B9BAE).withOpacity(0.04 + _pulseController.value * 0.03),
                ),
              ),
            ),
          ),

          SafeArea(child: Center(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

              // Logo
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/images/logo.png', width: 72, height: 72, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(colors: [Color(0xFF9E2016), Color(0xFFBF3328)]),
                    ),
                    child: const Center(child: Text('AV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22))),
                  ),
                ),
              ).animate().scale(duration: 700.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 16),
              Text('AV & Company', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 2.0)).animate().fadeIn(delay: 200.ms),
              Text('WORKFORCE PORTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sub, letterSpacing: 3.0)).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 48),

              // Hourglass animation
              AnimatedBuilder(
                animation: _rotateController,
                builder: (_, __) => Transform.rotate(
                  angle: _rotateController.value * 2 * 3.14159,
                  child: Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [isDark ? const Color(0xFF5A6A78) : const Color(0xFF8B9BAE), isDark ? const Color(0xFF8B9BAE) : Colors.white]),
                      boxShadow: [BoxShadow(color: (isDark ? Colors.black : const Color(0xFF8B9BAE)).withOpacity(0.3), blurRadius: 24, spreadRadius: 4)],
                    ),
                    child: const Center(child: Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 44)),
                  ),
                ),
              ).animate().scale(delay: 400.ms, duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 36),

              // Status card
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: border),
                    ),
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB74D).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.3)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFFFFB74D), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          const Text('PENDING APPROVAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFFFB74D), letterSpacing: 1.5)),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      Text('Account Under Review', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text(
                        'Your registration was successful!\nAn admin will review and approve your account shortly. You\'ll be able to access the app once approved.',
                        style: TextStyle(fontSize: 14, color: sub, height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      // Info steps
                      _infoStep('1', 'Registration complete', 'Your account has been created', const Color(0xFF00C896), textColor, sub),
                      const SizedBox(height: 10),
                      _infoStep('2', 'Awaiting admin review', 'Your request is in the queue', const Color(0xFFFFB74D), textColor, sub),
                      const SizedBox(height: 10),
                      _infoStep('3', 'Access granted', 'You can use the app once approved', sub, textColor, sub),
                    ]),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.06),

              const SizedBox(height: 24),

              // Check status button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _checking ? null : _checkNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9E2016),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF9E2016).withOpacity(0.5),
                    elevation: 10,
                    shadowColor: const Color(0xFF9E2016).withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _checking
                      ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                          SizedBox(width: 12),
                          Text('Checking status...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ])
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.refresh_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('Check Approval Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ]),
                ),
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 12),

              // Sign out
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: sub,
                    side: BorderSide(color: border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ).animate().fadeIn(delay: 700.ms),

            ]),
          ))),
        ]),
      ),
    );
  }

  Widget _infoStep(String num, String title, String subtitle, Color color, Color textColor, Color sub) {
    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.4))),
        child: Center(child: Text(num, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color))),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
        Text(subtitle, style: TextStyle(fontSize: 11, color: sub)),
      ])),
    ]);
  }
}
