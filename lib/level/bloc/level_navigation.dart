class LevelNavigation {
  const LevelNavigation({required this.onNext, required this.onExit});

  final void Function() onNext;
  final void Function() onExit;
}
