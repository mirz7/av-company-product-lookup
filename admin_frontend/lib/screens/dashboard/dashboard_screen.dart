import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/route_constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/approval_provider.dart';

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
      Provider.of<DashboardProvider>(context, listen: false).fetchMetrics();
      Provider.of<ApprovalProvider>(context, listen: false).fetchApprovals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final prov = context.watch<DashboardProvider>();
    final approvals = context.watch<ApprovalProvider>();

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
          _header(textColor, sub, context).animate().fadeIn(delay: 50.ms).slideY(begin: 0.05),
          Expanded(child: prov.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.crimson))
              : RefreshIndicator(color: AppTheme.crimson, onRefresh: () async { prov.fetchMetrics(); approvals.fetchApprovals(); },
                  child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Operational Hub', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
                    const SizedBox(height: 2),
                    Text('REAL-TIME PERFORMANCE METRICS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sub, letterSpacing: 1.5)).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 20),
                    if (prov.metrics != null) ...[
                      LayoutBuilder(builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width > 600 ? 4 : 2;
                        final childAspectRatio = width > 600 ? 1.5 : (width / 2) / 130;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _metric(Icons.people_outline, 'Total Employees', '${prov.metrics!.totalEmployees}', textColor, sub, card, border, 200, onTap: () => context.go(RouteConstants.employees)),
                            _metric(Icons.inbox_outlined, 'Pending Approvals', '${prov.metrics!.pendingApprovals}', AppTheme.crimsonGlow, sub,
                                AppTheme.crimson.withOpacity(0.12), AppTheme.crimson.withOpacity(0.3), 250,
                                badge: prov.metrics!.pendingApprovals > 0 ? '${prov.metrics!.pendingApprovals} NEW' : null,
                                onTap: () => context.go(RouteConstants.approvals)),
                            _metric(Icons.inventory_2_outlined, 'Total Products', '${prov.metrics!.totalProducts}', textColor, sub, card, border, 300, onTap: () => context.go(RouteConstants.search)),
                            _metric(Icons.bolt_outlined, 'Active Sessions', '${prov.metrics!.activeSessions}', textColor, sub, card, border, 350),
                          ],
                        );
                      }),
                    ],
                    const SizedBox(height: 28),
                    _sectionHead('Recent Activity', 'View All >', textColor, sub, () => context.go(RouteConstants.employees)).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 12),
                    _activity(Icons.person_add_outlined, 'New employee onboarded', 'Branch: North Flagship • 2m ago', card, border, textColor, sub, 450),
                    const SizedBox(height: 8),
                    _activity(Icons.inventory_2_outlined, 'Inventory audit completed', 'SKU Category: Luxury Apparel • 1h ago', card, border, textColor, sub, 500),
                    const SizedBox(height: 8),
                    _activity(Icons.policy_outlined, 'Policy update published', 'Global Compliance Hub • 3h ago', card, border, textColor, sub, 550),
                    const SizedBox(height: 16),
                  ])))),
        ])),
      ),
    );
  }

  Widget _header(Color textColor, Color sub, BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.asset('assets/images/logo.png', height: 38, width: 38, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.business, size: 38, color: AppTheme.crimson))),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('AV & Company', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)),
          Text('Admin Hub', style: TextStyle(fontSize: 12, color: sub, letterSpacing: 1.0)),
        ]),
      ]),
      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppTheme.crimson.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.crimson.withOpacity(0.4))),
        child: const Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.crimsonGlow, letterSpacing: 1.5))),
    ]),
  );

  Widget _metric(IconData icon, String label, String value, Color textColor, Color sub, Color card, Color border, int delay, {String? badge, VoidCallback? onTap}) {
    return GestureDetector(onTap: onTap, child: ClipRRect(borderRadius: BorderRadius.circular(18), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18), border: Border.all(color: border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, color: AppTheme.crimson, size: 20), if (badge != null) ...[const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppTheme.crimson, borderRadius: BorderRadius.circular(8)), child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)))]]),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(fontSize: 10, color: sub, fontWeight: FontWeight.w500, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: textColor, height: 1.0)),
      ]),
    )))).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.05);
  }

  Widget _sectionHead(String title, String action, Color textColor, Color sub, VoidCallback onAction) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    Row(children: [Container(width: 3, height: 14, decoration: BoxDecoration(color: AppTheme.crimson, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 10), Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.5))]),
    GestureDetector(onTap: onAction, child: Text(action, style: const TextStyle(fontSize: 12, color: AppTheme.crimsonGlow, fontWeight: FontWeight.w600))),
  ]);

  Widget _activity(IconData icon, String title, String sub2, Color card, Color border, Color textColor, Color sub, int delay) =>
    ClipRRect(borderRadius: BorderRadius.circular(14), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.crimson.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: AppTheme.crimsonGlow, size: 18)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 2),
          Text(sub2, style: TextStyle(fontSize: 11, color: sub)),
        ])),
      ]),
    ))).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.05);
}
