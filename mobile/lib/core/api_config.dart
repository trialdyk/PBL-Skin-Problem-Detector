/// Backend + Google OAuth settings for the mobile app.
///
/// Override at build/run time:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8000`
class ApiConfig {
  ApiConfig._();

  /// Android emulator → host machine. Physical device: use LAN IP + dart-define.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// Google Cloud **Web** OAuth client ID (same as backend `GOOGLE_CLIENT_ID`).
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '220141289372-dc5qhq2ilq1aia12kchuuspsadpjing6.apps.googleusercontent.com',
  );
}
