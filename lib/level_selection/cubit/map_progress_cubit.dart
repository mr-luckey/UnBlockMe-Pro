import 'dart:async';

import 'package:blocked/progress/progress.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MapProgressState {
  const MapProgressState({
    required this.loading,
    required this.progress,
  });

  const MapProgressState.loading()
      : loading = true,
        progress = null;

  final bool loading;
  final MapLevelProgress? progress;
}

class MapProgressCubit extends Cubit<MapProgressState> {
  MapProgressCubit(this.levelNames) : super(const MapProgressState.loading()) {
    load();
    // Keep map stars/unlocks in sync as soon as a level is completed
    // (result screen), even if the user never taps Next.
    _progressSub = playerProgressStream().listen((_) {
      load(showSpinner: false);
    });
    _mapSub = mapProgressStream().listen((_) {
      load(showSpinner: false);
    });
  }

  final List<String> levelNames;
  StreamSubscription<PlayerProgress>? _progressSub;
  StreamSubscription<void>? _mapSub;

  Future<void> load({bool showSpinner = true}) async {
    if (showSpinner) {
      emit(const MapProgressState.loading());
    }
    final progress = await loadMapLevelProgress(levelNames);
    if (isClosed) return;
    emit(MapProgressState(loading: false, progress: progress));
  }

  @override
  Future<void> close() async {
    await _progressSub?.cancel();
    await _mapSub?.cancel();
    return super.close();
  }
}
