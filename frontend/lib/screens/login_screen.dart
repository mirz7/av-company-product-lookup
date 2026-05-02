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

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _shakeCard = false;

  final String logoUrl = "https://lh3.googleusercontent.com/aida/ADBb0uh8CTvSHI_1-5xL4Ew7J-ycSYCb46Rbl2EAWU3AhWrvKJaAa4WwqVqZRdcMcnwBwmOQ_qdNfzXwX0T04Sx2eL-aNI50UTkBZL4pjn6yP9m0eN-nJm-aNtOXefV_VXmd3yPyDOCov9N3siIDOqiYG3A8o8leP_9RDe6ZP_SVF95LPAFV12p2K_hfw_16HkNnsrgoP5hvP2STLjtq8le4Hnj-RXTVr0bZYYfuXVULFQANlsDDyhwIFHTKcsQGm04TGMYTBnj-QcCBLg";

  Future<void> _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _triggerShake();
      return;
    }

    final success = await authProvider.login(username, password);

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/search');
    } else {
      _triggerShake();
    }
  }

  void _triggerShake() {
    setState(() => _shakeCard = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _shakeCard = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget loginCard = ClipRRect(
      borderRadius: BorderRadius.circular(32.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(32.0),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 50,
                offset: const Offset(0, 20),
              )
            ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    )
                  ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/logo.png', width: 80, height: 80, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.business, size: 80)),
                ),
              ),
              const Text(
                'AV & COMPANY',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'WORKFORCE PORTAL',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.7),
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 32),
              
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  if (authProvider.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        authProvider.errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                      ).animate().fade().slideY(begin: -0.2),
                    );
                  }
                  return const SizedBox.shrink();
                }
              ),

              _buildTextField(
                controller: _usernameController,
                label: 'Employee Username',
                icon: Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                label: 'Secure Password',
                icon: Icons.lock,
                isPassword: true,
              ),
              
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: false,
                          onChanged: (v) {},
                          fillColor: MaterialStateProperty.all(Colors.white.withOpacity(0.1)),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Remember me', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7))),
                    ],
                  ),
                  Text('Forgot Access?', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7), decoration: TextDecoration.underline)),
                ],
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9E2016),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFF9E2016).withOpacity(0.4),
                      ),
                      child: authProvider.isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Login to Workspace', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (_shakeCard) {
      loginCard = loginCard.animate(onPlay: (controller) => controller.repeat()).shake(hz: 8, curve: Curves.easeInOutCubic).then(delay: 500.ms);
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9E2016), Color(0xFF2E3131)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  loginCard.animate().fade(duration: 800.ms).slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOutCubic),
                  const SizedBox(height: 32),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.fingerprint, color: Colors.white),
                    label: const Text('Sign in with Biometrics', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ).animate().fade(delay: 400.ms),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text(
                      "Don't have an account? Register",
                      style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                    ),
                  ).animate().fade(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.8)),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.5)),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white.withOpacity(0.5)),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: const UnderlineInputBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              borderSide: BorderSide.none,
            ),
            focusedBorder: const UnderlineInputBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFF9E2016), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
