// import 'package:facebook_audience_network/facebook_audience_network.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
// // import 'package:flutter_facebook_audience_network/flutter_facebook_audience_network.dart';

// class AdManager {
//   BannerAd? _bannerAd;
//   InterstitialAd? _interstitialAd;
//   RewardedAd? _rewardedAd;

//   // List of ad unit IDs for Google Ads
//   final List<String> googleBannerAdIds = [
//     "ca-app-pub-5561438827097019/5440263702",
//     "ca-app-pub-5561438827097019/9075891424",
//   ];

//   final List<String> googleInterstitialAdIds = [
//     "ca-app-pub-5561438827097019/5136646412",
//     "ca-app-pub-5561438827097019/1767777858",
//   ];

//   final List<String> googleRewardedAdIds = [
//     "ca-app-pub-5561438827097019/3823564740",
//     "ca-app-pub-5561438827097019/2510483076",
//   ];

//   // List of ad unit IDs for Facebook Ads
//   final List<String> facebookBannerAdIds = [
//     "532584862762491_532586772762300",
//     "532584862762491_532587039428940",
//   ];

//   final List<String> facebookInterstitialAdIds = [
//     "532584862762491_532587406095570",
//     "532584862762491_532587779428866",
//   ];

//   final List<String> facebookRewardedAdIds = [
//     "532584862762491_532589669428677",
//     "532584862762491_532590162761961",
//   ];

//   int bannerAdIndex = 0;
//   int interstitialAdIndex = 0;
//   int rewardedAdIndex = 0;

//   int facebookBannerAdIndex = 0;
//   int facebookInterstitialAdIndex = 0;
//   int facebookRewardedAdIndex = 0;

//   bool _useGoogleAds = true;

//   void loadBannerAd() {
//     if (_useGoogleAds) {
//       if (bannerAdIndex < googleBannerAdIds.length) {
//         _bannerAd = BannerAd(
//           adUnitId: googleBannerAdIds[bannerAdIndex],
//           size: AdSize.banner,
//           request: const AdRequest(),
//           listener: BannerAdListener(
//             onAdFailedToLoad: (Ad ad, LoadAdError error) {
//               bannerAdIndex++;
//               if (bannerAdIndex >= googleBannerAdIds.length) {
//                 _useGoogleAds = false;
//                 loadBannerAd(); // Switch to Facebook Ads
//               } else {
//                 loadBannerAd(); // Retry with the next Google ad unit ID
//               }
//             },
//           ),
//         );

//         _bannerAd?.load();
//       } else {
//         // Switch to Facebook Ads if Google Ads failed
//         loadFacebookBannerAd();
//       }
//     } else {
//       loadFacebookBannerAd();
//     }
//   }

//   void loadInterstitialAd() {
//     if (_useGoogleAds) {
//       if (interstitialAdIndex < googleInterstitialAdIds.length) {
//         InterstitialAd.load(
//           adUnitId: googleInterstitialAdIds[interstitialAdIndex],
//           request: const AdRequest(),
//           adLoadCallback: InterstitialAdLoadCallback(
//             onAdLoaded: (InterstitialAd ad) {
//               _interstitialAd = ad;
//               ad.fullScreenContentCallback = FullScreenContentCallback(
//                 onAdDismissedFullScreenContent: (InterstitialAd ad) {
//                   ad.dispose();
//                   loadInterstitialAd();
//                 },
//                 onAdFailedToShowFullScreenContent:
//                     (InterstitialAd ad, AdError error) {
//                   ad.dispose();
//                   loadInterstitialAd();
//                 },
//               );
//             },
//             onAdFailedToLoad: (LoadAdError error) {
//               interstitialAdIndex++;
//               if (interstitialAdIndex >= googleInterstitialAdIds.length) {
//                 _useGoogleAds = false;
//                 loadInterstitialAd(); // Switch to Facebook Ads
//               } else {
//                 loadInterstitialAd(); // Retry with the next Google ad unit ID
//               }
//             },
//           ),
//         );
//       } else {
//         // Switch to Facebook Ads if Google Ads failed
//         loadFacebookInterstitialAd();
//       }
//     } else {
//       loadFacebookInterstitialAd();
//     }
//   }

