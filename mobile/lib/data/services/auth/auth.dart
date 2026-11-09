/// Auth API services — import this barrel from the rest of the app.
///
/// ```dart
/// import 'package:pbl_skin_problem_detector/data/services/auth/auth.dart';
///
/// final auth = AuthService();
/// final user = await auth.login(
///   email: 'pengguna@gmail.com',
///   password: 'skinscan123',
///   acceptedTerms: true,
/// );
/// // JWT tersimpan di auth.api.accessToken
/// ```
library;

export 'auth_exception.dart';
export 'auth_google.dart';
export 'auth_login.dart';
export 'auth_register.dart';
export 'auth_service.dart';
