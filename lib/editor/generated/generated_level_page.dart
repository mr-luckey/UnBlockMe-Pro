import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:flutter/material.dart';

import '../../ADs/ad_manager.dart';

class GeneratedLevelPage extends StatelessWidget {
  GeneratedLevelPage(this.mapString, {Key? key}) : super(key: key) {
    adManager.addAds(true, true, false);
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
    );
  }
}
