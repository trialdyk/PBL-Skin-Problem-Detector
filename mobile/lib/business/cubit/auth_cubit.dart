import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_state.dart';
import 'package:pbl_skin_problem_detector/data/repositories/auth_repository.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth.dart';
import 'package:pbl_skin_problem_detector/data/services/user/user.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  final AuthRepository _repository;

  /// JWT aktif di [ApiClient] bersama (untuk foto history ber-auth).
  String? get accessToken => _repository.api.accessToken;

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

  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// Menyinkronkan profil pengguna dari `GET /users/me`.
  Future<void> refreshProfile() async {
    if (state.status != AuthStatus.authenticated) return;
    try {
      final user = await _repository.fetchProfile();
      if (state.status != AuthStatus.authenticated) return;
      emit(state.copyWith(user: user));
    } on UserException catch (e) {
      if (e.isUnauthorized) {
        logout();
        return;
      }
      debugPrint('Refresh profile failed: ${e.message}');
    } catch (e) {
      debugPrint('Refresh profile failed: $e');
    }
  }

  /// Memperbarui nama dan email pengguna melalui `PATCH /users/me`.
  Future<bool> updateProfile({
    required String fullName,
    required String email,
  }) async {
    if (state.profileSaving) return false;

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

    emit(state.copyWith(profileSaving: true, clearError: true));
    try {
      final updated = await _repository.updateProfile(
        fullName: trimmedName,
        email: trimmedEmail,
      );
      emit(
        state.copyWith(
          user: updated,
          profileSaving: false,
          clearError: true,
        ),
      );
      return true;
    } on UserException catch (e) {
      if (e.isUnauthorized) {
        logout();
        return false;
      }
      emit(state.copyWith(profileSaving: false, errorMessage: e.message));
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          profileSaving: false,
          errorMessage: 'Gagal memperbarui profil. Coba lagi.',
        ),
      );
      return false;
    }
  }

  /// Memperbarui kata sandi pengguna pada sesi aktif.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (state.passwordSaving) return false;

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
              'Kata sandi baru tidak boleh sama dengan kata sandi saat ini.',
        ),
      );
      return false;
    }

    emit(state.copyWith(passwordSaving: true, clearError: true));
    try {
      final ok = await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!ok) {
        emit(
          state.copyWith(
            passwordSaving: false,
            errorMessage: 'Kata sandi saat ini salah.',
          ),
        );
        return false;
      }
      emit(state.copyWith(passwordSaving: false, clearError: true));
      return true;
    } on AuthException catch (e) {
      emit(state.copyWith(passwordSaving: false, errorMessage: e.message));
      return false;
    } catch (_) {
      emit(
        state.copyWith(
          passwordSaving: false,
          errorMessage: 'Gagal memperbarui kata sandi. Coba lagi.',
        ),
      );
      return false;
    }
  }

  void logout() {
    _repository.logout();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
