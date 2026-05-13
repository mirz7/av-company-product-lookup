import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/approval_provider.dart';
import '../../data/models/employee_model.dart';
import '../../data/services/sound_service.dart';
import '../../core/utils/custom_snack.dart';

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
    final bg = isDark
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF2D1010)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFCFBBAA)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final card = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.8);
    final border = isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2D1010) : const Color(0xFFCFBBAA),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: bg, begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.5, 1.0])),
        child: SafeArea(child: Column(children: [
          // Header
          // Header
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(
                height: 40, width: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset('assets/images/logo.png', fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Center(child: Text('AV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)))),
                ),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AV ADMIN PORTAL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.2)),
                const SizedBox(height: 1),
                Text('PENDING APPROVALS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: sub, letterSpacing: 1.5)),
              ]),
            ]),
            if (prov.pendingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                ),
                child: Text('${prov.pendingCount} PENDING', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.danger, letterSpacing: 0.5)),
              ),
          ])).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),

          Expanded(child: prov.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : RefreshIndicator(color: AppTheme.primary, onRefresh: () => prov.fetchApprovals(), child: prov.pendingApprovals.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 60), // Lifted up for visual balance
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.accent.withOpacity(0.15), width: 2),
                          ),
                          child: Icon(Icons.check_circle_rounded, size: 50, color: AppTheme.accent.withOpacity(0.8)),
                        ),
                        const SizedBox(height: 24),
                        Text('All caught up!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.5)),
                        const SizedBox(height: 8),
                        Text('There are no pending employee approvals.\nYour workspace is clean!', textAlign: TextAlign.center, style: TextStyle(color: sub, fontSize: 13, height: 1.5)),
                      ]).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.95, 0.95)),
                    ),
                  )
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Pending Requests', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)).animate().fadeIn(delay: 80.ms),
                        const SizedBox(height: 4),
                        Text('Manage new access requests from the retail team.', style: TextStyle(fontSize: 12, color: sub)).animate().fadeIn(delay: 100.ms),
                      ]),
                    ),
                    Expanded(child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: prov.pendingApprovals.length,
                      itemBuilder: (ctx, i) => _card(ctx, prov.pendingApprovals[i], prov, isDark, card, border, textColor, sub, i))),
                  ])),
          ),
        ])),
      ),
    );
  }

  Widget _card(BuildContext ctx, Employee emp, ApprovalProvider prov, bool isDark, Color card, Color border, Color textColor, Color sub, int idx) {
    final initials = emp.fullName.split(' ').take(2).map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
    final String initialText = initials.isEmpty ? emp.username.substring(0, emp.username.length > 2 ? 2 : emp.username.length).toUpperCase() : initials;
    final avatarColors = [AppTheme.primary, const Color(0xFF3D5A80), const Color(0xFF27AE60), const Color(0xFF8E44AD)];
    final ac = avatarColors[emp.id % avatarColors.length];

    return Padding(padding: const EdgeInsets.only(bottom: 14), child: ClipRRect(borderRadius: BorderRadius.circular(18), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: isDark ? [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 3))] : [],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [ac, ac.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: ac.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Center(child: Text(initialText.isEmpty ? '??' : initialText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(emp.fullName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 2),
            Text('@${emp.username}', style: TextStyle(fontSize: 12, color: AppTheme.primary.withOpacity(0.8))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppTheme.warning, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              const Text('New', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.warning)),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Icon(Icons.badge_outlined, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(emp.jobRole.isEmpty ? 'Staff Member' : emp.jobRole, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
        ]),
        if (emp.email.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.email_outlined, size: 14, color: sub),
            const SizedBox(width: 6),
            Text(emp.email, style: TextStyle(fontSize: 12, color: sub)),
          ]),
        ],
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: prov.isLoading ? null : () async {
              await prov.approveEmployee(emp.id);
              HapticFeedback.mediumImpact();
              SystemSound.play(SystemSoundType.click);
              if (ctx.mounted) {
                SoundService.playSuccess();
                CustomSnack.show(
                  ctx,
                  message: '${emp.fullName} approved!',
                  icon: Icons.verified_user_rounded,
                  color: AppTheme.primary,
                );
              }
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              elevation: 6,
              shadowColor: AppTheme.primary.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          )),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: prov.isLoading ? null : () async {
              final ok = await showDialog<bool>(context: ctx, builder: (c) => AlertDialog(
                title: const Text('Reject Employee'), content: Text('Reject ${emp.fullName}?'),
                actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), TextButton(onPressed: () => Navigator.pop(c, true), style: TextButton.styleFrom(foregroundColor: AppTheme.danger), child: const Text('Reject'))],
              ));
              if (ok == true && ctx.mounted) { 
                await prov.rejectEmployee(emp.id); 
                if (ctx.mounted) {
                  CustomSnack.show(
                    ctx,
                    message: 'Employee rejected.',
                    icon: Icons.person_remove_rounded,
                    color: AppTheme.danger,
                  );
                }
              }
            },
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : AppTheme.lightSubText,
              side: BorderSide(color: border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            ),
          ),
        ]),
      ]),
    )))).animate().fadeIn(delay: Duration(milliseconds: 150 + idx * 80)).slideY(begin: 0.05);
  }
}
