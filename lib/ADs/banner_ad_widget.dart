import 'package:blocked/ADs/ad_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum BannerAdSlot { shell, play }

/// Banner strip. Takes **zero** height when no ad is loaded — offline or
/// no-fill therefore never leaves an empty band in the layout.
///
/// Only one [AdWidget] may host a given [BannerAd] — the old widget is
/// detached for a frame before the new one is mounted when the ad changes.
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
    _scheduleMount(_notifier.value);
  }

  @override
  void dispose() {
    _notifier.removeListener(_onAdChanged);
    super.dispose();
  }

  void _onAdChanged() {
    final ad = _notifier.value;
    if (_shownAd == ad || !mounted) return;
    // Detach the current AdWidget first so one BannerAd is never mounted twice.
    setState(() => _shownAd = null);
    _scheduleMount(ad);
  }

  void _scheduleMount(BannerAd? ad) {
    if (ad == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _notifier.value != ad || _shownAd == ad) return;
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
    final adWidth = ad.size.width.toDouble();
    final adHeight = ad.size.height.toDouble();

    return ColoredBox(
      color: bg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: adHeight,
            // Rotating after the size was measured can leave the ad wider than
            // the screen for one load cycle — clip instead of overflowing.
            child: ClipRect(
              child: Center(
                child: SizedBox(
                  width: adWidth,
                  height: adHeight,
                  child: AdWidget(
                    key: ValueKey(
                      'ad-${widget.slot.name}-${identityHashCode(ad)}',
                    ),
                    ad: ad,
                  ),
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
