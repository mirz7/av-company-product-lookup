import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Note: Background service runs in a separate isolate. 
// It doesn't share memory with the main app.

Future<void> initializeService() async {
  final service = FlutterBackgroundService();

  // Android-specific configuration
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'registration_alerts', // id
    'Staff Registration Alerts', // title
    description: 'Notifications for new staff registrations.', // description
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: false,
      notificationChannelId: 'registration_alerts',
      initialNotificationTitle: 'AV Admin Portal',
      initialNotificationContent: 'Ready for alerts',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(), // Not implemented for this project yet
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // For flutter_background_service >= 5.0.0
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // MUST initialize inside onStart for background notifications to work visually
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Poll every 1 minute
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    try {
      // Fetch specific unread notifications for better alerts
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) return;

      final response = await http.get(
        Uri.parse('http://192.168.0.138:8000/api/admin/notifications/?is_read=false'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> unreadNotifs = json.decode(response.body);
        if (unreadNotifs.isEmpty) return;

        final lastShownId = prefs.getInt('last_shown_notification_id') ?? 0;
        
        // Find the latest notification that hasn't been shown yet
        final latest = unreadNotifs.first; // Django returns -timestamp (newest first)
        final int latestId = latest['id'];

        if (latestId > lastShownId) {
          // Show the notification with real details
          flutterLocalNotificationsPlugin.show(
            latestId,
            latest['title'] ?? 'New Admin Alert',
            latest['message'] ?? 'A new staff member is awaiting approval.',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'registration_alerts',
                'Staff Registration Alerts',
                channelDescription: 'Notifications for new staff registrations.',
                importance: Importance.max,
                priority: Priority.high,
                ticker: 'ticker',
                icon: 'ic_notification',
                largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
                ongoing: false,
                styleInformation: BigTextStyleInformation(''),
              ),
            ),
            payload: latest['notification_type'] ?? 'general',
          );
          
          await prefs.setInt('last_shown_notification_id', latestId);
        }
      }
    } catch (e) {
      print('Background fetch error: $e');
    }
  });
}
