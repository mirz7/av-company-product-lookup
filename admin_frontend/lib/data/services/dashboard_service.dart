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

  Future<Map<String, dynamic>> getActivities({int page = 1, String activityType = '', String search = ''}) async {
    final response = await ApiClient.get(
      Uri.parse('${ApiConstants.activities}?page=$page&type=$activityType&search=${Uri.encodeComponent(search)}'),
    );
    if (response.statusCode == 200) {
      final Map<String, dynamic> decoded = jsonDecode(response.body);
      final List results = decoded['results'] ?? [];
      final List<ActivityItem> items = results.map((e) => ActivityItem.fromJson(e)).toList();
      return {
        'count': decoded['count'] ?? 0,
        'next': decoded['next'] != null,
        'results': items,
      };
    }
    throw Exception('Failed to load activities: ${response.statusCode}');
  }
}
