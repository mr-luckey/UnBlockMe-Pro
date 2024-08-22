import 'dart:io';

import 'package:async/async.dart';
// import 'package:blocked/ADs/ad%20helper.dart';
import 'package:blocked/editor/editor.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/solver/solver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../ADs/ad_manager.dart';

class BoardControls extends StatefulWidget {
  const BoardControls({Key? key})
      : mapString = null,
        super(key: key);
  const BoardControls.generated(this.mapString, {Key? key}) : super(key: key);
  final String? mapString;

  bool get isGenerated => mapString != null;

  @override
  State<BoardControls> createState() => _BoardControlsState();
}

class _BoardControlsState extends State<BoardControls> {
  CancelableOperation? solutionOperation;
  final adManager = AdManager();

  @override
  void initState() {
    super.initState();
    adManager.addAds(true, true, true);
  }

  @override
  void dispose() {
    solutionOperation?.cancel();
    adManager.disposeAds();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted =
        context.select((LevelBloc bloc) => bloc.state.isCompleted);
    return MultiBlocListener(
      listeners: [
        BlocListener<PuzzleSolverBloc, PuzzleSolverState>(
          listenWhen: (previous, current) =>
              previous.isSolutionRequested != current.isSolutionRequested ||
              (!previous.hasSolutionResult && current.hasSolutionResult),
          listener: (context, state) {
            if (state.isSolutionRequested && !state.hasSolutionResult) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Calculating solution...',
                  ),
                ),
              );
            }
            if (state.hasSolutionResult) {
              ScaffoldMessenger.of(context).clearSnackBars();
              final moves = state.solution;

              if (moves == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No solution found')));
                return;
              }
              if (!widget.isGenerated) {
                ScaffoldMessenger.of(context).showMaterialBanner(
                  MaterialBanner(
                    content: const Text(
                        'Solution viewed. Reload level to save progress.'),
                    actions: [
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () => ScaffoldMessenger.of(context)
                            .hideCurrentMaterialBanner(
                                reason: MaterialBannerClosedReason.hide),
                      ),
                    ],
                  ),
                );
              }
            }
          },
        ),
        BlocListener<PuzzleSolverBloc, PuzzleSolverState>(
          listenWhen: (previous, current) =>
              !previous.isSolutionVisible && current.isSolutionVisible,
          listener: (context, state) async {
            final moves = state.solution;
            if (moves == null) {
              return;
            }

            await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => SolutionPage(
                initialState: context.read<LevelBloc>().initialState,
                solution: moves,
              ),
            ));
            context.read<PuzzleSolverBloc>().add(SolutionHidden());
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          return IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                PopupMenuButton(
                  icon: const Icon(Icons.lightbulb_outline_rounded),
                  tooltip: 'Hint',
                  onOpened: () {
                    adManager.showInterstitial();
                    print("reward ads here");
                    // AdHelper.showRewardedAd(onComplete: () {
                    //
                    // });
                    /// todo ads integration here
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'show_steps',
                      child: Text('Show steps'),
                    ),
                    const PopupMenuItem(
                      value: 'play_solution',
                      child: Text('Play solution'),
                    ),
                  ],
                  onSelected: (String value) {
                    switch (value) {
                      case 'show_steps':
                        // void showRewardAd()
                        adManager.showInterstitial();
                        context.read<PuzzleSolverBloc>().add(SolutionViewed());
                        break;
                      case 'play_solution':
                        adManager.showInterstitial();

                        ///todo google ads integration
                        context.read<PuzzleSolverBloc>().add(SolutionPlayed());
                        break;
                    }
                  },
                ),
                const VerticalDivider(),
                Tooltip(
                  message: 'Reset (R)',
                  child: TextButton.icon(
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset'),
                    onPressed: () {
                      ///intersatial ads here...
                      adManager.showInterstitial();
                      context.read<LevelBloc>().add(const LevelReset());
                    },
                  ),
                ),
                const Spacer(),
                if (widget.mapString != null) ...{
                  Tooltip(
                    message: 'Copy as YAML',
                    child: AdaptiveTextButton(
                      icon: const Icon(MdiIcons.contentCopy),
                      label: const Text('YAML'),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                              text: '- name: generated\n'
                                  '  map: |-\n'
                                  '${widget.mapString!.split('\n').map((line) => '    $line').join('\n')}'),
                        );
                      },
                    ),
                  ),
                  Tooltip(
                    message: 'Copy shareable link',
                    child: AdaptiveTextButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                              text:
                                  'https://slide.jeffsieu.com/#/editor/generated/${encodeMapString(widget.mapString!)}'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied link to clipboard'),
                          ),
                        );
                      },
                      icon: Icon(Icons.adaptive.share),
                      label: const Text('Copy link'),
                    ),
                  ),
                },
                if (!widget.isGenerated)
                  AnimatedOpacity(
                    opacity: isCompleted ? 1.0 : 0.0,
                    duration: kSlideDuration,
                    child: Tooltip(
                      message: 'Next (Enter)',
                      child: ElevatedButton.icon(
                        label: const Text('Next'),
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          ///intersatial ads here
                          adManager.showInterstitial();
                          context.read<LevelNavigation>().onNext();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
