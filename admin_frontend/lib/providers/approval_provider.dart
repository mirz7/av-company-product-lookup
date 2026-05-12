import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/models/employee_model.dart';
import '../data/services/auth_service.dart';
import '../core/constants/api_constants.dart';

class ApprovalProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  List<Employee> _pendingApprovals = [];
  bool isLoading = false;
  String? errorMessage;

  List<Employee> get pendingApprovals => _pendingApprovals;
  int get pendingCount => _pendingApprovals.length;

  Future<Map<String, String>> _headers() async {
    final token = await _auth.getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  Future<void> fetchApprovals() async {
    isLoading = true; errorMessage = null; notifyListeners();
    try {
      final headers = await _headers();
      final response = await http.get(Uri.parse(ApiConstants.approvals), headers: headers);
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _pendingApprovals = data.map((e) => Employee.fromJson(e)).toList();
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  Future<void> approveEmployee(int id) async {
    final headers = await _headers();
    await http.patch(Uri.parse('${ApiConstants.employees}$id/'),
        headers: headers, body: jsonEncode({'is_active': true}));
    _pendingApprovals.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> rejectEmployee(int id) async {
    final headers = await _headers();
    await http.delete(Uri.parse('${ApiConstants.employees}$id/'), headers: headers);
    _pendingApprovals.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
