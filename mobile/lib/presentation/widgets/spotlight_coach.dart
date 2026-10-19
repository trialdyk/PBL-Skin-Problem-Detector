import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Overlay spotlight ala Driver.js: dim layar + lubang highlight + tooltip.
class SpotlightCoach extends StatelessWidget {
  const SpotlightCoach({
    super.key,
    required this.target,
    required this.title,
    required this.body,
    required this.onDismiss,
    this.padding = 8,
    this.radius = 18,
  });

  final Rect target;
  final String title;
  final String body;
  final VoidCallback onDismiss;
  final double padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hole = Rect.fromLTRB(
      target.left - padding,
      target.top - padding,
      target.right + padding,
      target.bottom + padding,
    );
    final size = MediaQuery.sizeOf(context);
    final tipAbove = hole.top > 150;

    return Stack(
      children: [
        // Visual dim + lubang rounded (tidak menyerap tap).
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SpotlightPainter(hole: hole, radius: radius),
            ),
          ),
        ),
        // Panel tap di luar hole → dismiss; area hole tembus ke tombol asli.
        _DimHitZone(hole: hole, screen: size, onDismiss: onDismiss),
        // Ring highlight di tepi hole.
        Positioned(
          left: hole.left,
          top: hole.top,
          width: hole.width,
          height: hole.height,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(color: AppColors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Tempelkan tooltip rapat ke tombol (sedikit overlap ke hole).
        if (tipAbove)
          Positioned(
            left: 20,
            right: 20,
            bottom: size.height - hole.top - 2,
            child: _CoachTooltip(
              title: title,
              body: body,
              arrowDown: true,
              onDismiss: onDismiss,
            ),
          )
        else
          Positioned(
            left: 20,
            right: 20,
            top: hole.bottom - 2,
            child: _CoachTooltip(
              title: title,
              body: body,
              arrowDown: false,
              onDismiss: onDismiss,
            ),
          ),
      ],
    );
  }
}

/// Empat zona di luar [hole] — tap dismiss; tengah tembus.
class _DimHitZone extends StatelessWidget {
  const _DimHitZone({
    required this.hole,
    required this.screen,
    required this.onDismiss,
  });

  final Rect hole;
  final Size screen;
  final VoidCallback onDismiss;

  Widget _zone({
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    if (width <= 0 || height <= 0) return const SizedBox.shrink();
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: onDismiss,
        behavior: HitTestBehavior.opaque,
        child: const ColoredBox(color: Color(0x00000000)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _zone(left: 0, top: 0, width: screen.width, height: hole.top),
        _zone(
          left: 0,
          top: hole.bottom,
          width: screen.width,
          height: screen.height - hole.bottom,
        ),
        _zone(left: 0, top: hole.top, width: hole.left, height: hole.height),
        _zone(
          left: hole.right,
          top: hole.top,
          width: screen.width - hole.right,
          height: hole.height,
        ),
      ],
    );
  }
}

class _CoachTooltip extends StatelessWidget {
  const _CoachTooltip({
    required this.title,
    required this.body,
    required this.arrowDown,
    required this.onDismiss,
  });

  final String title;
  final String body;

  /// true = panah di bawah kartu (tooltip di atas target).
  final bool arrowDown;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: appFont(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const Gap(6),
          Text(
            body,
            style: appFont(
              fontSize: 13,
              color: AppColors.inkMuted,
              height: 1.4,
            ),
          ),
          const Gap(12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Mengerti',
                  style: appFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!arrowDown)
          CustomPaint(
            size: const Size(18, 9),
            painter: _ArrowPainter(up: true),
          ),
        card,
        if (arrowDown)
          CustomPaint(
            size: const Size(18, 9),
            painter: _ArrowPainter(up: false),
          ),
      ],
    );
  }
}

class _ArrowPainter extends CustomPainter {
  _ArrowPainter({required this.up});

  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (up) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) => old.up != up;
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.hole, required this.radius});

  final Rect hole;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final cut = Path()
      ..addRRect(RRect.fromRectAndRadius(hole, Radius.circular(radius)));
    final dimmed = Path.combine(PathOperation.difference, overlay, cut);
    canvas.drawPath(
      dimmed,
      Paint()..color = const Color(0xFF1F1A1D).withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole || old.radius != radius;
}
