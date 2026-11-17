import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_state.dart';
import 'package:pbl_skin_problem_detector/data/repositories/auth_repository.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  void togglePrivacy(bool value) {
    emit(state.copyWith(acceptedPrivacy: value, clearError: true));
  }

  void toggleTerms(bool value) {
    emit(state.copyWith(acceptedTerms: value, clearError: true));
  }

  void clearError() {
    if (state.errorMessage == null) return;
    emit(state.copyWith(clearError: true));
  }

  Future<void> login({
    required String email,
    required String password,
    bool viaGoogle = false,
  }) async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final user = await _repository.login(
        email: email,
        password: password,
        acceptedTerms: state.canSubmit,
        viaGoogle: viaGoogle,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearPendingEmail: true,
        ),
      );
    } on AuthException catch (e) {
      if (e.isEmailUnverified) {
        emit(
          state.copyWith(
            status: AuthStatus.pendingVerification,
            pendingEmail: email.trim().toLowerCase(),
            errorMessage: e.message,
          ),
        );
        return;
      }
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Login gagal. Coba lagi.',
        ),
      );
    }
  }

  Future<void> loginWithGoogle() async {
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final user = await _repository.loginWithGoogle(
        acceptedTerms: state.canSubmit,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearPendingEmail: true,
        ),
      );
    } on AuthException catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Login Google gagal. Coba lagi.',
        ),
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (state.status == AuthStatus.loading) return;
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final pending = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        acceptedTerms: state.canSubmit,
      );
      emit(
        state.copyWith(
          status: AuthStatus.pendingVerification,
          pendingEmail: pending.email,
          clearUser: true,
          clearError: true,
        ),
      );
    } on AuthException catch (e) {
      emit(state.copyWith(status: AuthStatus.failure, errorMessage: e.message));
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Registrasi gagal. Coba lagi.',
        ),
      );
    }
  }

  Future<void> verifyEmail({required String code}) async {
    final email = state.pendingEmail;
    if (email == null || email.isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.failure,
          errorMessage: 'Email verifikasi tidak ditemukan. Daftar ulang.',
        ),
      );
      return;
    }
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      final user = await _repository.verifyEmail(email: email, code: code);
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          clearPendingEmail: true,
        ),
      );
    } on AuthException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.pendingVerification,
          pendingEmail: email,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.pendingVerification,
          pendingEmail: email,
          errorMessage: 'Verifikasi gagal. Coba lagi.',
        ),
      );
    }
  }

  Future<void> resendVerification() async {
    final email = state.pendingEmail;
    if (email == null || email.isEmpty) return;
    emit(state.copyWith(status: AuthStatus.loading, clearError: true));
    try {
      await _repository.resendVerification(email: email);
      emit(
        state.copyWith(
          status: AuthStatus.pendingVerification,
          pendingEmail: email,
          clearError: true,
        ),
      );
    } on AuthException catch (e) {
      emit(
        state.copyWith(
          status: AuthStatus.pendingVerification,
          pendingEmail: email,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: AuthStatus.pendingVerification,
          pendingEmail: email,
          errorMessage: 'Gagal mengirim ulang kode.',
        ),
      );
    }
  }

  void logout() {
    _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
