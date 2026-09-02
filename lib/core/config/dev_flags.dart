/// Developer / QA flags — edit here only. Never shown in the app UI.
///
/// Set [adsTestMode] to `false` and add production IDs in [BlockedAdsConfig]
/// before release.
abstract final class DevFlags {
  /// `true` → Google sample ad units. `false` → production IDs in ads_config.
  static const bool adsTestMode = false;

  /// When `true`, schedules [testNotificationCount] alerts on each cold start.
  /// All are OS-scheduled so they fire after the app is killed.
  static const bool fireTestNotificationsOnLaunch = false;

  static const int testNotificationCount = 5;

  /// Gap between test alerts. First fires after [testNotificationFirstDelay].
  static const Duration testNotificationFirstDelay = Duration(seconds: 10);
  static const Duration testNotificationInterval = Duration(seconds: 10);

  /// Daily 17:00 / 21:00 reminders (independent of test batch above).
  static const bool useDailyNotificationSchedule = true;
}
