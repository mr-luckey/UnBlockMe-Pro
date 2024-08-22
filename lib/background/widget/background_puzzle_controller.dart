import 'dart:math';

import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BackgroundRotationController extends InheritedWidget {
  const BackgroundRotationController({
    Key? key,
    required Widget child,
    required this.controller,
  }) : super(key: key, child: child);

  final AnimationController controller;

  @override
  bool updateShouldNotify(BackgroundRotationController oldWidget) {
    return oldWidget.controller != controller;
  }

  static AnimationController of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<BackgroundRotationController>();
    assert(widget != null,
        'BackgroundRotationController.of() called with a context that does not contain a BackgroundRotationController.');
    return widget!.controller;
  }
}

class BackgroundPuzzleController extends StatefulWidget {
  const BackgroundPuzzleController({Key? key, required this.child})
      : super(key: key);

  final Widget child;

  @override
  State<BackgroundPuzzleController> createState() {
    return _BackgroundPuzzleControllerState();
  }
}

class _BackgroundPuzzleControllerState extends State<BackgroundPuzzleController>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(duration: const Duration(seconds: 30), vsync: this);

  var moveIndex = 0;

  final List<MoveDirection> moves = [
    MoveDirection.right,
    MoveDirection.right,
    MoveDirection.down,
    MoveDirection.down,
    MoveDirection.left,
    MoveDirection.left,
    MoveDirection.up,
    MoveDirection.up,
  ];

  @override
  void initState() {
    super.initState();
    // Start from a random position.
    _controller.value = Random().nextDouble();
    _controller.repeat(period: const Duration(seconds: 60));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return LevelBloc(
          LevelState.initial(
            PuzzleState.initial(
              3,
              3,
              blocks: [
                const Block(1, 1, isMain: true, hasControl: true).place(0, 0),
                const Block(1, 1).place(1, 0),
                const Block(1, 1).place(2, 2),
              ],
              walls: [
                Segment.horizontal(y: 0, start: 0, end: 3),
                Segment.vertical(x: 0, start: 0, end: 3),
                Segment.horizontal(y: 3, start: 0, end: 3),
                Segment.vertical(x: 3, start: 0, end: 3),
              ],
              sharpWalls: const [],
            ),
          ),
        )..add(MoveAttempt(moves[moveIndex++]));
      },
      child: BlocListener<LevelBloc, LevelState>(
        listenWhen: (previous, current) => previous != current,
        listener: (context, state) async {
          final move = moves[moveIndex];
          await Future.delayed(kSlideDuration * 10);
          context.read<LevelBloc>().add(MoveAttempt(move));
          moveIndex = (moveIndex + 1) % moves.length;
        },
        child: BackgroundRotationController(
          controller: _controller,
          child: widget.child,
        ),
      ),
    );
  }
}
