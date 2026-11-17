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

  /// Menutup pesan galat (mis. panel "kata sandi salah") saat pengguna
  /// kembali mengetik.
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
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } on AuthException catch (e) {
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
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
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
      final user = await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
        acceptedTerms: state.canSubmit,
      );
      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
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

  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// Memperbarui nama dan email pengguna pada sesi aktif.
  bool updateProfile({required String fullName, required String email}) {
    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedName.isEmpty || trimmedName.length > 255) {
      emit(
        state.copyWith(
          errorMessage: trimmedName.isEmpty
              ? 'Nama lengkap tidak boleh kosong.'
              : 'Nama lengkap maksimal 255 karakter.',
        ),
      );
      return false;
    }
    if (trimmedEmail.isEmpty ||
        trimmedEmail.length > 255 ||
        !_emailPattern.hasMatch(trimmedEmail)) {
      emit(
        state.copyWith(
          errorMessage: trimmedEmail.isEmpty
              ? 'Email tidak boleh kosong.'
              : 'Format email tidak valid.',
        ),
      );
      return false;
    }

    final updated = _repository.updateProfile(
      fullName: trimmedName,
      email: trimmedEmail,
    );
    if (updated == null) return false;
    emit(state.copyWith(user: updated, clearError: true));
    return true;
  }

  /// Memperbarui kata sandi pengguna pada sesi aktif.
  bool changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    if (currentPassword.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Kata sandi saat ini tidak boleh kosong.',
        ),
      );
      return false;
    }
    if (newPassword.length < 8 || newPassword.length > 128) {
      emit(
        state.copyWith(
          errorMessage: 'Kata sandi baru harus 8–128 karakter.',
        ),
      );
      return false;
    }
    if (newPassword == currentPassword) {
      emit(
        state.copyWith(
          errorMessage:
              'Kata sandi baru harus berbeda dari kata sandi saat ini.',
        ),
      );
      return false;
    }

    final ok = _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    if (!ok) return false;
    emit(state.copyWith(clearError: true));
    return true;
  }

  void logout() {
    _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
