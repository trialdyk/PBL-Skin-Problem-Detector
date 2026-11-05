/// Backend + Google OAuth settings for the mobile app.
///
/// Override at build/run time if needed:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000`
class ApiConfig {
  ApiConfig._();

  /// Production DermaScan API (same host as Swagger docs).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pbl.trialdyk.my.id',
  );

  /// Google Cloud **Web** OAuth client ID (same as backend `GOOGLE_CLIENT_ID`).
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '220141289372-dc5qhq2ilq1aia12kchuuspsadpjing6.apps.googleusercontent.com',
  );
}
