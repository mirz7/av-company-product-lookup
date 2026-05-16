import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';

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
      // Check if this employee has been approved by admin
      final api = ApiService();
      final profile = await api.getProfile(forceRefresh: true);
      if (!mounted) return;
      if (profile != null) {
        if (profile['is_active'] == false) {
          Navigator.pushReplacementNamed(context, '/restricted');
        } else if (profile['is_approved'] == true) {
          Navigator.pushReplacementNamed(context, '/search');
        } else {
          Navigator.pushReplacementNamed(context, '/pending');
        }
      }
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
    final isDark = context.watch<ThemeProvider>().isDark;

    final bgColors = isDark
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF2A0D0D)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFE8D0C8)];

    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final subTextColor = isDark ? Colors.white54 : AppTheme.lightSubText;
    final cardColor = isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.6);
    final borderColor = isDark ? Colors.white.withOpacity(0.10) : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2A0D0D) : const Color(0xFFE8D0C8),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Decorative glowing orb — top right (clipped)
            Positioned(
              top: 0,
              right: -40,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.crimson.withOpacity(0.07 + _pulseController.value * 0.05),
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32),

                      // Logo + branding
                      Center(
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.crimson.withOpacity(0.4),
                                    blurRadius: 40,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.business, size: 100, color: AppTheme.crimson),
                                ),
                              ),
                            ).animate().scale(delay: 100.ms, duration: 500.ms, curve: Curves.easeOutBack),
                            const SizedBox(height: 20),
                            Text(
                              'AV & Company',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 2.5),
                            ).animate().fadeIn(delay: 200.ms),
                            const SizedBox(height: 6),
                            Text(
                              'WORKFORCE PORTAL',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subTextColor, letterSpacing: 3.0),
                            ).animate().fadeIn(delay: 300.ms),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Welcome text
                      Text(
                        'Welcome back',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor),
                      ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.05),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to access your workspace',
                        style: TextStyle(fontSize: 13, color: subTextColor),
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
                                Expanded(child: Text(auth.errorMessage!, style: const TextStyle(color: AppTheme.crimsonGlow, fontSize: 13))),
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
                        isDark: isDark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ).animate().fadeIn(delay: 450.ms).slideX(begin: -0.05),

                      const SizedBox(height: 16),

                      // Password field
                      _buildPasswordField(
                        isDark: isDark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                        subTextColor: subTextColor,
                      ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.05),

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
                                    color: _rememberMe ? AppTheme.crimson : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: _rememberMe ? AppTheme.crimson : subTextColor.withOpacity(0.4), width: 1.5),
                                  ),
                                  child: _rememberMe ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
                                ),
                                const SizedBox(width: 8),
                                Text('Remember me', style: TextStyle(fontSize: 13, color: subTextColor)),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(fontSize: 13, color: subTextColor, decoration: TextDecoration.underline, decorationColor: subTextColor.withOpacity(0.3)),
                            ),
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
                              backgroundColor: AppTheme.crimson,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppTheme.crimson.withOpacity(0.5),
                              elevation: 16,
                              shadowColor: AppTheme.crimson.withOpacity(0.6),
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

                      const SizedBox(height: 32),


                      // Register link
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/register'),
                          child: RichText(
                            text: TextSpan(
                              text: "Don't have an account? ",
                              style: TextStyle(color: subTextColor, fontSize: 13),
                              children: const [
                                TextSpan(
                                  text: 'Register Now',
                                  style: TextStyle(color: AppTheme.crimsonGlow, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
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
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subTextColor, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              validator: validator,
              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 14),
                prefixIcon: Icon(icon, color: AppTheme.crimson, size: 20),
                filled: true,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.crimson, width: 1.5)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                errorStyle: const TextStyle(color: AppTheme.crimsonGlow, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subTextColor, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextFormField(
              controller: _passwordController,
              obscureText: !_passwordVisible,
              validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
              style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                hintStyle: TextStyle(color: subTextColor.withOpacity(0.5), fontSize: 14),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.crimson, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: isDark ? Colors.white70 : subTextColor, size: 20),
                  onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                ),
                filled: true,
                fillColor: cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.crimson, width: 1.5)),
                errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
                focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
                errorStyle: const TextStyle(color: AppTheme.crimsonGlow, fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
