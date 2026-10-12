import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/home_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/home_state.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/articles_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_bottom_nav.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Indeks tab di [HomeCubit]. Profil & Artikel tidak ada di bottom nav;
/// dibuka lewat avatar dan kartu "Tentang Skala GEA".
const _tabHome = 0;
const _tabArticles = 1;
const _tabProfile = 2;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.page,
          footers: [
            AppBottomNav(
              currentIndex: state.tabIndex == _tabHome ? 0 : -1,
              onChanged: (index) => handleBottomNavTap(
                context,
                index,
                current: NavIndex.home,
                onHome: () => context.read<HomeCubit>().setTab(_tabHome),
              ),
            ),
          ],
          child: switch (state.tabIndex) {
            _tabArticles => const ArticlesScreen(),
            _tabProfile => const _ProfileTab(),
            _ => const _HomeTab(),
          },
        );
      },
    );
  }
}

String _nameFromEmail(String? email) {
  if (email == null || email.isEmpty) return 'Pengguna';
  return email.contains('@') ? email.split('@').first : email;
}

String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String _greeting(DateTime now) {
  final hour = now.hour;
  if (hour < 11) return 'Selamat pagi';
  if (hour < 15) return 'Selamat siang';
  if (hour < 18) return 'Selamat sore';
  return 'Selamat malam';
}

EdgeInsets _pagePadding(BuildContext context) => EdgeInsets.fromLTRB(
  20,
  MediaQuery.paddingOf(context).top + 16,
  20,
  24,
);

// ───────────────────────────── Tab Beranda ─────────────────────────────

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthCubit>().state.user?.email;
    final name = _capitalize(_nameFromEmail(email));

    return Column(
      children: [
        AppHeader(
          onProfile: () => context.read<HomeCubit>().setTab(_tabProfile),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            children: [
              const _ProtocolRow(),
              const Gap(14),
              Text(
                '${_greeting(DateTime.now())}, $name',
                style: appFont(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const Gap(6),
              Text(
                'Pantau evolusi lesi kulit dan tingkat keparahan jerawat '
                'Anda secara terukur berbasis standar dermatologi klinis.',
                style: appFont(
                  fontSize: 12,
                  color: AppColors.inkMuted,
                  height: 1.65,
                ),
              ),
              const Gap(16),
              _NewExamCard(onStart: () => context.push('/scan')),
              const Gap(16),
              const _LatestResultCard(),
              const Gap(24),
              const _ValidationSection(),
              const Gap(14),
              _AboutGeaCard(
                onTap: () => context.read<HomeCubit>().setTab(_tabArticles),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProtocolRow extends StatelessWidget {
  const _ProtocolRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pill(
          leading: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
            ),
          ),
          label: 'Protokol Klinis GEA 2.0',
        ),
        const Spacer(),
        Text(
          'ID Sesi: #SKN-8841',
          style: appFont(fontSize: 11, color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

/// Pil kecil bertepi pink.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.leading});

  final String label;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const Gap(6)],
          Text(
            label,
            style: appFont(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.brand,
            ),
          ),
        ],
      ),
    );
  }
}

/// Panel blush bertepi pink — wadah kartu utama.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = 16, this.onTap});

  final Widget child;
  final double padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
    if (onTap == null) return panel;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: panel,
    );
  }
}

/// Tile putih bertepi pink di dalam panel.
class _WhiteTile extends StatelessWidget {
  const _WhiteTile({
    required this.child,
    this.highlighted = false,
    this.padding = const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
  });

