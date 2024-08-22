import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../ADs/ad_manager.dart';

class GeneratedLevelPage extends StatelessWidget {
  GeneratedLevelPage(this.mapString, {Key? key}) : super(key: key) {
    adManager.addAds(true, true, true);
  }

  final String mapString;
  final adManager = AdManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LevelPage(
        Level(
          'Generated level',
          initialState: parseLevel(mapString),
        ),
        onExit: () {
          Navigator.of(context).pop();
        },
        onNext: () {
          Navigator.of(context).pop();
        },
        boardControls: BoardControls.generated(mapString),
      ),
      bottomNavigationBar: Container(
        // alignment: Alignment.center,
        child: AdWidget(ad: adManager.getBannerAd()!),
        width: adManager.getBannerAd()?.size.width.toDouble(),
        height: adManager.getBannerAd()?.size.height.toDouble(),
      ),

      ///integration here
    );
  }
}
