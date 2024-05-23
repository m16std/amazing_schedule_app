part of 'theme_cubit.dart';

@immutable
class ThemeState {
  const ThemeState(this.brightness);

  final Brightness brightness;

  List<Object> get props => [brightness];
}
