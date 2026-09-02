import 'dart:async';

import 'package:blocked/ADs/ads_remote_config.dart';
import 'package:blocked/ADs/network_status.dart';
import 'package:blocked/core/config/ads_config.dart';
import 'package:blocked/core/config/dev_flags.dart';
import 'package:blocked/services/app_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardPlacement { hint, autoSolve }

extension RewardPlacementConfig on RewardPlacement {
  String get configName =>
      this == RewardPlacement.hint ? 'hint' : 'auto_solve';
}

enum RewardShowResult { notReady, shown }

void _log(String message) {
  if (kDebugMode) debugPrint('[Ads] $message');
}

/// Central AdMob manager — banner, interstitial, rewarded (hint / skip).
///
/// Uses production AdMob unit IDs in all builds.
///
/// Rules this class enforces, in order of importance:
///
/// * **Never touch AdMob while offline.** Loading with no connection is the
///   main source of retry storms, ANRs and load timeouts.
/// * **Never dispose a [BannerAd] in the frame its `AdWidget` is detached.**
///   The Android platform view can still be attached, which crashes the SDK.
///   Every banner is retired through [_disposeBannerLater].
/// * **Never show a full screen ad while the app is backgrounded**, and pace
///   interstitials so gameplay is not interrupted back to back.
/// * Banners use anchored adaptive sizes so they span the full screen width
///   instead of leaving dead space around a fixed 320x50 slot.
///
/// Call [bootstrap] only after the first Flutter frame.
class AdManager with WidgetsBindingObserver {
  factory AdManager() => _instance;
  AdManager._();
  static final AdManager _instance = AdManager._();

  static const _adsConfigDefaults = BlockedAdsConfig(testMode: false);

  BlockedAdsConfig get _adsConfig => BlockedAdsConfig(
        testMode: DevFlags.adsTestMode,
        bannerAdUnits: BlockedAdsConfig.productionBannerAdUnits,
        interstitialAdUnits: BlockedAdsConfig.productionInterstitialAdUnits,
        rewardedAdUnits: BlockedAdsConfig.productionRewardedAdUnits,
        minimumInterstitialInterval:
            _adsConfigDefaults.minimumInterstitialInterval,
        maxRetries: _adsConfigDefaults.maxRetries,
        retryBackoff: _adsConfigDefaults.retryBackoff,
      );

  AdsRemoteConfig get _rc => AdsRemoteConfig.instance;

  final ValueNotifier<BannerAd?> bannerAdNotifier =
      ValueNotifier<BannerAd?>(null);

  /// Separate banner for gameplay (AdWidget can only host one BannerAd each).
  final ValueNotifier<BannerAd?> playBannerAdNotifier =
      ValueNotifier<BannerAd?>(null);

  BannerAd? _bannerAd;
  BannerAd? _playBannerAd;
  InterstitialAd? _interstitialAd;
  final Map<RewardPlacement, RewardedAd?> _rewardedAds = {
    RewardPlacement.hint: null,
    RewardPlacement.autoSolve: null,
  };

  int _bannerRetryCount = 0;
  int _playBannerRetryCount = 0;
  int _interstitialRetryCount = 0;
  final Map<RewardPlacement, int> _rewardRetryCount = {
    RewardPlacement.hint: 0,
    RewardPlacement.autoSolve: 0,
  };

  int _bannerLoadGen = 0;
  int _playBannerLoadGen = 0;

  bool _sdkReady = false;
  bool _didBootstrap = false;
  /// Shared in-flight bootstrap — callers must await this instead of spinning
  /// when the SDK is not ready yet (prevents microtask storms on Play tap).
  Future<void>? _activeBootstrap;
  bool _bannerLoading = false;
  bool _playBannerLoading = false;
  bool _interstitialLoading = false;
  bool _lifecycleAttached = false;
  bool _isForeground = true;
  bool _consentResolved = false;
  bool _canRequestAds = true;

  final Map<RewardPlacement, bool> _rewardLoading = {
    RewardPlacement.hint: false,
    RewardPlacement.autoSolve: false,
  };
  final Map<RewardPlacement, Completer<void>?> _rewardReady = {
    RewardPlacement.hint: null,
    RewardPlacement.autoSolve: null,
  };

  /// Shared cooldown after no-fill / throttle — blocks all rewarded loads.
  DateTime? _rewardCooldownUntil;

