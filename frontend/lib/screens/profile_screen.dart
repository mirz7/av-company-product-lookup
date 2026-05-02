import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final data = await _apiService.getProfile();
    setState(() {
      _profileData = data;
      _isLoading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    await _apiService.logout();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Future<void> _editPhoneNumber() async {
    final controller = TextEditingController(text: _profileData?['phone_number'] ?? '');
    final newPhone = await showDialog<String>(
      context: context,
      builder: (context) => _buildDarkDialog(
        title: 'Edit Phone Number',
        icon: Icons.phone_outlined,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: _darkInputDecoration('Phone Number'),
        ),
        onSave: () => Navigator.pop(context, controller.text),
        onCancel: () => Navigator.pop(context),
      ),
    );
    if (newPhone != null) {
      setState(() => _isLoading = true);
      await _apiService.updateProfile({'phone_number': newPhone});
      await _fetchProfile();
    }
  }

  Future<void> _editProfilePhoto() async {
    final controller = TextEditingController(text: _profileData?['profile_photo'] ?? '');
    final newUrl = await showDialog<String>(
      context: context,
      builder: (context) => _buildDarkDialog(
        title: 'Edit Profile Photo',
        icon: Icons.image_outlined,
        child: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: _darkInputDecoration('Image URL'),
        ),
        onSave: () => Navigator.pop(context, controller.text),
        onCancel: () => Navigator.pop(context),
      ),
    );
    if (newUrl != null) {
      setState(() => _isLoading = true);
      await _apiService.updateProfile({'profile_photo': newUrl});
      await _fetchProfile();
    }
  }

  InputDecoration _darkInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.07),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF9E2016), width: 1.5)),
    );
  }

  Widget _buildDarkDialog({
    required String title,
    required IconData icon,
    required Widget child,
    required VoidCallback onSave,
    required VoidCallback onCancel,
  }) {
    return Dialog(
      backgroundColor: const Color(0xFF1A0505),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF9E2016), size: 20),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            child,
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9E2016),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E2E), Color(0xFF2D1010), Color(0xFFB22A1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF9E2016)))
              : Column(
                  children: [
                    // Top App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                                child: Image.asset('assets/images/logo.png', height: 26, errorBuilder: (c, e, s) => const Icon(Icons.business, size: 26)),
                              ),
                              const SizedBox(width: 12),
                              const Text('AV & COMPANY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9E2016).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF9E2016).withOpacity(0.4)),
                            ),
                            child: const Text('PROFILE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B), letterSpacing: 1.5)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _fetchProfile,
                        color: const Color(0xFF9E2016),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          child: Column(
                            children: [
                              // Profile Header Card
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                                    ),
                                    child: Column(
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              width: 96,
                                              height: 96,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: const Color(0xFF9E2016), width: 3),
                                                boxShadow: [BoxShadow(color: const Color(0xFF9E2016).withOpacity(0.4), blurRadius: 20)],
                                                image: DecorationImage(
                                                  image: NetworkImage(_profileData?['profile_photo'] ?? 'https://ui-avatars.com/api/?name=User&background=9E2016&color=fff'),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: GestureDetector(
                                                onTap: _editProfilePhoto,
                                                child: Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF9E2016),
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: const Color(0xFF0D0D0D), width: 2),
                                                  ),
                                                  child: const Icon(Icons.edit, color: Colors.white, size: 14),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '${_profileData?['first_name'] ?? ''} ${_profileData?['last_name'] ?? ''}'.trim().isEmpty
                                              ? (_profileData?['username']?.toString() ?? 'User')
                                              : '${_profileData?['first_name'] ?? ''} ${_profileData?['last_name'] ?? ''}'.trim(),
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF9E2016).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: const Color(0xFF9E2016).withOpacity(0.4)),
                                              ),
                                              child: Text((_profileData?['role'] ?? 'STAFF').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B), letterSpacing: 1)),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.07),
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: Colors.white.withOpacity(0.15)),
                                              ),
                                              child: Text('@${_profileData?['username'] ?? ''}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),

                              const SizedBox(height: 16),

                              // Stats Row
                              Row(
                                children: [
                                  Expanded(child: _buildStatCard('Scans Today', '142', 'units', true).animate().slideX(begin: -0.2, delay: 300.ms)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildStatCard('Hours Logged', '7.5', 'hrs', false).animate().slideX(begin: 0.2, delay: 300.ms)),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Permission card
                              _buildPermissionCard().animate().fadeIn(delay: 400.ms),

                              const SizedBox(height: 24),

                              // Section label
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Container(width: 3, height: 14, decoration: BoxDecoration(color: const Color(0xFF9E2016), borderRadius: BorderRadius.circular(2))),
                                    const SizedBox(width: 10),
                                    Text('USER DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.4), letterSpacing: 1.5)),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 450.ms),

                              const SizedBox(height: 12),

                              _buildActionItem(Icons.phone_outlined, _profileData?['phone_number']?.isNotEmpty == true ? _profileData!['phone_number'] : 'Add Phone Number', _editPhoneNumber).animate().fadeIn(delay: 500.ms),
                              const SizedBox(height: 8),
                              _buildActionItem(Icons.email_outlined, _profileData?['email']?.isNotEmpty == true ? _profileData!['email'] : 'No Email', () {}).animate().fadeIn(delay: 550.ms),
                              const SizedBox(height: 8),

                              // Logout
                              GestureDetector(
                                onTap: () => _logout(context),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.red.withOpacity(0.25)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(children: [
                                            const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B), size: 20),
                                            const SizedBox(width: 14),
                                            const Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B))),
                                          ]),
                                          const Icon(Icons.chevron_right, color: Color(0xFFFF6B6B)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 600.ms),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildStatCard(String title, String value, String unit, bool isPrimary) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 96,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFF9E2016).withOpacity(0.15) : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isPrimary ? const Color(0xFF9E2016).withOpacity(0.4) : Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.45), letterSpacing: 1.0)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isPrimary ? const Color(0xFFFF6B6B) : Colors.white, height: 1.0)),
                  const SizedBox(width: 4),
                  Text(unit, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.4))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: const Color(0xFF9E2016).withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.verified_user_outlined, color: Color(0xFFFF6B6B), size: 22),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PERMISSION LEVEL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.45), letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text('Level ${_profileData?['price_level'] ?? 1} Access', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
              ]),
              Icon(Icons.info_outline, color: Colors.white.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(icon, color: const Color(0xFF9E2016), size: 20),
                  const SizedBox(width: 14),
                  Text(title, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
                ]),
                Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D).withOpacity(0.9),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: 1,
        selectedItemColor: const Color(0xFFFF6B6B),
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 1.0),
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/search');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'SEARCH'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'PROFILE'),
        ],
      ),
    );
  }
}
