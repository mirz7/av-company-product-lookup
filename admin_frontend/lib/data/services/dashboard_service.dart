import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_model.dart';
import 'auth_service.dart';
import '../../core/constants/api_constants.dart';

class DashboardService {
  final AuthService _auth = AuthService();

  Future<DashboardMetrics> getMetrics() async {
    final token = await _auth.getToken();
    final response = await http.get(
      Uri.parse(ApiConstants.dashboard),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return DashboardMetrics.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load dashboard: ${response.statusCode}');
  }
}
