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
          Uri.parse('${ApiConstants.baseUrl}/auth/me/'),
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
}
