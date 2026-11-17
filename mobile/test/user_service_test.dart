import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_state.dart';
import 'package:pbl_skin_problem_detector/data/repositories/auth_repository.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth.dart';
import 'package:pbl_skin_problem_detector/data/services/user/user.dart';

final String _profileJson = jsonEncode({
  'id': '11111111-1111-1111-1111-111111111111',
  'email': 'budi@example.com',
  'full_name': 'Budi Santoso',
  'auth_provider': 'password',
  'email_verified': true,
  'created_at': '2026-11-17T08:00:00Z',
  'updated_at': '2026-11-17T08:05:00Z',
});

ApiClient _clientWith(MockClient httpClient) =>
    ApiClient(httpClient: httpClient)..accessToken = 'jwt-test';

void main() {
  setUp(() => AuthService.mockRemoteAuth = false);

  test('UserGetProfile mengirim GET /users/me dengan Bearer token', () async {
    late http.Request captured;
    final api = _clientWith(
      MockClient((request) async {
        captured = request;
        return http.Response(_profileJson, 200);
      }),
    );

    final user = await UserGetProfile(api)();

    expect(captured.method, 'GET');
    expect(captured.url.path, '/users/me');
    expect(captured.headers['Authorization'], 'Bearer jwt-test');
    expect(user.email, 'budi@example.com');
    expect(user.fullName, 'Budi Santoso');
    expect(user.accessToken, 'jwt-test');
  });

  test('UserUpdateProfile mengirim PATCH /users/me JSON sesuai OpenAPI', () async {
    late http.Request captured;
    final api = _clientWith(
      MockClient((request) async {
        captured = request;
        return http.Response(_profileJson, 200);
      }),
    );

    final user = await UserUpdateProfile(api)(
      fullName: '  Budi Santoso  ',
      email: '  Budi@Example.com  ',
    );

    expect(captured.method, 'PATCH');
    expect(captured.url.path, '/users/me');
    expect(captured.headers['Authorization'], 'Bearer jwt-test');
    expect(jsonDecode(captured.body), {
      'full_name': 'Budi Santoso',
      'email': 'Budi@Example.com',
    });
    expect(user.email, 'budi@example.com');
    expect(user.fullName, 'Budi Santoso');
    expect(user.accessToken, 'jwt-test');
  });

  test('melempar UserException detail server saat 409 conflict email', () async {
    final api = _clientWith(
      MockClient(
        (_) async => http.Response(
          jsonEncode({'detail': 'Email sudah digunakan oleh akun lain.'}),
          409,
        ),
      ),
    );

    await expectLater(
      UserUpdateProfile(api)(
        fullName: 'Budi',
        email: 'lain@gmail.com',
      ),
      throwsA(
        isA<UserException>()
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.message, 'message', 'Email sudah digunakan oleh akun lain.'),
      ),
    );
  });

  test('melempar UserException unauthorized saat 401', () async {
    final api = _clientWith(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail': 'Sesi tidak valid atau sudah berakhir. Silakan masuk kembali.',
          }),
          401,
        ),
      ),
    );

    await expectLater(
      UserGetProfile(api)(),
      throwsA(
        isA<UserException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue),
      ),
    );
  });

  test('tidak mem-parse detail list 422 atau traceback 500', () async {
    final api422 = _clientWith(
      MockClient(
        (_) async => http.Response(
          jsonEncode({
            'detail': [
              {'msg': 'value is not a valid email'}
            ],
          }),
          422,
        ),
      ),
    );

    await expectLater(
      UserUpdateProfile(api422)(fullName: 'Budi', email: 'bad'),
      throwsA(
        isA<UserException>().having(
          (e) => e.message,
          'message',
          'Periksa kembali nama dan email yang dimasukkan.',
        ),
      ),
    );

    final api500 = _clientWith(
      MockClient((_) async => http.Response('Traceback (most recent call last)...', 500)),
    );

    await expectLater(
      UserUpdateProfile(api500)(fullName: 'Budi', email: 'budi@gmail.com'),
      throwsA(
        isA<UserException>().having(
          (e) => e.message,
          'message',
          'Terjadi kesalahan pada server. Coba lagi nanti.',
        ),
      ),
    );
  });

  test('AuthCubit.updateProfile via HTTP menjaga status authenticated saat 409 dan logout saat 401', () async {
    var returnStatus = 200;
    final api = ApiClient(
      httpClient: MockClient((request) async {
        if (request.url.path == '/auth/login') {
          return http.Response(
            jsonEncode({
              'access_token': 'jwt-login',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': '11111111-1111-1111-1111-111111111111',
                'email': 'pengguna@gmail.com',
                'full_name': 'Pengguna',
              },
            }),
            200,
          );
        }
        if (request.url.path == '/users/me' && request.method == 'PATCH') {
          if (returnStatus == 409) {
            return http.Response(
              jsonEncode({'detail': 'Email sudah digunakan oleh akun lain.'}),
              409,
            );
          }
          if (returnStatus == 401) {
            return http.Response(
              jsonEncode({
                'detail': 'Sesi tidak valid atau sudah berakhir. Silakan masuk kembali.',
              }),
              401,
            );
          }
          return http.Response(_profileJson, 200);
        }
        return http.Response('Not found', 404);
      }),
    );

    final repo = AuthRepository(AuthService(apiClient: api));
    final cubit = AuthCubit(repo);
    addTearDown(cubit.close);

    cubit.togglePrivacy(true);
    cubit.toggleTerms(true);
    await cubit.login(email: 'pengguna@gmail.com', password: 'skinscan123');
    expect(cubit.state.status, AuthStatus.authenticated);

    returnStatus = 409;
    final conflictOk = await cubit.updateProfile(
      fullName: 'Budi Santoso',
      email: 'lain@gmail.com',
    );
    expect(conflictOk, isFalse);
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.errorMessage, 'Email sudah digunakan oleh akun lain.');

    returnStatus = 200;
    final ok = await cubit.updateProfile(
      fullName: 'Budi Santoso',
      email: 'budi@example.com',
    );
    expect(ok, isTrue);
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.user?.fullName, 'Budi Santoso');
    expect(cubit.state.user?.email, 'budi@example.com');
    expect(cubit.state.user?.accessToken, 'jwt-login');

    returnStatus = 401;
    final expiredOk = await cubit.updateProfile(
      fullName: 'Budi Santoso',
      email: 'budi@example.com',
    );
    expect(expiredOk, isFalse);
    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(api.accessToken, isNull);
  });
}
