import 'package:blocked/level/level.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StaticPuzzle extends StatelessWidget {
  const StaticPuzzle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final board = context.select((LevelBloc bloc) => bloc.state);
    final controlledBlock =
        context.select((LevelBloc bloc) => bloc.state.controlledBlock);

    return FittedBox(
      child: CustomPaint(
        size: Size(board.width.toBoardSize(), board.height.toBoardSize()),
        painter: BoardPainter(context, board, controlledBlock),
      ),
    );
  }
}
