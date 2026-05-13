import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class RestrictedScreen extends StatefulWidget {
  final String reason;
  const RestrictedScreen({super.key, this.reason = 'Your account has been restricted by an administrator.'});

  @override
  State<RestrictedScreen> createState() => _RestrictedScreenState();
}

class _RestrictedScreenState extends State<RestrictedScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  final ApiService _api = ApiService();
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    final profile = await _api.getProfile(forceRefresh: true);
    if (!mounted) return;
    setState(() => _checking = false);

    if (profile != null && profile['is_active'] == true) {
      if (profile['is_approved'] == true) {
        Navigator.pushReplacementNamed(context, '/search');
      } else {
        Navigator.pushReplacementNamed(context, '/pending');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.lock_person_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Account still restricted.', style: TextStyle(fontWeight: FontWeight.w600)),
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
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF161624)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFE2E2EA)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final card = isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.7);
    final border = isDark ? Colors.white.withOpacity(0.10) : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF161624) : const Color(0xFFE2E2EA),
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
                  color: (isDark ? const Color(0xFF8B9BAE) : const Color(0xFF9E2016)).withOpacity(0.08 + _pulseController.value * 0.04),
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
                  errorBuilder: (_, __, ___) => const Icon(Icons.business, size: 72, color: AppTheme.crimson),
                ),
              ).animate().scale(duration: 700.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 16),
              Text('AV & Company', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 2.0)),
              
              const SizedBox(height: 48),

              // Restricted Icon
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF9E2016).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFF9E2016).withOpacity(0.3), width: 2),
                  boxShadow: [BoxShadow(color: const Color(0xFF9E2016).withOpacity(0.2), blurRadius: 30, spreadRadius: 5)],
                ),
                child: const Center(child: Icon(Icons.lock_person_rounded, color: Color(0xFFFF6B6B), size: 48)),
              ).animate().shake(duration: 500.ms, hz: 4),

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
                          color: (isDark ? Colors.white : const Color(0xFF9E2016)).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: (isDark ? Colors.white : const Color(0xFF9E2016)).withOpacity(0.2)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: isDark ? Colors.white70 : const Color(0xFF9E2016), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('ACCESS RESTRICTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : const Color(0xFF9E2016), letterSpacing: 1.5)),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      Text('Access Suspended', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      Text(
                        widget.reason,
                        style: TextStyle(fontSize: 14, color: sub, height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Please contact your supervisor or reach out to the admin office to restore your account access.',
                        style: TextStyle(fontSize: 12, color: sub.withOpacity(0.7), fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ]),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.06),

              const SizedBox(height: 32),

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
                          Text('Updating access...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ])
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.security_update_good_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('Re-verify Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ]),
                ),
              ).animate().fadeIn(delay: 500.ms),

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
              ).animate().fadeIn(delay: 600.ms),

            ]),
          ))),
        ]),
      ),
    );
  }
}
