import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'select_state.dart';

class SelectCubit extends Cubit<SelectState> {
  SelectCubit() : super(const SelectState(-1, -1));
  void setSelect(int semester, int group) {
    emit(SelectState(semester, group));
  }
}
