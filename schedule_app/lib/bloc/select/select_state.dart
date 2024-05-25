part of 'select_cubit.dart';

@immutable
class SelectState {
  const SelectState(this.selectedSemester, this.selectedGroup);

  final int selectedSemester;
  final int selectedGroup;

  List<Object> get props => [selectedSemester, selectedGroup];
  List<Object> get props2 => [selectedSemester, selectedGroup];
}
