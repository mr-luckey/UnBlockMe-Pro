import 'package:blocked/settings/util/theme_color_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'theme_color_state.dart';
part 'theme_color_event.dart';

class ThemeColorBloc extends Bloc<ThemeColorEvent, ThemeColorState> {
  ThemeColorBloc(Color initialColor) : super(ThemeColorState(initialColor)) {
    on<ThemeColorChanged>(_onThemeColorChanged);
  }

  void _onThemeColorChanged(
      ThemeColorChanged event, Emitter<ThemeColorState> emit) async {
    await saveColor(event.color);
    emit(ThemeColorState(event.color));
  }
}