  final Widget child;
  final bool highlighted;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: highlighted ? AppColors.brandSoft : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _NewExamCard extends StatelessWidget {
  const _NewExamCard({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    const steps = <(IconData, String, String)>[
      (LucideIcons.camera, '1. Foto Makro', 'Depan & Samping'),
      (LucideIcons.clipboardList, '2. Wawancara', '5 Menit Klinis'),
      (LucideIcons.chartLine, '3. Skor GEA', 'Skala 0–5'),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _Pill(label: 'Langkah Evaluasi'),
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  LucideIcons.activity,
                  size: 20,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
          const Gap(2),
          Text(
            'Mulai Pemeriksaan Baru',
            style: appFont(fontSize: 15.5, fontWeight: FontWeight.w700),
          ),
          const Gap(6),
          Text(
            '3 langkah cepat: tangkap citra makro, respon anamnesis, dan '
            'peroleh kalkulasi GEA instan.',
            style: appFont(
              fontSize: 12.2,
              color: AppColors.inkMuted,
              height: 1.5,
            ),
          ),
          const Gap(14),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                Expanded(
                  child: _WhiteTile(
                    child: Column(
                      children: [
                        Icon(steps[i].$1, size: 18, color: AppColors.brand),
                        const Gap(6),
                        Text(
                          steps[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: appFont(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Gap(1),
                        Text(
                          steps[i].$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: appFont(
                            fontSize: 10,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (i != steps.length - 1) const Gap(8),
              ],
            ],
          ),
          const Gap(14),
          AppButton(
            label: 'Mulai Analisis Kulit',
            trailingIcon: LucideIcons.arrowRight,
            height: 44,
            fontSize: 14,
            onTap: onStart,
          ),
        ],
      ),
    );
  }
}

/// Hasil terbaru. Data contoh — riwayat pemeriksaan belum disimpan.
class _LatestResultCard extends StatelessWidget {
  const _LatestResultCard();

  @override
  Widget build(BuildContext context) {
    const counts = <(String, String)>[
      ('8', 'Komedo'),
      ('3', 'Papula'),
      ('0', 'Nodus'),
    ];

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hasil Paling Baru',
                      style: appFont(fontSize: 9.5, color: AppColors.inkMuted),
                    ),
                    const Gap(1),
                    Text(
                      '12 Mei 2024',
                      style: appFont(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const _Pill(label: 'Skor GEA: 2 (Ringan)'),
            ],
          ),
          const Gap(12),
          _WhiteTile(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kuantifikasi Lesi Aktif Terdeteksi',
                        style: appFont(
                          fontSize: 11,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                    Text(
                      '11 Titik',
                      style: appFont(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                Row(
                  children: [
                    for (var i = 0; i < counts.length; i++) ...[
                      Expanded(
                        child: _WhiteTile(
                          highlighted: i == 1,
                          child: Column(
                            children: [
                              Text(
                                counts[i].$1,
                                style: appFont(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: i == 1
                                      ? AppColors.brand
                                      : AppColors.ink,
                                ),
                              ),
                              Text(
                                counts[i].$2,
                                style: appFont(
                                  fontSize: 11,
                                  color: i == 1
                                      ? AppColors.brand
                                      : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (i != counts.length - 1) const Gap(8),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Gap(12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 3),
                child: Icon(
                  LucideIcons.trendingDown,
                  size: 16,
                  color: AppColors.brand,
                ),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  'Penurunan 24% lesi inflamasi dibanding pemeriksaan '
                  'bulan April.',
                  style: appFont(
                    fontSize: 12,
                    color: AppColors.inkMuted,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          AppButton(
            label: 'Lihat Arsip Lengkap',
            trailingIcon: LucideIcons.chevronRight,
            tonal: true,
            tonalForeground: AppColors.brand,
            height: 40,
            fontSize: 12.5,
            onTap: () => showComingSoon(context),
          ),
        ],
      ),
    );
  }
}

class _ValidationSection extends StatelessWidget {
  const _ValidationSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Validasi & Standar',
              style: appFont(fontSize: 15.5, fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            Expanded(
              child: Text(
                'WHO / FDA Approved Guidelines',
                maxLines: 1,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: appFont(fontSize: 11, color: AppColors.inkMuted),
              ),
            ),
          ],
        ),
        const Gap(10),
        const IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _StatCard(
                  icon: LucideIcons.badgeCheck,
                  value: '94.2%',
                  title: 'Akurasi Anamnesis',
                  body: 'Tervalidasi silang terhadap 1,200+ rekam histologis '
                      'dokter spesialis.',
                ),
              ),
              Gap(10),
              Expanded(
                child: _StatCard(
                  icon: LucideIcons.clipboardList,
                  value: 'GEA 0–5',
                  title: 'Global Evaluation',
                  body: 'Standarisasi klinis global untuk penentuan gradasi '
                      'keparahan akne vulgaris.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String value;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      padding: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, size: 18, color: AppColors.brand),
          ),
          const Gap(12),
          Text(
            value,
            style: appFont(fontSize: 17.5, fontWeight: FontWeight.w700),
          ),
          const Gap(1),
          Text(
            title,
            style: appFont(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const Gap(5),
          Text(
            body,
            style: appFont(
              fontSize: 9.75,
              height: 1.4,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutGeaCard extends StatelessWidget {
  const _AboutGeaCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(LucideIcons.info, size: 18, color: AppColors.brand),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tentang Skala Global Acne (GEA)',
                  style: appFont(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Gap(5),
                Text(
                  'Skala evaluasi dermatologis objektif mulai dari grade 0 '
                  '(bersih tanpa lesi), grade 2 (ringan / mild), hingga grade '
                  '5 (sangat parah dengan lesi nodulokistik merata).',
                  style: appFont(
                    fontSize: 12.75,
                    color: AppColors.inkMuted,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Tab Profil ─────────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthCubit>().state.user?.email ?? '-';
    final name = _nameFromEmail(email == '-' ? null : email);

    return ListView(
      padding: _pagePadding(context),
      children: [
        const Text('Profil').x2Large.bold,
        const Gap(20),
        Row(
          children: [
            Avatar(
              initials: _initials(name),
              size: 56,
              backgroundColor: AppColors.muted,
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)
                      .base
                      .semiBold,
                  const Gap(2),
                  Text(email, maxLines: 1, overflow: TextOverflow.ellipsis)
                      .small
                      .muted,
                ],
              ),
            ),
          ],
        ),
        const Gap(20),
        Card(
          theme: const CardTheme(padding: EdgeInsets.zero),
          child: Column(
            children: [
              _InfoRow(label: 'Email', value: email),
              const Divider(),
              const _InfoRow(label: 'Tipe akun', value: 'Prototipe'),
            ],
          ),
        ),
        const Gap(16),
        const Alert(
          leading: Icon(LucideIcons.info),
          title: Text('Sesi tersimpan di memori'),
          content: Text(
            'Sesi login hanya tersimpan di memori aplikasi dan hilang saat aplikasi ditutup.',
          ),
        ),
        const Gap(20),
        OutlineButton(
          alignment: Alignment.center,
          leading: const Icon(LucideIcons.logOut),
          onPressed: () {
            context.read<AuthCubit>().logout();
            context.go('/welcome');
          },
          child: const Text('Keluar'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(label).small.muted,
          const Gap(16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ).small.medium,
          ),
        ],
      ),
    );
  }
}
