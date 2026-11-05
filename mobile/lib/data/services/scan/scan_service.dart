import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/scan/scan_status.dart';

/// Facade untuk endpoint scan / user yang butuh Bearer token.
///
/// Pakai [ApiClient] yang sama dengan [AuthService] supaya token ikut:
///
/// ```dart
/// final auth = AuthService();
/// await auth.login(...); // set token otomatis
///
/// final scan = ScanService(apiClient: auth.api);
/// final status = await scan.status(); // Authorization: Bearer ...
/// ```
class ScanService {
  ScanService({required ApiClient apiClient})
      : api = apiClient,
        _status = ScanStatus(apiClient);

  final ApiClient api;
  final ScanStatus _status;

  /// `GET /users/status` — contoh fetch dengan header Bearer.
  Future<Map<String, dynamic>> status() => _status();
}
