import 'package:blocked/ADs/ad_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum BannerAdSlot { shell, play }

/// Banner strip. Takes **zero** height when no ad is loaded so layout
/// stays fully responsive / unchanged.
///
/// Only one [AdWidget] may host a given [BannerAd] — this widget keeps a
/// single mounted instance and swaps when the ad changes.
///
/// Play slot falls back to the shell banner while the gameplay unit loads
/// (shell [BannerAdBar] is unmounted during levels, so no double-mount).
class BannerAdBar extends StatefulWidget {
  const BannerAdBar({
    Key? key,
    this.slot = BannerAdSlot.shell,
    this.backgroundColor,
    this.includeBottomSafeArea = true,
  }) : super(key: key);

  final BannerAdSlot slot;
  final Color? backgroundColor;
  final bool includeBottomSafeArea;

  @override
  State<BannerAdBar> createState() => _BannerAdBarState();
}

class _BannerAdBarState extends State<BannerAdBar> {
  BannerAd? _shownAd;
  late final VoidCallback _onShellChanged;
  late final VoidCallback _onPlayChanged;

  @override
  void initState() {
    super.initState();
    _onShellChanged = () => _syncFromNotifiers();
    _onPlayChanged = () => _syncFromNotifiers();
    AdManager().bannerAdNotifier.addListener(_onShellChanged);
    if (widget.slot == BannerAdSlot.play) {
      AdManager().playBannerAdNotifier.addListener(_onPlayChanged);
    }
    _syncFromNotifiers();
  }

  @override
  void dispose() {
    AdManager().bannerAdNotifier.removeListener(_onShellChanged);
    if (widget.slot == BannerAdSlot.play) {
      AdManager().playBannerAdNotifier.removeListener(_onPlayChanged);
    }
    super.dispose();
  }

  BannerAd? _resolveAd() {
    if (widget.slot == BannerAdSlot.play) {
      return AdManager().playBannerAdNotifier.value ??
          AdManager().bannerAdNotifier.value;
    }
    return AdManager().bannerAdNotifier.value;
  }

  void _syncFromNotifiers() => _syncAd(_resolveAd());

  void _syncAd(BannerAd? ad) {
    if (_shownAd == ad) return;
    if (!mounted) return;
    if (ad == null) {
      // Only hide when there is truly nothing to show.
      setState(() => _shownAd = null);
      return;
    }
    // Swap directly — old AdWidget unmounts with the new one in the same frame.
    setState(() => _shownAd = ad);
  }

  @override
  Widget build(BuildContext context) {
    final ad = _shownAd;
    if (ad == null) return const SizedBox.shrink();

    final bottomInset = widget.includeBottomSafeArea
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    final bg = widget.backgroundColor ?? const Color(0xFF1A0E08);

    return ColoredBox(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: ad.size.height.toDouble(),
            child: Center(
              child: SizedBox(
                width: ad.size.width.toDouble(),
                height: ad.size.height.toDouble(),
                child: AdWidget(
                  key: ValueKey('ad-${widget.slot.name}-${identityHashCode(ad)}'),
                  ad: ad,
                ),
              ),
            ),
          ),
          if (bottomInset > 0) SizedBox(height: bottomInset),
        ],
      ),
    );
  }
}