  DateTime? _lastInterstitialAt;
  int _interstitialOpportunities = 0;

  /// When set, all AdMob loads/init are paused (offline / network errors).
  DateTime? _offlineUntil;
  bool _offlineRetryScheduled = false;

  bool get _isOfflinePaused =>
      _offlineUntil != null && DateTime.now().isBefore(_offlineUntil!);

  /// True while banner ads may be shown — UI keeps ad space at zero height
  /// when this is false.
  bool get adsAvailable =>
      _rc.bannerAdsEnabled &&
      _canRequestAds &&
      !_isOfflinePaused &&
      networkOnline.value;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void _attachLifecycle() {
    if (_lifecycleAttached) return;
    _lifecycleAttached = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (!_isForeground) return;
    // Connectivity very often changed while the app was in the background.
    invalidateNetworkCache();
    unawaited(_resumeAfterForeground());
  }

  Future<void> _resumeAfterForeground() async {
    final online = await hasInternetConnection(force: true);
    if (!online) return;
    _offlineUntil = null;
    // Interval-gated; uses on-disk RC cache when fetch is not due.
    await _rc.refreshIfNeeded();
    _applyRemoteConfigToLoadedAds();
    if (!_didBootstrap) {
      unawaited(bootstrap());
    } else {
      ensureLoaded();
    }
  }

