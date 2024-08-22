import 'package:blocked/editor/editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditorShortcutListener extends StatelessWidget {
  EditorShortcutListener({
    Key? key,
    required this.levelEditorBloc,
    required this.child,
  }) : super(key: key);

  final LevelEditorBloc levelEditorBloc;
  final Widget child;
  final FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(focusNode);
    return FocusableActionDetector(
      autofocus: true,
      descendantsAreFocusable: false,
      focusNode: focusNode,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.keyQ):
            const EditorActionIntent(EditorToolSelected(EditorTool.move)),
        LogicalKeySet(LogicalKeyboardKey.keyW):
            const EditorActionIntent(EditorToolSelected(EditorTool.segment)),
        LogicalKeySet(LogicalKeyboardKey.keyE):
            const EditorActionIntent(EditorToolSelected(EditorTool.block)),
        LogicalKeySet(LogicalKeyboardKey.keyC):
            const EditorActionIntent(MapCleared()),
        LogicalKeySet(LogicalKeyboardKey.keyS):
            const EditorActionIntent(SavePressed()),
        LogicalKeySet(LogicalKeyboardKey.delete):
            const EditorActionIntent(SelectedEditorObjectDeleted()),
        LogicalKeySet(LogicalKeyboardKey.backspace):
            const EditorActionIntent(SelectedEditorObjectDeleted()),
        LogicalKeySet(LogicalKeyboardKey.keyG):
            const EditorActionIntent(GridToggled()),
        LogicalKeySet(LogicalKeyboardKey.enter):
            const EditorActionIntent(TestMapPressed()),
        LogicalKeySet(LogicalKeyboardKey.space):
            const EditorActionIntent(TestMapPressed()),
        LogicalKeySet(LogicalKeyboardKey.escape):
            const EditorActionIntent(EscapePressed()),
      },
      actions: {
        EditorActionIntent:
            CallbackAction<EditorActionIntent>(onInvoke: (intent) {
          return levelEditorBloc.add(intent.event);
        }),
      },
      child: child,
    );
  }
}

class EditorActionIntent extends Intent {
  const EditorActionIntent(this.event);

  final LevelEditorEvent event;
}
