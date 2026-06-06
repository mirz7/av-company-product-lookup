import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/services/product_service.dart';
import '../../providers/dashboard_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _apiStatus = 'LOADING...';
  String _dbStatus = 'Checking...';
  String _ping = '-';

  @override
  void initState() {
    super.initState();
    _fetchHealth();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().refreshProfile();
    });
  }

  Future<void> _fetchHealth() async {
    final health = await AuthService().getHealth();
    if (mounted) {
      setState(() {
        _apiStatus = health['api_status'];
        _dbStatus = health['db_status'];
        _ping = health['ping'];
      });
    }
  }

  Future<void> _logout(BuildContext context, bool isDark) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: Dialog(
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
                  ]),
                ))),
              ),
            ),
          ),
        );
      },
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
          ])),

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
            ))),

            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: Row(children: [
              Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('SECURITY & ACCOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sub, letterSpacing: 1.5)),
            ])),
            const SizedBox(height: 12),

            _tile(Icons.manage_accounts_outlined, 'Edit Profile Details', card, border, textColor, sub, isDark, () => _editProfile(context, admin, isDark)),
            const SizedBox(height: 8),
            _tile(Icons.lock_reset, 'Change Password', card, border, textColor, sub, isDark, () => _changePassword(context, isDark)),
            const SizedBox(height: 20),
            Align(alignment: Alignment.centerLeft, child: Row(children: [
              Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('INVENTORY MANAGEMENT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sub, letterSpacing: 1.5)),
            ])),
            const SizedBox(height: 12),
            _tile(Icons.table_chart_outlined, 'Upload Inventory Spreadsheet', card, border, textColor, sub, isDark, () => _showUploadInventoryDialog(context, isDark)),
            const SizedBox(height: 8),

            // Theme toggle
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.read<ThemeProvider>().toggle(),
                borderRadius: BorderRadius.circular(14),
                splashColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.12),
                highlightColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                child: ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppTheme.primary, size: 20), const SizedBox(width: 14), Text(isDark ? 'Dark Mode' : 'Light Mode', style: TextStyle(fontSize: 14, color: textColor))]),
                    AnimatedContainer(duration: 300.ms, width: 50, height: 28, padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: isDark ? AppTheme.primary : AppTheme.silver),
                      child: AnimatedAlign(duration: 300.ms, alignment: isDark ? Alignment.centerRight : Alignment.centerLeft, child: Container(width: 22, height: 22, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: Icon(isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded, size: 13, color: isDark ? AppTheme.primary : AppTheme.silver)))),
                  ]),
                ))),
              ),
            ),
            const SizedBox(height: 8),

            // Sign Out
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _logout(context, isDark),
                borderRadius: BorderRadius.circular(14),
                splashColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.12),
                highlightColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                child: ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Row(children: [const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 20), const SizedBox(width: 14), Text('Sign Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor))]),
                    Icon(Icons.chevron_right, color: isDark ? Colors.white.withOpacity(0.3) : AppTheme.silverDark),
                  ]),
                ))),
              ),
            ),

            const SizedBox(height: 24),
            Align(alignment: Alignment.centerLeft, child: Row(children: [
              Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('SYSTEM & HEALTH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sub, letterSpacing: 1.5)),
            ])),
            const SizedBox(height: 12),

            // System health card
            ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [const Icon(Icons.cloud_done_outlined, color: Colors.greenAccent, size: 18), const SizedBox(width: 14), Text('API Server Status', style: TextStyle(fontSize: 13, color: textColor))]),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: _apiStatus == 'ONLINE' ? Colors.greenAccent.withOpacity(0.1) : AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Text(_apiStatus, style: TextStyle(color: _apiStatus == 'ONLINE' ? Colors.greenAccent : AppTheme.danger, fontSize: 9, fontWeight: FontWeight.bold))),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [const Icon(Icons.storage_rounded, color: AppTheme.primary, size: 18), const SizedBox(width: 14), Text('Database Health', style: TextStyle(fontSize: 13, color: textColor))]),
                  Text(_dbStatus, style: TextStyle(fontSize: 11, color: sub)),
                ]),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [const Icon(Icons.speed_rounded, color: AppTheme.primary, size: 18), const SizedBox(width: 14), Text('Server Ping', style: TextStyle(fontSize: 13, color: textColor))]),
                  Text(_ping, style: TextStyle(fontSize: 11, color: sub)),
                ]),
              ]),
            ))),

            const SizedBox(height: 24),
            Align(alignment: Alignment.centerLeft, child: Row(children: [
              Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Text('APP INFO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sub, letterSpacing: 1.5)),
            ])),
            const SizedBox(height: 12),

            _tile(Icons.info_outline_rounded, 'Privacy Policy', card, border, textColor, sub, isDark, () {}),
            const SizedBox(height: 8),
            _tile(Icons.description_outlined, 'Terms of Service', card, border, textColor, sub, isDark, () {}),
            
            const SizedBox(height: 24),
            Text('Version 1.0.4 (Stable)', style: TextStyle(fontSize: 11, color: sub.withOpacity(0.5), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 32),
          ]))),
        ])),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, dynamic admin, bool isDark) async {
    final fnCtrl = TextEditingController(text: admin?.firstName ?? '');
    final lnCtrl = TextEditingController(text: admin?.lastName ?? '');
    final emailCtrl = TextEditingController(text: admin?.email ?? '');
    final phoneCtrl = TextEditingController(text: admin?.phoneNumber ?? '');
    bool saving = false;

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        final textColor = isDark ? Colors.white : AppTheme.lightText;
        final subColor = isDark ? Colors.white70 : AppTheme.lightSubText;
        final fieldColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
        final borderColor = isDark ? Colors.white.withOpacity(0.1) : AppTheme.lightBorder;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E).withOpacity(0.98) : Colors.white.withOpacity(0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: borderColor),
          ),
          padding: EdgeInsets.only(left: 28, right: 28, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.manage_accounts_outlined, color: AppTheme.primary, size: 24)),
              const SizedBox(width: 16),
              Text('Edit Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
            ]),
            const SizedBox(height: 28),
            _modalField('First Name', fnCtrl, Icons.person_outline, isDark, fieldColor, borderColor, textColor, subColor),
            const SizedBox(height: 16),
            _modalField('Last Name', lnCtrl, Icons.person_outline, isDark, fieldColor, borderColor, textColor, subColor),
            const SizedBox(height: 16),
            _modalField('Gmail Address', emailCtrl, Icons.alternate_email, isDark, fieldColor, borderColor, textColor, subColor),
            const SizedBox(height: 16),
            _modalField('Phone Number', phoneCtrl, Icons.phone_outlined, isDark, fieldColor, borderColor, textColor, subColor),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: saving ? null : () async {
                setModalState(() => saving = true);
                try {
                  final success = await AuthService().updateProfile(fnCtrl.text, lnCtrl.text, emailCtrl.text, phoneCtrl.text);
                  if (success && ctx.mounted) {
                    await context.read<AuthProvider>().refreshProfile();
                  }
                } catch (_) {}
                if (ctx.mounted) Navigator.pop(ctx);
                if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Profile updated successfully'), backgroundColor: AppTheme.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(child: saving 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Future<void> _changePassword(BuildContext context, bool isDark) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    bool saving = false;
    String? err;

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        final textColor = isDark ? Colors.white : AppTheme.lightText;
        final subColor = isDark ? Colors.white70 : AppTheme.lightSubText;
        final fieldColor = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03);
        final borderColor = isDark ? Colors.white.withOpacity(0.1) : AppTheme.lightBorder;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E).withOpacity(0.98) : Colors.white.withOpacity(0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: borderColor),
          ),
          padding: EdgeInsets.only(left: 28, right: 28, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.lock_reset_rounded, color: AppTheme.primary, size: 24)),
              const SizedBox(width: 16),
              Text('Change Password', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
            ]),
            if (err != null) ...[const SizedBox(height: 16), Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(err!, style: const TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.w600)))],
            const SizedBox(height: 28),
            _modalField('Current Password', oldCtrl, Icons.lock_outline, isDark, fieldColor, borderColor, textColor, subColor, obscure: true),
            const SizedBox(height: 16),
            _modalField('New Password', newCtrl, Icons.vpn_key_outlined, isDark, fieldColor, borderColor, textColor, subColor, obscure: true),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: saving ? null : () async {
                setModalState(() => saving = true);
                final msg = await AuthService().changePassword(oldCtrl.text, newCtrl.text);
                if (msg != null) {
                  setModalState(() { saving = false; err = msg; });
                } else {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Password updated successfully'), backgroundColor: AppTheme.primary, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Center(child: saving 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16))),
              ),
            ),
          ]),
        );
      }),
    );
  }

  Widget _modalField(String label, TextEditingController ctrl, IconData icon, bool isDark, Color fill, Color border, Color text, Color sub, {bool obscure = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: sub, letterSpacing: 0.5)),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        obscureText: obscure,
        style: TextStyle(color: text, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          filled: true,
          fillColor: fill,
          prefixIcon: Icon(icon, size: 20, color: AppTheme.primary.withOpacity(0.7)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _tile(IconData icon, String title, Color card, Color border, Color textColor, Color sub, bool isDark, VoidCallback onTap) =>
    Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.12),
        highlightColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        child: ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [Icon(icon, color: AppTheme.primary, size: 20), const SizedBox(width: 14), Text(title, style: TextStyle(fontSize: 14, color: textColor))]),
            Icon(Icons.chevron_right, color: isDark ? Colors.white.withOpacity(0.3) : AppTheme.silverDark),
          ]),
        ))),
      ),
    );

  Future<void> _showUploadInventoryDialog(BuildContext context, bool isDark) async {
    final ProductService svc = ProductService();
    String uploadMode = 'upsert'; // 'upsert' or 'replace'
    bool uploading = false;
    String? err;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModalState) {
        final textColor = isDark ? Colors.white : AppTheme.lightText;
        final subColor = isDark ? Colors.white70 : AppTheme.lightSubText;
        final borderColor = isDark ? Colors.white.withOpacity(0.1) : AppTheme.lightBorder;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E).withOpacity(0.98) : Colors.white.withOpacity(0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: borderColor),
          ),
          padding: EdgeInsets.only(left: 28, right: 28, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.table_chart_outlined, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Text('Import Excel File', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
              ]),
              if (err != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(err!, style: const TextStyle(color: AppTheme.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                )
              ],
              const SizedBox(height: 24),
              Text('IMPORT MODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: subColor, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              
              // Upsert mode option
              InkWell(
                onTap: () => setModalState(() => uploadMode = 'upsert'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: uploadMode == 'upsert' ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: uploadMode == 'upsert' ? AppTheme.primary : borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.update_rounded, color: uploadMode == 'upsert' ? AppTheme.primary : subColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Update & Add Products', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('Updates prices/names for existing products, and appends new products.', style: TextStyle(color: subColor, fontSize: 11)),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: 'upsert',
                        groupValue: uploadMode,
                        activeColor: AppTheme.primary,
                        onChanged: (v) => setModalState(() => uploadMode = v!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Replace mode option
              InkWell(
                onTap: () => setModalState(() => uploadMode = 'replace'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: uploadMode == 'replace' ? AppTheme.danger.withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: uploadMode == 'replace' ? AppTheme.danger : borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_outlined, color: uploadMode == 'replace' ? AppTheme.danger : subColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Replace Product Table', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text('Clears the existing inventory database and does a fresh import.', style: TextStyle(color: subColor, fontSize: 11)),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: 'replace',
                        groupValue: uploadMode,
                        activeColor: AppTheme.danger,
                        onChanged: (v) => setModalState(() => uploadMode = v!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Action button to trigger upload
              GestureDetector(
                onTap: uploading ? null : () async {
                  setModalState(() { uploading = true; err = null; });
                  try {
                    final result = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['xlsx', 'xls', 'csv'],
                      withData: true,
                    );

                    if (result == null || result.files.isEmpty) {
                      setModalState(() { uploading = false; });
                      return;
                    }

                    final file = result.files.first;
                    final response = await svc.uploadInventory(file, mode: uploadMode);

                    if (response['success'] == true) {
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        Provider.of<DashboardProvider>(context, listen: false).fetchMetrics();
                        final created = response['created'] ?? 0;
                        final updated = response['updated'] ?? 0;
                        final total = created + updated;
                        showDialog(
                          context: context,
                          builder: (dCtx) => Dialog(
                            backgroundColor: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E0A08).withOpacity(0.97) : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                                boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8))],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                                      shape: BoxShape.circle,
                                      boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 20)],
                                    ),
                                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 32),
                                  ),
                                  const SizedBox(height: 20),
                                  Text('Import Complete!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.3)),
                                  const SizedBox(height: 8),
                                  Text(
                                    uploadMode == 'replace' ? 'Database replaced & re-imported' : 'Database updated successfully',
                                    style: TextStyle(fontSize: 13, color: subColor),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                                          ),
                                          child: Column(
                                            children: [
                                              Text('$created', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryGlow)),
                                              const SizedBox(height: 4),
                                              const Text('New', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryGlow)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          decoration: BoxDecoration(
                                            color: AppTheme.warning.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
                                          ),
                                          child: Column(
                                            children: [
                                              Text('$updated', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.warning)),
                                              const SizedBox(height: 4),
                                              const Text('Updated', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.warning)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                                          ),
                                          child: Column(
                                            children: [
                                              Text('$total', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primaryGlow)),
                                              const SizedBox(height: 4),
                                              const Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryGlow)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(dCtx),
                                    child: Container(
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                                      ),
                                      child: const Center(child: Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    } else {
                      setModalState(() {
                        uploading = false;
                        err = response['error'] ?? 'Failed to upload inventory.';
                      });
                    }
                  } catch (e) {
                    setModalState(() {
                      uploading = false;
                      err = 'Error picking/uploading file: $e';
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: uploadMode == 'upsert'
                          ? [AppTheme.primary, AppTheme.primaryLight]
                          : [AppTheme.danger, AppTheme.danger.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (uploadMode == 'upsert' ? AppTheme.primary : AppTheme.danger).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Center(
                    child: uploading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.file_upload_outlined, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                uploadMode == 'replace' ? 'Replace & Import Excel' : 'Select & Import Excel',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
