import 'package:flutter/material.dart';
import '../data/models/dashboard_model.dart';
import '../data/services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();
  DashboardMetrics? metrics;
  bool isLoading = false;
  String? errorMessage;

  Future<void> fetchMetrics() async {
    isLoading = true; errorMessage = null; notifyListeners();
    try {
      metrics = await _service.getMetrics();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false; notifyListeners();
    }
  }
}
