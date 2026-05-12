class DashboardMetrics {
  final int totalEmployees;
  final int pendingApprovals;
  final int totalProducts;
  final int activeSessions;

  DashboardMetrics({required this.totalEmployees, required this.pendingApprovals,
      required this.totalProducts, required this.activeSessions});

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) => DashboardMetrics(
    totalEmployees: json['total_employees'] ?? 0,
    pendingApprovals: json['pending_approvals'] ?? 0,
    totalProducts: json['total_products'] ?? 0,
    activeSessions: json['active_sessions'] ?? 0,
  );
}
