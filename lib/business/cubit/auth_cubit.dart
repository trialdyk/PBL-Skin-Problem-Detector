import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_state.dart';
import 'package:pbl_skin_problem_detector/data/repositories/auth_repository.dart';
import 'package:pbl_skin_problem_detector/data/services/auth_service.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  void togglePrivacy(bool value) {
    emit(state.copyWith(acceptedPrivacy: value, clearError: true));
  }

  void toggleTerms(bool value) {
    emit(state.copyWith(acceptedTerms: value, clearError: true));
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final user = await _repository.login(
        email: email,
        password: password,
        acceptedTerms: state.canSubmit,
      );
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } on AuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: 'Login gagal. Coba lagi.',
      ));
    }
  }

  void logout() {
    _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
