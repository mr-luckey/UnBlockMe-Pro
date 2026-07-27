import 'package:blocked/ADs/ad_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum BannerAdSlot { shell, play }

/// Banner strip. Takes **zero** height when no ad is loaded so layout
/// stays fully responsive / unchanged.
class BannerAdBar extends StatelessWidget {
  const BannerAdBar({
    Key? key,
    this.slot = BannerAdSlot.shell,
    this.backgroundColor,
    this.includeBottomSafeArea = true,
  }) : super(key: key);

  final BannerAdSlot slot;
  final Color? backgroundColor;
  final bool includeBottomSafeArea;

  ValueNotifier<BannerAd?> get _notifier => slot == BannerAdSlot.play
      ? AdManager().playBannerAdNotifier
      : AdManager().bannerAdNotifier;

  @override
  Widget build(BuildContext context) {
    final bottomInset =
        includeBottomSafeArea ? MediaQuery.paddingOf(context).bottom : 0.0;

    return ValueListenableBuilder<BannerAd?>(
      valueListenable: _notifier,
      builder: (context, ad, _) {
        if (ad == null) return const SizedBox.shrink();

        final bg = backgroundColor ?? const Color(0xFF1A0E08);
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
                    child: AdWidget(key: ValueKey('ad-${slot.name}'), ad: ad),
                  ),
                ),
              ),
              if (bottomInset > 0) SizedBox(height: bottomInset),
            ],
          ),
        );
      },
    );
  }
}
