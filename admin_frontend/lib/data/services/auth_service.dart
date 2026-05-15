import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/admin_model.dart';
import '../../core/constants/api_constants.dart';

class AuthService {
  Future<AdminModel> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['access'] ?? data['token'] ?? '';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      try {
        final userResp = await http.get(
          Uri.parse(ApiConstants.authMe),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (userResp.statusCode == 200) {
          return AdminModel.fromJson(jsonDecode(userResp.body), token);
        }
      } catch (_) {}
      return AdminModel.fromJson({'id': 0, 'username': username}, token);
    }
    throw Exception('Invalid credentials');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  Future<bool> isAdminSetupNeeded() async {
    final response = await http.get(Uri.parse(ApiConstants.setupCheck));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return !(data['admin_exists'] ?? true);
    }
    return false;
  }

  Future<void> registerAdmin(Map<String, String> data) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.setupRegister),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (response.statusCode == 201) return;
      
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      
      if (errorData.containsKey('error')) {
        throw Exception(errorData['error']);
      } else if (errorData.isNotEmpty) {
        // Handle validation errors like {'username': ['Enter a valid username...']}
        final firstError = errorData.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError.first.toString());
        }
        throw Exception(firstError.toString());
      }
      
      throw Exception('Registration failed. Please check your inputs.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Connection error. Please check if the server is running.');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.forgotPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200) return;
      
      final Map<String, dynamic> data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Failed to process request');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Server unreachable. Please try again later.');
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse(ApiConstants.resetPassword),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'password': newPassword,
      }),
    );
    return response.statusCode == 200;
  }
}
