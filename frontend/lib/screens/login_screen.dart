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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _shakeCard = false;

  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

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
    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFF0F172A), const Color(0xFF1E293B), _gradientController.value)!,
                      Color.lerp(const Color(0xFF1E293B), const Color(0xFF0F172A), _gradientController.value)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  Widget loginCard = Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo / Header
                        Hero(
                          tag: 'app_logo',
                          child: Icon(
                            Icons.storefront_rounded,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Staff Portal',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Error Message
                        if (authProvider.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              authProvider.errorMessage!,
                              style: const TextStyle(color: Colors.redAccent),
                            ).animate().fade().slideY(begin: -0.2),
                          ),

                        // Username Field
                        _buildTextField(
                          controller: _usernameController,
                          label: 'Username',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              elevation: 5,
                            ),
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (_shakeCard) {
                    loginCard = loginCard.animate(onPlay: (controller) => controller.repeat()).shake(hz: 8, curve: Curves.easeInOutCubic).then(delay: 500.ms);
                  }

                  return loginCard.animate().fade(duration: 800.ms).slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOutCubic);
                },
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
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey.shade400,
                ),
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
              )
            : null,
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16.0),
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
