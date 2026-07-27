import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardPlacement { hint, autoSolve }

enum RewardShowResult { notReady, shown }

/// Central AdMob manager — banner, interstitial, rewarded (hint / skip).
///
/// Non-release builds use Google **test** unit IDs so ads always fill while
/// developing. Release builds use your production unit IDs.
class AdManager {
  factory AdManager() => _instance;
  AdManager._();
  static final AdManager _instance = AdManager._();

  /// Set `true` only when you want real production ads in a debug run.
  static const bool forceProductionAds = false;

  static bool get _useTestAds =>
      !kReleaseMode && !forceProductionAds;

  // --- Production unit IDs ---
  static const _prodBanner = [
    'ca-app-pub-5561438827097019/5440263702',
    'ca-app-pub-5561438827097019/9075891424',
  ];
  static const _prodInterstitial = [
    'ca-app-pub-5561438827097019/5136646412',
    'ca-app-pub-5561438827097019/1767777858',
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

  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';

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
  int _interstitialIndex = 0;
  int _hintIndex = 0;
  int _skipIndex = 0;

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

  List<String> get _bannerIds =>
      _useTestAds ? const [_testBanner] : _prodBanner;
  List<String> get _interstitialIds =>
      _useTestAds ? const [_testInterstitial] : _prodInterstitial;
  List<String> get _hintIds =>
      _useTestAds ? const [_testRewarded] : _prodHintRewarded;
  List<String> get _skipIds =>
      _useTestAds ? const [_testRewarded] : _prodSkipRewarded;

  /// Call after the first Flutter frame (Activity must be ready).
  Future<void> bootstrap({
    bool interstitial = true,
    bool banner = true,
    bool rewarded = true,
  }) async {
    if (_bootstrapping) return;
    _bootstrapping = true;
    try {
      print('[Ads] bootstrap… testAds=$_useTestAds release=$kReleaseMode');

      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          // Empty list is fine — test ad *unit* IDs already force test creatives.
          testDeviceIds: const <String>[],
        ),
      );

      // Let the Activity / platform view settle after first frame.
      await Future<void>.delayed(const Duration(milliseconds: 600));

      _didBootstrap = true;
      if (banner) {
        _bannerLoading = false;
        _playBannerLoading = false;
        loadBannerAd(force: true);
        loadPlayBannerAd(force: true);
      }
      if (interstitial) {
        _interstitialLoading = false;
        loadInterstitialAd(force: true);
      }
      if (rewarded) prefetchRewardedAds();
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
    if (!_didBootstrap) {
      unawaited(bootstrap());
      return;
    }
    if (_bannerAd == null && !_bannerLoading) loadBannerAd();
    if (_playBannerAd == null && !_playBannerLoading) loadPlayBannerAd();
    if (_interstitialAd == null && !_interstitialLoading) {
      loadInterstitialAd();
    }
    prefetchRewardedAds();
  }

  // ---------------------------------------------------------------------------
  // Banner
  // ---------------------------------------------------------------------------

