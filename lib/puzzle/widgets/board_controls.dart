import 'package:async/async.dart';
import 'package:blocked/ADs/ad_manager.dart';
import 'package:blocked/level/level.dart';
import 'package:blocked/solver/solver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

/// Glossy action row: Restart / Hint / Solve.
class BoardControls extends StatefulWidget {
  const BoardControls({Key? key}) : super(key: key);

  @override
  State<BoardControls> createState() => _BoardControlsState();
}

class _BoardControlsState extends State<BoardControls> {
  CancelableOperation? solutionOperation;
  final adManager = AdManager();
  final _hintCharges = ValueNotifier<int>(3);

  @override
  void initState() {
    super.initState();
    // Rewarded ads only when playing — don't re-bootstrap banner/interstitial.
    adManager.prefetchRewardedAds();
  }

  @override
  void dispose() {
    solutionOperation?.cancel();
    _hintCharges.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<PuzzleSolverBloc, PuzzleSolverState>(
          listenWhen: (previous, current) =>
              previous.isSolutionRequested != current.isSolutionRequested ||
              (!previous.hasSolutionResult && current.hasSolutionResult),
          listener: (context, state) {
            if (state.isSolutionRequested && !state.hasSolutionResult) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calculating solution...')),
              );
            }
            if (state.hasSolutionResult) {
              ScaffoldMessenger.of(context).clearSnackBars();
              if (state.solution == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No solution found')),
                );
              }
            }
          },
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = constraints.maxWidth < 360 ? 6.0 : 10.0;
          return Row(
            children: [
              Expanded(
                child: _GlossyActionButton(
                  label: 'RESTART',
                  icon: Icons.refresh_rounded,
                  colors: const [
                    Color(0xFFFFB04A),
                    Color(0xFFFF8A1A),
                    Color(0xFFE06A00),
                  ],
                  onTap: () {
                    context.read<LevelBloc>().add(const LevelReset());
                  },
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: _hintCharges,
                  builder: (context, charges, _) {
                    return _GlossyActionButton(
                      label: 'HINT',
                      icon: Icons.lightbulb_rounded,
                      colors: const [
                        Color(0xFFC77DFF),
                        Color(0xFF9B4DE8),
                        Color(0xFF7A2FC4),
                      ],
                      badge: charges > 0 ? '$charges' : null,
                      onTap: () async {
                        await _showRewardedAdWithLoader(
                          placement: RewardPlacement.hint,
                          onRewardEarned: () {
                            if (!mounted) return;
                            if (_hintCharges.value > 0) {
                              _hintCharges.value--;
                            }
                            context
                                .read<PuzzleSolverBloc>()
                                .add(SolutionViewed());
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _GlossyActionButton(
                  label: 'SOLVE',
                  icon: Icons.auto_fix_high_rounded,
                  colors: const [
                    Color(0xFF8FE04A),
                    Color(0xFF4CBB28),
                    Color(0xFF2F9A1A),
                  ],
                  onTap: () async {
                    await _showRewardedAdWithLoader(
                      placement: RewardPlacement.autoSolve,
                      onRewardEarned: () {
                        if (!mounted) return;
                        context
                            .read<PuzzleSolverBloc>()
                            .add(SolutionPlayed());
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showRewardedAdWithLoader({
    required RewardPlacement placement,
    required VoidCallback onRewardEarned,
  }) async {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) => const _AdLoadingDialog(),
    );

    try {
      await adManager.waitUntilRewardedAdIsReady(
        placement,
        timeout: const Duration(seconds: 35),
      );
      if (!mounted) return;

      if (adManager.isRewardedReady(placement)) {
        await adManager.showRewardedAdForPlacement(
          placement,
          onRewardEarned: onRewardEarned,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ad not ready yet — try again in a moment.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) nav.pop();
      }
      adManager.prefetchRewardedAds();
    }
  }
}

class _GlossyActionButton extends StatelessWidget {
  const _GlossyActionButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.92,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: colors,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.last.withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.4,
                        shadows: const [
                          Shadow(
                            color: Colors.black38,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Top gloss
              Positioned(
                left: 8,
                right: 8,
                top: 5,
                height: 14,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.35),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              if (badge != null)
                Positioned(
                  right: -2,
                  top: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      badge!,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdLoadingDialog extends StatelessWidget {
  const _AdLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        decoration: BoxDecoration(
          color: const Color(0xFF4A2C14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFC4A574), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3.2,
                color: Color(0xFFFFE566),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading Reward Ad...',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please wait',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
