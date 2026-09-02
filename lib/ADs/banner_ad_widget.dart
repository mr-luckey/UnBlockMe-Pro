import 'package:blocked/ADs/ad_manager.dart';
import 'package:blocked/ADs/network_status.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum BannerAdSlot { shell, play }

/// One on-screen banner placement. Collapses on no-fill / offline.
/// Loads only when this widget is mounted (visibility-driven).
class BannerAdBar extends StatefulWidget {
  const BannerAdBar({
    Key? key,
    this.slot = BannerAdSlot.shell,
    this.backgroundColor,
    this.includeBottomSafeArea = true,
    this.topGap = 0,
  }) : super(key: key);

  final BannerAdSlot slot;
  final Color? backgroundColor;
  final bool includeBottomSafeArea;

  /// Space between gameplay controls and the ad strip.
  final double topGap;

  @override
  State<BannerAdBar> createState() => _BannerAdBarState();
}

class _BannerAdBarState extends State<BannerAdBar> {
  BannerAd? _shownAd;
  final _manager = AdManager();

  ValueNotifier<BannerAd?> get _notifier => widget.slot == BannerAdSlot.play
      ? _manager.playBannerAdNotifier
      : _manager.bannerAdNotifier;

  @override
  void initState() {
    super.initState();
    _notifier.addListener(_onAdChanged);
    networkOnline.addListener(_onNetworkChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.slot == BannerAdSlot.play) {
        _manager.enterGameplayBanner();
      } else {
        _manager.ensureShellBanner();
      }
    });
    _scheduleMount(_notifier.value);
  }

  @override
  void dispose() {
    _notifier.removeListener(_onAdChanged);
    networkOnline.removeListener(_onNetworkChanged);
    super.dispose();
  }

  void _onNetworkChanged() {
    if (!networkOnline.value && mounted) {
      setState(() => _shownAd = null);
    }
  }

  void _onAdChanged() {
    final ad = _notifier.value;
    if (_shownAd == ad || !mounted) return;
    setState(() => _shownAd = null);
    _scheduleMount(ad);
  }

  void _scheduleMount(BannerAd? ad) {
    if (ad == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _notifier.value != ad || _shownAd == ad) return;
      if (!_manager.adsAvailable) return;
      setState(() => _shownAd = ad);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_manager.adsAvailable) {
      return const SizedBox.shrink();
    }

    final ad = _shownAd;
    if (ad == null) {
      return const SizedBox.shrink();
    }

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
          if (widget.topGap > 0) SizedBox(height: widget.topGap),
          SizedBox(
            width: double.infinity,
            height: adHeight,
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