  void loadBannerAd({bool force = false}) {
    if (_bannerLoading && !force) return;
    if (_bannerAd != null && !force) return;

    final ids = _bannerIds;
    if (ids.isEmpty) return;
    if (_bannerIndex >= ids.length) _bannerIndex = 0;

    _bannerLoading = true;
    final unitId = ids[_bannerIndex].trim();
    print('[Ads] loading banner: $unitId');

    final ad = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad loaded) {
          _bannerLoading = false;
          final banner = loaded as BannerAd;
          final old = _bannerAd;
          _bannerAd = banner;
          bannerAdNotifier.value = banner;
          old?.dispose();
          print('[Ads] banner LOADED ✓ $unitId');
        },
        onAdFailedToLoad: (Ad failed, LoadAdError error) {
          print('[Ads] banner FAILED ✗ $unitId → $error');
          failed.dispose();
          _bannerLoading = false;
          if (_bannerAd != null) {
            _bannerAd?.dispose();
            _bannerAd = null;
            bannerAdNotifier.value = null;
          }
          _bannerIndex++;
          if (_bannerIndex < ids.length) {
            Future<void>.delayed(
              const Duration(milliseconds: 800),
              () => loadBannerAd(force: true),
            );
          } else {
            _bannerIndex = 0;
            Future<void>.delayed(
              const Duration(seconds: 20),
              () => loadBannerAd(force: true),
            );
          }
        },
      ),
    );

    // Safety: if SDK never callbacks (broken plugin channel), unlock loader.
    Future<void>.delayed(const Duration(seconds: 30), () {
      if (_bannerLoading && _bannerAd == null) {
        print('[Ads] banner load timeout — retrying');
        _bannerLoading = false;
        loadBannerAd(force: true);
      }
    });

    ad.load();
  }

  /// Gameplay-only banner (separate instance from the shell banner).
  void loadPlayBannerAd({bool force = false}) {
    if (_playBannerLoading && !force) return;
    if (_playBannerAd != null && !force) return;

    final ids = _bannerIds;
    if (ids.isEmpty) return;
    // Prefer second unit if available so shell/play don't share one.
    final unitId = ids[ids.length > 1 ? 1 % ids.length : 0].trim();
    // With a single test id, still fine to request twice.

    _playBannerLoading = true;
    print('[Ads] loading play banner: $unitId');

    final ad = BannerAd(
      adUnitId: unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad loaded) {
          _playBannerLoading = false;
          final banner = loaded as BannerAd;
          final old = _playBannerAd;
          _playBannerAd = banner;
          playBannerAdNotifier.value = banner;
          old?.dispose();
          print('[Ads] play banner LOADED ✓ $unitId');
        },
        onAdFailedToLoad: (Ad failed, LoadAdError error) {
          print('[Ads] play banner FAILED ✗ $unitId → $error');
          failed.dispose();
          _playBannerLoading = false;
          _playBannerAd?.dispose();
          _playBannerAd = null;
          playBannerAdNotifier.value = null;
          Future<void>.delayed(
            const Duration(seconds: 20),
            () => loadPlayBannerAd(force: true),
          );
        },
      ),
    );
    ad.load();
  }

  BannerAd? getBannerAd() => _bannerAd;

  // ---------------------------------------------------------------------------
  // Interstitial
  // ---------------------------------------------------------------------------

  void loadInterstitialAd({bool force = false}) {
    if ((_interstitialLoading || _interstitialAd != null) && !force) return;
    final ids = _interstitialIds;
    if (ids.isEmpty) return;
    if (_interstitialIndex >= ids.length) _interstitialIndex = 0;

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
          _interstitialIndex++;
          if (_interstitialIndex < ids.length) {
            Future<void>.delayed(
              const Duration(milliseconds: 800),
              () => loadInterstitialAd(force: true),
            );
          } else {
            _interstitialIndex = 0;
            Future<void>.delayed(
              const Duration(seconds: 20),
              () => loadInterstitialAd(force: true),
            );
          }
        },
      ),
    );
  }

  bool get isInterstitialReady => _interstitialAd != null;

  Future<bool> showInterstitial() async {
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
    try {
      // Serialize loads — concurrent requests for the same test unit hang/fail.
      _loadRewardedAd(RewardPlacement.hint);
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        _loadRewardedAd(RewardPlacement.autoSolve);
      });
    } catch (e) {
      print('[Ads] prefetch rewarded error: $e');
    }
  }

  bool get _rewardLoadInFlight =>
      _rewardLoading.values.any((v) => v == true);

  void _loadRewardedAd(RewardPlacement placement) {
    if (_rewardedAds[placement] != null) return;
    if (_rewardLoading[placement] == true) return;
    // One RewardedAd.load at a time (esp. test unit shared by both placements).
    if (_rewardLoadInFlight) {
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        _loadRewardedAd(placement);
      });
      return;
    }

    final ids =
        placement == RewardPlacement.hint ? _hintIds : _skipIds;
    if (ids.isEmpty) return;

    final streak = _rewardFailStreak[placement] ?? 0;
    if (streak >= ids.length * 2) {
      _rewardFailStreak[placement] = 0;
      Future<void>.delayed(
        const Duration(seconds: 30),
        () => _loadRewardedAd(placement),
      );
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
          _completeRewardReady(placement);
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
          // Unblock waiters so UI can retry / dismiss loader.
          _completeRewardReady(placement);
          Future<void>.delayed(
            Duration(milliseconds: 800 + (streak * 250).clamp(0, 3000)),
            () => _loadRewardedAd(placement),
          );
        },
      ),
    );
  }

  void _completeRewardReady(RewardPlacement placement) {
    final c = _rewardReady[placement];
    if (c != null && !c.isCompleted) c.complete();
    _rewardReady[placement] = null;
  }

  /// In test mode both placements share one unit — borrow a ready ad.
  RewardedAd? _takeReadyRewarded(RewardPlacement placement) {
    final own = _rewardedAds[placement];
    if (own != null) {
      _rewardedAds[placement] = null;
      return own;
    }
    if (_useTestAds) {
      for (final other in RewardPlacement.values) {
        if (other == placement) continue;
        final borrowed = _rewardedAds[other];
        if (borrowed != null) {
          _rewardedAds[other] = null;
          return borrowed;
        }
      }
    }
    return null;
  }

  Future<void> waitUntilRewardedAdIsReady(
    RewardPlacement placement, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_takePeekRewarded(placement) != null) return;

    _rewardReady[placement] ??= Completer<void>();
    _loadRewardedAd(placement);

    try {
      await _rewardReady[placement]!.future.timeout(timeout);
    } on TimeoutException {
      print('[Ads] rewarded wait timeout ($placement)');
      _completeRewardReady(placement);
    }
  }

  RewardedAd? _takePeekRewarded(RewardPlacement placement) {
    if (_rewardedAds[placement] != null) return _rewardedAds[placement];
    if (_useTestAds) {
      for (final other in RewardPlacement.values) {
        if (_rewardedAds[other] != null) return _rewardedAds[other];
      }
    }
    return null;
  }

  Future<RewardShowResult> showRewardedAdForPlacement(
    RewardPlacement placement, {
    required void Function() onRewardEarned,
  }) async {
    final ad = _takeReadyRewarded(placement);
    if (ad == null) {
      _loadRewardedAd(placement);
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
      // Wait until the native fullscreen is closed (or failed), with a cap.
      await done.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () {},
      );
      return didEarn || true
          ? RewardShowResult.shown
          : RewardShowResult.shown;
    } catch (e) {
      print('[Ads] rewarded show error: $e');
      ad.dispose();
      if (!done.isCompleted) done.complete();
      _loadRewardedAd(placement);
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
