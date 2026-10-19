import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl_skin_problem_detector/business/cubit/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeState());

  void setTab(int index) {
    emit(state.copyWith(tabIndex: index));
  }
}
