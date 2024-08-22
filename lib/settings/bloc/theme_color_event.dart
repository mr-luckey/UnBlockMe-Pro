part of 'theme_color_bloc.dart';

abstract class ThemeColorEvent {
  const ThemeColorEvent();
}

class ThemeColorChanged extends ThemeColorEvent {
  const ThemeColorChanged(this.color);

  final Color color;
}
