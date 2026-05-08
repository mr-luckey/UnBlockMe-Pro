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
                      color: Theme.of(context).colorScheme.scrim.withOpacity(0.5),
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

class _ExitLabel extends StatelessWidget {
  const _ExitLabel({
    required this.segment,
    required this.boardWidth,
    required this.boardHeight,
  });

  final Segment segment;
  final int boardWidth;
  final int boardHeight;

  @override
  Widget build(BuildContext context) {
    final openingLength =
        max(segment.width.toWallSize(), segment.height.toWallSize());
    final iconSize = (openingLength * 0.52).clamp(12.0, 26.0);

    final arrow = Icon(
      Icons.arrow_forward_rounded,
      size: iconSize,
      color: Theme.of(context).colorScheme.primary,
    );

    if (segment.isVertical) {
      final turn = segment.start.x == boardWidth ? 1 : 3;
      return RotatedBox(quarterTurns: turn, child: arrow);
    }

    if (segment.start.y == boardHeight) {
      return RotatedBox(quarterTurns: 2, child: arrow);
    }
    return arrow;
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
