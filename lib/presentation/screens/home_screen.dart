import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/home_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/home_state.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/articles_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_bottom_nav.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Indeks tab di [HomeCubit]. Profil & Artikel tidak ada di bottom nav;
/// dibuka lewat avatar / quick action / kartu "Untukmu".
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
              profileSelected: state.tabIndex == _tabProfile,
              onChanged: (index) => handleBottomNavTap(
                context,
                index,
                current: NavIndex.home,
                onHome: () => context.read<HomeCubit>().setTab(_tabHome),
              ),
              onProfile: () => context.read<HomeCubit>().setTab(_tabProfile),
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
    final scan = context.watch<ScanCubit>().state;
    final photosDone = [
      scan.session.frontPath,
      scan.session.leftPath,
      scan.session.rightPath,
    ].whereType<String>().length;
    final progress = (photosDone / 3).clamp(0.0, 1.0);
    final progressPct = (progress * 100).round();

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.muted,
            AppColors.page,
            Color(0xFFFFF8FA),
          ],
        ),
      ),
      child: Column(
        children: [
          AppHeader(
            onProfile: () => context.read<HomeCubit>().setTab(_tabProfile),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Text.rich(
                  TextSpan(
                    style: appFont(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      height: 1.2,
                    ),
                    children: [
                      const TextSpan(text: 'Halo, '),
                      TextSpan(
                        text: name,
                        style: appFont(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brand,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(6),
                Text(
                  'Mari rawat kulitmu hari ini',
                  style: appFont(
                    fontSize: 14,
                    color: AppColors.inkMuted,
                    height: 1.4,
                  ),
                ),
                const Gap(20),
                _RoutineCard(
                  progress: progress,
                  progressLabel: '$progressPct%',
                  subtitle: photosDone == 0
                      ? '3 langkah · Siap mulai'
                      : '$photosDone/3 foto · Lanjutkan',
                  onTap: () => context.push('/scan'),
                ),
                const Gap(16),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: LucideIcons.scanFace,
                        label: 'AI scan',
                        tint: AppColors.brandSoft,
                        iconColor: AppColors.brand,
                        onTap: () => context.push('/scan'),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: _QuickAction(
                        icon: LucideIcons.bookOpen,
                        label: 'Artikel',
                        tint: const Color(0xFFE8F5E9),
                        iconColor: const Color(0xFF2E7D32),
                        onTap: () =>
                            context.read<HomeCubit>().setTab(_tabArticles),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: _QuickAction(
                        icon: LucideIcons.user,
                        label: 'Profil',
                        tint: AppColors.accentSoft,
                        iconColor: AppColors.accent,
                        onTap: () =>
                            context.read<HomeCubit>().setTab(_tabProfile),
                      ),
                    ),
                  ],
                ),
                const Gap(24),
                _SectionHeader(
                  title: 'Untukmu',
                  action: 'Lihat semua',
                  onAction: () =>
                      context.read<HomeCubit>().setTab(_tabArticles),
                ),
                const Gap(12),
                _ForYouCard(
                  onTap: () => context.read<HomeCubit>().setTab(_tabArticles),
                ),
                const Gap(24),
                _SectionHeader(
                  title: 'Direkomendasikan',
                  action: 'Lihat semua',
                  onAction: () => showComingSoon(context),
                ),
                const Gap(12),
                const _RecommendedCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  const _SoftCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.white,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.progress,
    required this.progressLabel,
    required this.subtitle,
    required this.onTap,
  });

  final double progress;
  final String progressLabel;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              LucideIcons.sun,
              size: 22,
              color: AppColors.amber,
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pemeriksaan GEA',
                  style: appFont(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const Gap(2),
                Text(
                  subtitle,
                  style: appFont(fontSize: 12, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          const Gap(10),
          SizedBox(
            width: 72,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  progressLabel,
                  style: appFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
                const Gap(6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress <= 0 ? 0.04 : progress,
                    minHeight: 6,
                    backgroundColor: AppColors.muted,
                    color: AppColors.brand,
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.tint,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const Gap(10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: appFont(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: appFont(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action,
                style: appFont(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
              const Gap(2),
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.brand,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ForYouCard extends StatelessWidget {
  const _ForYouCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      color: AppColors.brand,
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 12,
                        color: AppColors.white,
                      ),
                      const Gap(5),
                      Text(
                        '3 menit',
                        style: appFont(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(14),
                Text(
                  'Cara scan wajah\nyang benar',
                  style: appFont(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    height: 1.2,
                  ),
                ),
                const Gap(16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Baca sekarang',
                        style: appFont(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brand,
                        ),
                      ),
                      const Gap(4),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 14,
                        color: AppColors.brand,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 96,
              height: 110,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/acne_people.png',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.2),
                  ),
                  Center(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.play,
                        size: 16,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedCard extends StatelessWidget {
  const _RecommendedCard();

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/acne_people.png',
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.15),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hasil GEA terakhir',
                  style: appFont(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Gap(4),
                Text(
                  'Skor 2 · Ringan',
                  style: appFont(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => showComingSoon(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.brand,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.plus,
                size: 20,
                color: AppColors.white,
              ),
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
    final name = _capitalize(_nameFromEmail(email == '-' ? null : email));

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.muted,
            AppColors.page,
            Color(0xFFFFF8FA),
          ],
        ),
      ),
      child: ListView(
        padding: _pagePadding(context),
        children: [
          Text(
            'Profil',
            style: appFont(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const Gap(20),
          _ProfileSummaryCard(name: name, email: email),
          const Gap(24),
          Text(
            'Akun',
            style: appFont(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const Gap(10),
          _ProfileMenuCard(
            children: [
              _ProfileMenuTile(
                label: 'Kelola langganan',
                onTap: () => showComingSoon(context),
              ),
              const _ProfileMenuDivider(),
              _ProfileMenuTile(
                label: 'Pulihkan pembelian',
                onTap: () => showComingSoon(context),
              ),
            ],
          ),
          const Gap(22),
          Text(
            'Preferensi',
            style: appFont(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const Gap(10),
          _ProfileMenuCard(
            children: [
              _ProfileMenuTile(
                icon: LucideIcons.settings,
                label: 'Pengaturan aplikasi',
                onTap: () => showComingSoon(context),
              ),
              const _ProfileMenuDivider(),
              _ProfileMenuTile(
                icon: LucideIcons.lock,
                label: 'Privasi & keamanan',
                onTap: () => showComingSoon(context),
              ),
              const _ProfileMenuDivider(),
              _ProfileMenuTile(
                icon: LucideIcons.bell,
                label: 'Notifikasi',
                onTap: () => showComingSoon(context),
              ),
              const _ProfileMenuDivider(),
              _ProfileMenuTile(
                icon: LucideIcons.globe,
                label: 'Bahasa',
                onTap: () => showComingSoon(context),
              ),
            ],
          ),
          const Gap(24),
          GestureDetector(
            onTap: () {
              context.read<AuthCubit>().logout();
              context.go('/splash');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.logOut,
                    size: 18,
                    color: AppColors.brand,
                  ),
                  const Gap(8),
                  Text(
                    'Keluar',
                    style: appFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(12),
          Text(
            'Sesi hanya tersimpan di memori aplikasi.',
            textAlign: TextAlign.center,
            style: appFont(fontSize: 11.5, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.brandSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _initials(name),
                      style: appFont(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: () => showComingSoon(context),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          size: 12,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appFont(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appFont(
                        fontSize: 12.5,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.brandBright, AppColors.brand],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'PRO',
                  style: appFont(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const Gap(18),
          GestureDetector(
            onTap: () => showComingSoon(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.pencil,
                    size: 16,
                    color: AppColors.white,
                  ),
                  const Gap(8),
                  Text(
                    'Edit profil',
                    style: appFont(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuCard extends StatelessWidget {
  const _ProfileMenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileMenuDivider extends StatelessWidget {
  const _ProfileMenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: AppColors.border),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.muted,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: AppColors.ink),
              ),
              const Gap(12),
            ],
            Expanded(
              child: Text(
                label,
                style: appFont(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}
