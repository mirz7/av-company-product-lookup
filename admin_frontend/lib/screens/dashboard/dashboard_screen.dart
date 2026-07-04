import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/approval_provider.dart';
import '../../providers/notification_provider.dart';
import '../../data/models/dashboard_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardProv = Provider.of<DashboardProvider>(context, listen: false);
      
      dashboardProv.fetchMetrics();
      dashboardProv.startPolling();
      dashboardProv.requestNotificationPermission();
      Provider.of<ApprovalProvider>(context, listen: false).fetchApprovals();
    });
  }

  DashboardProvider? _dashboardProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dashboardProvider ??= Provider.of<DashboardProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _dashboardProvider?.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final prov = context.watch<DashboardProvider>();
    final approvals = context.watch<ApprovalProvider>();

    final bg = isDark
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF2D1010)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFCFBBAA)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final card = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.8);
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.lightBorder;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2D1010) : const Color(0xFFCFBBAA),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: bg, begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: const [0.0, 0.5, 1.0])),
        child: SafeArea(child: Column(children: [
          _header(textColor, sub, context, isDark).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),
          Expanded(child: _buildBody(prov, approvals, textColor, sub, card, border, isDark)),
        ])),
      ),
    );
  }

  Widget _buildBody(DashboardProvider prov, ApprovalProvider approvals, Color textColor, Color sub, Color card, Color border, bool isDark) {
    if (prov.isLoading && prov.metrics == null) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    if (prov.errorMessage != null && prov.metrics == null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.cloud_off_rounded, size: 64, color: sub.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Connection Error', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(prov.errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: sub, fontSize: 13)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => prov.fetchMetrics(),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            child: const Text('Try Again'),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primary,
      onRefresh: () async { 
        await prov.fetchMetrics(); 
        await approvals.fetchApprovals(); 
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Operational Hub', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor)).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),
          const SizedBox(height: 4),
          Text('Real-time Performance Metrics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: sub, letterSpacing: 0.5)).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 22),
          
          if (prov.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text('Live sync failed: ${prov.errorMessage}', style: const TextStyle(color: AppTheme.danger, fontSize: 12))),
              ]),
            ).animate().shake(),

          // Approval Alert Banner
          if (prov.metrics != null && prov.metrics!.pendingApprovals > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go(RouteConstants.approvals),
                  borderRadius: BorderRadius.circular(16),
                  splashColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.warning.withValues(alpha: 0.15), AppTheme.warning.withValues(alpha: 0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.notification_important_rounded, color: AppTheme.warning, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('New Registrations', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('${prov.metrics!.pendingApprovals} staff members are awaiting your approval.', 
                                style: TextStyle(color: sub, fontSize: 12)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppTheme.warning),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn().shake(delay: 500.ms),

          if (prov.metrics != null) ...[
            Row(children: [
              Expanded(child: _metric(Icons.people_outline, 'Total Employees', '${prov.metrics!.totalEmployees}', textColor, sub, card, border, 200, isDark, onTap: () => context.go(RouteConstants.employees))),
              const SizedBox(width: 14),
              Expanded(child: _metric(Icons.inbox_outlined, 'Pending Approvals', '${prov.metrics!.pendingApprovals}', AppTheme.warning, sub,
                  isDark ? AppTheme.warning.withValues(alpha: 0.08) : AppTheme.warning.withValues(alpha: 0.12),
                  AppTheme.warning.withValues(alpha: 0.2), 250, isDark,
                  badge: prov.metrics!.pendingApprovals > 0 ? '${prov.metrics!.pendingApprovals}' : null,
                  onTap: () => context.go(RouteConstants.approvals))),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _metric(Icons.inventory_2_outlined, 'Total Products', '${prov.metrics!.totalProducts}', textColor, sub, card, border, 300, isDark, onTap: () => context.go(RouteConstants.search))),
              const SizedBox(width: 14),
              Expanded(child: _metric(Icons.bolt_outlined, 'Active Sessions', '${prov.metrics!.activeSessions}', AppTheme.accent, sub,
                  isDark ? AppTheme.accent.withValues(alpha: 0.08) : AppTheme.accent.withValues(alpha: 0.12),
                  AppTheme.accent.withValues(alpha: 0.2), 350, isDark)),
            ]),
          ],
          const SizedBox(height: 30),
          _sectionHead('Recent Activity', 'View All ›', textColor, sub, () => context.push(RouteConstants.activities)).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 14),
          
          if (prov.metrics != null && prov.metrics!.recentActivity.isEmpty)
            _emptyActivity(sub, card, border)
          else if (prov.metrics != null)
            ...prov.metrics!.recentActivity.asMap().entries.map((entry) {
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _activity(
                  _iconForType(item.type),
                  item.title,
                  item.subtitle.isNotEmpty ? item.subtitle : _relativeTime(item.timestamp),
                  card, border, textColor, sub, 450 + entry.key * 50, isDark,
                  timeLabel: _relativeTime(item.timestamp),
                ),
              );
            }),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'employee_onboarded':  return Icons.person_add_outlined;
      case 'employee_approved':   return Icons.verified_outlined;
      case 'employee_rejected':   return Icons.person_remove_outlined;
      case 'access_change':       return Icons.vpn_key_outlined;
      case 'profile_update':      return Icons.edit_outlined;
      case 'inventory_audit':     return Icons.inventory_2_outlined;
      case 'policy_update':       return Icons.policy_outlined;
      case 'data_sync':           return Icons.sync_outlined;
      default:                    return Icons.event_note_outlined;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _header(Color textColor, Color sub, BuildContext context, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Container(
          height: 42, width: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
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
          Text('Central Operational Hub', style: TextStyle(fontSize: 11, color: sub, letterSpacing: 0.5)),
        ]),
      ]),
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
            ),
            child: Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryGlow, letterSpacing: 1.5)),
          ),
        ],
      ),
    ]),
  );

  Widget _metric(IconData icon, String label, String value, Color textColor, Color sub, Color card, Color border, int delay, bool isDark, {String? badge, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.12),
        child: ClipRRect(borderRadius: BorderRadius.circular(18), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12), child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: isDark ? [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 4))] : [],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: AppTheme.primary, size: 18),
              ),
              if (badge != null) ...[const Spacer(), Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.danger, borderRadius: BorderRadius.circular(10)),
                child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
              )],
            ]),
            const SizedBox(height: 14),
            Text(label, style: TextStyle(fontSize: 11, color: sub, fontWeight: FontWeight.w500, letterSpacing: 0.3)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: textColor, height: 1.0)),
          ]),
        ))),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.05);
  }

  Widget _sectionHead(String title, String action, Color textColor, Color sub, VoidCallback onAction) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.5)),
    ]),
    GestureDetector(onTap: onAction, child: Text(action, style: TextStyle(fontSize: 12, color: AppTheme.primaryGlow, fontWeight: FontWeight.w600))),
  ]);

  Widget _emptyActivity(Color sub, Color card, Color border) =>
    ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Center(child: Column(children: [
        Icon(Icons.event_note_outlined, color: sub, size: 32),
        const SizedBox(height: 10),
        Text('No recent activity', style: TextStyle(fontSize: 13, color: sub)),
      ])),
    ))).animate().fadeIn(delay: 450.ms);

  Widget _activity(IconData icon, String title, String sub2, Color card, Color border, Color textColor, Color sub, int delay, bool isDark, {String? timeLabel}) =>
    ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryGlow, size: 19),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 3),
          Text(sub2, style: TextStyle(fontSize: 11, color: sub)),
        ])),
        if (timeLabel != null)
          Text(timeLabel, style: TextStyle(fontSize: 10, color: sub, fontWeight: FontWeight.w500)),
      ]),
    ))).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.05);
}
