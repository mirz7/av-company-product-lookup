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
    _emailCtrl.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
      Navigator.pushNamed(context, '/reset-password', arguments: {'email': email});
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
        child: SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(key: _formKey, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_reset_rounded, size: 80, color: AppTheme.crimson).animate().scale(),
            const SizedBox(height: 24),
            Text('FORGOT PASSWORD', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text('Enter your email to receive recovery instructions.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: sub)),
            const SizedBox(height: 40),
            
            if (_error != null)
              Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),

            _field(_emailCtrl, 'Email Address', 'Enter your registered email', Icons.email_outlined, textColor, sub, card, border),
            const SizedBox(height: 32),
            
            SizedBox(width: double.infinity, height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Back to Login', style: TextStyle(color: sub))),
            TextButton(onPressed: () => Navigator.pushNamed(context, '/reset-password'), child: const Text('Already have a token?', style: TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.w600))),
          ])),
        )),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, String hint, IconData icon, Color textColor, Color sub, Color card, Color border) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sub)),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: ctrl,
            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
            validator: (v) => (v == null || !v.contains('@')) ? 'Invalid email' : null,
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
