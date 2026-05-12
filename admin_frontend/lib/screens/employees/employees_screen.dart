import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/employee_provider.dart';
import '../../data/models/employee_model.dart';

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
    final bg = isDark ? [AppTheme.darkSurface, AppTheme.darkBg2, const Color(0xFF3A1010)] : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFE8CFC8)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final card = isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.7);
    final border = isDark ? Colors.white.withOpacity(0.10) : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF3A1010) : const Color(0xFFE8CFC8),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: bg, begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.65, 1.0])),
        child: SafeArea(child: Column(children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/images/logo.png', height: 38, width: 38, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.business, size: 38, color: AppTheme.crimson))),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AV & Company', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)),
                Text('Employees', style: TextStyle(fontSize: 12, color: sub)),
              ]),
            ]),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.crimson.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.crimson.withOpacity(0.4))),
              child: const Text('STAFF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.crimsonGlow, letterSpacing: 1.5))),
          ])).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),

          // Search
          Padding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 12), child: ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: TextField(
            controller: _searchCtrl, style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(hintText: 'Search employees...', hintStyle: TextStyle(color: sub.withOpacity(0.5), fontSize: 14), prefixIcon: const Icon(Icons.search, color: AppTheme.crimson, size: 20),
              filled: true, fillColor: card,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.crimson, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 14)),
            onChanged: (v) { prov.searchQuery = v; prov.fetchEmployees(); },
          )))).animate().fadeIn(delay: 100.ms),

          Expanded(child: prov.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.crimson))
            : RefreshIndicator(color: AppTheme.crimson, onRefresh: () => prov.fetchEmployees(), child: prov.employees.isEmpty
                ? const Center(child: Text('No employees found.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: prov.employees.length,
                    itemBuilder: (ctx, i) => _empCard(ctx, prov.employees[i], isDark, card, border, textColor, sub, i)))),
        ])),
      ),
    );
  }

  void _showSheet(Employee emp) => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _PermissionSheet(employee: emp));

  Widget _empCard(BuildContext ctx, Employee emp, bool isDark, Color card, Color border, Color textColor, Color sub, int idx) {
    final initials = emp.fullName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
    final String initialText = initials.isEmpty ? emp.username.substring(0, emp.username.length > 2 ? 2 : emp.username.length).toUpperCase() : initials;
    final avatarColors = [AppTheme.crimson, const Color(0xFF2980B9), const Color(0xFF27AE60), const Color(0xFF8E44AD)];
    final ac = avatarColors[emp.id % avatarColors.length];
    final sc = emp.isActive ? const Color(0xFF27AE60) : const Color(0xFFE74C3C);

    return Padding(padding: const EdgeInsets.only(bottom: 10), child: ClipRRect(borderRadius: BorderRadius.circular(18), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          CircleAvatar(radius: 24, backgroundColor: ac, child: Text(initialText.isEmpty ? '??' : initialText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emp.fullName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
            Text(emp.jobRole, style: TextStyle(fontSize: 12, color: sub)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: sc.withOpacity(0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: sc.withOpacity(0.3))),
            child: Text('● ${emp.isActive ? 'ACTIVE' : 'PENDING'}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: sc))),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : AppTheme.lightBg3.withOpacity(0.5), borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)), border: Border(top: BorderSide(color: border))),
          child: Row(children: [
            const Icon(Icons.local_offer_outlined, size: 14, color: AppTheme.crimson),
            const SizedBox(width: 6),
            Text('Price Access ${emp.priceCAccess ? 'A+B+C' : emp.priceBAccess ? 'A+B' : 'A only'}', style: TextStyle(fontSize: 12, color: sub, fontWeight: FontWeight.w500)),
            const Spacer(),
            GestureDetector(onTap: () => _showSheet(emp), child: const Text('MANAGE ACCESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.crimsonGlow, letterSpacing: 0.5))),
          ])),
      ]),
    )))).animate().fadeIn(delay: Duration(milliseconds: 150 + idx * 50)).slideY(begin: 0.05);
  }
}

class _PermissionSheet extends StatefulWidget {
  final Employee employee;
  const _PermissionSheet({required this.employee});
  @override
  State<_PermissionSheet> createState() => _PermissionSheetState();
}

