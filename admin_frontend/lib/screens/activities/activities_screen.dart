import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/dashboard_provider.dart';
import '../../data/models/dashboard_model.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchAllActivities(
        refresh: true,
        activityType: _selectedFilter,
        search: _searchQuery,
      );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final prov = Provider.of<DashboardProvider>(context, listen: false);
      if (!prov.isActivitiesLoading && prov.hasMoreActivities) {
        prov.fetchAllActivities(
          activityType: _selectedFilter,
          search: _searchQuery,
        );
      }
    }
  }

  void _onSearchQueryChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query;
      });
      Provider.of<DashboardProvider>(context, listen: false).fetchAllActivities(
        refresh: true,
        activityType: _selectedFilter,
        search: query,
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDark;
    final prov = context.watch<DashboardProvider>();

    final bg = isDark
        ? [AppTheme.darkBg1, AppTheme.darkBg2, const Color(0xFF2D1010)]
        : [AppTheme.lightBg1, AppTheme.lightBg2, const Color(0xFFCFBBAA)];
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final sub = isDark ? Colors.white54 : AppTheme.lightSubText;
    final card = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.8);
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.lightBorder;

    final filteredActivities = prov.allActivities;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF2D1010) : const Color(0xFFCFBBAA),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: bg,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Activity Ledger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.5)),
                          const SizedBox(height: 1),
                          Text('Complete system audit logs', style: TextStyle(fontSize: 11, color: sub, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text('AUDIT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryGlow, letterSpacing: 1.5)),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: isDark ? Colors.black26 : AppTheme.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search audit logs...',
                          hintStyle: TextStyle(color: sub.withValues(alpha: 0.5), fontSize: 14),
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primary, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppTheme.primary, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchQueryChanged('');
                                },
                              )
                            : null,
                          filled: true,
                          fillColor: card,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: border)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: _onSearchQueryChanged,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Filters Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _filterChip('all', 'All Logs', isDark),
                    const SizedBox(width: 8),
                    _filterChip('access', 'Security & Access', isDark),
                    const SizedBox(width: 8),
                    _filterChip('employee', 'Employee Ops', isDark),
                    const SizedBox(width: 8),
                    _filterChip('inventory', 'Inventory & System', isDark),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Activities List
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primary,
                  onRefresh: () => prov.fetchAllActivities(
                    refresh: true,
                    activityType: _selectedFilter,
                    search: _searchQuery,
                  ),
                  child: filteredActivities.isEmpty && !prov.isActivitiesLoading
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.event_note_outlined, color: sub, size: 48),
                                  const SizedBox(height: 16),
                                  Text('No matching activities found', style: TextStyle(fontSize: 14, color: sub, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : (filteredActivities.isEmpty && prov.isActivitiesLoading)
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              itemCount: filteredActivities.length + (prov.hasMoreActivities ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == filteredActivities.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Center(
                                      child: CircularProgressIndicator(color: AppTheme.primary),
                                    ),
                                  );
                                }
                                final item = filteredActivities[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _activityItem(
                                    _iconForType(item.type),
                                    item.title,
                                    item.subtitle.isNotEmpty ? item.subtitle : _relativeTime(item.timestamp),
                                    card,
                                    border,
                                    textColor,
                                    sub,
                                    index,
                                    isDark,
                                    timeLabel: _relativeTime(item.timestamp),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String filter, String label, bool isDark) {
    final isSelected = _selectedFilter == filter;
    final activeColor = isSelected ? AppTheme.primary : (isDark ? Colors.white12 : Colors.black12);
    final textCol = isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.lightText);

    return GestureDetector(
      onTap: () {
        if (_selectedFilter == filter) return;
        setState(() {
          _selectedFilter = filter;
        });
        Provider.of<DashboardProvider>(context, listen: false).fetchAllActivities(
          refresh: true,
          activityType: filter,
          search: _searchQuery,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: activeColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: textCol),
        ),
      ),
    );
  }

  Widget _activityItem(
    IconData icon,
    String title,
    String sub2,
    Color card,
    Color border,
    Color textColor,
    Color sub,
    int index,
    bool isDark, {
    String? timeLabel,
  }) {
    // Only animate the first visible chunk to avoid weird scrolling jumps
    final animationDelay = index < 15 ? (40 * index).ms : 0.ms;

    Widget cardWidget = ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryGlow, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                    const SizedBox(height: 3),
                    Text(sub2, style: TextStyle(fontSize: 11, color: sub)),
                  ],
                ),
              ),
              if (timeLabel != null)
                Text(timeLabel, style: TextStyle(fontSize: 10, color: sub, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );

    if (index < 15) {
      return cardWidget.animate().fadeIn(delay: animationDelay).slideY(begin: 0.05);
    }
    return cardWidget;
  }
}
