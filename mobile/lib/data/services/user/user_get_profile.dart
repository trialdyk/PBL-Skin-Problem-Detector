import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/data/models/user_model.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/user/user_exception.dart';
import 'package:pbl_skin_problem_detector/data/services/user/user_response.dart';

/// `GET /users/me` — protected (requires `Authorization: Bearer <token>`).
class UserGetProfile {
  UserGetProfile(this._api);

  final ApiClient _api;

  Future<UserModel> call() async {
    late final http.Response response;
    try {
      response = await _api.get('/users/me', auth: true);
    } catch (_) {
      throw UserException(
        'Tidak bisa menghubungi server. Cek koneksi internet.',
      );
    }

    return parseUserProfileResponse(
      response,
      endpoint: 'User API GET /users/me',
      fallbackError: 'Gagal memuat profil pengguna.',
      accessToken: _api.accessToken,
    );
  }
}
