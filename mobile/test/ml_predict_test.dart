import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/ml/ml.dart';

/// Respons sukses seperti `POST /ml/predict` (lihat `docs/api.md`).
final String _successBody = jsonEncode({
  'model': 'dermascan-custom-cnn-v1',
  'images': [
    {
      'filename': 'front.png',
      'top_label': 'IGA2',
      'grade': 2,
      'grade_label': 'Ringan',
      'predictions': [
        {'label': 'IGA0', 'grade': 0, 'probability': 0.05},
        {'label': 'IGA1', 'grade': 1, 'probability': 0.15},
        {'label': 'IGA2', 'grade': 2, 'probability': 0.60},
        {'label': 'IGA3', 'grade': 3, 'probability': 0.18},
        {'label': 'IGA4', 'grade': 4, 'probability': 0.02},
      ],
      'inference_ms': 41.2,
    },
  ],
  'aggregate': {
    'top_label': 'IGA2',
    'grade': 2,
    'grade_label': 'Ringan',
    'predictions': [
      {'label': 'IGA0', 'grade': 0, 'probability': 0.05},
      {'label': 'IGA1', 'grade': 1, 'probability': 0.15},
      {'label': 'IGA2', 'grade': 2, 'probability': 0.60},
      {'label': 'IGA3', 'grade': 3, 'probability': 0.18},
      {'label': 'IGA4', 'grade': 4, 'probability': 0.02},
    ],
  },
});

ApiClient _clientWith(MockClient httpClient) =>
    ApiClient(httpClient: httpClient)..accessToken = 'jwt-test';

void main() {
  late Directory tempDir;
  late String frontPath;
  late String leftPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ml_predict_test');
    frontPath = '${tempDir.path}${Platform.pathSeparator}front.png';
    leftPath = '${tempDir.path}${Platform.pathSeparator}left.png';
    await File(frontPath).writeAsBytes([1, 2, 3, 4]);
    await File(leftPath).writeAsBytes([5, 6, 7, 8]);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('mengirim multipart ke /ml/predict dengan Bearer token', () async {
    late http.Request captured;
    final api = _clientWith(
      MockClient((request) async {
        captured = request;
        return http.Response(_successBody, 200);
      }),
    );

    await MlPredict(api)([frontPath, leftPath]);

    expect(captured.method, 'POST');
    expect(captured.url.path, '/ml/predict');
    expect(captured.headers['Authorization'], 'Bearer jwt-test');
    expect(
      captured.headers['content-type'],
      startsWith('multipart/form-data'),
    );
    // Satu part per foto, semuanya di field `files`.
    expect(
      'name="${MlPredict.fileField}"'.allMatches(captured.body).length,
      2,
    );
  });

  test('membaca grade agregat dari respons', () async {
    final api = _clientWith(
      MockClient((_) async => http.Response(_successBody, 200)),
    );

    final prediction = await MlPredict(api)([frontPath]);

    expect(prediction.grade, 2);
    expect(prediction.topLabel, 'IGA2');
    expect(prediction.model, 'dermascan-custom-cnn-v1');
    expect(prediction.probabilities, hasLength(5));
    expect(prediction.probabilities[2], closeTo(0.6, 1e-9));
  });

  test('melempar MlException berisi detail server saat 503', () async {
    final api = _clientWith(
      MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': 'Layanan analisis belum siap. Coba lagi nanti.'}),
          503,
        ),
      ),
    );

    await expectLater(
      MlPredict(api)([frontPath]),
      throwsA(
        isA<MlException>().having(
          (error) => error.message,
          'message',
          contains('belum siap'),
        ),
      ),
    );
  });

  test('melempar MlException saat jaringan gagal', () async {
    final api = _clientWith(
      MockClient((_) async => throw const SocketException('offline')),
    );

    await expectLater(
      MlPredict(api)([frontPath]),
      throwsA(
        isA<MlException>().having(
          (error) => error.message,
          'message',
          contains('Tidak bisa menghubungi server'),
        ),
      ),
    );
  });

  test('melempar MlException saat body sukses tidak dikenali', () async {
    final api = _clientWith(
      MockClient((_) async => http.Response('<html>oops</html>', 200)),
    );

    await expectLater(
      MlPredict(api)([frontPath]),
      throwsA(isA<MlException>()),
    );
  });

  test('menolak daftar foto kosong tanpa memanggil server', () async {
    var called = false;
    final api = _clientWith(
      MockClient((_) async {
        called = true;
        return http.Response(_successBody, 200);
      }),
    );

    await expectLater(
      MlPredict(api)(const []),
      throwsA(isA<MlException>()),
    );
    expect(called, isFalse);
  });
}