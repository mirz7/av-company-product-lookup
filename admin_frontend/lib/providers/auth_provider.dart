import 'package:flutter/material.dart';
import '../data/models/admin_model.dart';
import '../data/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AdminModel? adminUser;
  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String username, String password) async {
    isLoading = true; errorMessage = null; notifyListeners();
    try {
      adminUser = await _authService.login(username, password);
      isLoading = false; notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Invalid username or password.';
      isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    adminUser = null;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final token = await _authService.getToken();
    if (token == null) return;
    try {
      adminUser = await _authService.getProfile(token);
      notifyListeners();
    } catch (_) {}
  }
}
