import 'dart:async';

import 'package:blocked/level/bloc/level_bloc.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/solver/puzzle_solver.dart';
import 'package:blocked/storage/storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _tutorialDoneKey = 'tutorial.firstLevel.completed';

Future<void> markFirstLevelTutorialDone() async {
  await setBool(_tutorialDoneKey, true);
}

Future<bool> isFirstLevelTutorialDone() async {
  return getBool(_tutorialDoneKey) ?? false;
}

/// Coach overlay for the very first level: a pointing hand demonstrates the
/// swipe the player has to make next, recomputed from the solver after every
/// move so it keeps guiding even when the player goes off the optimal path.
///
/// Purely decorative — everything except the skip chip ignores pointers so the
/// normal swipe gestures still reach the level's shortcut listener.
class FirstLevelTutorial extends StatefulWidget {
  const FirstLevelTutorial({
    Key? key,
    required this.levelState,
  }) : super(key: key);

  final LevelState levelState;

  @override
  State<FirstLevelTutorial> createState() => _FirstLevelTutorialState();
}

class _FirstLevelTutorialState extends State<FirstLevelTutorial> {
  bool _visible = false;
  bool _dismissed = false;
  MoveDirection? _nextMove;
  int _solveToken = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  @override
  void didUpdateWidget(covariant FirstLevelTutorial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.levelState.isCompleted) {
      // build() below already hides the overlay — don't setState mid-update.
      _markDone();
      return;
    }
    if (_visible &&
        widget.levelState.puzzle != oldWidget.levelState.puzzle) {
      unawaited(_resolveNextMove());
    }
  }

  Future<void> _start() async {
    if (await isFirstLevelTutorialDone()) return;
    if (!mounted) return;
    setState(() => _visible = true);
    await _resolveNextMove();
  }

  Future<void> _resolveNextMove() async {
    final token = ++_solveToken;
    final solution = await solve(widget.levelState.puzzle);
    if (!mounted || token != _solveToken) return;
    setState(() {
      _nextMove = (solution == null || solution.isEmpty) ? null : solution.first;
    });
  }

  void _markDone() {
    if (_dismissed) return;
    _dismissed = true;
    _solveToken++;
    unawaited(markFirstLevelTutorialDone());
  }

  void _skip() {
    _markDone();
    setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    final direction = _nextMove;
    if (!_visible || _dismissed || direction == null) {
      return const SizedBox.shrink();
    }

    final pad = MediaQuery.paddingOf(context);
    final size = MediaQuery.sizeOf(context);
    final s = (size.height / 840).clamp(0.78, 1.12);

    // Mirrors the LevelPage chrome so the coach card never lands on the board.
    final topChrome =
        pad.top + 4 + (64.0 * s).clamp(54.0, 76.0) + 8 * s + 46 + 8 * s;
    final bottomChrome = (88.0 * s).clamp(72.0, 96.0) + 16 * s + 56;

    return Padding(
      padding: EdgeInsets.only(
        top: topChrome.clamp(0.0, size.height * 0.4),
        bottom: bottomChrome.clamp(0.0, size.height * 0.4),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: _SwipeHand(direction: direction, scale: s.toDouble()),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: _CoachCard(
              direction: direction,
              scale: s.toDouble(),
              onSkip: _skip,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({
    required this.direction,
    required this.scale,
    required this.onSkip,
  });

  final MoveDirection direction;
  final double scale;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 18 * scale),
      padding: EdgeInsets.fromLTRB(12 * scale, 8 * scale, 8 * scale, 8 * scale),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B4226), Color(0xFF3A2210)],
        ),
        border: Border.all(color: const Color(0xFFC4A574), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            direction.arrowIcon,
            color: const Color(0xFFFFD54F),
            size: 26 * scale,
          ),
          SizedBox(width: 8 * scale),
          Flexible(
            child: Text(
              'Swipe ${direction.label} to move the block',
              style: GoogleFonts.nunito(
                color: const Color(0xFFFFF1D6),
                fontWeight: FontWeight.w800,
                fontSize: 14 * scale,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(width: 8 * scale),
          Material(
            color: const Color(0xFFC4A574),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onSkip,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 10 * scale,
                  vertical: 6 * scale,
                ),
                child: Text(
                  'SKIP',
                  style: GoogleFonts.nunito(
                    color: const Color(0xFF3A2210),
                    fontWeight: FontWeight.w900,
                    fontSize: 12 * scale,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Looping hand that slides along [direction] with a touch ripple at the
/// fingertip.
class _SwipeHand extends StatefulWidget {
  const _SwipeHand({required this.direction, required this.scale});

  final MoveDirection direction;
  final double scale;

  @override
  State<_SwipeHand> createState() => _SwipeHandState();
}

class _SwipeHandState extends State<_SwipeHand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handWidth = (74.0 * widget.scale).clamp(60.0, 88.0);
    final handHeight = handWidth * (512 / 432);
    final travel = (96.0 * widget.scale).clamp(72.0, 120.0);
    final axis = widget.direction.unitOffset;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        // 0.00-0.12 appear · 0.12-0.62 slide · 0.62-0.80 hold · 0.80-1.0 fade
        final slide = Curves.easeInOutCubic
            .transform(((t - 0.12) / 0.50).clamp(0.0, 1.0));
        final opacity = t < 0.12
            ? t / 0.12
            : (t < 0.80 ? 1.0 : (1 - (t - 0.80) / 0.20));
        final press = t >= 0.12 && t <= 0.80 ? 1.0 : 0.0;

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: axis * (travel * (slide - 0.5)),
            child: _HandArt(
              width: handWidth,
              height: handHeight,
              pressed: press == 1.0,
            ),
          ),
        );
      },
    );
  }
}

class _HandArt extends StatelessWidget {
  const _HandArt({
    required this.width,
    required this.height,
    required this.pressed,
  });

  final double width;
  final double height;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    // Fingertip sits near the top-left corner of the artwork.
    final tip = Offset(width * 0.09, height * 0.03);
    final ringSize = width * 0.62;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: tip.dx - ringSize / 2,
            top: tip.dy - ringSize / 2,
            child: AnimatedScale(
              scale: pressed ? 1 : 0.6,
              duration: const Duration(milliseconds: 180),
              child: Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.75),
                    width: 2.5,
                  ),
                ),
              ),
            ),
          ),
          Image.asset(
            'assets/ui/hand.png',
            width: width,
            height: height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ],
      ),
    );
  }
}

extension on MoveDirection {
  String get label {
    switch (this) {
      case MoveDirection.up:
        return 'UP';
      case MoveDirection.down:
        return 'DOWN';
      case MoveDirection.left:
        return 'LEFT';
      case MoveDirection.right:
        return 'RIGHT';
    }
  }

  IconData get arrowIcon {
    switch (this) {
      case MoveDirection.up:
        return Icons.arrow_upward_rounded;
      case MoveDirection.down:
        return Icons.arrow_downward_rounded;
      case MoveDirection.left:
        return Icons.arrow_back_rounded;
      case MoveDirection.right:
        return Icons.arrow_forward_rounded;
    }
  }

  Offset get unitOffset {
    switch (this) {
      case MoveDirection.up:
        return const Offset(0, -1);
      case MoveDirection.down:
        return const Offset(0, 1);
      case MoveDirection.left:
        return const Offset(-1, 0);
      case MoveDirection.right:
        return const Offset(1, 0);
    }
  }
}
