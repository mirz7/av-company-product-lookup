import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/route_constants.dart';
import '../../data/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  const ResetPasswordScreen({super.key, this.initialEmail});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailCtrl;
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }
  
  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final ok = await AuthService().resetPassword(_emailCtrl.text.trim(), _otpCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successful!')));
        context.go(RouteConstants.login);
      } else {
        setState(() => _error = 'Invalid OTP or email.');
      }
    } catch (_) {
      setState(() => _error = 'An error occurred.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final card = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.7);
    final border = isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2D1010) : const Color(0xFFCFBBAA),
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(colors: isDark ? [AppTheme.darkBg1, AppTheme.darkBg2] : [AppTheme.lightBg1, AppTheme.lightBg2], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(child: SingleChildScrollView(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(key: _formKey, child: Column(children: [
            const Icon(Icons.published_with_changes_rounded, size: 70, color: AppTheme.primary).animate().rotate(),
            const SizedBox(height: 24),
            Text('RESET PASSWORD', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)),
            const SizedBox(height: 32),
            
            if (_error != null)
              Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(_error!, style: const TextStyle(color: AppTheme.danger))),

            _field(_emailCtrl, 'Email', 'Enter your email address', Icons.email_outlined, textColor, sub, card, border),
            const SizedBox(height: 16),
            _field(_otpCtrl, 'OTP', 'Enter 6-digit OTP from email', Icons.pin_outlined, textColor, sub, card, border),
            const SizedBox(height: 16),
            _field(_passCtrl, 'New Password', 'Enter your new password', Icons.lock_outline, textColor, sub, card, border, isPass: true),
            
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _reset,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: () => context.go(RouteConstants.login), child: Text('Back to Login', style: TextStyle(color: sub))),
          ])),
        ))),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, IconData icon, Color textColor, Color sub, Color card, Color border, {bool isPass = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sub)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl, obscureText: isPass,
        style: TextStyle(color: textColor),
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: sub.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          filled: true, fillColor: card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
        ),
      ),
    ]);
  }
}
