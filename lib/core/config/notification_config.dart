import 'package:blocked/core/config/dev_flags.dart';

class NotificationMessage {
  const NotificationMessage({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final String body;

  factory NotificationMessage.fromJson(Map<String, dynamic> json) {
    return NotificationMessage(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

enum NotificationRotationMode { alternate, sequential }

class NotificationConfig {
  const NotificationConfig({
    this.enabled = true,
    this.assetPath = 'assets/notifications/notifications.json',
    this.scheduleTimes = const ['17:00', '21:00'],
    this.rotationMode = NotificationRotationMode.alternate,
    this.daysToSchedule = 14,
    this.androidChannelId = 'daily_local',
    this.androidChannelName = 'Daily reminders',
  });

  final bool enabled;
  final String assetPath;
  final List<String> scheduleTimes;
  final NotificationRotationMode rotationMode;
  final int daysToSchedule;
  final String androidChannelId;
  final String androidChannelName;

  /// Respects [DevFlags.fireTestNotificationsOnLaunch] for QA batches.
  bool get scheduleTestBatchOnLaunch => DevFlags.fireTestNotificationsOnLaunch;

  bool get scheduleDailyOnLaunch => DevFlags.useDailyNotificationSchedule;
}
