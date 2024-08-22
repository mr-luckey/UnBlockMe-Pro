import 'package:blocked/editor/editor.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/resizable/resizable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ResizableBlock extends StatelessWidget {
  const ResizableBlock(this.block, {Key? key, this.isSelected})
      : super(key: key);

  final EditorBlock block;
  final bool? isSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = this.isSelected ??
        context.select<LevelEditorBloc, bool>(
          (LevelEditorBloc bloc) => bloc.state.selectedObject == block,
        );
    final isMainBlock = context.select(
      (LevelEditorBloc bloc) => bloc.state.mainBlock == block,
    );
    final isInitialBlock = context.select(
      (LevelEditorBloc bloc) => bloc.state.initialBlock == block,
    );

    return Resizable(
      enabled: isSelected,
      minHeight: kBlockSize,
      minWidth: kBlockSize,
      baseHeight: kBlockSize,
      baseWidth: kBlockSize,
      initialOffset: block.offset,
      initialSize: block.size,
      snapHeightInterval: kBlockSizeInterval,
      snapWidthInterval: kBlockSizeInterval,
      snapWhileMoving: true,
      snapWhileResizing: true,
      snapOffsetInterval: const Offset(
        kBlockSize + kBlockToBlockGap,
        kBlockSize + kBlockToBlockGap,
      ),
      snapBaseOffset: const Offset(
        kWallWidth + kBlockGap,
        kWallWidth + kBlockGap,
      ),
      onTap: () {
        context.read<LevelEditorBloc>().add(EditorObjectSelected(block));
      },
      onUpdate: (position) {
        final newSize = position.size;
        final newOffset = position.offset;
        if (block.offset != newOffset || block.size != newSize) {
          context.read<LevelEditorBloc>().add(
                EditorObjectMoved(
                  block,
                  position.size,
                  position.offset,
                ),
              );
        }
      },
      builder: (context, size) {
        final blockSize = size / kBlockSize;

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
                Opacity(
                  opacity: isMainBlock ? 0 : 1,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<LevelEditorBloc>()
                          .add(MainEditorBlockSet(block));
                    },
                    icon: const Icon(MdiIcons.circleBoxOutline),
                    label: const Text('Make main'),
                  ),
                ),
                const SizedBox(height: 8.0),
                if (!isInitialBlock) ...{
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<LevelEditorBloc>()
                          .add(InitialEditorBlockSet(block));
                    },
                    icon: const Icon(MdiIcons.checkboxBlank),
                    label: const Text('Make initial'),
                  ),
                },
              ],
            ),
          ),
          child: AnimatedSelectable(
            isSelected: isSelected,
            child: PuzzleBlock(Block(
                blockSize.width.round(), blockSize.height.round(),
                isMain: block.isMain, hasControl: block.hasControl)),
          ),
        );
      },
    );
  }
}
