import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

void _log(String message) {
  if (kDebugMode) debugPrint('[AdsRC] $message');
}

/// Firebase Remote Config values that gate / pace ads.
///
/// Defaults match the previous hardcoded production behavior so a missing
/// Firebase project, offline first launch, or failed fetch still behaves
/// exactly like before.
///
/// The Remote Config SDK already persists the last activated values on disk.
/// A 12-hour minimum fetch interval keeps read quota low.
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

  FirebaseRemoteConfig? _rc;
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
    final rc = _rc;
    if (rc == null) return fallback;
    try {
      return rc.getBool(key);
    } catch (_) {
      return fallback;
    }
  }

  int _int(String key, int fallback) {
    final rc = _rc;
    if (rc == null) return fallback;
    try {
      return rc.getInt(key);
    } catch (_) {
      return fallback;
    }
  }

  /// Safe to call repeatedly. Uses in-code defaults when Firebase is absent.
  Future<void> ensureInitialized() async {
    if (_ready && _rc != null) {
      await refreshIfNeeded();
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Production: at most one network fetch per 12 hours per install.
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 12),
        ),
      );
      await rc.setDefaults(_defaults);
      // Activate last-on-disk values immediately (works offline after first fetch).
      await rc.activate();
      _rc = rc;
      _ready = true;
      _log(
        'active: ads=$adsEnabled banner=$bannerAdsEnabled '
        'interstitial=$interstitialAdsEnabled '
        'gap=${interstitialMinInterval.inSeconds}s '
        'skipFirst=$interstitialSkipFirst',
      );
      await refreshIfNeeded();
    } catch (e) {
      _rc = null;
      _ready = true; // defaults-only mode
      _log('using in-code defaults (Firebase unavailable): $e');
    }
  }

  /// Fetches from the network only when the minimum interval allows it.
  Future<void> refreshIfNeeded() async {
    final rc = _rc;
    if (rc == null) return;
    try {
      final updated = await rc.fetchAndActivate();
      if (updated) {
        _log(
          'fetched: ads=$adsEnabled banner=$bannerAdsEnabled '
          'interstitial=$interstitialAdsEnabled '
          'gap=${interstitialMinInterval.inSeconds}s '
          'skipFirst=$interstitialSkipFirst',
        );
      }
    } catch (e) {
      _log('fetch skipped/failed (using cache/defaults): $e');
    }
  }
}
