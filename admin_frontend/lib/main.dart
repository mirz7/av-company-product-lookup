import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/route_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/approval_provider.dart';
import 'providers/product_provider.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/employees/employees_screen.dart';
import 'screens/approvals/approvals_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/profile/profile_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => ApprovalProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: const AdminApp(),
    ),
  );
}

// Router is top-level constant — never recreated on theme change, preventing sign-out bug
final _router = GoRouter(
  initialLocation: RouteConstants.splash,
  routes: [
    GoRoute(path: RouteConstants.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(path: RouteConstants.login,  builder: (_, __) => const LoginScreen()),
    ShellRoute(
      builder: (context, state, child) => AdminScaffold(child: child),
      routes: [
        GoRoute(path: RouteConstants.dashboard, builder: (_, __) => const DashboardScreen()),
        GoRoute(path: RouteConstants.search,    builder: (_, __) => const SearchScreen()),
        GoRoute(path: RouteConstants.employees, builder: (_, __) => const EmployeesScreen()),
        GoRoute(path: RouteConstants.approvals, builder: (_, __) => const ApprovalsScreen()),
        GoRoute(path: RouteConstants.profile,   builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    TextTheme poppins(TextTheme base) => GoogleFonts.poppinsTextTheme(base);

    final dark = ThemeData(
      useMaterial3: true, brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(primary: AppTheme.crimson, secondary: AppTheme.silver, surface: AppTheme.darkSurface, onPrimary: Colors.white, onSurface: Colors.white),
      scaffoldBackgroundColor: AppTheme.darkBg1,
    ).copyWith(textTheme: poppins(ThemeData.dark().textTheme));

    final light = ThemeData(
      useMaterial3: true, brightness: Brightness.light,
      colorScheme: const ColorScheme.light(primary: AppTheme.crimson, secondary: AppTheme.silverDark, surface: AppTheme.lightSurface, onPrimary: Colors.white, onSurface: AppTheme.lightText),
      scaffoldBackgroundColor: AppTheme.lightBg1,
    ).copyWith(textTheme: poppins(ThemeData.light().textTheme));

    return MaterialApp.router(
      title: 'AV & Company Admin Portal',
      theme: light,
      darkTheme: dark,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// ─── Shell with 5-tab bottom nav ─────────────────────────────────────────────
class AdminScaffold extends StatelessWidget {
  final Widget child;
  const AdminScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final loc = GoRouterState.of(context).uri.toString();

    int idx = 0;
    if (loc == RouteConstants.search)    idx = 1;
    if (loc == RouteConstants.employees) idx = 2;
    if (loc == RouteConstants.approvals) idx = 3;
    if (loc == RouteConstants.profile)   idx = 4;

    final navBg = isDark ? const Color(0xFF12121F) : AppTheme.lightSurface;
    final border = isDark ? Colors.white.withOpacity(0.08) : AppTheme.lightBorder;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: border)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        padding: const EdgeInsets.only(bottom: 8, top: 6),
        child: Row(children: [
          _NavItem(icon: Icons.grid_view_rounded,  label: 'DASHBOARD',  isActive: idx == 0, isDark: isDark, onTap: () => context.go(RouteConstants.dashboard)),
          _NavItem(icon: Icons.search_rounded,     label: 'SEARCH',     isActive: idx == 1, isDark: isDark, onTap: () => context.go(RouteConstants.search)),
          _NavItem(icon: Icons.people_rounded,     label: 'EMPLOYEES',  isActive: idx == 2, isDark: isDark, onTap: () => context.go(RouteConstants.employees)),
          Consumer<ApprovalProvider>(builder: (_, prov, __) =>
            _NavItem(icon: Icons.shield_rounded, label: 'APPROVALS', isActive: idx == 3, isDark: isDark,
                badge: prov.pendingCount > 0 ? '${prov.pendingCount}' : null,
                onTap: () => context.go(RouteConstants.approvals))),
          _NavItem(icon: Icons.person_rounded,     label: 'MY SPACE',   isActive: idx == 4, isDark: isDark, onTap: () => context.go(RouteConstants.profile)),
        ]),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool isActive;
  final bool isDark; final String? badge; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.isActive, required this.isDark, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppTheme.crimsonGlow : (isDark ? Colors.white38 : AppTheme.silverDark);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: isActive ? AppTheme.crimsonGlow.withOpacity(0.15) : Colors.transparent, borderRadius: BorderRadius.circular(20)),
              child: Icon(icon, color: color, size: 22),
            ),
            if (badge != null)
              Positioned(top: -2, right: 0, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: AppTheme.crimson, borderRadius: BorderRadius.circular(8)),
                child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
              )),
          ]),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.0)),
        ]),
      ),
    );
  }
}
