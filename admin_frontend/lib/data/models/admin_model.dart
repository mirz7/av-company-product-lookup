class AdminModel {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String fullName;
  final bool isStaff;
  final bool isAdmin;
  final String token;

  AdminModel({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.fullName,
    required this.isStaff,
    required this.isAdmin,
    required this.token,
  });

  factory AdminModel.fromJson(Map<String, dynamic> json, String token) => AdminModel(
    id: json['id'] ?? 0,
    username: json['username'] ?? '',
    email: json['email'] ?? '',
    firstName: json['first_name'] ?? '',
    lastName: json['last_name'] ?? '',
    phoneNumber: json['phone_number'] ?? '',
    fullName: '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
    isStaff: json['is_staff'] ?? false,
    isAdmin: json['is_superuser'] ?? false,
    token: token,
  );
}
