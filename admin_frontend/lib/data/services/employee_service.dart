import 'dart:convert';
import '../models/employee_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class EmployeeService {
  Future<Map<String, String>> _headers() async {
    return {'Content-Type': 'application/json'};
  }

  Future<List<Employee>> getEmployees({String? search, String? status}) async {
    final headers = await _headers();
    var uri = Uri.parse(ApiConstants.employees);
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (params.isNotEmpty) uri = uri.replace(queryParameters: params);
    final response = await ApiClient.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Employee.fromJson(e)).toList();
    }
    throw Exception('Failed to load employees: ${response.statusCode}');
  }

  Future<void> updatePermissions(int id, Map<String, dynamic> data) async {
    final headers = await _headers();
    final r = await ApiClient.patch(Uri.parse('${ApiConstants.employees}$id/'), headers: headers, body: jsonEncode(data));
    if (r.statusCode != 200) throw Exception('Failed to update permissions');
  }

  Future<void> updateStatus(int id, bool isActive) async {
    final headers = await _headers();
    final r = await ApiClient.patch(Uri.parse('${ApiConstants.employees}$id/'), headers: headers, body: jsonEncode({'is_active': isActive}));
    if (r.statusCode != 200) throw Exception('Failed to update status');
  }

  Future<void> deleteEmployee(int id) async {
    final headers = await _headers();
    final r = await ApiClient.delete(Uri.parse('${ApiConstants.employees}$id/'), headers: headers);
    if (r.statusCode != 204 && r.statusCode != 200) throw Exception('Failed to delete');
  }
}
