import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final String profilePic = "https://lh3.googleusercontent.com/aida-public/AB6AXuBlrXTbMoLn_jf7NjYQLwTJj2IolEsQWqLr-n2Nm1Yvsc47cslQg6c7wS3IjFVy29gnqNpjKv4I_EyD_OczewkR9WelYiJPuVUiWXESGc-Hx0q3IQ6i7psEEVHyi-aRkQpOc9FGr3vdGfvVO23wA73UKuZ76Z2FqznsiQ2PFoL69dOrrRuVvihmcVSiMXjXi10qlCBUYC3vmj5js6zFFpFXkXVmavlrU1FXVXtqP2qUQHrnwjuMxTrXiq7-OuBpsMqTn1Gu5pfggww";

  Future<void> _logout(BuildContext context) async {
    final apiService = ApiService();
    await apiService.logout();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F9),
      body: SafeArea(
        child: Column(
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
              child: SingleChildScrollView(
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
                              image: NetworkImage(profilePic),
                              fit: BoxFit.cover,
                            )
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
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
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Alex Mercer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF191C1C))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFCFE2F9), borderRadius: BorderRadius.circular(16)),
                          child: const Text('STORE MANAGER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF526478))),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFE1E3E3), borderRadius: BorderRadius.circular(16)),
                          child: const Text('#AV-01', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF59413D))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Stats Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard('Scans Today', '142', 'units', true),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard('Hours Logged', '7.5', 'hrs', false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionCard(),
                    const SizedBox(height: 32),

                    // Actions
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('MANAGEMENT & SECURITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF59413D), letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 8),
                    _buildActionItem(Icons.account_circle, 'Account Settings'),
                    const SizedBox(height: 8),
                    _buildActionItem(Icons.shield, 'Security & Privacy'),
                    const SizedBox(height: 8),
                    _buildActionItem(Icons.support_agent, 'Support Center'),
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
                    ),
                  ],
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
                children: const [
                  Text('PERMISSION LEVEL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF59413D))),
                  Text('Level 3 Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF191C1C))),
                ],
              )
            ],
          ),
          const Icon(Icons.info, color: Color(0xFF59413D)),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title) {
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
              Icon(icon, color: const Color(0xFF59413D)),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 16, color: Color(0xFF191C1C))),
            ],
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF59413D)),
        ],
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
