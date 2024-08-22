import 'package:blocked/solver/bloc/solution_player_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SolutionShortcutListener extends StatelessWidget {
  SolutionShortcutListener({Key? key, required this.child}) : super(key: key);

  final Widget child;
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    _focusNode.requestFocus();
    return FocusableActionDetector(
      child: child,
      focusNode: _focusNode,
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.arrowRight):
            const _SolutionPlayerIntent(NextSolutionStepSelected()),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft):
            const _SolutionPlayerIntent(PreviousSolutionStepSelected()),
        LogicalKeySet(LogicalKeyboardKey.keyR):
            const _SolutionPlayerIntent(SolutionStepSelected(0)),
      },
      actions: {
        _SolutionPlayerIntent:
            CallbackAction<_SolutionPlayerIntent>(onInvoke: (intent) {
          return context.read<SolutionPlayerBloc>().add(intent.event);
        }),
      },
    );
  }
}

class _SolutionPlayerIntent extends Intent {
  const _SolutionPlayerIntent(this.event);

  final SolutionPlayerEvent event;
}
