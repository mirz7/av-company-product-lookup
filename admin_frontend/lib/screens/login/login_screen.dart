import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _passVisible = false;
  bool _rememberMe = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() { _userCtrl.dispose(); _passCtrl.dispose(); _pulse.dispose(); super.dispose(); }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkSetup();
  }

  Future<void> _checkSetup() async {
    try {
      final needed = await AuthService().isAdminSetupNeeded();
      if (needed && mounted) {
        context.go(RouteConstants.register);
      }
    } catch (e) {
      debugPrint('Setup check failed: $e');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ok = await auth.login(_userCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) context.go(RouteConstants.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF2D1010)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFCFBBAA)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final card = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7);
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2D1010) : const Color(0xFFCFBBAA),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: bg, begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.5, 1.0])),
        child: Stack(children: [
          Positioned(top: 0, right: -40, child: AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.06 + _pulse.value * 0.04))))),
          Positioned(bottom: -60, left: -60, child: AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.accent.withOpacity(0.04 + _pulse.value * 0.03))))),
          SafeArea(child: LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Form(key: _formKey, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 10),
                  // Top Branding
                  Column(children: [
                    Container(
                      height: 100, width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 12))],
                      ),
                      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.asset('assets/images/logo.png', fit: BoxFit.cover, errorBuilder: (c, e, s) => const Center(child: Text('AV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32))))),
                    ).animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 20),
                    Text('AV ADMIN PORTAL', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 6),
                    Text('SECURE ACCESS HUB', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sub, letterSpacing: 3.0)).animate().fadeIn(delay: 300.ms),
                  ]),
                  
                  const SizedBox(height: 48),
                  
                  // Welcome & Description (Centered)
                  Column(children: [
                    Text('Welcome back', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor)).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                    const SizedBox(height: 6),
                    Text('Sign in to access your admin workspace', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: sub)).animate().fadeIn(delay: 400.ms),
                  ]),

                  const SizedBox(height: 32),
                  
                  // Error banner
                  Consumer<AuthProvider>(builder: (_, auth, __) {
                    if (auth.errorMessage == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3))),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(auth.errorMessage!, style: TextStyle(color: AppTheme.danger, fontSize: 13))),
                      ]),
                    ).animate().fadeIn().shake();
                  }),

                  // Fields
                  _field(_userCtrl, 'Admin Username', 'Enter your username', Icons.alternate_email_rounded, false, textColor, sub, card, border,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  _field(_passCtrl, 'Password', 'Enter your password', Icons.lock_outline_rounded, true, textColor, sub, card, border,
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                  
                  const SizedBox(height: 16),
                  
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    GestureDetector(onTap: () => setState(() => _rememberMe = !_rememberMe), child: Row(children: [
                      AnimatedContainer(duration: 200.ms, width: 20, height: 20,
                        decoration: BoxDecoration(color: _rememberMe ? AppTheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(6), border: Border.all(color: _rememberMe ? AppTheme.primary : sub.withValues(alpha: 0.4), width: 1.5)),
                        child: _rememberMe ? const Icon(Icons.check, color: Colors.white, size: 13) : null),
                      const SizedBox(width: 8),
                      Text('Remember me', style: TextStyle(fontSize: 13, color: sub)),
                    ])),
                    GestureDetector(
                      onTap: () => context.push(RouteConstants.forgotPassword),
                      child: Text('Forgot password?', style: TextStyle(fontSize: 13, color: sub, decoration: TextDecoration.underline, decorationColor: sub.withValues(alpha: 0.3))),
                    ),
                  ]).animate().fadeIn(delay: 550.ms),
                  
                  const SizedBox(height: 32),
                  
                  Consumer<AuthProvider>(builder: (_, auth, __) => SizedBox(width: double.infinity, height: 58,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: AppTheme.primary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.login_rounded, size: 20), SizedBox(width: 10), Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
                    ),
                  )).animate().fadeIn(delay: 600.ms),
                  
                  const SizedBox(height: 32),
                  Center(child: Text('Secure Internal Access Only © 2025', style: TextStyle(fontSize: 11, color: sub.withValues(alpha: 0.4)))).animate().fadeIn(delay: 700.ms),
                  const SizedBox(height: 20),
                ])),
              ),
            ),
          ))),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, IconData icon, bool isPassword, Color textColor, Color sub, Color card, Color border, {String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sub, letterSpacing: 0.3)),
      const SizedBox(height: 8),
      ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: TextFormField(
        controller: ctrl,
        obscureText: isPassword ? !_passVisible : false,
        validator: validator,
        style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
        onFieldSubmitted: (_) { if (isPassword) _login(); },
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: sub.withOpacity(0.5), fontSize: 14),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          suffixIcon: isPassword ? IconButton(icon: Icon(_passVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: sub, size: 20), onPressed: () => setState(() => _passVisible = !_passVisible)) : null,
          filled: true, fillColor: card,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.danger)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.danger, width: 1.5)),
          errorStyle: TextStyle(color: AppTheme.danger, fontSize: 11),
        ),
      ))),
    ]);
  }
}
