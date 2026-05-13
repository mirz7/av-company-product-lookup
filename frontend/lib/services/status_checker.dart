import 'package:flutter/material.dart';
import '../main.dart';
import 'api_service.dart';

class StatusChecker {
  static final ApiService _api = ApiService();

  /// Checks the current user status with the server and redirects if they are restricted or deleted.
  static Future<void> checkAndRedirect() async {
    final profile = await _api.getProfile(forceRefresh: true);
    
    // If profile is null, getProfile already called logout() if it was a 401/403.
    // We just need to ensure the UI follows.
    if (profile == null) {
      final context = StaffApp.navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
      return;
    }

    if (profile['is_active'] == false) {
      final context = StaffApp.navigatorKey.currentContext;
      if (context != null) {
        // Only redirect if not already on restricted screen
        bool isRestrictedScreen = false;
        Navigator.popUntil(context, (route) {
          if (route.settings.name == '/restricted') isRestrictedScreen = true;
          return true;
        });
        
        if (!isRestrictedScreen) {
          Navigator.of(context).pushNamedAndRemoveUntil('/restricted', (route) => false);
        }
      }
    }
  }
}
