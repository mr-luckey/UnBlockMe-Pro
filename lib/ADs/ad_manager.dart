import 'dart:async';

import 'package:blocked/ADs/network_status.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardPlacement { hint, autoSolve }

enum RewardShowResult { notReady, shown }

/// Central AdMob manager — banner, interstitial, rewarded (hint / skip).
///
/// Uses production AdMob unit IDs in all builds.
///
/// Loads are staggered and guarded so AdMob / GMS work never piles onto the
/// UI isolate (ANR / jank). Call [bootstrap] only after the first Flutter frame.
///
/// Offline: never call [MobileAds.initialize] and never retry-storm loads —
/// that is the main ANR / crash cause when the user turns off internet.
class AdManager {
  factory AdManager() => _instance;
  AdManager._();
  static final AdManager _instance = AdManager._();

  // --- Production unit IDs ---
  static const _prodBanner = [
    'ca-app-pub-5561438827097019/9629852666',
    'ca-app-pub-5561438827097019/8316770999',
    'ca-app-pub-5561438827097019/1207482870',
    'ca-app-pub-5561438827097019/1280589357',
    'ca-app-pub-5561438827097019/2896923355',
  ];
  static const _prodInterstitial = [
    'ca-app-pub-5561438827097019/2053926619',
    'ca-app-pub-5561438827097019/9740844949',
    'ca-app-pub-5561438827097019/9438280976',
    'ca-app-pub-5561438827097019/7114681608',
    'ca-app-pub-5561438827097019/7537921658',
  ];
  static const _prodHintRewarded = [
    'ca-app-pub-5561438827097019/6764030149',
    'ca-app-pub-5561438827097019/5450948476',
    'ca-app-pub-5561438827097019/7397402617',
    'ca-app-pub-5561438827097019/9999515220',
    'ca-app-pub-5561438827097019/9535557351',
    'ca-app-pub-5561438827097019/5488501134',
    'ca-app-pub-5561438827097019/7373351887',
  ];
  static const _prodSkipRewarded = [
    'ca-app-pub-5561438827097019/5683942253',
    'ca-app-pub-5561438827097019/4283230677',
    'ca-app-pub-5561438827097019/2824785130',
    'ca-app-pub-5561438827097019/4747188542',
    'ca-app-pub-5561438827097019/1657067333',
    'ca-app-pub-5561438827097019/4175419460',
    'ca-app-pub-5561438827097019/2121025205',
    'ca-app-pub-5561438827097019/2862337799',
  ];

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

  int _bannerIndex = 0;
  int _playBannerIndex = 0;
  int _interstitialIndex = 0;
  int _hintIndex = 0;
  int _skipIndex = 0;

  int _bannerLoadGen = 0;
  int _playBannerLoadGen = 0;

  bool _sdkReady = false;
  bool _bootstrapping = false;
  bool _didBootstrap = false;
  bool _bannerLoading = false;
  bool _playBannerLoading = false;
  bool _interstitialLoading = false;
  final Map<RewardPlacement, bool> _rewardLoading = {
    RewardPlacement.hint: false,
    RewardPlacement.autoSolve: false,
  };
  final Map<RewardPlacement, Completer<void>?> _rewardReady = {
    RewardPlacement.hint: null,
    RewardPlacement.autoSolve: null,
  };
  final Map<RewardPlacement, int> _rewardFailStreak = {
    RewardPlacement.hint: 0,
    RewardPlacement.autoSolve: 0,
  };

  /// Shared cooldown after no-fill / throttle — blocks all rewarded loads.
  DateTime? _rewardCooldownUntil;

  /// When set, all AdMob loads/init are paused (offline / network errors).
  DateTime? _offlineUntil;
  bool _offlineRetryScheduled = false;

  List<String> get _bannerIds => _prodBanner;
  List<String> get _interstitialIds => _prodInterstitial;
  List<String> get _hintIds => _prodHintRewarded;
  List<String> get _skipIds => _prodSkipRewarded;

  bool get _isOfflinePaused =>
      _offlineUntil != null && DateTime.now().isBefore(_offlineUntil!);

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
    // Invalidate in-flight load generations so delayed retries no-op.
    _bannerLoadGen++;
    _playBannerLoadGen++;
    print('[Ads] offline pause ${forDuration.inSeconds}s — no AdMob traffic');
    _scheduleOfflineWake();
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

