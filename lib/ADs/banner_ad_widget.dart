import 'package:blocked/ADs/ad_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum BannerAdSlot { shell, play }

/// Banner strip. Takes **zero** height when no ad is loaded so layout
/// stays fully responsive / unchanged.
///
/// Only one [AdWidget] may host a given [BannerAd] — this widget keeps a
/// single mounted instance and swaps on the next frame when the ad changes.
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

  ValueNotifier<BannerAd?> get _notifier => widget.slot == BannerAdSlot.play
      ? AdManager().playBannerAdNotifier
      : AdManager().bannerAdNotifier;

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_onAdChanged);
    _syncAd(_notifier.value);
  }

  @override
  void dispose() {
    _notifier.removeListener(_onAdChanged);
    super.dispose();
  }

  void _onAdChanged() => _syncAd(_notifier.value);

  void _syncAd(BannerAd? ad) {
    if (_shownAd == ad) return;
    if (!mounted) return;
    setState(() => _shownAd = null);
    if (ad == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _notifier.value != ad) return;
      setState(() => _shownAd = ad);
    });
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
