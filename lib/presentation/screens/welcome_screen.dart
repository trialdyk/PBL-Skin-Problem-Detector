import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            LucideIcons.scanFace,
                            size: 24,
                            color: scheme.primaryForeground,
                          ),
                        ),
                        const Gap(24),
                        const OutlineBadge(
                          leading: Icon(LucideIcons.sparkles, size: 12),
                          child: Text('Skala GEA 0–5'),
                        ),
                        const Gap(12),
                        const Text('Scan, analisis, dan pahami kulitmu')
                            .x3Large
                            .bold,
                        const Gap(10),
                        const Text(
                          'Ambil 3 selfie, jawab pertanyaan singkat, dan dapatkan tingkat keparahan jerawatmu.',
                        ).muted,
                        const Gap(24),
                        Card(
                          theme: const CardTheme(padding: EdgeInsets.zero),
                          child: Column(
                            children: [
                              for (var i = 0; i < _features.length; i++) ...[
                                Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      IconTile(
                                        icon: _features[i].$1,
                                        size: 36,
                                        iconSize: 18,
                                      ),
                                      const Gap(12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(_features[i].$2).small.semiBold,
                                            const Gap(2),
                                            Text(_features[i].$3).xSmall.muted,
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
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
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
                    const Gap(12),
                    const Text(
                      'Hasil bersifat informatif, bukan diagnosis medis.',
                      textAlign: TextAlign.center,
                    ).xSmall.muted,
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
