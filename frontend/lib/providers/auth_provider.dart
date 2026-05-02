import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final success = await _apiService.login(username, password);

    if (!success) {
      _errorMessage = 'Invalid username or password.';
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> register(String name, String username, String role, String password, String phone, String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final success = await _apiService.register(name, username, role, password, phone, email);

    if (!success) {
      _errorMessage = 'Registration failed. Username may already exist.';
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
