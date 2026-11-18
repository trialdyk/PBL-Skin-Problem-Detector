import 'package:equatable/equatable.dart';
import 'package:pbl_skin_problem_detector/data/models/user_model.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  /// Registered but waiting for the email OTP screen.
  pendingVerification,
  unauthenticated,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.pendingEmail,
    this.acceptedPrivacy = false,
    this.acceptedTerms = false,
    this.profileSaving = false,
    this.passwordSaving = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  /// Email awaiting OTP after register / unverified login.
  final String? pendingEmail;
  final bool acceptedPrivacy;
  final bool acceptedTerms;
  final bool profileSaving;
  final bool passwordSaving;
  final String? errorMessage;

  bool get canSubmit => acceptedPrivacy && acceptedTerms;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? pendingEmail,
    bool? acceptedPrivacy,
    bool? acceptedTerms,
    bool? profileSaving,
    bool? passwordSaving,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
    bool clearPendingEmail = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      pendingEmail:
          clearPendingEmail ? null : (pendingEmail ?? this.pendingEmail),
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      profileSaving: profileSaving ?? this.profileSaving,
      passwordSaving: passwordSaving ?? this.passwordSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        pendingEmail,
        acceptedPrivacy,
        acceptedTerms,
        profileSaving,
        passwordSaving,
        errorMessage,
      ];
}
