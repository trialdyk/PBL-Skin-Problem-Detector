import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_state.dart';
import 'package:pbl_skin_problem_detector/business/cubit/home_cubit.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/diagnosis_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/home_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/interview_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/login_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/scan_capture_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/scan_confirm_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/scan_intro_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/scan_upload_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/splash_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/welcome_screen.dart';

GoRouter createRouter(AuthCubit authCubit) {
  const publicRoutes = {'/splash', '/welcome', '/login'};

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefresh(authCubit),
    redirect: (context, state) {
      final loggedIn = authCubit.state.status == AuthStatus.authenticated;
      final location = state.matchedLocation;
      final isPublic = publicRoutes.contains(location);

      if (!loggedIn && !isPublic) return '/welcome';
      if (loggedIn && isPublic) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => BlocProvider(
          create: (_) => HomeCubit(),
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const ScanIntroScreen(),
      ),
      GoRoute(
        path: '/scan/capture',
        builder: (context, state) => const ScanCaptureScreen(),
      ),
      GoRoute(
        path: '/scan/upload',
        builder: (context, state) => const ScanUploadScreen(),
      ),
      GoRoute(
        path: '/scan/confirm',
        builder: (context, state) => const ScanConfirmScreen(),
      ),
      GoRoute(
        path: '/scan/interview',
        builder: (context, state) => const InterviewScreen(),
      ),
      GoRoute(
        path: '/scan/result',
        builder: (context, state) => const DiagnosisScreen(),
      ),
    ],
  );
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._authCubit) {
    _subscription = _authCubit.stream.listen((_) => notifyListeners());
  }

  final AuthCubit _authCubit;
  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
