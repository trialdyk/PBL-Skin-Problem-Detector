import 'dart:async';
import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _designHeight = 640.0;
  static const _minScale = 0.82;
  static const _revealGap = Duration(seconds: 1);

  static const _features = <(IconData, String, String)>[
    (
      LucideIcons.camera,
      'Scan 3 sudut',
      'Selfie depan, kiri, dan kanan dengan panduan posisi langsung.',
    ),
    (
      LucideIcons.messagesSquare,
      'Interview singkat',
      'Lima pertanyaan tentang jenis kulit dan kebiasaanmu.',
    ),
    (
      LucideIcons.activity,
      'Hasil skala GEA',
      'Tingkat keparahan jerawat 0–5 beserta penjelasannya.',
    ),
  ];

  /// Jumlah fitur yang sudah terlihat (0 → 3).
  int _revealed = 0;

  /// Index yang sedang di-highlight overlay (null = selesai).
  int? _activeOverlay;

  bool _ctaVisible = false;
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    _startRevealSequence();
  }

  void _startRevealSequence() {
    // Fitur 1 segera, lalu tiap 1 detik; CTA 1 detik setelah fitur terakhir.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _revealAt(0);
      for (var i = 1; i < _features.length; i++) {
        _timers.add(
          Timer(_revealGap * i, () {
            if (mounted) _revealAt(i);
          }),
        );
      }
      _timers.add(
        Timer(_revealGap * _features.length, () {
          if (!mounted) return;
          setState(() {
            _activeOverlay = null;
            _ctaVisible = true;
          });
        }),
      );
    });
  }

  void _revealAt(int index) {
    setState(() {
      _activeOverlay = index;
      _revealed = index + 1;
    });
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.page,
              AppColors.muted,
              AppColors.page,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = (constraints.maxHeight / _designHeight).clamp(
                _minScale,
                1.0,
              );
              double s(double value) => value * scale;
              final contentWidth = math.min(
                math.max(constraints.maxWidth - 48, 0.0),
                400.0,
              );

              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: _BackCircleButton(
                        onPressed: () => context.go('/splash'),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: contentWidth,
                            child: _WelcomeBody(
                              scale: s,
                              features: _features,
                              revealed: _revealed,
                              activeOverlay: _activeOverlay,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, s(8), 24, s(16)),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: AnimatedOpacity(
                        opacity: _ctaVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 450),
                        child: IgnorePointer(
                          ignoring: !_ctaVisible,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PrimaryButton(
                                alignment: Alignment.center,
                                onPressed: () => context.go('/login'),
                                trailing: const Icon(LucideIcons.scanFace),
                                child: const Text('Coba Scan Wajah'),
                              ),
                              Gap(s(10)),
                              Text(
                                'Hasil bersifat informatif, bukan diagnosis medis.',
                                textAlign: TextAlign.center,
                                style: appFont(
                                  fontSize: s(11),
                                  color: AppColors.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BackCircleButton extends StatelessWidget {
  const _BackCircleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          LucideIcons.arrowLeft,
          size: 18,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _WelcomeBody extends StatelessWidget {
  const _WelcomeBody({
    required this.scale,
    required this.features,
    required this.revealed,
    required this.activeOverlay,
  });

  final double Function(double) scale;
  final List<(IconData, String, String)> features;
  final int revealed;
  final int? activeOverlay;

  @override
  Widget build(BuildContext context) {
    final s = scale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scan, analisis, dan pahami kulitmu',
          style: appFont(
            fontSize: s(26),
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            height: 1.18,
          ),
        ),
        Gap(s(8)),
        Text(
          'Ambil 3 selfie, jawab pertanyaan singkat, dan dapatkan '
          'tingkat keparahan jerawatmu.',
          style: appFont(
            fontSize: s(14),
            color: AppColors.inkMuted,
            height: 1.45,
          ),
        ),
        Gap(s(22)),
        for (var i = 0; i < features.length; i++) ...[
          _FeatureRevealRow(
            index: i,
            icon: features[i].$1,
            title: features[i].$2,
            subtitle: features[i].$3,
            visible: i < revealed,
            highlighted: activeOverlay == i,
            scale: s,
          ),
          if (i != features.length - 1) Gap(s(10)),
        ],
      ],
    );
  }
}

class _FeatureRevealRow extends StatelessWidget {
  const _FeatureRevealRow({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.visible,
    required this.highlighted,
    required this.scale,
  });

  final int index;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool visible;
  final bool highlighted;
  final double Function(double) scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 0.18),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          padding: EdgeInsets.all(s(12)),
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.brandSoft.withValues(alpha: 0.85)
                : AppColors.white.withValues(alpha: visible ? 0.92 : 0),
            borderRadius: BorderRadius.circular(s(16)),
            border: Border.all(
              color: highlighted ? AppColors.brandLight : AppColors.border,
              width: highlighted ? 1.4 : 1,
            ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: s(36),
                height: s(36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: highlighted ? AppColors.brand : AppColors.brandSoft,
                  borderRadius: BorderRadius.circular(s(10)),
                ),
                child: highlighted
                    ? Text(
                        '${index + 1}',
                        style: appFont(
                          fontSize: s(14),
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      )
                    : Icon(
                        icon,
                        size: s(17),
                        color: AppColors.brand,
                      ),
              ),
              Gap(s(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: appFont(
                        fontSize: s(14),
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Gap(s(3)),
                    Text(
                      subtitle,
                      style: appFont(
                        fontSize: s(12),
                        color: AppColors.inkMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