//   void loadRewardedAd() {
//     if (_useGoogleAds) {
//       if (rewardedAdIndex < googleRewardedAdIds.length) {
//         RewardedAd.load(
//           adUnitId: googleRewardedAdIds[rewardedAdIndex],
//           request: const AdRequest(),
//           rewardedAdLoadCallback: RewardedAdLoadCallback(
//             onAdLoaded: (RewardedAd ad) {
//               _rewardedAd = ad;
//             },
//             onAdFailedToLoad: (LoadAdError error) {
//               rewardedAdIndex++;
//               if (rewardedAdIndex >= googleRewardedAdIds.length) {
//                 _useGoogleAds = false;
//                 loadRewardedAd(); // Switch to Facebook Ads
//               } else {
//                 loadRewardedAd(); // Retry with the next Google ad unit ID
//               }
//             },
//           ),
//         );
//       } else {
//         // Switch to Facebook Ads if Google Ads failed
//         loadFacebookRewardedAd();
//       }
//     } else {
//       loadFacebookRewardedAd();
//     }
//   }

//   void loadFacebookBannerAd() {
//     if (facebookBannerAdIndex < facebookBannerAdIds.length) {
//       FacebookBannerAd(
//         placementId: facebookBannerAdIds[facebookBannerAdIndex],
//         bannerSize: BannerSize.STANDARD,
//         listener: (result, value) {
//           if (result == BannerAdResult.ERROR) {
//             facebookBannerAdIndex++;
//             if (facebookBannerAdIndex >= facebookBannerAdIds.length) {
//               _useGoogleAds = true;
//               bannerAdIndex = 0;
//               loadBannerAd(); // Switch back to Google Ads
//             } else {
//               loadFacebookBannerAd(); // Retry with the next Facebook ad unit ID
//             }
//           }
//         },
//       );
//     } else {
//       _useGoogleAds = true;
//       bannerAdIndex = 0;
//       loadBannerAd(); // Switch back to Google Ads
//     }
//   }

//   void loadFacebookInterstitialAd() {
//     if (facebookInterstitialAdIndex < facebookInterstitialAdIds.length) {
//       FacebookInterstitialAd.loadInterstitialAd(
//         placementId: facebookInterstitialAdIds[facebookInterstitialAdIndex],
//         listener: (result, value) {
//           if (result == InterstitialAdResult.ERROR) {
//             facebookInterstitialAdIndex++;
//             if (facebookInterstitialAdIndex >=
//                 facebookInterstitialAdIds.length) {
//               _useGoogleAds = true;
//               interstitialAdIndex = 0;
//               loadInterstitialAd(); // Switch back to Google Ads
//             } else {
//               loadFacebookInterstitialAd(); // Retry with the next Facebook ad unit ID
//             }
//           }
//         },
//       );
//     } else {
//       _useGoogleAds = true;
//       interstitialAdIndex = 0;
//       loadInterstitialAd(); // Switch back to Google Ads
//     }
//   }

//   void loadFacebookRewardedAd() {
//     if (facebookRewardedAdIndex < facebookRewardedAdIds.length) {
//       FacebookRewardedVideoAd.loadRewardedVideoAd(
//         placementId: facebookRewardedAdIds[facebookRewardedAdIndex],
//         listener: (result, value) {
//           if (result == RewardedVideoAdResult.ERROR) {
//             facebookRewardedAdIndex++;
//             if (facebookRewardedAdIndex >= facebookRewardedAdIds.length) {
//               _useGoogleAds = true;
//               rewardedAdIndex = 0;
//               loadRewardedAd(); // Switch back to Google Ads
//             } else {
//               loadFacebookRewardedAd(); // Retry with the next Facebook ad unit ID
//             }
//           }
//         },
//       );
//     } else {
//       _useGoogleAds = true;
//       rewardedAdIndex = 0;
//       loadRewardedAd(); // Switch back to Google Ads
//     }
//   }

//   void addAds(bool interstitial, bool bannerAd, bool rewardedAd) {
//     if (interstitial) {
//       loadInterstitialAd();
//     }

//     if (bannerAd) {
//       loadBannerAd();
//     }

//     if (rewardedAd) {
//       loadRewardedAd();
//     }
//   }

//   void showInterstitial() {
//     _interstitialAd?.show();
//   }

//   BannerAd? getBannerAd() {
//     return _bannerAd;
//   }

//   void showRewardedAd() {
//     if (_rewardedAd != null) {
//       _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
//         onAdShowedFullScreenContent: (RewardedAd ad) {
//           print("Ad onAdShowedFullScreenContent");
//         },
//         onAdDismissedFullScreenContent: (RewardedAd ad) {
//           ad.dispose();
//           loadRewardedAd();
//         },
//         onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
//           ad.dispose();
//           loadRewardedAd();
//         },
//       );

//       _rewardedAd!.setImmersiveMode(true);
//       _rewardedAd!.show(
//           onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
//         print("${reward.amount} ${reward.type}");
//       });
//     }
//   }

