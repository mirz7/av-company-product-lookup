import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
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
    _emailCtrl = TextEditingController();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['email'] != null && _emailCtrl.text.isEmpty) {
      _emailCtrl.text = args['email'];
    }
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
          child: Form(key: _formKey, child: Column(children: [
            const Icon(Icons.published_with_changes_rounded, size: 70, color: AppTheme.crimson).animate().rotate(),
            const SizedBox(height: 24),
            Text('RESET PASSWORD', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)),
            const SizedBox(height: 32),
            
            if (_error != null)
              Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(_error!, style: const TextStyle(color: Colors.redAccent))),

            _field(_emailCtrl, 'Email', 'Enter your email address', Icons.email_outlined, textColor, sub, card, border),
            const SizedBox(height: 16),
            _field(_otpCtrl, 'OTP', 'Enter 6-digit OTP from email', Icons.pin_outlined, textColor, sub, card, border),
            const SizedBox(height: 16),
            _field(_passCtrl, 'New Password', 'Enter your new password', Icons.lock_outline, textColor, sub, card, border, isPass: true),
            
            const SizedBox(height: 40),
            SizedBox(width: double.infinity, height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _reset,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Reset Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/login')), child: Text('Back to Login', style: TextStyle(color: sub))),
          ])),
        ))),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, IconData icon, Color textColor, Color sub, Color card, Color border, {bool isPass = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sub)),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: ctrl, obscureText: isPass,
            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
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
