import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/dashboard_model.dart';
import '../data/services/dashboard_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import to prevent crashes on mobile
import 'dart:html' if (dart.library.io) 'package:admin_frontend/core/utils/html_stub.dart' as html;

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  DashboardMetrics? metrics;
  List<ActivityItem> allActivities = [];
  int _lastPendingCount = 0;
  bool isLoading = false;
  bool isActivitiesLoading = false;
  String? errorMessage;
  Timer? _pollTimer;

  Future<void> fetchMetrics() async {
    isLoading = true; errorMessage = null; notifyListeners();
    try {
      metrics = await _service.getMetrics();
      _checkNewApprovals();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false; notifyListeners();
    }
  }

  int _currentActivitiesPage = 1;
  bool hasMoreActivities = true;

  Future<void> fetchAllActivities({
    bool refresh = false,
    String activityType = '',
    String search = '',
  }) async {
    if (refresh) {
      _currentActivitiesPage = 1;
      allActivities = [];
      hasMoreActivities = true;
    }
    if (!hasMoreActivities) return;
    isActivitiesLoading = true; errorMessage = null; notifyListeners();
    try {
      final result = await _service.getActivities(
        page: _currentActivitiesPage,
        activityType: activityType,
        search: search,
      );
      final List<ActivityItem> newItems = result['results'];
      
      if (refresh) {
        allActivities = newItems;
      } else {
        allActivities.addAll(newItems);
      }
      
      hasMoreActivities = result['next'];
      if (hasMoreActivities) {
        _currentActivitiesPage++;
      }
    } catch (e) {
      errorMessage = e.toString();
      hasMoreActivities = false;
    } finally {
      isActivitiesLoading = false; notifyListeners();
    }
  }

  void _checkNewApprovals() {
    if (metrics == null) return;
    final currentCount = metrics!.pendingApprovals;
    
    if (currentCount > _lastPendingCount) {
      _playNotificationSound();
      _showBrowserNotification(currentCount - _lastPendingCount);
    }
    _lastPendingCount = currentCount;
  }

  void _playNotificationSound() async {
    try {
      // Clean "Ping" notification sound
      await _audioPlayer.play(UrlSource('https://assets.mixkit.co/active_storage/sfx/2358/2358-preview.mp3'));
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }

  void _showBrowserNotification(int newCount) {
    if (kIsWeb && html.Notification.permission == 'granted') {
      html.Notification(
        'New Staff Registration',
        body: '$newCount new staff member(s) awaiting approval.',
      );
    }
  }

  void requestNotificationPermission() {
    if (kIsWeb && html.Notification.permission != 'granted') {
      html.Notification.requestPermission();
    }
  }

  /// Starts a 30-second polling loop to keep Active Sessions current.
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final fresh = await _service.getMetrics();
        metrics = fresh;
        _checkNewApprovals();
        notifyListeners();
      } catch (_) {}
    });
  }

  void stopPolling() => _pollTimer?.cancel();

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
