import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      builder: (context) => AlertDialog(
        title: const Text('Edit Phone Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
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
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile Photo URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Image URL', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );

    if (newUrl != null) {
      setState(() => _isLoading = true);
      await _apiService.updateProfile({'profile_photo': newUrl});
      await _fetchProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F9),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF9E2016)))
            : Column(
                children: [
                  // Top App Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/images/logo.png', height: 32, errorBuilder: (c,e,s) => const Icon(Icons.business)),
                            const SizedBox(width: 12),
                            const Text(
                              'AV & COMPANY',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF091D2E), letterSpacing: -1.0),
                            ),
                          ],
                        ),
                        const Text('Staff Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9E2016))),
                      ],
                    ),
                  ),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _fetchProfile,
                      color: const Color(0xFF9E2016),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
                        child: Column(
                          children: [
                            // Profile Header
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 112,
                                  height: 112,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF9E2016), width: 4),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                                    image: DecorationImage(
                                      image: NetworkImage(_profileData?['profile_photo'] ?? 'https://ui-avatars.com/api/?name=User'),
                                      fit: BoxFit.cover,
                                    )
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _editProfilePhoto,
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF9E2016),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFFF8F9F9), width: 2),
                                      ),
                                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                    ),
                                  ),
                                )
                              ],
                            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                            const SizedBox(height: 16),
                            Text(
                              '${_profileData?['first_name'] ?? ''} ${_profileData?['last_name'] ?? ''}'.trim().isEmpty ? (_profileData?['username']?.toString() ?? 'User') : '${_profileData?['first_name'] ?? ''} ${_profileData?['last_name'] ?? ''}'.trim(),
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF191C1C))
                            ).animate().fadeIn(delay: 100.ms),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFCFE2F9), borderRadius: BorderRadius.circular(16)),
                                  child: Text((_profileData?['role'] ?? 'STAFF').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF526478))),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFFE1E3E3), borderRadius: BorderRadius.circular(16)),
                                  child: Text('#${_profileData?['username'] ?? 'AV'}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF59413D))),
                                ),
                              ],
                            ).animate().fadeIn(delay: 200.ms),
                            const SizedBox(height: 32),

                            // Stats Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard('Scans Today', '142', 'units', true).animate().slideX(begin: -0.2, delay: 300.ms),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildStatCard('Hours Logged', '7.5', 'hrs', false).animate().slideX(begin: 0.2, delay: 300.ms),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildPermissionCard().animate().fadeIn(delay: 400.ms),
                            const SizedBox(height: 32),

                            // Actions
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('USER DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF59413D), letterSpacing: 1.5)),
                            ).animate().fadeIn(delay: 500.ms),
                            const SizedBox(height: 8),
                            _buildActionItem(Icons.phone, _profileData?['phone_number']?.isNotEmpty == true ? _profileData!['phone_number'] : 'Add Phone Number', _editPhoneNumber).animate().fadeIn(delay: 600.ms),
                            const SizedBox(height: 8),
                            _buildActionItem(Icons.email, _profileData?['email']?.isNotEmpty == true ? _profileData!['email'] : 'No Email', () {}).animate().fadeIn(delay: 700.ms),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _logout(context),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: const [
                                        Icon(Icons.logout, color: Colors.red),
                                        SizedBox(width: 16),
                                        Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                                      ],
                                    ),
                                    const Icon(Icons.chevron_right, color: Colors.red),
                                  ],
                                ),
                              ),
                            ).animate().fadeIn(delay: 800.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildStatCard(String title, String value, String unit, bool primaryBorder) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: primaryBorder ? const Color(0xFF9E2016) : Colors.transparent, width: 4),
          top: BorderSide(color: Colors.white.withOpacity(0.3)),
          right: BorderSide(color: Colors.white.withOpacity(0.3)),
          bottom: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF59413D), letterSpacing: 1.0)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryBorder ? const Color(0xFF9E2016) : const Color(0xFF191C1C), height: 1.0)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF59413D))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: const Color(0xFF9E2016).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.verified_user, color: Color(0xFF9E2016)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PERMISSION LEVEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF59413D))),
                  Text('Level ${_profileData?['price_level'] ?? 1} Access', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF191C1C))),
                ],
              )
            ],
          ),
          const Icon(Icons.info, color: Color(0xFF59413D)),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF59413D)),
                const SizedBox(width: 16),
                Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF191C1C))),
              ],
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF59413D)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: 1,
            selectedItemColor: const Color(0xFF9E2016),
            unselectedItemColor: const Color(0xFF4E6073),
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.0),
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacementNamed(context, '/search');
              }
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'SEARCH'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
            ],
          ),
        ),
      ),
    );
  }
}
