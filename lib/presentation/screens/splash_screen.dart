import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      context.go('/welcome');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.sizeOf(context).shortestSide;
    final logoSize = (shortest * 0.28).clamp(88.0, 140.0);

    return Scaffold(
      backgroundColor: AppColors.white,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: AppColors.mint.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.scanFace,
                    size: logoSize * 0.45,
                    color: AppColors.slate,
                  ),
                ),
                const Gap(20),
                const Text(
                  'Skin Problem Detector',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate,
                  ),
                ),
                const Gap(8),
                const Text(
                  'Analisis kulit berbasis skala GEA',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7A8494),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
