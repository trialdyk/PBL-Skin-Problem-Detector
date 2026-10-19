import 'package:equatable/equatable.dart';
import 'package:pbl_skin_problem_detector/data/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, failure }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.acceptedPrivacy = false,
    this.acceptedTerms = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserModel? user;
  final bool acceptedPrivacy;
  final bool acceptedTerms;
  final String? errorMessage;

  bool get canSubmit => acceptedPrivacy && acceptedTerms;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    bool? acceptedPrivacy,
    bool? acceptedTerms,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, user, acceptedPrivacy, acceptedTerms, errorMessage];
}
