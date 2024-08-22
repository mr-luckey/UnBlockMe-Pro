import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeColorPreview extends StatelessWidget {
  const ThemeColorPreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LevelBloc(
        LevelState.initial(
          PuzzleState.initial(
            3,
            1,
            blocks: [
              const Block(1, 1, isMain: true, hasControl: true).place(0, 0),
              const Block(1, 1).place(1, 0),
            ],
            walls: [
              Segment.horizontal(y: 0, start: 0, end: 3),
              Segment.horizontal(y: 1, start: 0, end: 3),
              Segment.vertical(x: 0, start: 0, end: 1),
            ],
            sharpWalls: const [],
          ),
        ),
      ),
      child: const Puzzle(),
    );
  }
}
