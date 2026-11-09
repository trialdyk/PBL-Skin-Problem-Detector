import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pbl_skin_problem_detector/core/api_config.dart';

/// Shared HTTP client for DermaScan API.
///
/// Set [accessToken] after login; pass `auth: true` on protected routes so
/// requests include `Authorization: Bearer <token>`.
class ApiClient {
  ApiClient({http.Client? httpClient, this.accessToken})
      : _http = httpClient;

  http.Client? _http;
  String? accessToken;

  http.Client get _client => _http ??= http.Client();

  Uri uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Map<String, String> headers({bool auth = false}) {
    final token = accessToken;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (auth && token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(
    String path, {
    bool auth = false,
    Duration timeout = const Duration(seconds: 20),
  }) {
    return _client
        .get(uri(path), headers: headers(auth: auth))
        .timeout(timeout);
  }

  Future<http.Response> post(
    String path, {
    Map<String, Object?>? body,
    bool auth = false,
    Duration timeout = const Duration(seconds: 20),
  }) {
    return _client
        .post(
          uri(path),
          headers: headers(auth: auth),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);
  }

  /// Multipart POST for file uploads, e.g. `POST /ml/predict`.
  ///
  /// [files] maps a form field name to absolute file paths (one part per path).
  /// The JSON `Content-Type` is dropped so `http` can set the multipart boundary.
  Future<http.Response> postMultipart(
    String path, {
    required Map<String, List<String>> files,
    Map<String, String> fields = const {},
    bool auth = false,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final multipartHeaders = headers(auth: auth)..remove('Content-Type');
    final request = http.MultipartRequest('POST', uri(path))
      ..headers.addAll(multipartHeaders)
      ..fields.addAll(fields);

    for (final entry in files.entries) {
      for (final filePath in entry.value) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, filePath),
        );
      }
    }

    final streamed = await _client.send(request).timeout(timeout);
    return http.Response.fromStream(streamed);
  }

  void dispose() {
    _http?.close();
    _http = null;
  }
}