//   void disposeAds() {
//     _bannerAd?.dispose();
//     _interstitialAd?.dispose();
//     _rewardedAd?.dispose();
//   }
// }
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum RewardPlacement { hint, autoSolve }

class AdManager {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  final Map<RewardPlacement, RewardedAd?> _rewardedAds = {
    RewardPlacement.hint: null,
    RewardPlacement.autoSolve: null,
  };

  final List<String> googleBannerAdIds = [
    "ca-app-pub-5561438827097019/5440263702",
    "ca-app-pub-5561438827097019/9075891424",
  ];

  final List<String> googleInterstitialAdIds = [
    "ca-app-pub-5561438827097019/5136646412",
    "ca-app-pub-5561438827097019/1767777858",
  ];

  // Example rewarded ad IDs for quick testing; replace later with your own IDs.
  final List<String> hintRewardedAdIds = [
    "ca-app-pub-3940256099942544/5224354917",
  ];
  final List<String> autoSolveRewardedAdIds = [
    "ca-app-pub-3940256099942544/5224354917",
  ];

  int bannerAdIndex = 0;
  int interstitialAdIndex = 0;
  int hintRewardedAdIndex = 0;
  int autoSolveRewardedAdIndex = 0;

  void loadBannerAd() {
    if (bannerAdIndex < googleBannerAdIds.length) {
      _bannerAd = BannerAd(
        adUnitId: googleBannerAdIds[bannerAdIndex],
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            bannerAdIndex++;
            if (bannerAdIndex < googleBannerAdIds.length) {
              loadBannerAd();
            }
          },
        ),
      );

      _bannerAd?.load();
    }
  }

  void loadInterstitialAd() {
    if (interstitialAdIndex < googleInterstitialAdIds.length) {
      InterstitialAd.load(
        adUnitId: googleInterstitialAdIds[interstitialAdIndex],
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                ad.dispose();
                loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent:
                  (InterstitialAd ad, AdError error) {
                ad.dispose();
                loadInterstitialAd();
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            interstitialAdIndex++;
            if (interstitialAdIndex < googleInterstitialAdIds.length) {
              loadInterstitialAd();
            }
          },
        ),
      );
    }
  }

  void _loadRewardedAd(RewardPlacement placement) {
    final ids = placement == RewardPlacement.hint
        ? hintRewardedAdIds
        : autoSolveRewardedAdIds;
    final currentIndex = placement == RewardPlacement.hint
        ? hintRewardedAdIndex
        : autoSolveRewardedAdIndex;

    if (currentIndex < ids.length) {
      RewardedAd.load(
        adUnitId: ids[currentIndex],
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewardedAds[placement]?.dispose();
            _rewardedAds[placement] = ad;
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (placement == RewardPlacement.hint) {
              hintRewardedAdIndex++;
            } else {
              autoSolveRewardedAdIndex++;
            }
            _loadRewardedAd(placement);
          },
        ),
      );
    }
  }

  void addAds(bool interstitial, bool bannerAd, bool rewardedAd) {
    if (interstitial) {
      loadInterstitialAd();
    }
    if (bannerAd) {
      loadBannerAd();
    }
    if (rewardedAd) {
      prefetchRewardedAds();
    }
  }

  void showInterstitial() {
    _interstitialAd?.show();
  }

  BannerAd? getBannerAd() {
    return _bannerAd;
  }

  void prefetchRewardedAds() {
    if (_rewardedAds[RewardPlacement.hint] == null) {
      _loadRewardedAd(RewardPlacement.hint);
    }
    if (_rewardedAds[RewardPlacement.autoSolve] == null) {
      _loadRewardedAd(RewardPlacement.autoSolve);
    }
  }

  Future<bool> showRewardedAdForPlacement(
    RewardPlacement placement, {
    required void Function() onRewardEarned,
  }) async {
    final ad = _rewardedAds[placement];
    if (ad == null) {
      _loadRewardedAd(placement);
      return false;
    }

    var rewarded = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAds[placement] = null;
        _loadRewardedAd(placement);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAds[placement] = null;
        _loadRewardedAd(placement);
      },
    );
    ad.setImmersiveMode(true);
    await ad.show(
      onUserEarnedReward: (adWithoutView, reward) {
        rewarded = true;
        onRewardEarned();
      },
    );
    return rewarded;
  }

  void showRewardedAd() {
    showRewardedAdForPlacement(
      RewardPlacement.hint,
      onRewardEarned: () {},
    );
  }

  void disposeAds() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    for (final ad in _rewardedAds.values) {
      ad?.dispose();
    }
  }
}
