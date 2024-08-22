import 'package:blocked/level/level.dart';
import 'package:blocked/models/models.dart';
import 'package:blocked/puzzle/puzzle.dart';
import 'package:blocked/solver/bloc/solution_player_bloc.dart';
import 'package:blocked/solver/solver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SolutionPage extends StatefulWidget {
  SolutionPage(
      {Key? key, required LevelState initialState, required this.solution})
      : super(key: key) {
    final solutionStates = [initialState];
    for (final move in solution) {
      final nextState =
          solutionStates.last.withMoveAttempt(MoveAttempt(move)).last;
      solutionStates.add(nextState);
    }
    this.solutionStates = solutionStates;
  }

  final List<MoveDirection> solution;
  late final List<LevelState> solutionStates;

  @override
  State<SolutionPage> createState() => _SolutionPageState();
}

class _SolutionPageState extends State<SolutionPage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocProvider(
        create: (context) => LevelBloc(widget.solutionStates.first),
        child: BlocProvider(
          create: (context) => SolutionPlayerBloc(widget.solutionStates.length),
          child: BlocConsumer<SolutionPlayerBloc, SolutionPlayerState>(
            listener: (context, state) {
              context
                  .read<LevelBloc>()
                  .add(LevelStateSet(widget.solutionStates[state.index]));
            },
            builder: (context, state) => SolutionShortcutListener(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: 0,
                        maxHeight: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          FittedBox(
                            child: Hero(tag: 'puzzle', child: Puzzle()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                        onPressed: state.index > 0
                            ? () {              //          todo ads integration here
                                context
                                    .read<SolutionPlayerBloc>()
                                    .add(const SolutionStepSelected(0));
                              }
                            : null,
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        icon: Icon(Icons.adaptive.arrow_back),
                        label: const Text('Back'),
                        onPressed: state.index > 0
                            ? () {           ///todo ads integration here
                                context
                                    .read<SolutionPlayerBloc>()
                                    .add(const PreviousSolutionStepSelected());
                              }
                            : null,
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        icon: Icon(Icons.adaptive.arrow_forward),
                        label: const Text('Next'),
                        onPressed:
                            state.index < widget.solutionStates.length - 1
                                ? () {
                                    context
                                        .read<SolutionPlayerBloc>()
                                        .add(const NextSolutionStepSelected());
                                  }
                                : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 512),
                        child: Material(
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Column(
                              children: [
                                Text(
                                  'Solution',
                                  style:
                                      Theme.of(context).textTheme.headlineSmall,
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemBuilder: (context, index) {
                                      final isInitialState = index == 0;
                                      final move = isInitialState
                                          ? null
                                          : widget.solution[index - 1];
                                      return ListTile(
                                        selected: state.index == index,
                                        selectedTileColor: Theme.of(context)
                                            .colorScheme
                                            .surfaceVariant,
                                        leading: isInitialState
                                            ? const Icon(MdiIcons.flag)
                                            : Icon(_directionToIcon(move!)),
                                        title: Text(
                                          isInitialState
                                              ? 'Start'
                                              : 'Move ${move!.name}',
                                        ),
                                        onTap: () {
                                          /// todo 15 sec ads integration
                                          context
                                              .read<SolutionPlayerBloc>()
                                              .add(SolutionStepSelected(index));
                                        },
                                      );
                                    },
                                    itemCount: widget.solutionStates.length,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

IconData _directionToIcon(MoveDirection direction) {
  switch (direction) {
    case MoveDirection.up:
      return Icons.arrow_upward;
    case MoveDirection.down:
      return Icons.arrow_downward;
    case MoveDirection.left:
      return Icons.arrow_back;
    case MoveDirection.right:
      return Icons.arrow_forward;
  }
}
