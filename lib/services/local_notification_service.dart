import 'dart:convert';

import 'package:blocked/core/config/dev_flags.dart';
import 'package:blocked/core/config/notification_config.dart';
import 'package:blocked/storage/storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

typedef NotificationTapCallback = void Function(String? payload);

/// Fully offline local notifications. Idempotent. Device-local timezone.
class LocalNotificationService {
  LocalNotificationService({
    NotificationConfig config = const NotificationConfig(),
    FlutterLocalNotificationsPlugin? plugin,
    this.onTap,
  })  : _config = config,
        _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _fingerprintKey = 'local_notification_fingerprint_v1';

  final NotificationConfig _config;
  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationTapCallback? onTap;

  bool _initialized = false;

  Future<void> init() async {
    if (!_config.enabled || _initialized) return;
    try {
      await initLocalStorage();
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(await _localTimezoneName()));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: (response) {
          onTap?.call(response.payload);
        },
      );
      _initialized = true;
    } catch (error, stack) {
      debugPrint('LocalNotificationService.init failed: $error\n$stack');
    }
  }

  Future<bool> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final androidOk = await android?.requestNotificationsPermission() ?? true;
      final iosOk =
          await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
              true;
      return androidOk && iosOk;
    } catch (error, stack) {
      debugPrint('Notification permission failed: $error\n$stack');
      return false;
    }
  }

  /// Safe to call on every launch. Does not create duplicates.
  Future<int> bootstrapScheduledNotifications() async {
    if (!_config.enabled) return 0;
    var total = 0;
    if (_config.scheduleDailyOnLaunch) {
      total += await scheduleNotifications();
    }
    if (_config.scheduleTestBatchOnLaunch) {
      total += await scheduleTestNotifications();
    }
    return total;
  }

  /// Daily schedule must not wipe OS test alerts (IDs 9001+).
  Future<int> scheduleNotifications() async {
    if (!_config.enabled) return 0;
    await init();
    if (!_initialized) return 0;

    final allowed = await requestPermission();
    if (!allowed) return 0;

    try {
      final messages = await _loadMessages();
      if (messages.isEmpty) return 0;

      final fingerprint = await _fingerprint(messages);
      if (getString(_fingerprintKey) == fingerprint) {
        final pending = await _plugin.pendingNotificationRequests();
        final dailyPending = pending.where((p) => p.id < 9001).length;
        if (dailyPending > 0) return dailyPending;
      }

      for (final request in await _plugin.pendingNotificationRequests()) {
        if (request.id < 9001) {
          await _plugin.cancel(id: request.id);
        }
      }
      final count = await _scheduleUpcoming(messages);
      await setString(_fingerprintKey, fingerprint);
      return count;
    } catch (error, stack) {
      debugPrint('scheduleNotifications failed: $error\n$stack');
      return 0;
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      await remove(_fingerprintKey);
    } catch (error, stack) {
      debugPrint('cancelAll notifications failed: $error\n$stack');
    }
  }

  /// OS-scheduled test batch — survives app kill. IDs 9001+.
  Future<int> scheduleTestNotifications({
    int count = DevFlags.testNotificationCount,
    Duration firstDelay = DevFlags.testNotificationFirstDelay,
    Duration interval = DevFlags.testNotificationInterval,
  }) async {
    await init();
    if (!_initialized) return 0;

    final allowed = await requestPermission();
    if (!allowed) return 0;

    try {
      final messages = await _loadMessages();
      if (messages.isEmpty) return 0;

      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          '${_config.androidChannelId}_test',
          'Test reminders',
          channelDescription: 'Short test notifications for QA',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

      for (var i = 0; i < count; i++) {
        await _plugin.cancel(id: 9001 + i);
      }

      final now = tz.TZDateTime.now(tz.local);
      var scheduled = 0;
      for (var i = 0; i < count; i++) {
        final message = messages[i % messages.length];
        final id = 9001 + i;
        final fire = now.add(firstDelay + interval * i);
        await _plugin.zonedSchedule(
          id: id,
          title: 'Test ${i + 1}/$count — ${message.title}',
          body: message.body,
          scheduledDate: fire,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'test_${message.id}',
        );
        scheduled++;
      }

      debugPrint(
        '[Notifications] $scheduled test alerts OS-scheduled — first in '
        '${firstDelay.inSeconds}s, every ${interval.inSeconds}s (kill app OK)',
      );
      return scheduled;
    } catch (error, stack) {
      debugPrint('scheduleTestNotifications failed: $error\n$stack');
      return 0;
    }
  }

  Future<List<NotificationMessage>> _loadMessages() async {
    final raw = await rootBundle.loadString(_config.assetPath);
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final list = decoded['notifications'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(NotificationMessage.fromJson)
        .where((m) => m.id.isNotEmpty && m.title.isNotEmpty)
        .toList();
  }

  Future<int> _scheduleUpcoming(List<NotificationMessage> messages) async {
    var scheduled = 0;
    final now = tz.TZDateTime.now(tz.local);
    for (var day = 0; day < _config.daysToSchedule; day++) {
      final time = _timeForDay(day);
      if (time == null) continue;
      var fire = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      ).add(Duration(days: day));
      if (!fire.isAfter(now)) continue;
      final message = messages[day % messages.length];
      await _plugin.zonedSchedule(
        id: day + 1,
        title: message.title,
        body: message.body,
        scheduledDate: fire,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _config.androidChannelId,
            _config.androidChannelName,
            channelDescription: 'Daily puzzle reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: message.id,
      );
      scheduled++;
    }
    return scheduled;
  }

  ({int hour, int minute})? _timeForDay(int dayIndex) {
    final times = _config.scheduleTimes;
    if (times.isEmpty) return null;
    final token = _config.rotationMode == NotificationRotationMode.alternate
        ? times[dayIndex % times.length]
        : times[0];
    final parts = token.split(':');
    if (parts.length != 2) return null;
    return (hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<String> _localTimezoneName() async {
    final value = await FlutterTimezone.getLocalTimezone();
    return value.identifier;
  }

  Future<String> _fingerprint(List<NotificationMessage> messages) async {
    final payload = jsonEncode({
      'tz': await _localTimezoneName(),
      'times': _config.scheduleTimes,
      'mode': _config.rotationMode.name,
      'days': _config.daysToSchedule,
      'messages': messages
          .map((m) => {'id': m.id, 'title': m.title, 'body': m.body})
          .toList(),
    });
    return payload;
  }
}