  Future<void> _ensureSdk() async {
    if (_sdkReady) return;
    try {
      // Short timeout — offline / broken GMS must not hang the UI.
      await MobileAds.instance.initialize().timeout(const Duration(seconds: 5));
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          testDeviceIds: const <String>[],
        ),
      );
      _sdkReady = true;
      print('[Ads] MobileAds SDK ready (production units)');
    } catch (e) {
      print('[Ads] MobileAds init failed: $e');
      _sdkReady = false;
      _enterOfflineMode(forDuration: const Duration(seconds: 90));
      rethrow;
    }
  }

  /// Call after the first Flutter frame (Activity must be ready).
  Future<void> bootstrap({
    bool interstitial = true,
    bool banner = true,
    bool rewarded = true,
  }) async {
    if (_bootstrapping) return;
    if (_isOfflinePaused) {
      print('[Ads] bootstrap skipped — offline pause active');
      _scheduleOfflineWake();
      return;
    }
    _bootstrapping = true;
    try {
      print('[Ads] bootstrap… production units release=$kReleaseMode');

      // Core ANR fix: never touch MobileAds while offline.
      if (!await _guardOnline(forceCheck: true)) {
        print('[Ads] bootstrap skipped — no internet');
        return;
      }

      await _ensureSdk();

      await Future<void>.delayed(const Duration(milliseconds: 250));

      _didBootstrap = true;

      if (banner) {
        _bannerLoading = false;
        loadBannerAd(force: true);
        Future<void>.delayed(const Duration(milliseconds: 900), () {
          if (_playBannerAd == null && !_playBannerLoading) {
            loadPlayBannerAd();
          }
        });
      }

      if (interstitial) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        _interstitialLoading = false;
        loadInterstitialAd(force: true);
      }

      if (rewarded) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        prefetchRewardedAds();
      }
    } catch (e, st) {
      print('[Ads] bootstrap error: $e\n$st');
      _didBootstrap = false;
    } finally {
      _bootstrapping = false;
    }
  }

  void addAds(bool interstitial, bool bannerAd, bool rewardedAd) {
    unawaited(
      bootstrap(
        interstitial: interstitial,
        banner: bannerAd,
        rewarded: rewardedAd,
      ),
    );
  }

  void ensureLoaded() {
    if (_isOfflinePaused) {
      _scheduleOfflineWake();
      return;
    }
    if (!_didBootstrap) {
      unawaited(bootstrap());
      return;
    }
    if (_bannerAd == null && !_bannerLoading) loadBannerAd();
    if (_interstitialAd == null && !_interstitialLoading) {
      loadInterstitialAd();
    }
    prefetchRewardedAds();
  }

  // ---------------------------------------------------------------------------
  // Banner
  // ---------------------------------------------------------------------------

  void loadBannerAd({bool force = false}) {
    if (_isOfflinePaused) return;
    if (!_sdkReady) {
      unawaited(bootstrap(banner: true, interstitial: false, rewarded: false));
      return;
    }
    if (_bannerLoading && !force) return;
    if (_bannerAd != null && !force) return;

    final ids = _bannerIds;
    if (ids.isEmpty) return;
    if (_bannerIndex >= ids.length) _bannerIndex = 0;

    // Keep the current banner visible until a replacement loads — avoids gaps.
    final gen = ++_bannerLoadGen;
    _bannerLoading = true;
    final unitId = ids[_bannerIndex].trim();
    print('[Ads] loading banner: $unitId');

    final ad = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad loaded) {
          if (gen != _bannerLoadGen) {
            loaded.dispose();
            return;
          }
          _bannerLoading = false;
          final banner = loaded as BannerAd;
          final old = _bannerAd;
          _bannerAd = banner;
          bannerAdNotifier.value = banner;
          old?.dispose();
          print('[Ads] banner LOADED ✓ $unitId');
        },
        onAdFailedToLoad: (Ad failed, LoadAdError error) {
          if (gen != _bannerLoadGen) {
            failed.dispose();
            return;
          }
          print('[Ads] banner FAILED ✗ $unitId → $error');
          failed.dispose();
          _bannerLoading = false;
          if (_isNetworkAdError(error)) {
            _enterOfflineMode();
            return;
          }
          _bannerIndex++;
          if (_bannerIndex < ids.length) {
            Future<void>.delayed(
              const Duration(milliseconds: 900),
              () {
                if (gen == _bannerLoadGen && !_isOfflinePaused) {
                  loadBannerAd(force: true);
                }
              },
            );
          } else {
            _bannerIndex = 0;
            Future<void>.delayed(
              const Duration(seconds: 45),
              () {
                if (gen == _bannerLoadGen && !_isOfflinePaused) {
                  loadBannerAd(force: true);
                }
              },
            );
          }
        },
      ),
    );

    Future<void>.delayed(const Duration(seconds: 20), () {
      if (gen != _bannerLoadGen) return;
      if (_bannerLoading && _bannerAd == null) {
        print('[Ads] banner load timeout — pausing');
        _bannerLoading = false;
        _enterOfflineMode(forDuration: const Duration(seconds: 45));
      }
    });

    ad.load();
  }

  /// Gameplay-only banner (separate instance from the shell banner).
  void loadPlayBannerAd({bool force = false}) {
    if (_isOfflinePaused) return;
    if (!_sdkReady) {
      unawaited(
        bootstrap(banner: true, interstitial: false, rewarded: false).then((_) {
          if (!_isOfflinePaused) loadPlayBannerAd(force: force);
        }),
      );
      return;
    }
    if (_playBannerLoading && !force) return;
    if (_playBannerAd != null && !force) return;

    final ids = _bannerIds;
    if (ids.isEmpty) return;

    // Prefer a different unit from the shell banner when available.
    if (ids.length > 1) {
      _playBannerIndex = (_bannerIndex + 1) % ids.length;
    } else {
      _playBannerIndex = 0;
    }
    final unitId = ids[_playBannerIndex].trim();

    final gen = ++_playBannerLoadGen;
    _playBannerLoading = true;
    print('[Ads] loading play banner: $unitId');

    final ad = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad loaded) {
          if (gen != _playBannerLoadGen) {
            loaded.dispose();
            return;
          }
          _playBannerLoading = false;
          final banner = loaded as BannerAd;
          final old = _playBannerAd;
          _playBannerAd = banner;
          playBannerAdNotifier.value = banner;
          old?.dispose();
          print('[Ads] play banner LOADED ✓ $unitId');
        },
        onAdFailedToLoad: (Ad failed, LoadAdError error) {
          if (gen != _playBannerLoadGen) {
            failed.dispose();
            return;
          }
          print('[Ads] play banner FAILED ✗ $unitId → $error');
          failed.dispose();
          _playBannerLoading = false;
          if (_isNetworkAdError(error)) {
            _enterOfflineMode();
            return;
          }
          Future<void>.delayed(
            const Duration(seconds: 45),
            () {
              if (gen == _playBannerLoadGen && !_isOfflinePaused) {
                loadPlayBannerAd(force: true);
              }
            },
          );
        },
      ),
    );
    ad.load();
  }

  /// Shell banner stays loaded — [MainShell] hides it while a level is open.
  /// Only ensure the gameplay banner is ready (no dispose / reload flicker).
  void enterGameplayBanner() {
    if (_playBannerAd == null && !_playBannerLoading) {
      loadPlayBannerAd();
    }
  }

  /// Drop gameplay banner and restore the shell strip (already loaded).
  void leaveGameplayBanner() {
    _detachPlayBanner();
    if (_bannerAd != null) {
      bannerAdNotifier.value = _bannerAd;
    } else if (!_bannerLoading) {
      loadBannerAd();
    }
  }

  void _detachPlayBanner() {
    _playBannerLoadGen++;
    _playBannerLoading = false;
    final old = _playBannerAd;
    _playBannerAd = null;
    playBannerAdNotifier.value = null;
    old?.dispose();
  }

  BannerAd? getBannerAd() => _bannerAd;

  // ---------------------------------------------------------------------------
  // Interstitial
  // ---------------------------------------------------------------------------

  void loadInterstitialAd({bool force = false}) {
    if (_isOfflinePaused) return;
    if (!_sdkReady) return;
    if ((_interstitialLoading || _interstitialAd != null) && !force) return;
    final ids = _interstitialIds;
    if (ids.isEmpty) return;
    if (_interstitialIndex >= ids.length) _interstitialIndex = 0;

    if (force) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }

    _interstitialLoading = true;
    final unitId = ids[_interstitialIndex].trim();
    print('[Ads] loading interstitial: $unitId');

    InterstitialAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialLoading = false;
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          print('[Ads] interstitial LOADED ✓ $unitId');
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('[Ads] interstitial FAILED ✗ $unitId → $error');
          _interstitialLoading = false;
          _interstitialAd = null;
          if (_isNetworkAdError(error)) {
            _enterOfflineMode();
            return;
          }
          _interstitialIndex++;
          if (_interstitialIndex < ids.length) {
            Future<void>.delayed(
              const Duration(milliseconds: 900),
              () {
                if (!_isOfflinePaused) loadInterstitialAd(force: true);
              },
            );
          } else {
            _interstitialIndex = 0;
            Future<void>.delayed(
              const Duration(seconds: 45),
              () {
                if (!_isOfflinePaused) loadInterstitialAd(force: true);
              },
            );
          }
        },
      ),
    );
  }

  bool get isInterstitialReady => _interstitialAd != null;

  Future<bool> showInterstitial() async {
    if (_isOfflinePaused) return false;
    final ad = _interstitialAd;
    if (ad == null) {
      loadInterstitialAd(force: true);
      return false;
    }

    final done = Completer<void>();
    _interstitialAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        loadInterstitialAd(force: true);
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        print('[Ads] interstitial show failed: $error');
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
      print('[Ads] interstitial show error: $e');
      ad.dispose();
      loadInterstitialAd(force: true);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Rewarded
  // ---------------------------------------------------------------------------

  void prefetchRewardedAds() {
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
      print('[Ads] prefetch rewarded error: $e');
    }
  }

  bool isRewardedReady(RewardPlacement placement) =>
      _takePeekRewarded(placement) != null;

  bool get _rewardLoadInFlight => _rewardLoading.values.any((v) => v == true);

  void _loadRewardedAd(RewardPlacement placement,
      {bool userInitiated = false}) {
    if (_isOfflinePaused) return;
    if (!_sdkReady) {
      unawaited(
        bootstrap(interstitial: false, banner: false, rewarded: true).then((_) {
          if (!_isOfflinePaused) {
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

    final ids = placement == RewardPlacement.hint ? _hintIds : _skipIds;
    if (ids.isEmpty) return;

    final streak = _rewardFailStreak[placement] ?? 0;
    if (!userInitiated && streak >= ids.length * 2) {
      _rewardFailStreak[placement] = 0;
      _enterOfflineMode(forDuration: const Duration(seconds: 60));
      return;
    }

    _rewardLoading[placement] = true;
    var index = placement == RewardPlacement.hint ? _hintIndex : _skipIndex;
    index = index % ids.length;
    final unitId = ids[index].trim();
    print('[Ads] loading rewarded ($placement): $unitId');

    RewardedAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          _rewardedAds[placement]?.dispose();
          _rewardedAds[placement] = ad;
          _rewardLoading[placement] = false;
          _rewardFailStreak[placement] = 0;
          _rewardCooldownUntil = null;
          _signalRewardReady(placement);
          print('[Ads] rewarded LOADED ✓ ($placement)');
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('[Ads] rewarded FAILED ✗ ($placement / $unitId): $error');
          _rewardLoading[placement] = false;
          _rewardFailStreak[placement] = streak + 1;
          final next = (index + 1) % ids.length;
          if (placement == RewardPlacement.hint) {
            _hintIndex = next;
          } else {
            _skipIndex = next;
          }

          if (_isNetworkAdError(error)) {
            _enterOfflineMode();
            _completeRewardReady(placement);
            return;
          }

          final noFillOrThrottled = error.code == 3 || error.code == 1;
          final delaySec = noFillOrThrottled
              ? (userInitiated ? 5 : 15) + (streak * 5).clamp(0, 30)
              : 3 + streak;
          _rewardCooldownUntil =
              DateTime.now().add(Duration(seconds: delaySec));
          Future<void>.delayed(
            Duration(seconds: delaySec),
            () {
              if (!_isOfflinePaused) _loadRewardedAd(placement);
            },
          );
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
    if (_isOfflinePaused) return;
    if (!await _guardOnline()) return;

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

    print('[Ads] rewarded wait timeout ($placement)');
    _rewardReady[placement] = null;
  }

  RewardedAd? _takePeekRewarded(RewardPlacement placement) {
    return _rewardedAds[placement];
  }

  Future<RewardShowResult> showRewardedAdForPlacement(
    RewardPlacement placement, {
    required void Function() onRewardEarned,
  }) async {
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
          } catch (e) {
            print('[Ads] reward callback error: $e');
          }
        }
        ad.dispose();
        if (!done.isCompleted) done.complete();
        _loadRewardedAd(placement);
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        print('[Ads] rewarded show failed: $error');
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
      print('[Ads] rewarded show error: $e');
      ad.dispose();
      if (!done.isCompleted) done.complete();
      _loadRewardedAd(placement, userInitiated: true);
      return RewardShowResult.notReady;
    }
  }

  void showRewardedAd() {
    unawaited(
      showRewardedAdForPlacement(
        RewardPlacement.hint,
        onRewardEarned: () {},
      ),
    );
  }

  void disposeAds() {}

  void disposeAll() {
    _bannerLoadGen++;
    _playBannerLoadGen++;
    _bannerAd?.dispose();
    _bannerAd = null;
    bannerAdNotifier.value = null;
    _playBannerAd?.dispose();
    _playBannerAd = null;
    playBannerAdNotifier.value = null;
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
