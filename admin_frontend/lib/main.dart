import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/route_constants.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/employee_provider.dart';
import 'providers/approval_provider.dart';
import 'providers/product_provider.dart';
import 'providers/notification_provider.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/employees/employees_screen.dart';
import 'screens/approvals/approvals_screen.dart';
import 'screens/search/search_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/login/registration_screen.dart';
import 'screens/login/forgot_password_screen.dart';
import 'screens/login/reset_password_screen.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    // Initialize notifications for foreground tap handling
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload == 'new_registration') {
          _router.go(RouteConstants.approvals);
        }
      },
    );

    await initializeService();
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => ApprovalProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
    GoRoute(path: RouteConstants.register, builder: (_, __) => const AdminRegistrationScreen()),
    GoRoute(path: RouteConstants.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
    GoRoute(path: RouteConstants.resetPassword, builder: (_, state) => ResetPasswordScreen(initialEmail: state.uri.queryParameters['email'])),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AdminScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: RouteConstants.dashboard, pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()))]),
        StatefulShellBranch(routes: [GoRoute(path: RouteConstants.search,    pageBuilder: (context, state) => const NoTransitionPage(child: SearchScreen()))]),
        StatefulShellBranch(routes: [GoRoute(path: RouteConstants.employees, pageBuilder: (context, state) => const NoTransitionPage(child: EmployeesScreen()))]),
        StatefulShellBranch(routes: [GoRoute(path: RouteConstants.profile,   pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()))]),
      ],
    ),
    GoRoute(path: RouteConstants.approvals, builder: (context, state) => const ApprovalsScreen()),
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
      colorScheme: const ColorScheme.dark(
        primary: AppTheme.primary,
        secondary: AppTheme.accent,
        surface: AppTheme.darkSurface,
        onPrimary: Colors.white,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: AppTheme.darkBg1,
    ).copyWith(textTheme: poppins(ThemeData.dark().textTheme));

    final light = ThemeData(
      useMaterial3: true, brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppTheme.primary,
        secondary: AppTheme.accent,
        surface: AppTheme.lightSurface,
        onPrimary: Colors.white,
        onSurface: AppTheme.lightText,
      ),
      scaffoldBackgroundColor: AppTheme.lightBg1,
    ).copyWith(textTheme: poppins(ThemeData.light().textTheme));

    return MaterialApp.router(
      title: 'AV Admin Portal',
      theme: light,
      darkTheme: dark,
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// ─── Shell with 4-tab bottom nav (matching Stitch design) ──────────────────
class AdminScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AdminScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    int idx = navigationShell.currentIndex;

    final navBg = isDark ? const Color(0xFF161622) : AppTheme.lightSurface;
    final border = isDark ? Colors.white.withOpacity(0.06) : AppTheme.lightBorder;

    final dashboard = context.watch<DashboardProvider>();
    final pendingCount = dashboard.metrics?.pendingApprovals ?? 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(top: BorderSide(color: border)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.5 : 0.08), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(icon: Icons.dashboard_rounded,    label: 'Dashboard',  isActive: idx == 0, isDark: isDark, onTap: () => navigationShell.goBranch(0)),
                _NavItem(icon: Icons.search_rounded,       label: 'Search',     isActive: idx == 1, isDark: isDark, onTap: () => navigationShell.goBranch(1)),
                _NavItem(icon: Icons.groups_rounded,       label: 'Employees',  isActive: idx == 2, isDark: isDark, badge: pendingCount > 0 ? '$pendingCount' : null, onTap: () => navigationShell.goBranch(2)),
                _NavItem(icon: Icons.person_rounded,       label: 'My Space',   isActive: idx == 3, isDark: isDark, onTap: () => navigationShell.goBranch(3)),
              ],
            ),
          ),
        ),
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
    final color = isActive ? AppTheme.primary : (isDark ? Colors.white38 : AppTheme.silverDark);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primary.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (badge != null)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.danger,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF161622) : AppTheme.lightSurface, width: 1.5),
                      ),
                      child: Text(
                        badge!,
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
