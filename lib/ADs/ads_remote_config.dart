import 'package:blocked/storage/storage.dart';
import 'package:flutter/foundation.dart';

void _log(String message) {
  if (kDebugMode) debugPrint('[AdsConfig] $message');
}

/// Local ad pacing / feature flags — fully offline, no Firebase.
///
/// Defaults match the previous production behavior. Values persist in Hive
/// so you can change them in-app later if needed.
class AdsRemoteConfig {
  AdsRemoteConfig._();
  static final AdsRemoteConfig instance = AdsRemoteConfig._();

  static const _keyAdsEnabled = 'ads_enabled';
  static const _keyBannerEnabled = 'banner_ads_enabled';
  static const _keyInterstitialEnabled = 'interstitial_ads_enabled';
  static const _keyInterstitialMinIntervalSeconds =
      'interstitial_min_interval_seconds';
  static const _keyInterstitialSkipFirst = 'interstitial_skip_first';

  /// Matches previous in-code interstitial pacing.
  static const defaultInterstitialMinIntervalSeconds = 60;

  static const Map<String, dynamic> _defaults = {
    _keyAdsEnabled: true,
    _keyBannerEnabled: true,
    _keyInterstitialEnabled: true,
    _keyInterstitialMinIntervalSeconds: defaultInterstitialMinIntervalSeconds,
    _keyInterstitialSkipFirst: true,
  };

  bool _ready = false;

  bool get isReady => _ready;

  bool get adsEnabled => _bool(_keyAdsEnabled, true);

  bool get bannerAdsEnabled => adsEnabled && _bool(_keyBannerEnabled, true);

  bool get interstitialAdsEnabled =>
      adsEnabled && _bool(_keyInterstitialEnabled, true);

  bool get interstitialSkipFirst => _bool(_keyInterstitialSkipFirst, true);

  Duration get interstitialMinInterval {
    final seconds = _int(
      _keyInterstitialMinIntervalSeconds,
      defaultInterstitialMinIntervalSeconds,
    );
    return Duration(seconds: seconds.clamp(0, 3600));
  }

  bool _bool(String key, bool fallback) {
    return getBool(key) ?? _defaults[key] as bool? ?? fallback;
  }

  int _int(String key, int fallback) {
    return getInt(key) ?? _defaults[key] as int? ?? fallback;
  }

  /// Safe to call repeatedly. Seeds Hive defaults on first launch.
  Future<void> ensureInitialized() async {
    if (_ready) return;

    await initLocalStorage();
    for (final entry in _defaults.entries) {
      if (!containsKey(entry.key)) {
        final value = entry.value;
        if (value is bool) {
          await setBool(entry.key, value);
        } else if (value is int) {
          await setInt(entry.key, value);
        }
      }
    }

    _ready = true;
    _log(
      'active: ads=$adsEnabled banner=$bannerAdsEnabled '
      'interstitial=$interstitialAdsEnabled '
      'gap=${interstitialMinInterval.inSeconds}s '
      'skipFirst=$interstitialSkipFirst',
    );
  }

  /// No-op — kept for API compatibility with AdManager.
  Future<void> refreshIfNeeded() async {}
}
