import 'dart:async';

import 'package:go_router/go_router.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          LucideIcons.scanFace,
                          size: 34,
                          color: scheme.primaryForeground,
                        ),
                      ),
                      const Gap(20),
                      const Text(
                        'Skin Problem Detector',
                        textAlign: TextAlign.center,
                      ).x2Large.bold,
                      const Gap(6),
                      const Text(
                        'Analisis kulit berbasis skala GEA',
                        textAlign: TextAlign.center,
                      ).small.muted,
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 32),
              child: CircularProgressIndicator(size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
