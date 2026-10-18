import 'package:flutter_svg/flutter_svg.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Lockup horizontal DermaScan (tanpa tagline GEA).
/// Teks wordmark di-reveal kiri → kanan lewat [reveal].
class DermaScanBrandLogo extends StatelessWidget {
  const DermaScanBrandLogo({
    super.key,
    this.width = 280,
    this.reveal,
  });

  final double width;

  /// 0 = tersembunyi, 1 = penuh. Null = tampil penuh tanpa animasi.
  final Animation<double>? reveal;

  static const _asset = 'assets/images/dermascan-horizontal-color.svg';

  @override
  Widget build(BuildContext context) {
    final logo = SvgPicture.asset(
      _asset,
      width: width,
      fit: BoxFit.fitWidth,
      alignment: Alignment.centerLeft,
    );

    if (reveal == null) return logo;

    return AnimatedBuilder(
      animation: reveal!,
      builder: (context, _) {
        final t = reveal!.value.clamp(0.0, 1.0);
        return ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: t <= 0 ? 0.001 : t,
            child: Opacity(
              opacity: t <= 0 ? 0 : 1,
              child: logo,
            ),
          ),
        );
      },
    );
  }
}
