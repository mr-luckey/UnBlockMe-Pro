import 'package:blocked/editor/editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class EditorToolbar extends StatelessWidget {
  const EditorToolbar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final levelEditorBloc = context.select((LevelEditorBloc bloc) => bloc);
    final selectedTool =
        context.select((LevelEditorBloc bloc) => bloc.state.selectedTool);

    return RepaintBoundary(
      child: Material(
        elevation: 8.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AdaptiveTextButton(
                  icon: const Icon(MdiIcons.cursorDefault),
                  label: const Text('Select (Q)'),
                  onPressed: () {
                    context
                        .read<LevelEditorBloc>()
                        .add(const EditorToolSelected(EditorTool.move));
                  },
                  style: selectedTool == EditorTool.move
                      ? TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
                AdaptiveTextButton(
                  icon: const Icon(MdiIcons.wall),
                  label: const Text('Wall/Exit (W)'),
                  onPressed: () {
                    levelEditorBloc
                        .add(const EditorToolSelected(EditorTool.segment));
                  },
                  style: selectedTool == EditorTool.segment
                      ? TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
                AdaptiveTextButton(
                  icon: const Icon(MdiIcons.checkboxIntermediate),
                  label: const Text('Block (E)'),
                  onPressed: () {
                    levelEditorBloc
                        .add(const EditorToolSelected(EditorTool.block));
                  },
                  style: selectedTool == EditorTool.block
                      ? TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
                VerticalDivider(
                    color: Theme.of(context).colorScheme.primaryContainer),
                AdaptiveTextButton(
                  icon: const Icon(Icons.delete_rounded),
                  label: const Text('Clear (C)'),
                  onPressed: () {
                    levelEditorBloc.add(const MapCleared());
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
