class Employee {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String jobRole;
  final bool isActive;
  final bool priceBAccess;
  final bool priceCAccess;
  final String permissionLevel;

  Employee({required this.id, required this.username, required this.email,
      required this.fullName, required this.jobRole, required this.isActive,
      required this.priceBAccess, required this.priceCAccess, required this.permissionLevel});

  factory Employee.fromJson(Map<String, dynamic> json) {
    final level = json['permission_level']?.toString() ?? 'standard';
    final fn = '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim();
    return Employee(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: fn.isNotEmpty ? fn : json['username'] ?? '',
      jobRole: json['job_role'] ?? json['role'] ?? 'Staff',
      isActive: json['is_active'] ?? false,
      priceBAccess: level == 'discount' || level == 'wholesale' || (json['price_b_access'] ?? false),
      priceCAccess: level == 'wholesale' || (json['price_c_access'] ?? false),
      permissionLevel: level,
    );
  }
}
