import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _featureAsset = 'assets/images/acne_people.png';

  late final AnimationController _motion;
  late final AnimationController _enter;

  late final Animation<double> _decorEnter;
  late final Animation<double> _heroEnter;
  late final Animation<double> _featureEnter;
  late final Animation<double> _ctaEnter;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    Animation<double> staggered(double begin, double end) {
      return CurvedAnimation(
        parent: _enter,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );
    }

    _decorEnter = staggered(0.00, 0.35);
    _heroEnter = staggered(0.12, 0.50);
    _featureEnter = staggered(0.32, 0.70);
    _ctaEnter = staggered(0.48, 0.92);

    _enter.forward();
  }

  @override
  void dispose() {
    _motion.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8FA),
              AppColors.muted,
              Color(0xFFFFE4EC),
              Color(0xFFFFF0F4),
            ],
            stops: [0.0, 0.35, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final circleSize = (w * 0.58).clamp(180.0, 260.0);
              final featureW = (w * 0.42).clamp(140.0, 190.0);
              final featureH = featureW * 0.72;
              // Sejajarkan kartu dengan gelombang baris ke-4 (y ≈ 0.54h).
              final featureTop = h * 0.54 - featureH * 0.42;

              return Stack(
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_motion, _decorEnter]),
                      builder: (context, _) {
                        final fade = _decorEnter.value;
                        return Opacity(
                          opacity: fade,
                          child: CustomPaint(
                            painter: _SplashDecorPainter(
                              progress: _motion.value,
                              lineColor: AppColors.ink.withValues(
                                alpha: 0.16 * fade,
                              ),
                              sparkleColor: AppColors.brand.withValues(
                                alpha: fade,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    top: h * 0.08,
                    left: w * 0.08,
                    child: _AppearOverlay(
                      animation: _heroEnter,
                      beginOffset: const Offset(0, -0.08),
                      beginScale: 0.88,
                      child: _HeroCircle(size: circleSize),
                    ),
                  ),
                  Positioned(
                    top: featureTop,
                    right: w * 0.06,
                    child: _AppearOverlay(
                      animation: _featureEnter,
                      beginOffset: const Offset(0.12, 0.06),
                      beginScale: 0.9,
                      child: _FeatureImageCard(
                        width: featureW,
                        height: featureH,
                        assetPath: _featureAsset,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 20,
                    child: _AppearOverlay(
                      animation: _ctaEnter,
                      beginOffset: const Offset(0, 0.18),
                      beginScale: 0.96,
                      child: _BottomCtaCard(
                        onStart: () => context.go('/welcome'),
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

/// Fade + slide + scale masuk — overlay appear untuk tiap komponen splash.
class _AppearOverlay extends StatelessWidget {
  const _AppearOverlay({
    required this.animation,
    required this.child,
    this.beginOffset = const Offset(0, 0.1),
    this.beginScale = 0.92,
  });

  final Animation<double> animation;
  final Widget child;
  final Offset beginOffset;
  final double beginScale;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        final offset = Offset.lerp(beginOffset, Offset.zero, t)!;
        final scale = beginScale + (1 - beginScale) * t;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              offset.dx * MediaQuery.sizeOf(context).width * 0.2,
              offset.dy * 48,
            ),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _HeroCircle extends StatelessWidget {
  const _HeroCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 5),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandSoft,
            AppColors.brandLight,
            Color(0xFFFFF0F4),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            LucideIcons.scanFace,
            size: size * 0.34,
            color: AppColors.brand.withValues(alpha: 0.85),
          ),
          Positioned(
            right: size * 0.22,
            top: size * 0.28,
            child: Container(
              width: size * 0.08,
              height: size * 0.08,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureImageCard extends StatelessWidget {
  const _FeatureImageCard({
    required this.width,
    required this.height,
    required this.assetPath,
  });

  final double width;
  final double height;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    const borderWidth = 3.0;
    const radius = 28.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.white, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - borderWidth),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              assetPath,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.15),
              filterQuality: FilterQuality.high,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x40FFE4EC),
                    Color(0x28F9A8C4),
                    Color(0x35FFF0F4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomCtaCard extends StatelessWidget {
  const _BottomCtaCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'The Perfect',
            style: appFont(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.15,
            ),
          ),
          const Gap(4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Skin',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appFont(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.15,
                  ),
                ),
              ),
              const Gap(10),
              GestureDetector(
                onTap: onStart,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Mulai',
                        style: appFont(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                      const Gap(6),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 16,
                        color: AppColors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Gap(4),
          Text(
            'Care Regimen',
            style: appFont(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              height: 1.15,
            ),
          ),
          const Gap(8),
          Text(
            'Skin Problem Detector · analisis berbasis skala GEA',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: appFont(
              fontSize: 12,
              color: AppColors.inkMuted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashDecorPainter extends CustomPainter {
  _SplashDecorPainter({
    required this.progress,
    required this.lineColor,
    required this.sparkleColor,
  });

  final double progress;
  final Color lineColor;
  final Color sparkleColor;

  double _waveY(
    double x,
    double width,
    double baseY,
    double amp,
    double phase,
  ) {
    return baseY + math.sin((x / width * math.pi * 2) + phase) * amp;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Kelipatan 2π agar wrap AnimationController.repeat() mulus (tanpa loncat).
    final phaseShift = progress * math.pi * 2;
    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;

    // speed harus bilangan bulat agar posisi bintang seamless saat loop.
    final waves = <({
      double y,
      double amp,
      double phase,
      int starCount,
      int speed,
    })>[
      (
        y: size.height * 0.18,
        amp: 11,
        phase: 0.25 + phaseShift,
        starCount: 3,
        speed: 1,
      ),
      (
        y: size.height * 0.30,
        amp: 13,
        phase: 1.05 + phaseShift * 2,
        starCount: 3,
        speed: -1,
      ),
      (
        y: size.height * 0.42,
        amp: 10,
        phase: 0.55 + phaseShift,
        starCount: 2,
        speed: 1,
      ),
      (
        y: size.height * 0.54,
        amp: 12,
        phase: 1.4 + phaseShift * 2,
        starCount: 3,
        speed: -1,
      ),
    ];

    for (final wave in waves) {
      final path = Path();
      var started = false;
      for (var x = -20.0; x <= size.width + 20; x += 5) {
        final y = _waveY(x, size.width, wave.y, wave.amp, wave.phase);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, linePaint);

      for (var i = 0; i < wave.starCount; i++) {
        final base = (i + 0.5) / wave.starCount;
        var travel = (progress * wave.speed + base) % 1.0;
        if (travel < 0) travel += 1.0;
        final x = size.width * travel;
        final y = _waveY(x, size.width, wave.y, wave.amp, wave.phase);
        final twinkle =
            0.72 + 0.28 * math.sin((progress * math.pi * 4) + i * 1.7);
        _drawSparkle(canvas, Offset(x, y), 7.5 + 2.5 * twinkle, twinkle);
      }
    }
  }

  void _drawSparkle(Canvas canvas, Offset c, double r, double opacity) {
    final p = Paint()
      ..color = sparkleColor.withValues(alpha: opacity.clamp(0.45, 1.0))
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(c.dx, c.dy - r), Offset(c.dx, c.dy + r), p);
    canvas.drawLine(Offset(c.dx - r, c.dy), Offset(c.dx + r, c.dy), p);
    canvas.drawLine(
      Offset(c.dx - r * 0.55, c.dy - r * 0.55),
      Offset(c.dx + r * 0.55, c.dy + r * 0.55),
      p,
    );
    canvas.drawLine(
      Offset(c.dx + r * 0.55, c.dy - r * 0.55),
      Offset(c.dx - r * 0.55, c.dy + r * 0.55),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _SplashDecorPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.sparkleColor != sparkleColor;
  }
}
