import 'package:flutter/foundation.dart';

/// Official Google sample units. Use only when [BlockedAdsConfig.testMode] is true.
abstract final class GoogleTestAdUnits {
  static const androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  static const androidBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const androidRewarded = 'ca-app-pub-3940256099942544/5224354917';

  static const iosBanner = 'ca-app-pub-3940256099942544/2934735716';
  static const iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const iosRewarded = 'ca-app-pub-3940256099942544/1712485313';
}

class BlockedAdsConfig {
  const BlockedAdsConfig({
    this.isEnabled = true,
    this.testMode = false,
    this.bannerEnabled = true,
    this.interstitialEnabled = true,
    this.rewardedEnabled = true,
    this.bannerAdUnits = productionBannerAdUnits,
    this.interstitialAdUnits = productionInterstitialAdUnits,
    this.rewardedAdUnits = productionRewardedAdUnits,
    this.bannerPlacements = const {
      'home': 0,
      'play': 1,
      'result': 2,
    },
    this.interstitialPlacements = const {
      'after_level': 0,
    },
    this.rewardedPlacements = const {
      'hint': 0,
      'auto_solve': 1,
    },
    this.minimumInterstitialInterval = const Duration(seconds: 60),
    this.maxRetries = 2,
    this.retryBackoff = const Duration(seconds: 30),
  });

  final bool isEnabled;
  final bool testMode;
  final bool bannerEnabled;
  final bool interstitialEnabled;
  final bool rewardedEnabled;

  final List<String> bannerAdUnits;
  final List<String> interstitialAdUnits;
  final List<String> rewardedAdUnits;

  final Map<String, int> bannerPlacements;
  final Map<String, int> interstitialPlacements;
  final Map<String, int> rewardedPlacements;

  final Duration minimumInterstitialInterval;
  final int maxRetries;
  final Duration retryBackoff;

  static const productionBannerAdUnits = [
    'ca-app-pub-6619866004331477/3145240294',
    'ca-app-pub-6619866004331477/5579831942',
    'ca-app-pub-6619866004331477/4266750273',
    'ca-app-pub-6619866004331477/5796338840',
    'ca-app-pub-6619866004331477/4441070744',
  ];

  static const productionInterstitialAdUnits = [
    'ca-app-pub-6619866004331477/4249499907',
    'ca-app-pub-6619866004331477/9401753383',
    'ca-app-pub-6619866004331477/1623335712',
    'ca-app-pub-6619866004331477/2762096914',
    'ca-app-pub-6619866004331477/6509770231',
  ];

  static const productionRewardedAdUnits = [
    'ca-app-pub-6619866004331477/7997127375',
    'ca-app-pub-6619866004331477/9544012160',
    'ca-app-pub-6619866004331477/5604767157',
    'ca-app-pub-6619866004331477/2553274001',
    'ca-app-pub-6619866004331477/3851817309',
  ];

  static const productionAppId = 'ca-app-pub-6619866004331477~6166919646';

  String? bannerUnitId(String placement) =>
      _unit(bannerAdUnits, bannerPlacements[placement], bannerEnabled);

  String? interstitialUnitId(String placement) => _unit(
        interstitialAdUnits,
        interstitialPlacements[placement],
        interstitialEnabled,
      );

  String? rewardedUnitId(String placement) =>
      _unit(rewardedAdUnits, rewardedPlacements[placement], rewardedEnabled);

  String? _unit(List<String> units, int? index, bool enabled) {
    if (!isEnabled || !enabled || index == null || index < 0) return null;
    if (testMode) return _testIdFor(units);
    if (index >= units.length) return null;
    final id = units[index].trim();
    return id.isEmpty ? null : id;
  }

  String _testIdFor(List<String> units) {
    if (identical(units, bannerAdUnits)) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? GoogleTestAdUnits.iosBanner
          : GoogleTestAdUnits.androidBanner;
    }
    if (identical(units, interstitialAdUnits)) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? GoogleTestAdUnits.iosInterstitial
          : GoogleTestAdUnits.androidInterstitial;
    }
    return defaultTargetPlatform == TargetPlatform.iOS
        ? GoogleTestAdUnits.iosRewarded
        : GoogleTestAdUnits.androidRewarded;
  }
}
