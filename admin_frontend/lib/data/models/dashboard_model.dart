class ActivityItem {
  final int id;
  final String type;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  ActivityItem({required this.id, required this.type, required this.title,
      required this.subtitle, required this.timestamp});

  factory ActivityItem.fromJson(Map<String, dynamic> json) => ActivityItem(
    id: json['id'] ?? 0,
    type: json['type'] ?? '',
    title: json['title'] ?? '',
    subtitle: json['subtitle'] ?? '',
    timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
  );
}

class DashboardMetrics {
  final int totalEmployees;
  final int pendingApprovals;
  final int totalProducts;
  final int activeSessions;
  final List<ActivityItem> recentActivity;

  DashboardMetrics({required this.totalEmployees, required this.pendingApprovals,
      required this.totalProducts, required this.activeSessions,
      required this.recentActivity});

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) => DashboardMetrics(
    totalEmployees: json['total_employees'] ?? 0,
    pendingApprovals: json['pending_approvals'] ?? 0,
    totalProducts: json['total_products'] ?? 0,
    activeSessions: json['active_sessions'] ?? 0,
    recentActivity: (json['recent_activity'] as List? ?? [])
        .map((e) => ActivityItem.fromJson(e))
        .toList(),
  );
}
