import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/app_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/data/repositories/auth_repository.dart';
import 'package:pbl_skin_problem_detector/data/repositories/scan_repository.dart';
import 'package:pbl_skin_problem_detector/data/services/auth_service.dart';
import 'package:pbl_skin_problem_detector/data/services/gea_diagnosis_service.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_theme.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SkinProblemDetectorApp());
}

class SkinProblemDetectorApp extends StatefulWidget {
  const SkinProblemDetectorApp({super.key});

  @override
  State<SkinProblemDetectorApp> createState() => _SkinProblemDetectorAppState();
}

class _SkinProblemDetectorAppState extends State<SkinProblemDetectorApp> {
  late final AuthRepository _authRepository;
  late final ScanRepository _scanRepository;
  late final AuthCubit _authCubit;
  late final ScanCubit _scanCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository(AuthService());
    _scanRepository = ScanRepository(GeaDiagnosisService());
    _authCubit = AuthCubit(_authRepository);
    _scanCubit = ScanCubit(_scanRepository);
    _router = createRouter(_authCubit);
  }

  @override
  void dispose() {
    _authCubit.close();
    _scanCubit.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: _scanCubit),
      ],
      child: ShadcnApp.router(
        title: 'Skin Problem Detector',
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
