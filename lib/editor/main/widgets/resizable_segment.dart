import 'package:blocked/editor/editor.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/resizable/resizable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ResizableSegment extends StatelessWidget {
  const ResizableSegment(this.wall, {Key? key, this.isExit, this.isSelected})
      : super(key: key);

  final EditorSegment wall;
  final bool? isExit;
  final bool? isSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = this.isSelected ??
        context.select<LevelEditorBloc, bool>(
          (LevelEditorBloc bloc) => bloc.state.selectedObject == wall,
        );

    final isExit = this.isExit ??
        context.select<LevelEditorBloc, bool>(
          (LevelEditorBloc bloc) => bloc.state.isExit(wall),
        );

    final isSharp = wall.type == SegmentType.sharp;

    return Resizable.custom(
      enabled: isSelected,
      minHeight: kWallWidth,
      minWidth: kWallWidth,
      baseHeight: kWallWidth,
      baseWidth: kWallWidth,
      initialOffset: wall.offset,
      initialSize: wall.size,
      snapSizeDelegate: SnapSizeDelegate((size) {
        // See which size is longer
        final snappedHorizontalSize = SnapSizeDelegate.interval(
          width: kBlockSizeInterval,
          widthOffset: kWallWidth,
          minWidth: kWallWidth,
          minHeight: kWallWidth,
          maxHeight: kWallWidth,
        ).sizeSnapper(size);

        final snappedVerticalSize = SnapSizeDelegate.interval(
          height: kBlockSizeInterval,
          heightOffset: kWallWidth,
          minHeight: kWallWidth,
          minWidth: kWallWidth,
          maxWidth: kWallWidth,
        ).sizeSnapper(size);

        final horizontalSnapDiff = Offset(
                snappedHorizontalSize.width - size.width,
                snappedHorizontalSize.height - size.height)
            .distance;
        final verticalSnapDiff = Offset(snappedVerticalSize.width - size.width,
                snappedVerticalSize.height - size.height)
            .distance;

        return horizontalSnapDiff < verticalSnapDiff
            ? snappedHorizontalSize
            : snappedVerticalSize;
      }),
      snapOffsetDelegate: SnapOffsetDelegate.interval(
        interval: const Offset(
          kBlockSize + kBlockToBlockGap,
          kBlockSize + kBlockToBlockGap,
        ),
      ),
      snapWhileMoving: true,
      snapWhileResizing: true,
      onTap: () {
        context.read<LevelEditorBloc>().add(EditorObjectSelected(wall));
      },
      onUpdate: (position) {
        final newSize = position.size;
        final newOffset = position.offset;
        if (wall.offset != newOffset || wall.size != newSize) {
          context.read<LevelEditorBloc>().add(
                EditorObjectMoved(
                  wall,
                  position.size,
                  position.offset,
                ),
              );
        }
      },
      builder: (context, size) {
        final width = size.width.boardSizeToBlockCount();
        final height = size.height.boardSizeToBlockCount();
        return PortalEntry(
          visible: isSelected,
          childAnchor: Alignment.topRight,
          portalAnchor: Alignment.topLeft,
          portal: Padding(
            padding: const EdgeInsets.only(left: kHandleSize),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<LevelEditorBloc>()
                        .add(const SelectedEditorObjectDeleted());
                  },
                  child: const Icon(Icons.clear),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<LevelEditorBloc>().add(EditorSegmentTypeSet(
                        wall,
                        wall.type == SegmentType.wall
                            ? SegmentType.sharp
                            : SegmentType.wall));
                  },
                  icon: wall.type == SegmentType.wall
                      ? const Icon(MdiIcons.triangleOutline)
                      : const Icon(MdiIcons.squareRoundedOutline),
                  label: Text(wall.type == SegmentType.wall
                      ? 'Make sharp'
                      : 'Make round'),
                ),
              ],
            ),
          ),
          child: AnimatedSelectable(
            isSelected: isSelected,
            child: isExit
                ? PuzzleExit(
                    Segment(const Position(0, 0), Position(width, height)))
                : PuzzleWall(
                    Segment(const Position(0, 0), Position(width, height)),
                    isSharp: isSharp,
                  ),
          ),
        );
      },
    );
  }
}
