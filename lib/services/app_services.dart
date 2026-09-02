import 'dart:async';

import 'package:blocked/services/analytics_service.dart';
import 'package:blocked/services/local_notification_service.dart';

/// App-wide service singletons — initialized from main.dart.
final analyticsService = AnalyticsService();

final localNotificationService = LocalNotificationService(
  onTap: (payload) {
    unawaited(
      analyticsService.logNotificationOpened(
        notificationId: payload,
        source: 'local',
      ),
    );
  },
);
