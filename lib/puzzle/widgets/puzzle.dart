import 'dart:math';

import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Puzzle extends StatefulWidget {
  const Puzzle({Key? key}) : super(key: key);

  @override
  State<Puzzle> createState() => _PuzzleState();
}

class _PuzzleState extends State<Puzzle> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kSlideDuration * 0.5,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = context.select((LevelBloc bloc) => bloc.state);
    final latestMove =
        context.select((LevelBloc bloc) => bloc.state.latestMove);
    final isCompleted =
        context.select((LevelBloc bloc) => bloc.state.isCompleted);

    final exits = _getExits(board.width, board.height, board.walls);

    return RepaintBoundary(
      child: FittedBox(
        child: BlocListener<LevelBloc, LevelState>(
          listenWhen: (previous, current) =>
              previous.latestMove != current.latestMove,
          listener: (context, state) async {
            final latestMove = state.latestMove;
            if (latestMove != null && !latestMove.didMove) {
              await _controller.forward(from: 0);
              await _controller.reverse();
            }
          },
          child: PuzzleFloor.container(
            width: board.width,
            height: board.height,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topLeft,
              children: [
                for (var block in board.blocks)
                  AnimatedPositioned(
                    key: ValueKey(board.blocks.indexOf(block)),
                    duration: kSlideDuration,
                    curve: Curves.easeInOutCubic,
                    left: block.left.toBlockOffset(),
                    top: block.top.toBlockOffset(),
                    child: AnimatedOpacity(
                      opacity: board.isCompleted && block.isMain ? 0 : 1,
                      duration: kSlideDuration,
                      child: SlideTransition(
                        position: (block.position == latestMove?.block.position
                                ? _controller
                                : const AlwaysStoppedAnimation(0.0))
                            .drive(CurveTween(curve: Curves.easeInOutCubic))
                            .drive(Tween(
                                begin: Offset.zero,
                                end: Offset.fromDirection(
                                    latestMove?.direction.toRadians() ?? 0,
                                    ((2 * kBlockGap + kWallWidth) /
                                            kBlockSize) /
                                        (latestMove?.direction.isVertical ??
                                                false
                                            ? block.height
                                            : block.width)))),
                        child: PuzzleBlock(block),
                      ),
                    ),
                  ),
                for (var wall in board.walls)
                  Positioned(
                    left: wall.start.x.toWallOffset(),
                    top: wall.start.y.toWallOffset(),
                    child: PuzzleWall(
                      wall,
                      isSharp: false,
                    ),
                  ),
                for (var wall in board.sharpWalls)
                  Positioned(
                    left: wall.start.x.toWallOffset(),
                    top: wall.start.y.toWallOffset(),
                    child: PuzzleWall(
                      wall,
                      isSharp: true,
                    ),
                  ),
                for (var exit in exits)
                  Positioned(
                    left: exit.start.x.toWallOffset(),
                    top: exit.start.y.toWallOffset(),
                    width: exit.width.toWallSize(),
                    height: exit.height.toWallSize(),
                    child: Center(
                      child: _ExitLabel(
                        segment: exit,
                        boardWidth: board.width,
                        boardHeight: board.height,
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: isCompleted ? 1 : 0,
                    duration: kSlideDuration,
                    child: Container(
                      color:
                          Theme.of(context).colorScheme.scrim.withOpacity(0.5),
                      child: AnimatedScale(
                        scale: isCompleted ? 1 : 0,
                        duration: kSlideDuration * 5,
                        curve: const Interval(1 / 3, 1.0,
                            curve: Curves.elasticOut),
                        child: FittedBox(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Icon(Icons.check,
                                color: BoardColor.of(context).checkmark),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Segment> _getExits(
  int mapWidth,
  int mapHeight,
  Iterable<Segment> wallsToSubtract,
) {
  final outerWalls = [
    Segment.horizontal(y: 0, start: 0, end: mapWidth),
    Segment.horizontal(y: mapHeight, start: 0, end: mapWidth),
    Segment.vertical(x: 0, start: 0, end: mapHeight),
    Segment.vertical(x: mapWidth, start: 0, end: mapHeight),
  ];

  final exits = <Segment>[];
  for (final wall in outerWalls) {
    exits.addAll(wall.subtractAll(wallsToSubtract));
  }
  return exits;
}

enum _ExitSide { left, right, top, bottom }

class _ExitLabel extends StatefulWidget {
  const _ExitLabel({
    required this.segment,
    required this.boardWidth,
    required this.boardHeight,
  });

  final Segment segment;
  final int boardWidth;
  final int boardHeight;

  @override
  State<_ExitLabel> createState() => _ExitLabelState();
}

class _ExitLabelState extends State<_ExitLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segment = widget.segment;
    final openingLength =
        max(segment.width.toWallSize(), segment.height.toWallSize());
    final iconSize = (openingLength * 0.52).clamp(12.0, 26.0);
    final accent = Theme.of(context).colorScheme.primary;

    // Which edge of the board this exit sits on. This — not the old
    // start.x/start.y-vs-turn guesswork — is the single source of truth
    // for both which way the arrow points AND which way it's pushed.
    final _ExitSide side;
    if (segment.isVertical) {
      side = segment.start.x == widget.boardWidth
          ? _ExitSide.right
          : _ExitSide.left;
    } else {
      side = segment.start.y == widget.boardHeight
          ? _ExitSide.bottom
          : _ExitSide.top;
    }

    // Base icon (arrow_forward_rounded) points right (0°). Rotate it so it
    // points the same way a block would actually leave the board on this
    // side — right-wall exit -> arrow points right, left-wall -> left,
    // top -> up, bottom -> down. (The previous version had these mixed up,
    // e.g. a right-side exit rendered a downward-pointing arrow.)
    int quarterTurns;
    switch (side) {
      case _ExitSide.right:
        quarterTurns = 0;
        break;
      case _ExitSide.bottom:
        quarterTurns = 1;
        break;
      case _ExitSide.left:
        quarterTurns = 2;
        break;
      case _ExitSide.top:
        quarterTurns = 3;
        break;
    }

    // Push the arrow clear of the board edge, in the same direction it
    // points, so it visually reads as "flying out" of the exit rather than
    // sitting half-on/half-off the wall.
    final pushDistance = iconSize * 0.85;
    Offset outwardOffset;
    switch (side) {
      case _ExitSide.right:
        outwardOffset = Offset(pushDistance, 0);
        break;
      case _ExitSide.left:
        outwardOffset = Offset(-pushDistance, 0);
        break;
      case _ExitSide.top:
        outwardOffset = Offset(0, -pushDistance);
        break;
      case _ExitSide.bottom:
        outwardOffset = Offset(0, pushDistance);
        break;
    }

    // The arrow used to render as a bare Icon floating in the exit gap,
    // with nothing to anchor it visually — it read as a stray glitchy mark
    // rather than an intentional "the exit is here" signal. Wrapping it in
    // a soft glowing halo + a slow pulse makes it unmistakably a beacon.
    final arrow = AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = _pulseController.value;
        final scale = 1.0 + (0.12 * t);
        final glow = 0.15 + (0.20 * t);
        return Container(
          padding: EdgeInsets.all(iconSize * 0.35),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(glow),
                blurRadius: iconSize * 0.9,
                spreadRadius: iconSize * 0.15,
              ),
            ],
          ),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Icon(
        Icons.arrow_forward_rounded,
        size: iconSize,
        color: accent,
      ),
    );

    return Transform.translate(
      offset: outwardOffset,
      child: RotatedBox(quarterTurns: quarterTurns, child: arrow),
    );
  }
}

extension on MoveDirection {
  double toRadians() {
    switch (this) {
      case MoveDirection.right:
        return 0.0;
      case MoveDirection.down:
        return 0.5 * pi;
      case MoveDirection.left:
        return 1.0 * pi;
      case MoveDirection.up:
        return 1.5 * pi;
    }
  }
}
