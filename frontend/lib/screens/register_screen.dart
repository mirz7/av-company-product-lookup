import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'Sales';
  final _roles = ['Sales', 'Manager', 'Admin', 'Warehouse', 'Accounts'];

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  int _currentStep = 0; // 0 = personal info, 1 = credentials

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      _nameController.text.trim(),
      _usernameController.text.trim(),
      _selectedRole,
      _passwordController.text,
      _phoneController.text.trim(),
      _emailController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Account created! Please login.', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          backgroundColor: const Color(0xFF2D7A4F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    }
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
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button + header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.15)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Create Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                            Text('Join the AV & Company team', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
                          ],
                        ),
                      ),
                      // Logo
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(Icons.business, size: 36, color: Color(0xFF9E2016)),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms),

                  const SizedBox(height: 32),

                  // Step indicator
                  Row(
                    children: [
                      _buildStepDot(0, 'Personal Info'),
                      Expanded(child: Container(height: 1, color: _currentStep >= 1 ? const Color(0xFF9E2016) : Colors.white.withOpacity(0.2))),
                      _buildStepDot(1, 'Credentials'),
                    ],
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 32),

                  // STEP 1: Personal Info
                  if (_currentStep == 0) ...[
                    _buildSectionLabel('PERSONAL INFORMATION'),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _nameController,
                      label: 'Full Name',
                      hint: 'e.g. Ahmed Khan',
                      icon: Icons.person_outline_rounded,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                    ).animate().fadeIn(delay: 250.ms).slideX(begin: -0.05),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'you@company.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Enter a valid email';
                        return null;
                      },
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.05),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: '+91 98765 43210',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                    ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.05),
                    const SizedBox(height: 16),
                    _buildRoleDropdown().animate().fadeIn(delay: 400.ms).slideX(begin: -0.05),
                    const SizedBox(height: 32),
                    _buildNextButton().animate().fadeIn(delay: 450.ms),
                  ],

                  // STEP 2: Credentials
                  if (_currentStep == 1) ...[
                    _buildSectionLabel('ACCOUNT CREDENTIALS'),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _usernameController,
                      label: 'Username',
                      hint: 'e.g. ahmed.khan',
                      icon: Icons.alternate_email_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Username is required';
                        if (v.contains(' ')) return 'Username cannot contain spaces';
                        if (v.length < 3) return 'Minimum 3 characters';
                        return null;
                      },
                    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Min. 8 characters',
                      visible: _passwordVisible,
                      onToggle: () => setState(() => _passwordVisible = !_passwordVisible),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 8) return 'Minimum 8 characters required';
                        return null;
                      },
                    ).animate().fadeIn(delay: 250.ms).slideX(begin: 0.05),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      visible: _confirmPasswordVisible,
                      onToggle: () => setState(() => _confirmPasswordVisible = !_confirmPasswordVisible),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your password';
                        if (v != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05),
                    const SizedBox(height: 8),
                    _buildPasswordStrengthBar().animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: 32),
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return Column(
                          children: [
                            if (authProvider.errorMessage != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(authProvider.errorMessage!, style: const TextStyle(color: Color(0xFFFFB4A9), fontSize: 13))),
                                  ],
                                ),
                              ).animate().fadeIn().shake(),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9E2016),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(0xFF9E2016).withOpacity(0.5),
                                  elevation: 12,
                                  shadowColor: const Color(0xFF9E2016).withOpacity(0.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.how_to_reg_rounded, size: 20),
                                          SizedBox(width: 10),
                                          Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () => setState(() => _currentStep = 0),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        );
                      },
                    ).animate().fadeIn(delay: 350.ms),
                  ],

                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                          children: const [
                            TextSpan(text: 'Sign In', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        AnimatedContainer(
          duration: 300.ms,
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF9E2016) : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? const Color(0xFF9E2016) : Colors.white.withOpacity(0.2), width: 2),
          ),
          child: Center(
            child: isActive
                ? (_currentStep > step ? const Icon(Icons.check, color: Colors.white, size: 16) : Text('${step + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)))
                : Text('${step + 1}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isActive ? Colors.white70 : Colors.white30, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFF9E2016), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5), letterSpacing: 1.5)),
      ],
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF9E2016), width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                ),
                errorStyle: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 11),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
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
              obscureText: !visible,
              validator: validator,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14),
                prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF9E2016), size: 20),
                suffixIcon: IconButton(
                  icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white38, size: 20),
                  onPressed: onToggle,
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

  Widget _buildPasswordStrengthBar() {
    final password = _passwordController.text;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    final labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];
    final colors = [Colors.transparent, Colors.red, Colors.orange, Colors.yellow, Colors.green];

    if (password.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (i) => Expanded(
            child: AnimatedContainer(
              duration: 300.ms,
              margin: const EdgeInsets.only(right: 4),
              height: 3,
              decoration: BoxDecoration(
                color: i < strength ? colors[strength] : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )),
        ),
        const SizedBox(height: 4),
        Text('Password strength: ${labels[strength]}', style: TextStyle(fontSize: 11, color: colors[strength], fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Company Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70, letterSpacing: 0.3)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DropdownButtonFormField<String>(
              value: _selectedRole,
              dropdownColor: const Color(0xFF1C0A0A),
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              iconEnabledColor: const Color(0xFF9E2016),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF9E2016), size: 20),
                filled: true,
                fillColor: Colors.white.withOpacity(0.07),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF9E2016), width: 1.5)),
              ),
              items: _roles.map((role) => DropdownMenuItem(
                value: role,
                child: Text(role, style: const TextStyle(color: Colors.white)),
              )).toList(),
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // Validate only step 1 fields
          final nameValid = _nameController.text.trim().isNotEmpty;
          final emailValid = RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text.trim());
          final phoneValid = _phoneController.text.trim().isNotEmpty;

          if (!nameValid || !emailValid || !phoneValid) {
            _formKey.currentState!.validate();
            return;
          }
          setState(() => _currentStep = 1);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9E2016),
          foregroundColor: Colors.white,
          elevation: 12,
          shadowColor: const Color(0xFF9E2016).withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
