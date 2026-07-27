import 'package:blocked/ADs/ad_manager.dart';
import 'package:blocked/ADs/banner_ad_widget.dart';
import 'package:blocked/home_page.dart';
import 'package:blocked/level_selection/level_selection.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/settings/settings.dart';
import 'package:blocked/widgets/forest_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Keeps Home / Levels / Settings alive in an [IndexedStack] so tab switches
/// are instant (no Navigator page rebuild / transition).
///
/// Order (bottom → top of chrome): content → wood nav → banner (very bottom).
/// When no banner is loaded, it occupies 0 height so UI looks identical.
class MainShell extends StatelessWidget {
  const MainShell({Key? key, required this.chapters}) : super(key: key);

  final List<LevelChapter> chapters;

  static ForestNavTab tabEnum(int index) {
    switch (index) {
      case 1:
        return ForestNavTab.levels;
      case 2:
        return ForestNavTab.settings;
      default:
        return ForestNavTab.home;
    }
  }

  static String _bgFor(int index) {
    switch (index) {
      case 1:
        return 'assets/ui/map/bg.png';
      case 2:
        return 'assets/ui/home/bg.png';
      default:
        return 'assets/ui/home/bg.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final s = (MediaQuery.sizeOf(context).height / 840).clamp(0.82, 1.12);
    final nav = context.read<NavigatorCubit>();

    return BlocBuilder<NavigatorCubit, AppRoutePath>(
      buildWhen: (prev, next) {
        final wasPlaying = prev is LevelRoutePath && prev.levelName != null;
        final isPlaying = next is LevelRoutePath && next.levelName != null;
        if (wasPlaying != isPlaying) {
          return wasPlaying;
        }
        if (isPlaying) return false;
        return nav.effectiveShellTab(prev) != nav.effectiveShellTab(next);
      },
      builder: (context, path) {
        final index = context.read<NavigatorCubit>().effectiveShellTab(path);
        final inLevel =
            path is LevelRoutePath && path.levelName != null;
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: _ResponsiveBg(asset: _bgFor(index)),
            ),
            Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: index,
                    sizing: StackFit.expand,
                    children: [
                      HomePage(chapters: chapters),
                      LevelMapPage(chapters),
                      const SettingsPage(),
                    ],
                  ),
                ),
                // Only nav padding reacts to banner — pages stay untouched.
                ValueListenableBuilder<BannerAd?>(
                  valueListenable: AdManager().bannerAdNotifier,
                  builder: (context, banner, _) {
                    return ForestBottomNav(
                      current: tabEnum(index),
                      bottomPad: banner != null ? 0 : pad.bottom,
                      scale: s,
                    );
                  },
                ),
                // Hide while a level is open — play screen has its own banner.
                if (!inLevel) const BannerAdBar(),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ResponsiveBg extends StatelessWidget {
  const _ResponsiveBg({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      ),
    );
  }
}
