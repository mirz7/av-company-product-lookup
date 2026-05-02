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
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'Sales';
  final _roles = ['Sales', 'Manager', 'Admin'];

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || username.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(name, username, _selectedRole, password, phone, email);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please login.'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9E2016), Color(0xFF410000)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20)),
                      ],
                    ),
                    child: Image.asset('assets/images/logo.png', width: 64, height: 64, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.business, size: 64)),
                  ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 24),
                  const Text(
                    'CREATE ACCOUNT',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2),
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (authProvider.errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(authProvider.errorMessage!, style: const TextStyle(color: Color(0xFFFFB4A9), fontSize: 14)),
                          ).animate().fadeIn(),
                        _buildTextField('Full Name', Icons.person_outline, _nameController, false),
                        const SizedBox(height: 16),
                        _buildTextField('Username', Icons.alternate_email, _usernameController, false),
                        const SizedBox(height: 16),
                        _buildTextField('Email', Icons.email_outlined, _emailController, false),
                        const SizedBox(height: 16),
                        _buildTextField('Phone Number', Icons.phone_outlined, _phoneController, false),
                        const SizedBox(height: 16),
                        _buildDropdownField(),
                        const SizedBox(height: 16),
                        _buildTextField('Password', Icons.lock_outline, _passwordController, true),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF9E2016),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: authProvider.isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF9E2016), strokeWidth: 2))
                              : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ).animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Already have an account? Login', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500)),
                        ).animate().fadeIn(delay: 700.ms),
                      ],
                    ),
                  ).animate().slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOutQuad).fadeIn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, bool isPassword) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.1),
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Role',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(Icons.badge_outlined, color: Colors.white.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.1),
      ),
      dropdownColor: const Color(0xFF9E2016),
      style: const TextStyle(color: Colors.white),
      items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
      onChanged: (value) {
        setState(() {
          if (value != null) _selectedRole = value;
        });
      },
    );
  }
}
