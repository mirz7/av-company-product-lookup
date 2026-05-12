import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/approval_provider.dart';
import '../../data/models/employee_model.dart';

class ApprovalsScreen extends StatefulWidget {
  const ApprovalsScreen({super.key});
  @override
  State<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends State<ApprovalsScreen> {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => Provider.of<ApprovalProvider>(context, listen: false).fetchApprovals()); }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final prov = context.watch<ApprovalProvider>();
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
                Text('Approvals', style: TextStyle(fontSize: 12, color: sub)),
              ]),
            ]),
            if (prov.pendingCount > 0)
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.crimson.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.crimson.withOpacity(0.4))),
                child: Text('${prov.pendingCount} PENDING', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.crimsonGlow))),
          ])).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),

          Expanded(child: prov.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.crimson))
            : RefreshIndicator(color: AppTheme.crimson, onRefresh: () => prov.fetchApprovals(), child: prov.pendingApprovals.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle_outline, size: 64, color: const Color(0xFF27AE60).withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text('All caught up!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                    const SizedBox(height: 6),
                    Text('No pending approvals.', style: TextStyle(color: sub)),
                  ]))
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: prov.pendingApprovals.length,
                    itemBuilder: (ctx, i) => _card(ctx, prov.pendingApprovals[i], prov, isDark, card, border, textColor, sub, i)))),
        ])),
      ),
    );
  }

  Widget _card(BuildContext ctx, Employee emp, ApprovalProvider prov, bool isDark, Color card, Color border, Color textColor, Color sub, int idx) {
    final initials = emp.fullName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
    final String initialText = initials.isEmpty ? emp.username.substring(0, emp.username.length > 2 ? 2 : emp.username.length).toUpperCase() : initials;
    final avatarColors = [AppTheme.crimson, const Color(0xFF3D5A80), const Color(0xFF27AE60)];
    final ac = avatarColors[emp.id % avatarColors.length];

    return Padding(padding: const EdgeInsets.only(bottom: 12), child: ClipRRect(borderRadius: BorderRadius.circular(18), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 24, backgroundColor: ac, child: Text(initialText.isEmpty ? '??' : initialText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emp.fullName, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
            Text('@${emp.username}', style: TextStyle(fontSize: 12, color: sub)),
          ]),
        ]),
        const SizedBox(height: 14),
        Row(children: [const Icon(Icons.badge_outlined, size: 16, color: AppTheme.crimson), const SizedBox(width: 8), Text(emp.jobRole.isEmpty ? 'Staff Member' : emp.jobRole, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor))]),
        if (emp.email.isNotEmpty) ...[const SizedBox(height: 6), Row(children: [Icon(Icons.email_outlined, size: 14, color: sub), const SizedBox(width: 6), Text(emp.email, style: TextStyle(fontSize: 12, color: sub))])],
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: ElevatedButton(
            onPressed: prov.isLoading ? null : () async {
              await prov.approveEmployee(emp.id);
              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('${emp.fullName} approved!'), backgroundColor: const Color(0xFF27AE60), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson, foregroundColor: Colors.white, elevation: 8, shadowColor: AppTheme.crimson.withOpacity(0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13)),
            child: const Text('Approve & Set Access', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          )),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: prov.isLoading ? null : () async {
              final ok = await showDialog<bool>(context: ctx, builder: (c) => AlertDialog(
                title: const Text('Reject Employee'), content: Text('Reject ${emp.fullName}?'),
                actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Reject'))],
              ));
              if (ok == true && ctx.mounted) { await prov.rejectEmployee(emp.id); if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Employee rejected.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)); }
            },
            style: OutlinedButton.styleFrom(foregroundColor: isDark ? Colors.white70 : AppTheme.lightSubText, side: BorderSide(color: border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20)),
            child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ]),
      ]),
    )))).animate().fadeIn(delay: Duration(milliseconds: 150 + idx * 80)).slideY(begin: 0.05);
  }
}
