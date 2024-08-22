import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LevelShortcutListener extends StatelessWidget {
  LevelShortcutListener({
    Key? key,
    required this.levelBloc,
    required this.child,
  }) : super(key: key);

  final LevelBloc levelBloc;
  final Widget child;

  static const puzzleShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyR): _LevelIntent(LevelReset()),
    SingleActivator(LogicalKeyboardKey.arrowLeft):
        _LevelIntent(MoveAttempt(MoveDirection.left)),
    SingleActivator(LogicalKeyboardKey.arrowRight):
        _LevelIntent(MoveAttempt(MoveDirection.right)),
    SingleActivator(LogicalKeyboardKey.arrowUp):
        _LevelIntent(MoveAttempt(MoveDirection.up)),
    SingleActivator(LogicalKeyboardKey.arrowDown):
        _LevelIntent(MoveAttempt(MoveDirection.down)),
    SingleActivator(LogicalKeyboardKey.keyW):
        _LevelIntent(MoveAttempt(MoveDirection.up)),
    SingleActivator(LogicalKeyboardKey.keyA):
        _LevelIntent(MoveAttempt(MoveDirection.left)),
    SingleActivator(LogicalKeyboardKey.keyS):
        _LevelIntent(MoveAttempt(MoveDirection.down)),
    SingleActivator(LogicalKeyboardKey.keyD):
        _LevelIntent(MoveAttempt(MoveDirection.right)),
  };

  static final levelShortcuts = {
    const SingleActivator(LogicalKeyboardKey.enter):
        _LevelNavigationIntent((levelNavigation) {
      levelNavigation.onNext();
    }),
    const SingleActivator(LogicalKeyboardKey.escape):
        _LevelNavigationIntent((levelNavigation) {
      levelNavigation.onExit();
    }),
  };

  static final shortcuts = <ShortcutActivator, Intent>{
    ...puzzleShortcuts,
    ...levelShortcuts,
  };

  final FocusNode focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(focusNode);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 0) {
          levelBloc.add(const MoveAttempt(MoveDirection.right));
        } else if ((details.primaryVelocity ?? 0) < 0) {
          levelBloc.add(const MoveAttempt(MoveDirection.left));
        }
      },
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 0) {
          levelBloc.add(const MoveAttempt(MoveDirection.down));
        } else if ((details.primaryVelocity ?? 0) < 0) {
          levelBloc.add(const MoveAttempt(MoveDirection.up));
        }
      },
      child: FocusableActionDetector(
        focusNode: focusNode,
        autofocus: true,
        shortcuts: shortcuts,
        actions: {
          _LevelIntent: CallbackAction<_LevelIntent>(onInvoke: (intent) {
            return levelBloc.add(intent.levelEvent);
          }),
          _LevelNavigationIntent: CallbackAction<_LevelNavigationIntent>(
            onInvoke: (intent) {
              return intent
                  .levelNavigationCallback(context.read<LevelNavigation>());
            },
          ),
        },
        child: child,
      ),
    );
  }
}

class _LevelIntent extends Intent {
  const _LevelIntent(this.levelEvent);

  final LevelEvent levelEvent;
}

class _LevelNavigationIntent extends Intent {
  const _LevelNavigationIntent(this.levelNavigationCallback);

  final void Function(LevelNavigation) levelNavigationCallback;
}
