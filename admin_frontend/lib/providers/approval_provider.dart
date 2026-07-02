import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/models/employee_model.dart';
import '../data/services/auth_service.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class ApprovalProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  List<Employee> _pendingApprovals = [];
  bool isLoading = false;
  String? errorMessage;

  List<Employee> get pendingApprovals => _pendingApprovals;
  int get pendingCount => _pendingApprovals.length;



  Future<void> fetchApprovals() async {
    isLoading = true; errorMessage = null; notifyListeners();
    try {
      final response = await ApiClient.get(Uri.parse(ApiConstants.approvals));
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
    await ApiClient.post(
      Uri.parse('${ApiConstants.approvals}$id/approve/'),
    );
    _pendingApprovals.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> rejectEmployee(int id) async {
    await ApiClient.post(
      Uri.parse('${ApiConstants.approvals}$id/reject/'),
    );
    _pendingApprovals.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
