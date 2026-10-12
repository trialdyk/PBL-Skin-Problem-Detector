import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  /// Tinggi desain acuan; di bawah ini konten mulai memadat.
  static const _designHeight = 50.0;

  /// Batas bawah skala agar teks tidak menjadi terlalu kecil.
  static const _minScale = 1;

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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Memadat di layar pendek, tidak membesar di layar tinggi.
            final scale = (constraints.maxHeight / _designHeight).clamp(
              _minScale,
              1.0,
            );
            double s(double value) => value * scale;

            // Lebar mengikuti layar (dibatasi 400), sehingga FittedBox hanya
            // mengecil karena tinggi — bukan karena lebar.
            final contentWidth = math.min(
              math.max(constraints.maxWidth - 48, 0.0),
              400.0,
            );

            final content = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: s(40),
                  height: s(40),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(s(11)),
                  ),
                  child: Icon(
                    LucideIcons.scanFace,
                    size: s(22),
                    color: scheme.primaryForeground,
                  ),
                ),
                Gap(s(10)),
                const OutlineBadge(
                  leading: Icon(LucideIcons.sparkles, size: 12),
                  child: Text('Skala GEA 0–5'),
                ),
                Gap(s(10)),
                Text(
                  'Scan, analisis, dan pahami kulitmu',
                  style: appFont(
                    fontSize: s(24),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                Gap(s(8)),
                Text(
                  'Ambil 3 selfie, jawab pertanyaan singkat, dan dapatkan '
                  'tingkat keparahan jerawatmu.',
                  style: appFont(
                    fontSize: s(13.5),
                    color: scheme.mutedForeground,
                    height: 1.45,
                  ),
                ),
                Gap(s(18)),
                Card(
                  theme: const CardTheme(padding: EdgeInsets.zero),
                  child: Column(
                    children: [
                      for (var i = 0; i < _features.length; i++) ...[
                        Padding(
                          padding: EdgeInsets.all(s(12)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconTile(
                                icon: _features[i].$1,
                                size: s(32),
                                iconSize: s(17),
                              ),
                              Gap(s(12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _features[i].$2,
                                      style: appFont(
                                        fontSize: s(13),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Gap(s(2)),
                                    Text(
                                      _features[i].$3,
                                      style: appFont(
                                        fontSize: s(11.5),
                                        color: scheme.mutedForeground,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (i != _features.length - 1) const Divider(),
                      ],
                    ],
                  ),
                ),
              ],
            );

            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(width: contentWidth, child: content),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(24, s(8), 24, s(16)),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PrimaryButton(
                          alignment: Alignment.center,
                          onPressed: () => context.go('/login'),
                          trailing: const Icon(LucideIcons.arrowRight),
                          child: const Text('Mulai Sekarang'),
                        ),
                        Gap(s(10)),
                        Text(
                          'Hasil bersifat informatif, bukan diagnosis medis.',
                          textAlign: TextAlign.center,
                          style: appFont(
                            fontSize: s(11),
                            color: scheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