  /// Drop banners that Remote Config has turned off so the UI collapses.
  void _applyRemoteConfigToLoadedAds() {
    if (!_rc.bannerAdsEnabled) {
      final shell = _bannerAd;
      final play = _playBannerAd;
      _bannerAd = null;
      _playBannerAd = null;
      bannerAdNotifier.value = null;
      playBannerAdNotifier.value = null;
      _disposeBannerLater(shell);
      _disposeBannerLater(play);
    }
    if (!_rc.interstitialAdsEnabled) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Offline handling
  // ---------------------------------------------------------------------------

  bool _isNetworkAdError(LoadAdError error) {
    // 0 = INTERNAL_ERROR (very common offline), 2 = NETWORK_ERROR
    if (error.code == 0 || error.code == 2) return true;
    final msg = error.message.toLowerCase();
    return msg.contains('network') ||
        msg.contains('internal error') ||
        msg.contains('unable to resolve') ||
        msg.contains('unknown host');
  }

  void _enterOfflineMode({Duration forDuration = const Duration(seconds: 60)}) {
    markNetworkOffline();
    _offlineUntil = DateTime.now().add(forDuration);
    _bannerLoading = false;
    _playBannerLoading = false;
    _interstitialLoading = false;
    for (final p in RewardPlacement.values) {
      _rewardLoading[p] = false;
    }
    _bannerLoadGen++;
    _playBannerLoadGen++;
    _hideBannersFromUi();
    _log('offline pause ${forDuration.inSeconds}s — no AdMob traffic');
    _scheduleOfflineWake();
  }

  /// Collapse banner slots immediately — offline / no-fill must not leave a hole.
  void _hideBannersFromUi() {
    final shell = _bannerAd;
    final play = _playBannerAd;
    _bannerAd = null;
    _playBannerAd = null;
    bannerAdNotifier.value = null;
    playBannerAdNotifier.value = null;
    _disposeBannerLater(shell);
    _disposeBannerLater(play);
  }

  void _scheduleOfflineWake() {
    if (_offlineRetryScheduled) return;
    _offlineRetryScheduled = true;
    final wait = _offlineUntil?.difference(DateTime.now()) ??
        const Duration(seconds: 60);
    Future<void>.delayed(wait + const Duration(seconds: 1), () async {
      _offlineRetryScheduled = false;
      final online = await hasInternetConnection(force: true);
      if (!online) {
        _enterOfflineMode(forDuration: const Duration(seconds: 90));
        return;
      }
      markNetworkOnline();
      _offlineUntil = null;
      if (!_didBootstrap) {
        unawaited(bootstrap());
      } else {
        ensureLoaded();
      }
    });
  }

  Future<bool> _guardOnline({bool forceCheck = false}) async {
    if (_isOfflinePaused && !forceCheck) return false;
    final online = await hasInternetConnection(force: forceCheck);
    if (!online) {
      _enterOfflineMode();
      return false;
    }
    markNetworkOnline();
    _offlineUntil = null;
    return true;
  }

  // ---------------------------------------------------------------------------
  // SDK / consent
  // ---------------------------------------------------------------------------

  /// UMP consent must be resolved before the SDK requests any ad.
  ///
  /// A missing or broken privacy message must never leave the game without
  /// ads forever, so every failure path falls through to "may request ads".
  Future<void> _ensureConsent() async {
    if (_consentResolved) return;
    _consentResolved = true;

    final done = Completer<void>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((error) {
              if (error != null) _log('consent form: ${error.message}');
            });
          } catch (e) {
            _log('consent form error: $e');
          }
          if (!done.isCompleted) done.complete();
        },
        (error) {
          _log('consent update failed: ${error.message}');
          if (!done.isCompleted) done.complete();
        },
      );
    } catch (e) {
      _log('consent request error: $e');
      if (!done.isCompleted) done.complete();
    }

    await done.future
        .timeout(const Duration(seconds: 10), onTimeout: () {});

    try {
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      _log('canRequestAds error: $e');
      _canRequestAds = true;
    }
    _log('consent resolved — canRequestAds=$_canRequestAds');
  }

  Future<void> _ensureSdk() async {
    if (_sdkReady) return;
    try {
      // Short timeout — offline / broken GMS must not hang the UI.
      await MobileAds.instance.initialize().timeout(const Duration(seconds: 8));
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          testDeviceIds: const <String>[],
        ),
      );
      _sdkReady = true;
      _log('MobileAds SDK ready (production units)');
    } catch (e) {
      _log('MobileAds init failed: $e');
      _sdkReady = false;
      _enterOfflineMode(forDuration: const Duration(seconds: 90));
    }
  }

  /// Call after the first Flutter frame (Activity must be ready).
  ///
  /// Concurrent callers share one in-flight run — never returns immediately while
  /// bootstrap is still working (that used to re-trigger banner/reward loads in
  /// a tight microtask loop when Play opened before the SDK finished init).
  Future<void> bootstrap({
    bool interstitial = true,
    bool banner = true,
    bool rewarded = true,
  }) {
    final inflight = _activeBootstrap;
    if (inflight != null) return inflight;
    if (_didBootstrap && _sdkReady) return Future<void>.value();

    final done = _runBootstrap(
      interstitial: interstitial,
      banner: banner,
      rewarded: rewarded,
    );
    _activeBootstrap = done;
    unawaited(
      done.whenComplete(() {
        if (identical(_activeBootstrap, done)) {
          _activeBootstrap = null;
        }
      }),
    );
    return done;
  }

  Future<void> _runBootstrap({
    required bool interstitial,
    required bool banner,
    required bool rewarded,
  }) async {
    _attachLifecycle();
    await _rc.ensureInitialized();
    _applyRemoteConfigToLoadedAds();
    if (_isOfflinePaused) {
      _log('bootstrap skipped — offline pause active');
      _scheduleOfflineWake();
      return;
    }
    try {
      // Core ANR fix: never touch MobileAds while offline.
      if (!await _guardOnline(forceCheck: true)) {
        _log('bootstrap skipped — no internet');
        return;
      }

      await _ensureConsent();
      if (!_canRequestAds) {
        _log('bootstrap stopped — consent does not allow ad requests');
        return;
      }

      await _ensureSdk();
      if (!_sdkReady) return;

      await Future<void>.delayed(const Duration(milliseconds: 250));

      _didBootstrap = true;

      final wantBanner = banner && _rc.bannerAdsEnabled;
      final wantInterstitial = interstitial && _rc.interstitialAdsEnabled;

      if (wantBanner) {
        _bannerLoading = false;
        loadBannerAd(force: true);
      }

      if (wantInterstitial) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        _interstitialLoading = false;
        loadInterstitialAd(force: true);
      }

      // Rewarded is never gated by Remote Config (always enabled).
      if (rewarded) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        prefetchRewardedAds();
      }
    } catch (e, st) {
      _log('bootstrap error: $e\n$st');
      _didBootstrap = false;
    }
  }

  void ensureLoaded() {
    if (!_canRequestAds) return;
    if (_isOfflinePaused) {
      _scheduleOfflineWake();
      return;
    }
    if (!_didBootstrap) {
      unawaited(bootstrap());
      return;
    }
    _applyRemoteConfigToLoadedAds();
    if (_rc.bannerAdsEnabled && _bannerAd == null && !_bannerLoading) {
      loadBannerAd();
    }
    if (_rc.interstitialAdsEnabled &&
        _interstitialAd == null &&
        !_interstitialLoading) {
      loadInterstitialAd();
    }
    prefetchRewardedAds();
  }

  // ---------------------------------------------------------------------------
  // Banner
  // ---------------------------------------------------------------------------

  /// Load the shell/home banner when the bottom [BannerAdBar] mounts.
  void ensureShellBanner() {
    if (!_rc.bannerAdsEnabled || !adsAvailable) return;
    if (!_didBootstrap) {
      unawaited(bootstrap(banner: true, interstitial: false, rewarded: false));
      return;
    }
    if (_bannerAd == null && !_bannerLoading) {
      unawaited(loadBannerAd());
    }
  }

  /// Anchored adaptive size — fills the screen width so no dead space is left
  /// beside a fixed 320x50 banner. Falls back to the standard banner.
  Future<AdSize> _bannerSize() async {
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final widthDp =
          (view.physicalSize.width / view.devicePixelRatio).truncate();
      if (widthDp > 0) {
        final adaptive = await AdSize
            // ignore: deprecated_member_use
            .getCurrentOrientationAnchoredAdaptiveBannerAdSize(widthDp);
        if (adaptive != null) {
          return adaptive;
        }
      }
    } catch (e) {
      _log('adaptive size failed: $e');
    }
    return AdSize.banner;
  }

  /// Retire a banner one beat after its `AdWidget` was detached. Disposing a
  /// banner that is still attached to the render tree crashes the Android SDK.
  void _disposeBannerLater(BannerAd? ad) {
    if (ad == null) return;
    Future<void>.delayed(const Duration(seconds: 2), () {
      try {
        ad.dispose();
      } catch (e) {
        _log('banner dispose error: $e');
      }
    });
  }

  void _scheduleRetry(void Function() retry, {required int attempt}) {
    if (attempt >= _adsConfig.maxRetries) return;
    final delay = _adsConfig.retryBackoff * (attempt + 1);
    Future<void>.delayed(delay, () {
      if (!_isOfflinePaused) retry();
    });
  }

  Future<void> loadBannerAd({bool force = false}) async {
    if (!_rc.bannerAdsEnabled) return;
    if (!_canRequestAds) return;
    if (_isOfflinePaused) return;
    if (!await _guardOnline()) return;
    if (!_sdkReady) {
      unawaited(bootstrap(banner: true, interstitial: false, rewarded: false));
      return;
    }
    if (_bannerLoading && !force) return;
    if (_bannerAd != null && !force) return;

    final unitId = _adsConfig.bannerUnitId('home');
    if (unitId == null) return;

    // Keep the current banner visible until a replacement loads — avoids gaps.
    final gen = ++_bannerLoadGen;
    _bannerLoading = true;
    final size = await _bannerSize();
    if (gen != _bannerLoadGen) return;
    _log('loading banner: $unitId (${size.width}x${size.height})');

    final ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad loaded) {
          if (gen != _bannerLoadGen) {
            _disposeBannerLater(loaded as BannerAd);
            return;
          }
          _bannerLoading = false;
          _bannerRetryCount = 0;
          final banner = loaded as BannerAd;
          final old = _bannerAd;
          _bannerAd = banner;
          bannerAdNotifier.value = banner;
          _disposeBannerLater(old);
          _log('banner LOADED ✓ $unitId');
        },
        onAdFailedToLoad: (Ad failed, LoadAdError error) {
          if (gen != _bannerLoadGen) {
            _disposeBannerLater(failed as BannerAd);
            return;
          }
          _log('banner FAILED ✗ $unitId → $error');
          _disposeBannerLater(failed as BannerAd);
          _bannerLoading = false;
          if (_isNetworkAdError(error)) {
            _enterOfflineMode();
            return;
          }
          final attempt = ++_bannerRetryCount;
          _scheduleRetry(() => loadBannerAd(force: true), attempt: attempt);
        },
      ),
    );

    Future<void>.delayed(const Duration(seconds: 20), () {
      if (gen != _bannerLoadGen) return;
      if (_bannerLoading && _bannerAd == null) {
        _log('banner load timeout — pausing');
        _bannerLoading = false;
        _enterOfflineMode(forDuration: const Duration(seconds: 45));
      }
    });

    try {
      await ad.load();
    } catch (e) {
      _log('banner load threw: $e');
      _bannerLoading = false;
      _disposeBannerLater(ad);
    }
  }

  /// Gameplay-only banner (separate instance from the shell banner).
  Future<void> loadPlayBannerAd({bool force = false}) async {
    if (!_rc.bannerAdsEnabled) return;
    if (!_canRequestAds) return;
    if (_isOfflinePaused) return;
    if (!await _guardOnline()) return;
    if (!_sdkReady) {
      unawaited(
        bootstrap(banner: true, interstitial: false, rewarded: false).then((_) {
          if (!_isOfflinePaused &&
              _sdkReady &&
              _playBannerAd == null &&
              !_playBannerLoading) {
            unawaited(loadPlayBannerAd(force: force));
          }
        }),
      );
      return;
    }
    if (_playBannerLoading && !force) return;
    if (_playBannerAd != null && !force) return;

    final unitId = _adsConfig.bannerUnitId('play');
    if (unitId == null) return;

    final gen = ++_playBannerLoadGen;
    _playBannerLoading = true;
    final size = await _bannerSize();
    if (gen != _playBannerLoadGen) return;
    _log('loading play banner: $unitId');

    final ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad loaded) {
          if (gen != _playBannerLoadGen) {
            _disposeBannerLater(loaded as BannerAd);
            return;
          }
          _playBannerLoading = false;
          _playBannerRetryCount = 0;
          final banner = loaded as BannerAd;
          final old = _playBannerAd;
          _playBannerAd = banner;
          playBannerAdNotifier.value = banner;
          _disposeBannerLater(old);
          _log('play banner LOADED ✓ $unitId');
        },
        onAdFailedToLoad: (Ad failed, LoadAdError error) {
          if (gen != _playBannerLoadGen) {
            _disposeBannerLater(failed as BannerAd);
            return;
          }
          _log('play banner FAILED ✗ $unitId → $error');
          _disposeBannerLater(failed as BannerAd);
          _playBannerLoading = false;
          if (_isNetworkAdError(error)) {
            _enterOfflineMode();
            return;
          }
          final attempt = ++_playBannerRetryCount;
          _scheduleRetry(() => loadPlayBannerAd(force: true), attempt: attempt);
        },
      ),
    );

    try {
      await ad.load();
    } catch (e) {
      _log('play banner load threw: $e');
      _playBannerLoading = false;
      _disposeBannerLater(ad);
    }
  }

  /// Shell banner stays loaded — the main shell hides it while a level is open.
  /// Only ensure the gameplay banner is ready (no dispose / reload flicker).
  void enterGameplayBanner() {
    if (!_rc.bannerAdsEnabled || !adsAvailable) return;
    if (_playBannerAd == null && !_playBannerLoading) {
      unawaited(loadPlayBannerAd());
    }
  }

  /// Drop gameplay banner and restore the shell strip (already loaded).
  void leaveGameplayBanner() {
    _detachPlayBanner();
    if (_bannerAd != null) {
      bannerAdNotifier.value = _bannerAd;
    } else if (!_bannerLoading) {
      unawaited(loadBannerAd());
    }
  }

  void _detachPlayBanner() {
    _playBannerLoadGen++;
    _playBannerLoading = false;
    final old = _playBannerAd;
    _playBannerAd = null;
    playBannerAdNotifier.value = null;
    _disposeBannerLater(old);
  }

  BannerAd? getBannerAd() => _bannerAd;

  // ---------------------------------------------------------------------------
  // Interstitial
  // ---------------------------------------------------------------------------

  void loadInterstitialAd({bool force = false}) {
    if (!_rc.interstitialAdsEnabled) return;
    if (!_canRequestAds) return;
    if (_isOfflinePaused) return;
    if (!_sdkReady) return;
    if ((_interstitialLoading || _interstitialAd != null) && !force) return;
    final unitId = _adsConfig.interstitialUnitId('after_level');
    if (unitId == null) return;

    if (force) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }

    _interstitialLoading = true;
    _log('loading interstitial: $unitId');

    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialLoading = false;
          _interstitialRetryCount = 0;
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          _log('interstitial LOADED ✓ $unitId');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _log('interstitial FAILED ✗ $unitId → $error');
          _interstitialLoading = false;
          _interstitialAd = null;
          if (_isNetworkAdError(error)) {
            _enterOfflineMode();
            return;
          }
          final attempt = ++_interstitialRetryCount;
          _scheduleRetry(() => loadInterstitialAd(force: true), attempt: attempt);
        },
      ),
    );
  }

  bool get isInterstitialReady => _interstitialAd != null;

  /// Shows an interstitial if pacing allows it. Always resolves — callers can
  /// safely `await` this before navigating.
  Future<bool> showInterstitial() async {
    if (!_rc.interstitialAdsEnabled) return false;
    if (!_canRequestAds || _isOfflinePaused || !_isForeground) return false;

    _interstitialOpportunities++;
    // Remote Config: skip first opportunity (default true) and min gap (60s).
    if (_rc.interstitialSkipFirst && _interstitialOpportunities <= 1) {
      loadInterstitialAd();
      return false;
    }
    final last = _lastInterstitialAt;
    if (last != null &&
        DateTime.now().difference(last) < _rc.interstitialMinInterval) {
      return false;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      loadInterstitialAd(force: true);
      return false;
    }

    final done = Completer<void>();
    _interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (InterstitialAd ad) {
        _lastInterstitialAt = DateTime.now();
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        loadInterstitialAd(force: true);
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        _log('interstitial show failed: $error');
        ad.dispose();
        loadInterstitialAd(force: true);
        if (!done.isCompleted) done.complete();
      },
    );

    try {
      await ad.show();
      await done.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {},
      );
      return true;
    } catch (e) {
      _log('interstitial show error: $e');
      try {
        ad.dispose();
      } catch (_) {}
      loadInterstitialAd(force: true);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Rewarded
  // ---------------------------------------------------------------------------

  void prefetchRewardedAds() {
    if (!_canRequestAds) return;
    if (_isOfflinePaused) return;
    if (!_sdkReady) {
      unawaited(
        bootstrap(interstitial: false, banner: false, rewarded: true),
      );
      return;
    }
    try {
      _loadRewardedAd(RewardPlacement.hint);
      Future<void>.delayed(const Duration(seconds: 2), () {
        if (!_isOfflinePaused) _loadRewardedAd(RewardPlacement.autoSolve);
      });
    } catch (e) {
      _log('prefetch rewarded error: $e');
    }
  }

  bool isRewardedReady(RewardPlacement placement) =>
      _rewardedAds[placement] != null;

  bool get _rewardLoadInFlight => _rewardLoading.values.any((v) => v == true);

  void _loadRewardedAd(RewardPlacement placement,
      {bool userInitiated = false}) {
    if (!_canRequestAds) return;
    if (_isOfflinePaused) return;
    if (!_sdkReady) {
      unawaited(
        bootstrap(interstitial: false, banner: false, rewarded: true).then((_) {
          if (!_isOfflinePaused && _sdkReady) {
            _loadRewardedAd(placement, userInitiated: userInitiated);
          }
        }),
      );
      return;
    }

    if (_rewardedAds[placement] != null) return;
    if (_rewardLoading[placement] == true) return;

    final now = DateTime.now();
    if (!userInitiated &&
        _rewardCooldownUntil != null &&
        now.isBefore(_rewardCooldownUntil!)) {
      final wait = _rewardCooldownUntil!.difference(now);
      Future<void>.delayed(wait, () {
        if (!_isOfflinePaused) {
          _loadRewardedAd(placement, userInitiated: userInitiated);
        }
      });
      return;
    }

    // One RewardedAd.load at a time.
    if (_rewardLoadInFlight) {
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (!_isOfflinePaused) {
          _loadRewardedAd(placement, userInitiated: userInitiated);
        }
      });
      return;
    }

    final unitId = _adsConfig.rewardedUnitId(placement.configName);
    if (unitId == null) return;

    final retryCount = _rewardRetryCount[placement] ?? 0;
    if (!userInitiated && retryCount >= _adsConfig.maxRetries) return;

    _rewardLoading[placement] = true;
    _log('loading rewarded ($placement): $unitId');

    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAds[placement]?.dispose();
          _rewardedAds[placement] = ad;
          _rewardLoading[placement] = false;
          _rewardRetryCount[placement] = 0;
          _rewardCooldownUntil = null;
          _signalRewardReady(placement);
          _log('rewarded LOADED ✓ ($placement)');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _log('rewarded FAILED ✗ ($placement / $unitId): $error');
          _rewardLoading[placement] = false;
          _rewardRetryCount[placement] = (retryCount + 1);

          if (_isNetworkAdError(error)) {
            _enterOfflineMode();
            _completeRewardReady(placement);
            return;
          }

          final noFillOrThrottled = error.code == 3 || error.code == 1;
          final delaySec = noFillOrThrottled
              ? (userInitiated ? 5 : 15) + (retryCount * 5).clamp(0, 30)
              : 3 + retryCount;
          _rewardCooldownUntil =
              DateTime.now().add(Duration(seconds: delaySec));
          if (retryCount < _adsConfig.maxRetries) {
            Future<void>.delayed(
              Duration(seconds: delaySec),
              () {
                if (!_isOfflinePaused) {
                  _loadRewardedAd(placement, userInitiated: userInitiated);
                }
              },
            );
          }
          _completeRewardReady(placement);
        },
      ),
    );
  }

  void _signalRewardReady(RewardPlacement placement) {
    final c = _rewardReady[placement];
    if (c != null && !c.isCompleted) c.complete();
  }

  void _completeRewardReady(RewardPlacement placement) {
    final c = _rewardReady[placement];
    if (c != null && !c.isCompleted) c.complete();
    _rewardReady[placement] = null;
  }

  RewardedAd? _takeReadyRewarded(RewardPlacement placement) {
    final own = _rewardedAds[placement];
    if (own != null) {
      _rewardedAds[placement] = null;
      return own;
    }
    return null;
  }

  Future<void> waitUntilRewardedAdIsReady(
    RewardPlacement placement, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (isRewardedReady(placement)) return;
    if (!_canRequestAds) return;
    // The player explicitly asked for this ad — re-probe instead of making
    // them sit out an offline pause that may already be stale.
    if (!await _guardOnline(forceCheck: _isOfflinePaused)) return;

    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_isOfflinePaused) return;
      if (isRewardedReady(placement)) return;

      _rewardReady[placement] ??= Completer<void>();
      _loadRewardedAd(placement, userInitiated: true);

      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) break;

      try {
        await _rewardReady[placement]!.future.timeout(
              remaining < const Duration(seconds: 4)
                  ? remaining
                  : const Duration(seconds: 4),
            );
      } on TimeoutException {
        // Load still in flight or failed — loop and retry.
      }
      _rewardReady[placement] = null;

      if (isRewardedReady(placement)) return;
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }

    _log('rewarded wait timeout ($placement)');
    _rewardReady[placement] = null;
  }

  Future<RewardShowResult> showRewardedAdForPlacement(
    RewardPlacement placement, {
    required void Function() onRewardEarned,
  }) async {
    if (!_isForeground) return RewardShowResult.notReady;

    final ad = _takeReadyRewarded(placement);
    if (ad == null) {
      _loadRewardedAd(placement, userInitiated: true);
      return RewardShowResult.notReady;
    }

    var didEarn = false;
    final done = Completer<void>();

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        if (didEarn) {
          try {
            onRewardEarned();
            unawaited(
              analyticsService.logRewardedAdCompleted(
                placement: placement.configName,
                source: 'rewarded_ad',
              ),
            );
          } catch (e) {
            _log('reward callback error: $e');
          }
        }
        ad.dispose();
        if (!done.isCompleted) done.complete();
        _loadRewardedAd(placement);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        _log('rewarded show failed: $error');
        ad.dispose();
        if (!done.isCompleted) done.complete();
        _loadRewardedAd(placement);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (_, __) {
          didEarn = true;
        },
      );
      await done.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {},
      );
      return RewardShowResult.shown;
    } catch (e) {
      _log('rewarded show error: $e');
      try {
        ad.dispose();
      } catch (_) {}
      if (!done.isCompleted) done.complete();
      _loadRewardedAd(placement, userInitiated: true);
      return RewardShowResult.notReady;
    }
  }

  void disposeAll() {
    _bannerLoadGen++;
    _playBannerLoadGen++;
    final banner = _bannerAd;
    final playBanner = _playBannerAd;
    _bannerAd = null;
    _playBannerAd = null;
    bannerAdNotifier.value = null;
    playBannerAdNotifier.value = null;
    _disposeBannerLater(banner);
    _disposeBannerLater(playBanner);
    _interstitialAd?.dispose();
    _interstitialAd = null;
    for (final p in RewardPlacement.values) {
      _rewardedAds[p]?.dispose();
      _rewardedAds[p] = null;
      _rewardLoading[p] = false;
      _completeRewardReady(p);
    }
    _didBootstrap = false;
    _bannerLoading = false;
    _playBannerLoading = false;
    _interstitialLoading = false;
  }
}
