// Stub file to prevent 'dart:html' errors on mobile
class Notification {
  static String permission = 'denied';
  static void requestPermission() {}
  
  Notification(String title, {String? body});
}
