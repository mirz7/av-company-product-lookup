class AdminNotification {
  final int id;
  final String type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final int? relatedUserId;

  AdminNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
    this.relatedUserId,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    return AdminNotification(
      id: json['id'],
      type: json['notification_type'] ?? 'new_registration',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      relatedUserId: json['related_user'],
    );
  }
}
