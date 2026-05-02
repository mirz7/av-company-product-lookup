import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _rememberMe = false;
  bool _shakeCard = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, '/search');
    } else {
      _triggerShake();
    }
  }

  void _triggerShake() {
    setState(() => _shakeCard = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _shakeCard = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D0D), Color(0xFF1A0505), Color(0xFF9E2016)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative glowing orbs
            Positioned(
              top: -80,
              right: -60,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF9E2016).withOpacity(0.08 + _pulseController.value * 0.06),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF9E2016).withOpacity(0.05 + _pulseController.value * 0.04),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // Logo + branding
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF9E2016).withOpacity(0.4),
                                    blurRadius: 40,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 72,
                                height: 72,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => const Icon(Icons.business, size: 72, color: Color(0xFF9E2016)),
                              ),
                            ).animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.easeOutBack),
                            const SizedBox(height: 20),
                            const Text(
                              'AV & COMPANY',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.5),
                            ).animate().fadeIn(delay: 200.ms),
                            const SizedBox(height: 6),
                            Text(
                              'WORKFORCE PORTAL',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.45), letterSpacing: 3.0),
                            ).animate().fadeIn(delay: 300.ms),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Welcome text
                      const Text(
                        'Welcome back',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                      ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.05),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to access your workspace',
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.45)),
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 28),

                      // Error banner
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          if (auth.errorMessage == null) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                const SizedBox(width: 10),
                                Expanded(child: Text(auth.errorMessage!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13))),
                              ],
                            ),
                          ).animate().fadeIn().shake();
                        },
                      ),

                      // Username field
                      _buildField(
                        controller: _usernameController,
                        label: 'Username',
                        hint: 'Enter your username',
                        icon: Icons.alternate_email_rounded,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
                      ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.05),

                      const SizedBox(height: 16),

                      // Password field
                      _buildPasswordField().animate().fadeIn(delay: 500.ms).slideX(begin: -0.05),

                      const SizedBox(height: 16),

                      // Remember me + Forgot
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: 200.ms,
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: _rememberMe ? const Color(0xFF9E2016) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _rememberMe ? const Color(0xFF9E2016) : Colors.white.withOpacity(0.3), width: 1.5),
                                  ),
                                  child: _rememberMe ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
                                ),
                                const SizedBox(width: 8),
                                Text('Remember me', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.6))),
                              ],
                            ),
                          ),
                          Text(
                            'Forgot password?',
                            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.55), decoration: TextDecoration.underline, decorationColor: Colors.white30),
                          ),
                        ],
                      ).animate().fadeIn(delay: 550.ms),

                      const SizedBox(height: 32),

                      // Login button
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) => SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9E2016),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF9E2016).withOpacity(0.5),
                              elevation: 16,
                              shadowColor: const Color(0xFF9E2016).withOpacity(0.6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.login_rounded, size: 20),
                                      SizedBox(width: 10),
                                      Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                    ],
                                  ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms),

                      const SizedBox(height: 20),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('OR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.3), letterSpacing: 2)),
                          ),
                          Expanded(child: Divider(color: Colors.white.withOpacity(0.1), thickness: 1)),
                        ],
                      ).animate().fadeIn(delay: 650.ms),

                      const SizedBox(height: 20),

                      // Biometrics button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.fingerprint_rounded, size: 22),
                          label: const Text('Sign in with Biometrics', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.5),
                            backgroundColor: Colors.white.withOpacity(0.04),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ).animate().fadeIn(delay: 700.ms),

                      const SizedBox(height: 32),

                      // Register link
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
                              children: const [
                                TextSpan(
                                  text: 'Register Now',
                                  style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 750.ms),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                prefixIcon: Icon(icon, color: const Color(0xFF9E2016), size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF9E2016), width: 1.5)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextFormField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF9E2016), size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white38, size: 20),
                  onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF9E2016), width: 1.5)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
