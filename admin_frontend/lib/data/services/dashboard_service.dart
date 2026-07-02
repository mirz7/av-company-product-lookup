import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/dashboard_model.dart';
import 'auth_service.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class DashboardService {

  Future<DashboardMetrics> getMetrics() async {
    final response = await ApiClient.get(
      Uri.parse(ApiConstants.dashboard),
    );
    if (response.statusCode == 200) {
      return DashboardMetrics.fromJson(jsonDecode(response.body));
    }
    throw Exception('Failed to load dashboard: ${response.statusCode}');
  }
}
