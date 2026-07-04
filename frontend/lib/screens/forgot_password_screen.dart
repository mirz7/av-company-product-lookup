import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

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
  int _step = 0; // 0 = Email, 1 = OTP, 2 = Password
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
      await ApiService().forgotPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An OTP has been sent to your email.'))
      );
      setState(() => _step = 1);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueToPassword() async {
    if (_otpCtrl.text.trim().length < 6) {
      setState(() => _error = 'Please enter a 6-digit OTP');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ApiService().verifyOtp(_emailCtrl.text.trim(), _otpCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _error = null;
        _step = 2;
      });
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
      final ok = await ApiService().resetPassword(_emailCtrl.text.trim(), _otpCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successful!')));
        Navigator.popUntil(context, ModalRoute.withName('/login'));
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
    
    final bgColors = isDark
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF2A0D0D)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFE8D0C8)];

    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final card = isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.6);
    final border = isDark ? Colors.white.withOpacity(0.10) : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2A0D0D) : const Color(0xFFE8D0C8),
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(colors: bgColors, begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(child: SingleChildScrollView(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(key: _formKey, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(height: _step > 0 ? 20 : 60),
            Icon(_step == 0 ? Icons.lock_reset_rounded : (_step == 1 ? Icons.pin_outlined : Icons.published_with_changes_rounded), size: 80, color: AppTheme.crimson).animate().scale(),
            const SizedBox(height: 24),
            Text(_step == 0 ? 'FORGOT PASSWORD' : (_step == 1 ? 'VERIFY OTP' : 'RESET PASSWORD'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(_step == 0 ? 'Enter your email to receive recovery instructions.' : (_step == 1 ? 'Enter the 6-digit code sent to your email.' : 'Securely create a new password.'), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: sub)),
            const SizedBox(height: 40),
            
            if (_error != null)
              Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),

            if (_step == 0) ...[
              _field(_emailCtrl, 'Email Address', 'Enter your registered email', Icons.email_outlined, textColor, sub, card, border),
            ] else if (_step == 1) ...[
              _field(_otpCtrl, 'OTP', 'Enter 6-digit OTP', Icons.pin_outlined, textColor, sub, card, border),
            ] else if (_step == 2) ...[
              _field(_passCtrl, 'New Password', 'Enter your new password', Icons.lock_outline, textColor, sub, card, border, isPass: true),
              const SizedBox(height: 16),
              _field(_confirmPassCtrl, 'Confirm Password', 'Re-enter your new password', Icons.lock_outline, textColor, sub, card, border, isPass: true),
            ],
            
            const SizedBox(height: 32),
            
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : (_step == 0 ? _sendOtp : (_step == 1 ? _continueToPassword : _verifyAndReset)),
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withOpacity(0.2),
                child: Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withOpacity(_isLoading ? 0.5 : 1.0),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _isLoading ? null : [BoxShadow(color: AppTheme.crimson.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                      : Text(_step == 0 ? 'Send OTP' : (_step == 1 ? 'Verify OTP' : 'Reset Password'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (_step == 1) {
                    setState(() {
                      _step = 0;
                      _error = null;
                      _otpCtrl.clear();
                    });
                  } else if (_step == 2) {
                    setState(() {
                      _step = 1;
                      _error = null;
                      _passCtrl.clear();
                      _confirmPassCtrl.clear();
                    });
                  } else {
                    Navigator.pop(context);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                splashColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(_step == 0 ? 'Back to Login' : 'Back', style: TextStyle(color: sub)),
                ),
              ),
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
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: ctrl,
            obscureText: isPass,
            readOnly: readOnly,
            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Required';
              if (!isPass && label.contains('Email') && !v.contains('@')) return 'Invalid email';
              return null;
            },
            decoration: InputDecoration(
              hintText: hint, hintStyle: TextStyle(color: sub.withOpacity(0.5)),
              prefixIcon: Icon(icon, color: AppTheme.crimson, size: 20),
              filled: true, fillColor: card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.crimson, width: 1.5)),
            ),
          ),
        ),
      ),
    ]);
  }
}