class _PermissionSheetState extends State<_PermissionSheet> {
  late bool _priceB, _priceC, _active;
  bool _saving = false;

  @override
  void initState() { super.initState(); _priceB = widget.employee.priceBAccess; _priceC = widget.employee.priceCAccess; _active = widget.employee.isActive; }

  Future<void> _save() async {
    setState(() => _saving = true);
    final prov = Provider.of<EmployeeProvider>(context, listen: false);
    final level = _priceC ? 'wholesale' : (_priceB ? 'discount' : 'standard');
    await prov.updatePermissions(widget.employee.id, {'permission_level': level});
    if (_active != widget.employee.isActive) await prov.updateStatus(widget.employee.id, _active);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Delete Account'),
      content: Text('Delete ${widget.employee.fullName}? This cannot be undone.'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete'))],
    ));
    if (ok == true && mounted) { await Provider.of<EmployeeProvider>(context, listen: false).deleteEmployee(widget.employee.id); if (mounted) Navigator.pop(context); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final border = isDark ? Colors.white.withOpacity(0.10) : AppTheme.lightBorder;
    final initials = widget.employee.fullName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
    final String initialText = initials.isEmpty ? widget.employee.username.substring(0, widget.employee.username.length > 2 ? 2 : widget.employee.username.length).toUpperCase() : initials;

    return DraggableScrollableSheet(initialChildSize: 0.75, minChildSize: 0.5, maxChildSize: 0.95, builder: (_, ctrl) => ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: Container(
      decoration: BoxDecoration(color: bg.withOpacity(isDark ? 0.95 : 0.98), borderRadius: const BorderRadius.vertical(top: Radius.circular(24)), border: Border(top: BorderSide(color: border))),
      child: ListView(controller: ctrl, padding: const EdgeInsets.all(24), children: [
        Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
        Row(children: [
          CircleAvatar(radius: 28, backgroundColor: AppTheme.crimson, child: Text(initialText.isEmpty ? '??' : initialText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.employee.fullName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor)),
            Text('${widget.employee.jobRole} • #AV-${widget.employee.id.toString().padLeft(4, '0')}', style: TextStyle(fontSize: 12, color: sub)),
          ]),
        ]),
        const SizedBox(height: 28),
        Text('ACCESS CONTROL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: sub, letterSpacing: 1.5)),
        const SizedBox(height: 14),
        _toggle(Icons.local_offer_outlined, 'Price A', 'Retail Listing Price', true, null, textColor, sub),
        Divider(height: 24, color: border),
        _toggle(Icons.price_change_outlined, 'Extended Pricing', 'Unlock Wholesale / Cost tiers', _priceB, (v) => setState(() { _priceB = v; if (!v) _priceC = false; }), textColor, sub),
        if (_priceB) ...[const SizedBox(height: 10), Padding(padding: const EdgeInsets.only(left: 16), child: _toggle(Icons.diamond_outlined, 'Price C (Wholesale)', 'Cost price visibility', _priceC, (v) => setState(() => _priceC = v), textColor, sub))],
        Divider(height: 24, color: border),
        _toggle(Icons.power_settings_new, 'Account Active', 'Allow employee to login', _active, (v) => setState(() => _active = v), textColor, sub),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white, elevation: 8, shadowColor: AppTheme.crimson.withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: _saving ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2) : const Text('Save Access Settings', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        )),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 48, child: OutlinedButton(
          onPressed: _delete,
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          child: const Text('Delete Employee Account', style: TextStyle(fontWeight: FontWeight.w600)),
        )),
      ]),
    ))));
  }

  Widget _toggle(IconData icon, String title, String sub, bool value, ValueChanged<bool>? onChange, Color textColor, Color subColor) => Row(children: [
    Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.crimson.withOpacity(0.15), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppTheme.crimsonGlow, size: 20)),
    const SizedBox(width: 12),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)), Text(sub, style: TextStyle(fontSize: 11, color: subColor))])),
    Switch(value: value, onChanged: onChange, activeColor: AppTheme.crimson),
  ]);
}
