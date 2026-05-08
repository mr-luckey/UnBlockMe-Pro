import 'package:async/async.dart';
// import 'package:blocked/ADs/ad%20helper.dart';
import 'package:blocked/editor/editor.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/routing/routing.dart';
import 'package:blocked/solver/solver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Solution viewed. Reload level to save progress.'),
                    duration: Duration(seconds: 2),
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
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(16),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 520;
                final baseButtons = [
                  Expanded(
                    child: _compactControlButton(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'Hint',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.ondemand_video_rounded,
                                size: 10,
                                color:
                                    Theme.of(context).colorScheme.onTertiaryContainer),
                            // SizedBox(width: 3),
                            // Text('Ad 15s',
                            //     style: TextStyle(color: Colors.black)),
                          ],
                        ),
                      ),
                      onPressed: () async {
                        await _showRewardedAdWithLoader(
                          placement: RewardPlacement.hint,
                          onRewardEarned: () {
                            context
                                .read<PuzzleSolverBloc>()
                                .add(SolutionViewed());
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _compactControlButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Auto Solve',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.ondemand_video_rounded,
                                size: 10,
                                color:
                                    Theme.of(context).colorScheme.onSecondaryContainer),
                            // SizedBox(width: 3),
                            // Text('Ad 60s',
                            //     style: TextStyle(
                            //         color: Colors.black, fontSize: 5)),
                          ],
                        ),
                      ),
                      onPressed: () async {
                        await _showRewardedAdWithLoader(
                          placement: RewardPlacement.autoSolve,
                          onRewardEarned: () {
                            context
                                .read<PuzzleSolverBloc>()
                                .add(SolutionPlayed());
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _compactControlButton(
                      icon: Icons.refresh_rounded,
                      label: 'Reset',
                      onPressed: () {
                        context.read<LevelBloc>().add(const LevelReset());
                      },
                    ),
                  ),
                ];

                if (widget.isGenerated) {
                  return Column(
                    children: [
                      Row(children: baseButtons),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: AdaptiveTextButton(
                              icon: const Icon(MdiIcons.contentCopy),
                              label: const Text('YAML'),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text: '- name: generated\n'
                                        '  map: |-\n'
                                        '${widget.mapString!.split('\n').map((line) => '    $line').join('\n')}',
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AdaptiveTextButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(
                                    text:
                                        'https://slide.jeffsieu.com/#/editor/generated/${encodeMapString(widget.mapString!)}',
                                  ),
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
                        ],
                      ),
                    ],
                  );
                }

                if (isNarrow) {
                  return Column(
                    children: [
                      Row(children: baseButtons),
                      if (isCompleted) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            label: const Text('Next'),
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              context.read<LevelNavigation>().onNext();
                            },
                          ),
                        ),
                      ],
                    ],
                  );
                }

                return Row(
                  children: [
                    ...baseButtons,
                    if (isCompleted) ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        label: const Text('Next'),
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          adManager.showInterstitial();
                          context.read<LevelNavigation>().onNext();
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _compactControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Widget? trailing,
  }) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showRewardedAdWithLoader({
    required RewardPlacement placement,
    required VoidCallback onRewardEarned,
  }) async {
    if (!mounted) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Theme.of(context).colorScheme.scrim.withOpacity(0.54),
      builder: (dialogContext) => const _AdLoadingDialog(),
    );

    try {
      while (mounted) {
        await adManager.waitUntilRewardedAdIsReady(placement);
        if (!mounted) {
          break;
        }
        final showResult = await adManager.showRewardedAdForPlacement(
          placement,
          onRewardEarned: onRewardEarned,
        );
        if (showResult == RewardShowResult.shown) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      adManager.prefetchRewardedAds();
    }
  }
}

class _AdLoadingDialog extends StatelessWidget {
  const _AdLoadingDialog();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withOpacity(0.18),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3.2,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading Reward Ad...',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Please wait',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
