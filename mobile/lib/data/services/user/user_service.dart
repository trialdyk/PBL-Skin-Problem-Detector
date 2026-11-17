import 'package:flutter/foundation.dart';
import 'package:pbl_skin_problem_detector/data/models/user_model.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth_service.dart';
import 'package:pbl_skin_problem_detector/data/services/user/user_get_profile.dart';
import 'package:pbl_skin_problem_detector/data/services/user/user_update_profile.dart';

/// Facade for user profile endpoints (`GET /users/me`, `PATCH /users/me`).
///
/// Shares [ApiClient] with [AuthService] so the Bearer JWT is included.
class UserService {
  /// Widget tests: skip HTTP calls to backend.
  @visibleForTesting
  static bool mockRemoteUser = false;

  UserService({required ApiClient apiClient})
      : api = apiClient,
        _getProfile = UserGetProfile(apiClient),
        _updateProfile = UserUpdateProfile(apiClient);

  final ApiClient api;
  final UserGetProfile _getProfile;
  final UserUpdateProfile _updateProfile;

  /// `GET /users/me` — fetches the signed-in user's profile.
  Future<UserModel> getProfile({UserModel? currentUser}) async {
    if (mockRemoteUser) {
      return currentUser ??
          const UserModel(
            email: AuthService.demoEmail,
            accessToken: 'mock-token',
          );
    }

    return _getProfile();
  }

  /// `PATCH /users/me` — updates `full_name` and/or `email`.
  Future<UserModel> updateProfile({
    required String fullName,
    required String email,
    UserModel? currentUser,
  }) async {
    if (mockRemoteUser) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final base = currentUser ??
          const UserModel(
            email: AuthService.demoEmail,
            accessToken: 'mock-token',
          );
      return base.copyWith(
        fullName: fullName.trim(),
        email: email.trim().toLowerCase(),
      );
    }

    return _updateProfile(fullName: fullName, email: email);
  }
}
