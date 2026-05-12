import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/employee_provider.dart';
import '../../data/models/employee_model.dart';

void _viewPhoto(BuildContext context, String url, String name, int id) {
  Navigator.push(context, PageRouteBuilder(
    opaque: false,
    barrierColor: Colors.black.withOpacity(0.3),
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, _, __) => _PhotoPreview(url: url, name: name, id: id),
  ));
}

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});
  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => Provider.of<EmployeeProvider>(context, listen: false).fetchEmployees()); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final prov = context.watch<EmployeeProvider>();
    final bg = isDark
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF2D1010)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFCFBBAA)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final card = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.8);
    final border = isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder;

    // Filter to only show approved employees in this screen
    final approvedEmployees = prov.employees.where((e) => e.isApproved).toList();
    
    // Calculate stats based on approved list
    final activeCount = approvedEmployees.length;
    final totalCount = approvedEmployees.length;
    final complianceRate = 100; // Since we're only looking at approved ones now

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2D1010) : const Color(0xFFCFBBAA),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: bg, begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.5, 1.0])),
        child: SafeArea(child: Column(children: [
          // Header
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                height: 42, width: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Center(child: Text('AV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)))),
                ),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AV ADMIN PORTAL', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)),
                const SizedBox(height: 1),
                Text('Employee Directory', style: TextStyle(fontSize: 11, color: sub, letterSpacing: 0.5)),
              ]),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Text('STAFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryGlow, letterSpacing: 1.5)),
            ),
          ])).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),

          // Title + Stats row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('All Employees', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)).animate().fadeIn(delay: 80.ms),
              Row(children: [
                _statBadge('Active Staff', '$activeCount', AppTheme.accent, isDark),
                const SizedBox(width: 8),
                _statBadge('Compliance', '$complianceRate%', AppTheme.primary, isDark),
              ]).animate().fadeIn(delay: 100.ms),
            ]),
          ),

          // Search
          Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 12), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: TextField(
            controller: _searchCtrl, style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search employees...', hintStyle: TextStyle(color: sub.withOpacity(0.5), fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppTheme.primary, size: 20),
              filled: true, fillColor: card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: (v) { prov.searchQuery = v; prov.fetchEmployees(); },
          )))).animate().fadeIn(delay: 120.ms),

          Expanded(child: prov.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : RefreshIndicator(color: AppTheme.primary, onRefresh: () => prov.fetchEmployees(), child: approvedEmployees.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.people_outline, size: 56, color: sub.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    Text('No approved employees found.', style: TextStyle(color: sub, fontSize: 14)),
                  ]))
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: approvedEmployees.length,
                    itemBuilder: (ctx, i) => _empCard(ctx, approvedEmployees[i], isDark, card, border, textColor, sub, i)))),
        ])),
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(isDark ? 0.12 : 0.10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: color.withOpacity(0.8), letterSpacing: 0.3)),
    ]),
  );

  void _showSheet(Employee emp) => showModalBottomSheet(
    context: context, 
    isScrollControlled: true, 
    backgroundColor: Colors.transparent, 
    builder: (_) => Stack(children: [
      GestureDetector(onTap: () => Navigator.pop(context), child: Container(color: Colors.transparent)),
      _PermissionSheet(employee: emp),
    ]),
  );



  Widget _empCard(BuildContext ctx, Employee emp, bool isDark, Color card, Color border, Color textColor, Color sub, int idx) {
    final initials = emp.fullName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
    final String initialText = initials.isEmpty ? emp.username.substring(0, emp.username.length > 2 ? 2 : emp.username.length).toUpperCase() : initials;
    final avatarColors = [AppTheme.primary, const Color(0xFF2980B9), const Color(0xFF27AE60), const Color(0xFF8E44AD), AppTheme.accent];
    final ac = avatarColors[emp.id % avatarColors.length];
    final sc = emp.isApproved ? AppTheme.accent : AppTheme.warning;

    return Padding(padding: const EdgeInsets.only(bottom: 10), child: ClipRRect(borderRadius: BorderRadius.circular(18), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: GestureDetector(
      onTap: () => _showSheet(emp),
      child: Container(
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
        child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Row(children: [
            // Avatar — Clickable Hero Animation (keeps its own tap for photo)
            GestureDetector(
            onTap: emp.profilePhotoUrl != null ? () => _viewPhoto(ctx, emp.profilePhotoUrl!, emp.fullName, emp.id) : null,
              child: Hero(
                tag: 'emp_avatar_${emp.id}',
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    gradient: emp.profilePhotoUrl == null
                        ? LinearGradient(colors: [ac, ac.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: ac.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: emp.profilePhotoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            emp.profilePhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                              child: Text(initialText.isEmpty ? '??' : initialText,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                            ),
                          ),
                        )
                      : Center(child: Text(initialText.isEmpty ? '??' : initialText,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(emp.fullName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 2),
              Text(emp.jobRole, style: TextStyle(fontSize: 12, color: sub)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: sc.withOpacity(0.12), borderRadius: BorderRadius.circular(10), border: Border.all(color: sc.withOpacity(0.25))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Text(emp.isApproved ? 'Approved' : 'Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sc)),
              ]),
            ),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : AppTheme.lightBg3.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              border: Border(top: BorderSide(color: border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.vpn_key_outlined, size: 14, color: AppTheme.primary),
                const SizedBox(width: 6),
                Text('Price Access ${emp.priceCAccess ? 'A+B+C' : emp.priceBAccess ? 'A+B' : 'A only'}', style: TextStyle(fontSize: 12, color: sub, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ]),
      ),
    )))).animate().fadeIn(delay: Duration(milliseconds: 150 + idx * 50)).slideY(begin: 0.05);
  }
}

// ─── Permission Sheet (matches Stitch "Permission Control" design) ────────────
class _PermissionSheet extends StatefulWidget {
  final Employee employee;
  const _PermissionSheet({required this.employee});
  @override
  State<_PermissionSheet> createState() => _PermissionSheetState();
}

class _PermissionSheetState extends State<_PermissionSheet> {
  late bool _priceBC, _active;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Price B and C are always granted/revoked together
    _priceBC = widget.employee.priceBAccess || widget.employee.priceCAccess;
    _active = widget.employee.isActive;
  }

  Future<void> _autoSave(String type, bool val) async {
    final prov = Provider.of<EmployeeProvider>(context, listen: false);
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);

    try {
      if (type == 'priceBC') {
        setState(() => _priceBC = val);
        final level = val ? 'wholesale' : 'standard';
        await prov.updatePermissions(widget.employee.id, {'permission_level': level});
      } else if (type == 'active') {
        setState(() => _active = val);
        await prov.updateStatus(widget.employee.id, val);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text('Settings saved for ${widget.employee.fullName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
            backgroundColor: AppTheme.primary,
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save settings')));
      }
    }
  }

  Future<void> _delete() async {
    HapticFeedback.heavyImpact();
    final isDark = context.read<ThemeProvider>().isDark;
    
    final ok = await showDialog<bool>(
      context: context, 
      builder: (c) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.danger.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.delete_forever_rounded, color: AppTheme.danger, size: 32),
              ),
              const SizedBox(height: 20),
              Text('Delete Account?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppTheme.lightText)),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete ${widget.employee.fullName}? This action is permanent and cannot be reversed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : AppTheme.lightSubText, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white60 : AppTheme.lightSubText, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 300.ms).fadeIn(),
      ),
    );
    if (ok == true && mounted) { 
      await Provider.of<EmployeeProvider>(context, listen: false).deleteEmployee(widget.employee.id); 
      if (mounted) Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? const Color(0xFF0F0F1A) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final border = isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder;
    final initials = widget.employee.fullName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
    final String initialText = initials.isEmpty ? widget.employee.username.substring(0, widget.employee.username.length > 2 ? 2 : widget.employee.username.length).toUpperCase() : initials;

    return DraggableScrollableSheet(
      initialChildSize: 0.53, 
      minChildSize: 0.4, 
      maxChildSize: 0.95, 
      builder: (_, ctrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), 
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), 
          child: Container(
            decoration: BoxDecoration(
              color: bg.withOpacity(isDark ? 0.97 : 0.98), 
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), 
              border: Border(top: BorderSide(color: AppTheme.primary.withOpacity(0.3), width: 2))
            ),
            child: ListView(
              controller: ctrl, 
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), 
              children: [
                Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey[500], borderRadius: BorderRadius.circular(2)))),

                // ── Header ──
                Text('Employee Overview', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sub, letterSpacing: 1.5)),
                const SizedBox(height: 10),

                // ── Employee info ──
                Row(children: [
                  GestureDetector(
                    onTap: widget.employee.profilePhotoUrl != null ? () => _viewPhoto(context, widget.employee.profilePhotoUrl!, widget.employee.fullName, widget.employee.id) : null,
                    child: Hero(
                      tag: 'emp_avatar_${widget.employee.id}',
                      child: Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 2),
                          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: widget.employee.profilePhotoUrl != null && widget.employee.profilePhotoUrl!.isNotEmpty
                            ? Image.network(widget.employee.profilePhotoUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(initialText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24))))
                            : Center(child: Text(initialText.isEmpty ? '??' : initialText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24))),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.employee.fullName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 0.2)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBg3, borderRadius: BorderRadius.circular(6)),
                      child: Text('${widget.employee.jobRole} • #AV-${widget.employee.id.toString().padLeft(4, '0')}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sub, letterSpacing: 0.5)),
                    ),
                  ])),
                ]),
                const SizedBox(height: 18),

                // ── Access Control Section ──
                Row(children: [
                  Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Text('Access Control', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.5)),
                ]),
                const SizedBox(height: 8),
                _toggle(Icons.local_offer_outlined, 'Price A', 'Retail Listing Price', true, null, textColor, sub, isDark),
                Divider(height: 24, color: border),
                _toggle(Icons.diamond_outlined, 'Extended Pricing (Price B + C)', 'Unlock wholesale, cost tiers & cost price visibility', _priceBC, (v) => _autoSave('priceBC', v), textColor, sub, isDark),
                Divider(height: 24, color: border),
                _toggle(Icons.power_settings_new, 'Account Active', 'Allow employee to login', _active, (v) => _autoSave('active', v), textColor, sub, isDark),

                const SizedBox(height: 24),

                // ── Delete Button ──
                SizedBox(width: double.infinity, height: 50, child: OutlinedButton(
                  onPressed: _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: BorderSide(color: AppTheme.danger.withOpacity(0.5), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Delete Employee Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                )).animate(onPlay: (ctrl) => ctrl.repeat(reverse: true)).shimmer(duration: 2000.ms, color: Colors.white12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggle(IconData icon, String title, String sub, bool value, ValueChanged<bool>? onChange, Color textColor, Color subColor, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppTheme.primaryGlow, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 12, color: subColor, height: 1.2)),
      ])),
      const SizedBox(width: 8),
      Transform.scale(
        scale: 0.9,
        child: Switch(
          value: value,
          onChanged: onChange,
          activeColor: AppTheme.primaryGlow,
          activeTrackColor: AppTheme.primary.withOpacity(0.4),
        ),
      ),
    ]),
  );

  Widget _historyItem(String text, IconData icon, Color color, Color sub, bool isDark) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(isDark ? 0.08 : 0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.15)),
    ),
    child: Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 10),
      Text(text, style: TextStyle(fontSize: 13, color: sub, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ─── Photo Preview Overlay (Hero Animation & Glassmorphism) ────────────
class _PhotoPreview extends StatelessWidget {
  final String url;
  final String name;
  final int id;

  const _PhotoPreview({required this.url, required this.name, required this.id});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Immersive blurred background
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(color: Colors.black.withOpacity(0.55)),
              ),
            ),
            
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    child: Text(
                      name.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  
                  Hero(
                    tag: 'emp_avatar_$id',
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                        maxHeight: MediaQuery.of(context).size.height * 0.65,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.2),
                            blurRadius: 50,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  
                  Text(
                    'TAP ANYWHERE TO CLOSE',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .fadeIn(duration: 1.seconds),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
