import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/models/user_model.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/user/user_exception.dart';
import 'package:pbl_skin_problem_detector/data/services/user/user_response.dart';

/// `PATCH /users/me` — protected (requires `Authorization: Bearer <token>`).
///
/// Request schema: `UpdateProfileRequest` (`full_name`, `email`).
class UserUpdateProfile {
  UserUpdateProfile(this._api);

  final ApiClient _api;

  Future<UserModel> call({
    String? fullName,
    String? email,
  }) async {
    final body = <String, Object?>{
      if (fullName != null) 'full_name': fullName.trim(),
      if (email != null) 'email': email.trim(),
    };

    late final http.Response response;
    try {
      response = await _api.patch('/users/me', body: body, auth: true);
    } catch (_) {
      throw UserException(
        'Tidak bisa menghubungi server. Cek koneksi internet.',
      );
    }

    return parseUserProfileResponse(
      response,
      endpoint: 'User API PATCH /users/me',
      fallbackError: 'Gagal memperbarui profil. Coba lagi.',
      accessToken: _api.accessToken,
    );
  }
}
