import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String baseUrl =
      kIsWeb ? 'http://127.0.0.1:8000/api' : 'http://192.168.0.108:8000/api';
  static const String login = '$baseUrl/token/';
  static const String authMe = '$baseUrl/auth/me/';
  static const String dashboard = '$baseUrl/admin/dashboard/';
  static const String employees = '$baseUrl/admin/employees/';
  static const String approvals = '$baseUrl/admin/approvals/';
  static const String products = '$baseUrl/products/';
  static const String setupCheck = '$baseUrl/admin/setup/check/';
  static const String setupRegister = '$baseUrl/admin/setup/register/';
  static const String forgotPassword = '$baseUrl/auth/forgot-password/';
  static const String resetPassword = '$baseUrl/auth/reset-password/';
  static const String changePassword = '$baseUrl/admin/change-password/';
  static const String health = '$baseUrl/admin/health/';
}
