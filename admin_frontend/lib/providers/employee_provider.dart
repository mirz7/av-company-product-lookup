import 'package:flutter/material.dart';
import '../data/models/employee_model.dart';
import '../data/services/employee_service.dart';

class EmployeeProvider extends ChangeNotifier {
  final EmployeeService _service = EmployeeService();
  List<Employee> employees = [];
  bool isLoading = false;
  String searchQuery = '';
  String statusFilter = '';
  String? errorMessage;

  Future<void> fetchEmployees() async {
    isLoading = true; errorMessage = null; notifyListeners();
    try {
      employees = await _service.getEmployees(search: searchQuery, status: statusFilter);
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  Future<bool> updatePermissions(int id, Map<String, dynamic> data) async {
    try {
      await _service.updatePermissions(id, data);
      await fetchEmployees();
      return true;
    } catch (e) {
      errorMessage = e.toString(); notifyListeners(); return false;
    }
  }

  Future<bool> updateStatus(int id, bool isActive) async {
    try {
      await _service.updateStatus(id, isActive);
      await fetchEmployees();
      return true;
    } catch (e) {
      errorMessage = e.toString(); notifyListeners(); return false;
    }
  }

  Future<bool> deleteEmployee(int id) async {
    try {
      await _service.deleteEmployee(id);
      await fetchEmployees();
      return true;
    } catch (e) {
      errorMessage = e.toString(); notifyListeners(); return false;
    }
  }
}
