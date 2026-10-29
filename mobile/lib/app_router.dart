import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_state.dart';
import 'package:pbl_skin_problem_detector/business/cubit/home_cubit.dart';
import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/data/models/article_item.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/article_detail_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/diagnosis_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/home_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/interview_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/login_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/privacy_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/scan_capture_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/scan_confirm_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/scan_photo_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/scan_upload_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/splash_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/terms_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/welcome_screen.dart';

GoRouter createRouter(AuthCubit authCubit) {
  const publicRoutes = {'/splash', '/welcome', '/login', '/terms', '/privacy'};

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefresh(authCubit),
    redirect: (context, state) {
      final loggedIn = authCubit.state.status == AuthStatus.authenticated;
      final location = state.matchedLocation;
      final isPublic = publicRoutes.contains(location);

      if (!loggedIn && !isPublic) return '/splash';
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
        path: '/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => BlocProvider(
          create: (_) => HomeCubit(),
          child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/articles/detail',
        builder: (context, state) {
          final article = state.extra;
          return ArticleDetailScreen(
            article: article is ArticleItem
                ? article
                : const ArticleItem(
                    category: 'Info',
                    title: 'Artikel tidak ditemukan',
                    body:
                        'Kembali dan pilih artikel dari daftar untuk melihat detail.',
                    readTime: '-',
                    image: 'assets/images/acne_people.png',
                  ),
          );
        },
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const ScanPhotoScreen(),
      ),
      GoRoute(
        path: '/scan/capture',
        builder: (context, state) => ScanCaptureScreen(
          angle: switch (state.uri.queryParameters['angle']) {
            'front' => SelfieAngle.front,
            'left' => SelfieAngle.left,
            'right' => SelfieAngle.right,
            _ => null,
          },
        ),
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
