import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/auth_provider.dart';
import '../../data/services/auth_service.dart';

class AdminRegistrationScreen extends StatefulWidget {
  const AdminRegistrationScreen({super.key});
  @override
  State<AdminRegistrationScreen> createState() => _AdminRegistrationScreenState();
}

class _AdminRegistrationScreenState extends State<AdminRegistrationScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  
  bool _passVisible = false;
  bool _isLoading = false;
  String? _error;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _emailCtrl.dispose();
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _confirmPassCtrl.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      await AuthService().registerAdmin({
        'username': _userCtrl.text.trim(),
        'password': _passCtrl.text,
        'email': _emailCtrl.text.trim(),
        'first_name': _firstCtrl.text.trim(),
        'last_name': _lastCtrl.text.trim(),
      });

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Admin account created! Please log in.')),
      );
      context.go(RouteConstants.login);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF2D1010)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFCFBBAA)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final card = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.7);
    final border = isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2D1010) : const Color(0xFFCFBBAA),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: bg, begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.5, 1.0])),
        child: Stack(children: [
          Positioned(top: 0, right: -40, child: AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.06 + _pulse.value * 0.04))))),
          SafeArea(child: LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Form(key: _formKey, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 20),
                  // Header
                  Column(children: [
                    Text('INITIAL SETUP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 3.0)).animate().fadeIn(),
                    const SizedBox(height: 8),
                    Text('Create Admin Account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 8),
                    Text('This is a one-time setup process.', style: TextStyle(fontSize: 13, color: sub)).animate().fadeIn(delay: 200.ms),
                  ]),
                  
                  const SizedBox(height: 40),
                  
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.danger.withOpacity(0.3))),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: TextStyle(color: AppTheme.danger, fontSize: 13))),
                      ]),
                    ).animate().shake(),

                  _field(_userCtrl, 'Username', 'Choose admin username', Icons.person_outline, false, textColor, sub, card, border, validator: (v) => (v == null || v.isEmpty) ? 'Required' : null),
                  const SizedBox(height: 16),
                  _field(_emailCtrl, 'Email Address', 'Enter recovery email', Icons.email_outlined, false, textColor, sub, card, border, validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: _field(_firstCtrl, 'First Name', 'First Name', Icons.badge_outlined, false, textColor, sub, card, border)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_lastCtrl, 'Last Name', 'Last Name', Icons.badge_outlined, false, textColor, sub, card, border)),
                  ]),
                  const SizedBox(height: 16),
                  _field(_passCtrl, 'Password', 'Create a strong password', Icons.lock_outline_rounded, true, textColor, sub, card, border, validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null),
                  const SizedBox(height: 16),
                  _field(_confirmPassCtrl, 'Confirm Password', 'Re-enter your password', Icons.lock_outline_rounded, true, textColor, sub, card, border, validator: (v) => (v != _passCtrl.text) ? 'Passwords do not match' : null),
                  
                  const SizedBox(height: 40),
                  
                  SizedBox(width: double.infinity, height: 58,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: AppTheme.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.how_to_reg_rounded, size: 20), SizedBox(width: 10), Text('Complete Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 24),
                  TextButton(onPressed: () => context.go(RouteConstants.login), child: Text('Back to Login', style: TextStyle(color: sub, fontSize: 13))),
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
