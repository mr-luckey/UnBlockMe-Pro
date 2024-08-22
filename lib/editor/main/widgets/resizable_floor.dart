import 'package:blocked/editor/editor.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/resizable/resizable.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResizableFloor extends StatelessWidget {
  const ResizableFloor(this.floor, this.exits, {Key? key, this.isSelected})
      : useContainer = false,
        super(key: key);
  const ResizableFloor.container(this.floor, this.exits,
      {Key? key, this.isSelected})
      : useContainer = true,
        super(key: key);

  final EditorFloor floor;
  final List<Segment> exits;
  final bool useContainer;
  final bool? isSelected;

  @override
  Widget build(BuildContext context) {
    return Resizable(
      enabled: isSelected ??
          context.select(
              (LevelEditorBloc bloc) => bloc.state.selectedObject == null),
      initialSize: Size(floor.width.toBoardSize(), floor.height.toBoardSize()),
      minHeight: 1.toBoardSize(),
      minWidth: 1.toBoardSize(),
      snapHeightInterval: 2.toBoardSize() - 1.toBoardSize(),
      snapWidthInterval: 2.toBoardSize() - 1.toBoardSize(),
      snapWhileMoving: true,
      snapWhileResizing: true,
      baseWidth: 1.toBoardSize(),
      baseHeight: 1.toBoardSize(),
      snapOffsetInterval: const Offset(
        kBlockSize + kBlockToBlockGap,
        kBlockSize + kBlockToBlockGap,
      ),
      onTap: () {
        context.read<LevelEditorBloc>().add(const EditorObjectSelected(null));
      },
      onUpdate: (position) {
        final newSize = position.size;
        final newOffset = position.offset;
        if (floor.offset != newOffset || floor.size != newSize) {
          context.read<LevelEditorBloc>().add(
                EditorObjectMoved(
                  floor,
                  position.size,
                  position.offset,
                ),
              );
        }
      },
      builder: (context, size) {
        final boardWidth = size.width.boardSizeToBlockCount();
        final boardHeight = size.height.boardSizeToBlockCount();

        final walls = [
          Segment.from(const Position(0, 0), Position(boardWidth, 0)),
          Segment.from(const Position(0, 0), Position(0, boardHeight)),
          Segment.from(
              Position(0, boardHeight), Position(boardWidth, boardHeight)),
          Segment.from(
              Position(boardWidth, 0), Position(boardWidth, boardHeight)),
        ];

        final subtractedWalls = walls
            .map((wall) => wall.subtractAll(
                exits.map((e) => e.translate(-floor.left, -floor.top))))
            .flattened
            .toList();

        return Stack(
          children: [
            if (useContainer)
              PuzzleFloor.container(width: boardWidth, height: boardHeight)
            else
              PuzzleFloor.material(
                width: boardWidth,
                height: boardHeight,
              ),
            for (var wall in subtractedWalls) ...{
              Positioned(
                left: wall.start.x.toWallOffset(),
                top: wall.start.y.toWallOffset(),
                child: PuzzleWall(
                  wall,
                  isSharp: false,
                ),
              ),
            },
          ],
        );
      },
    );
  }
}
