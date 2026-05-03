import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import 'search_screen.dart';

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

  Future<void> _fetchProfile({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final data = await _apiService.getProfile(forceRefresh: forceRefresh);
    setState(() {
      _profileData = data;
      _isLoading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    final isDark = context.read<ThemeProvider>().isDark;
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(curved),
          child: FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
              child: Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(horizontal: 32),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1A1A2E).withOpacity(0.95)
                            : Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.10)
                              : AppTheme.lightBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.crimson.withOpacity(0.15),
                            blurRadius: 40,
                            spreadRadius: -5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppTheme.crimson.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.crimson.withOpacity(0.25), width: 1.5),
                            ),
                            child: const Icon(Icons.logout_rounded, color: AppTheme.crimson, size: 28),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Sign Out?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppTheme.lightText,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You will be returned to the login screen. Any unsaved work will be lost.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white54 : AppTheme.lightSubText,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(ctx, false),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.07)
                                          : AppTheme.lightBg2,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.10)
                                            : AppTheme.lightBorder,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isDark ? Colors.white70 : AppTheme.lightSubText,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(ctx, true),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.crimson,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.crimson.withOpacity(0.4),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Sign Out',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;
    ApiService.clearProductCache();
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
          style: TextStyle(color: context.read<ThemeProvider>().isDark ? Colors.white : AppTheme.lightText),
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
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() => _isLoading = true);
        final success = await _apiService.updateProfilePhoto(image.path);
        if (success) {
          await _fetchProfile();
        } else {
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to update profile photo')),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
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
    final isDark = context.watch<ThemeProvider>().isDark;
    final bgColors = isDark
        ? [AppTheme.darkSurface, AppTheme.darkBg2, const Color(0xFF3A1010)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFE8CFC8)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final subTextColor = isDark ? Colors.white54 : AppTheme.lightSubText;
    final cardColor = isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.7);
    final borderColor = isDark ? Colors.white.withOpacity(0.10) : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF3A1010) : const Color(0xFFE8CFC8),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bgColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset('assets/images/logo.png', height: 38, width: 38, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.business, size: 38, color: AppTheme.crimson)),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('AV & Company', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)),
                                  Text('Retail Hub', style: TextStyle(fontSize: 12, color: subTextColor, letterSpacing: 1.0)),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.crimson.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.crimson.withOpacity(0.4)),
                            ),
                            child: const Text('MY SPACE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.crimsonGlow, letterSpacing: 1.5)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),

                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _fetchProfile(forceRefresh: true),
                        color: const Color(0xFF9E2016),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: borderColor),
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
                                                  image: NetworkImage(
                                                    (_profileData?['profile_photo'] != null && _profileData!['profile_photo'].toString().isNotEmpty)
                                                        ? (_profileData!['profile_photo'].toString().startsWith('http')
                                                            ? _profileData!['profile_photo']
                                                            : 'http://192.168.1.5:8000${_profileData!['profile_photo']}')
                                                        : 'https://ui-avatars.com/api/?name=User&background=9E2016&color=fff'
                                                  ),
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
                                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
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
                                              child: Text((_profileData?['role'] ?? 'STAFF').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.crimsonGlow, letterSpacing: 1)),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isDark ? Colors.white.withOpacity(0.07) : AppTheme.lightBg3,
                                                borderRadius: BorderRadius.circular(20),
                                                border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : AppTheme.lightBorder),
                                              ),
                                              child: Text('@${_profileData?['username'] ?? ''}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subTextColor, letterSpacing: 1)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(child: _buildStatCard('Searches Today', _profileData?['searches_today']?.toString() ?? '0', 'searches', true).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildStatCard('Hours Logged', _profileData?['hours_logged']?.toString() ?? '0.0', 'hrs', false).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05)),
                                ],
                              ),

                              const SizedBox(height: 12),

                              _buildPermissionCard().animate().fadeIn(delay: 250.ms).slideY(begin: 0.05),

                              const SizedBox(height: 24),

                              Align(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.crimson, borderRadius: BorderRadius.circular(2))),
                                    const SizedBox(width: 10),
                                    Text('USER DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: subTextColor, letterSpacing: 1.5)),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

                              const SizedBox(height: 12),

                              _buildActionItem(Icons.phone_outlined, _profileData?['phone_number']?.isNotEmpty == true ? _profileData!['phone_number'] : 'Add Phone Number', _editPhoneNumber).animate().fadeIn(delay: 350.ms).slideY(begin: 0.05),
                              const SizedBox(height: 8),
                              _buildActionItem(Icons.email_outlined, _profileData?['email']?.isNotEmpty == true ? _profileData!['email'] : 'No Email', () {}).animate().fadeIn(delay: 400.ms).slideY(begin: 0.05),
                              const SizedBox(height: 8),

                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: cardColor,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: borderColor),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(children: [
                                          Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: AppTheme.crimson, size: 20),
                                          const SizedBox(width: 14),
                                          Text(isDark ? 'Dark Mode' : 'Light Mode', style: TextStyle(fontSize: 14, color: isDark ? Colors.white.withOpacity(0.8) : AppTheme.lightText)),
                                        ]),
                                        GestureDetector(
                                          onTap: () => context.read<ThemeProvider>().toggle(),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            width: 50,
                                            height: 28,
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(14),
                                              color: isDark ? AppTheme.crimson : AppTheme.silver,
                                            ),
                                            child: AnimatedAlign(
                                              duration: const Duration(milliseconds: 300),
                                              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                                              child: Container(
                                                width: 22,
                                                height: 22,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.white,
                                                ),
                                                child: Icon(
                                                  isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                                                  size: 13,
                                                  color: isDark ? AppTheme.crimson : AppTheme.silver,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.05),
                              const SizedBox(height: 8),

                              GestureDetector(
                                onTap: () => _logout(context),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: borderColor),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(children: [
                                            const Icon(Icons.logout_rounded, color: AppTheme.crimson, size: 20),
                                            const SizedBox(width: 14),
                                            Text('Sign Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                                          ]),
                                          Icon(Icons.chevron_right, color: isDark ? Colors.white.withOpacity(0.3) : AppTheme.silverDark),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.05),
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
    final isDark = context.read<ThemeProvider>().isDark;
    final cardColor = isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.65);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : AppTheme.lightBorder;
    final subTextColor = isDark ? Colors.white.withOpacity(0.45) : AppTheme.lightSubText;
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 96,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPrimary ? AppTheme.crimson.withOpacity(0.15) : cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isPrimary ? AppTheme.crimson.withOpacity(0.4) : borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: subTextColor, letterSpacing: 1.0)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isPrimary ? AppTheme.crimsonGlow : textColor, height: 1.0)),
                  const SizedBox(width: 4),
                  Text(unit, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: subTextColor)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard() {
    final isDark = context.read<ThemeProvider>().isDark;
    final cardColor = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.65);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : AppTheme.lightBorder;
    final subTextColor = isDark ? Colors.white.withOpacity(0.45) : AppTheme.lightSubText;
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppTheme.crimson.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.verified_user_outlined, color: AppTheme.crimsonGlow, size: 22),
                ),
                const SizedBox(width: 14),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PERMISSION LEVEL', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: subTextColor, letterSpacing: 1.5)),
                  const SizedBox(height: 2),
                  Text('Level ${_profileData?['price_level'] ?? 1} Access', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                ]),
              ]),
              Icon(Icons.info_outline, color: subTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, VoidCallback onTap) {
    final isDark = context.read<ThemeProvider>().isDark;
    final cardColor = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.65);
    final borderColor = isDark ? Colors.white.withOpacity(0.1) : AppTheme.lightBorder;
    final textColor = isDark ? Colors.white.withOpacity(0.8) : AppTheme.lightText;
    final subTextColor = isDark ? Colors.white.withOpacity(0.3) : AppTheme.silverDark;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(icon, color: AppTheme.crimson, size: 20),
                  const SizedBox(width: 14),
                  Text(title, style: TextStyle(fontSize: 14, color: textColor)),
                ]),
                Icon(Icons.chevron_right, color: subTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isDark = context.read<ThemeProvider>().isDark;
    final navBg = isDark ? const Color(0xFF12121F) : AppTheme.lightSurface;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder;
    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.1), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: Row(
        children: [
          Expanded(
            child: _navItem(
              context: context,
              icon: Icons.search_rounded,
              label: 'SEARCH',
              isActive: false,
              isDark: isDark,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const SearchScreen(),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _navItem(
              context: context,
              icon: Icons.person_rounded,
              label: 'MY SPACE',
              isActive: true,
              isDark: isDark,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({required BuildContext context, required IconData icon, required String label, required bool isActive, required VoidCallback onTap, required bool isDark}) {
    final color = isActive ? AppTheme.crimsonGlow : (isDark ? Colors.white38 : AppTheme.silverDark);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.crimsonGlow.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.2)),
        ],
      ),
    );
  }
}
