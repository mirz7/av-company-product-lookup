import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/route_constants.dart';
import '../../data/services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  bool _isOtpSent = false;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final email = _emailCtrl.text.trim();
      await AuthService().forgotPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An OTP has been sent to your email.'))
      );
      setState(() => _isOtpSent = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAndReset() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_passCtrl.text != _confirmPassCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

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
          child: Form(key: _formKey, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(height: _isOtpSent ? 20 : 60),
            Icon(_isOtpSent ? Icons.published_with_changes_rounded : Icons.lock_reset_rounded, size: 80, color: AppTheme.primary).animate().scale(),
            const SizedBox(height: 24),
            Text(_isOtpSent ? 'RESET PASSWORD' : 'FORGOT PASSWORD', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(_isOtpSent ? 'Enter the OTP sent to your email and your new password.' : 'Enter your email to receive recovery instructions.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: sub)),
            const SizedBox(height: 40),
            
            if (_error != null)
              Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),

            if (!_isOtpSent) ...[
              _field(_emailCtrl, 'Email Address', 'Enter your registered email', Icons.email_outlined, textColor, sub, card, border),
            ] else ...[
              _field(_emailCtrl, 'Email Address', 'Enter your registered email', Icons.email_outlined, textColor, sub, card, border, readOnly: true),
              const SizedBox(height: 16),
              _field(_otpCtrl, 'OTP', 'Enter 6-digit OTP', Icons.pin_outlined, textColor, sub, card, border),
              const SizedBox(height: 16),
              _field(_passCtrl, 'New Password', 'Enter your new password', Icons.lock_outline, textColor, sub, card, border, isPass: true),
              const SizedBox(height: 16),
              _field(_confirmPassCtrl, 'Confirm Password', 'Re-enter your new password', Icons.lock_outline, textColor, sub, card, border, isPass: true),
            ],
            
            const SizedBox(height: 32),
            
            SizedBox(width: double.infinity, height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : (_isOtpSent ? _verifyAndReset : _sendOtp),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(_isOtpSent ? 'Verify & Reset' : 'Send OTP', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                if (_isOtpSent) {
                  setState(() {
                    _isOtpSent = false;
                    _error = null;
                    _otpCtrl.clear();
                    _passCtrl.clear();
                    _confirmPassCtrl.clear();
                  });
                } else {
                  context.go(RouteConstants.login);
                }
              }, 
              child: Text(_isOtpSent ? 'Back to Email' : 'Back to Login', style: TextStyle(color: sub))
            ),
          ])),
        ))),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, IconData icon, Color textColor, Color sub, Color card, Color border, {bool isPass = false, bool readOnly = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sub)),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        obscureText: isPass,
        readOnly: readOnly,
        style: TextStyle(color: textColor),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Required';
          if (!isPass && label.contains('Email') && !v.contains('@')) return 'Invalid email';
          return null;
        },
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: sub.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
          filled: true, fillColor: card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
        ),
      ),
    ]);
  }
}
