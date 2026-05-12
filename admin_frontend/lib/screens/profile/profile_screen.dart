import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E).withOpacity(0.97) : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 28),
            ),
            const SizedBox(height: 20),
            Text('Sign Out?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppTheme.lightText)),
            const SizedBox(height: 8),
            Text('You will be returned to the login screen.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : AppTheme.lightSubText, height: 1.5)),
            const SizedBox(height: 28),
            Row(children: [
              Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx, false), child: Container(height: 48,
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.06) : AppTheme.lightBg2, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder)),
                child: Center(child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white70 : AppTheme.lightSubText)))))),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(onTap: () => Navigator.pop(ctx, true), child: Container(height: 48,
                decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppTheme.danger.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))]),
                child: const Center(child: Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white)))))),
            ]),
          ]).animate().fade(duration: 200.ms).scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),
        ))),
      ),
    );
    if (confirmed != true) return;
    await context.read<AuthProvider>().logout();
    if (context.mounted) context.go(RouteConstants.login);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final admin = context.watch<AuthProvider>().adminUser;
    final bg = isDark
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF2D1010)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFCFBBAA)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final card = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.8);
    final border = isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2D1010) : const Color(0xFFCFBBAA),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: bg, begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.5, 1.0])),
        child: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                height: 42, width: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Center(child: Text('AV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)))),
                ),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AV ADMIN PORTAL', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)),
                const SizedBox(height: 1),
                Text('Personal Dashboard', style: TextStyle(fontSize: 11, color: sub, letterSpacing: 0.5)),
              ]),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
              child: Text('MY SPACE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGlow, letterSpacing: 1.5)),
            ),
          ])).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),

          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Column(children: [
            // Avatar card
            ClipRRect(borderRadius: BorderRadius.circular(24), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(24), border: Border.all(color: border)),
              child: Column(children: [
                Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 20)],
                    ),
                    child: ClipOval(child: Image.asset('assets/images/logo.png', fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.person, size: 50, color: Colors.white))),
                  ),
                  Positioned(bottom: 0, right: 0, child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle, border: Border.all(color: isDark ? AppTheme.darkBg1 : AppTheme.lightSurface, width: 2)),
                    child: const Icon(Icons.shield, color: Colors.white, size: 14),
                  )),
                ]),
                const SizedBox(height: 16),
                Text(admin?.fullName.isNotEmpty == true ? admin!.fullName : (admin?.username ?? 'Admin User'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
                    child: Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryGlow, letterSpacing: 1)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.06) : AppTheme.lightBg3, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
                    child: Text('@${admin?.username ?? 'admin'}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sub, letterSpacing: 1)),
                  ),
                ]),
              ]),
            ))).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: Row(children: [
              Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('SECURITY & ACCOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sub, letterSpacing: 1.5)),
            ])).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),

            _tile(Icons.manage_accounts_outlined, 'Edit Profile Details', card, border, textColor, sub, isDark, () {}).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05),
            const SizedBox(height: 8),
            _tile(Icons.lock_reset, 'Change Password', card, border, textColor, sub, isDark, () {}).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
            const SizedBox(height: 8),

            // Theme toggle
            ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppTheme.primary, size: 20), const SizedBox(width: 14), Text(isDark ? 'Dark Mode' : 'Light Mode', style: TextStyle(fontSize: 14, color: textColor))]),
                GestureDetector(onTap: () => context.read<ThemeProvider>().toggle(), child: AnimatedContainer(duration: 300.ms, width: 50, height: 28, padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: isDark ? AppTheme.primary : AppTheme.silver),
                  child: AnimatedAlign(duration: 300.ms, alignment: isDark ? Alignment.centerRight : Alignment.centerLeft, child: Container(width: 22, height: 22, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                    child: Icon(isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded, size: 13, color: isDark ? AppTheme.primary : AppTheme.silver))))),
              ]),
            ))).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05),
            const SizedBox(height: 8),

            // Sign Out
            GestureDetector(onTap: () => _logout(context, isDark), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 20), const SizedBox(width: 14), Text('Sign Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor))]),
                Icon(Icons.chevron_right, color: isDark ? Colors.white.withOpacity(0.3) : AppTheme.silverDark),
              ]),
            )))).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),

            const SizedBox(height: 24),
            Align(alignment: Alignment.centerLeft, child: Row(children: [
              Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('SYSTEM & HEALTH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sub, letterSpacing: 1.5)),
            ])).animate().fadeIn(delay: 450.ms),
            const SizedBox(height: 12),

            // System health card
            ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [const Icon(Icons.cloud_done_outlined, color: Colors.greenAccent, size: 18), const SizedBox(width: 14), Text('API Server Status', style: TextStyle(fontSize: 13, color: textColor))]),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Text('ONLINE', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold))),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [const Icon(Icons.storage_rounded, color: AppTheme.primary, size: 18), const SizedBox(width: 14), Text('Database Health', style: TextStyle(fontSize: 13, color: textColor))]),
                  Text('98% Optimized', style: TextStyle(fontSize: 11, color: sub)),
                ]),
              ]),
            ))).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05),

            const SizedBox(height: 24),
            Align(alignment: Alignment.centerLeft, child: Row(children: [
              Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('APP INFO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sub, letterSpacing: 1.5)),
            ])).animate().fadeIn(delay: 550.ms),
            const SizedBox(height: 12),

            _tile(Icons.info_outline_rounded, 'Privacy Policy', card, border, textColor, sub, isDark, () {}).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 8),
            _tile(Icons.description_outlined, 'Terms of Service', card, border, textColor, sub, isDark, () {}).animate().fadeIn(delay: 650.ms),
            
            const SizedBox(height: 24),
            Text('Version 1.0.4 (Stable)', style: TextStyle(fontSize: 11, color: sub.withOpacity(0.5), fontWeight: FontWeight.w600, letterSpacing: 0.5)).animate().fadeIn(delay: 700.ms),
            const SizedBox(height: 32),
          ]))),
        ])),
      ),
    );
  }

  Widget _tile(IconData icon, String title, Color card, Color border, Color textColor, Color sub, bool isDark, VoidCallback onTap) =>
    GestureDetector(onTap: onTap, child: ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [Icon(icon, color: AppTheme.primary, size: 20), const SizedBox(width: 14), Text(title, style: TextStyle(fontSize: 14, color: textColor))]),
        Icon(Icons.chevron_right, color: isDark ? Colors.white.withOpacity(0.3) : AppTheme.silverDark),
      ]),
    ))));
}
