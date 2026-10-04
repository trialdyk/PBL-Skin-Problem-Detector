import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/home_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/home_state.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/articles_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_bottom_nav.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          footers: [
            AppBottomNav(
              currentIndex: state.tabIndex,
              onChanged: context.read<HomeCubit>().setTab,
            ),
          ],
          child: switch (state.tabIndex) {
            1 => const ArticlesScreen(),
            2 => const _ProfileTab(),
            _ => const _HomeTab(),
          },
        );
      },
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthCubit>().state.user?.email ?? 'Pengguna';
    final name = email.contains('@') ? email.split('@').first : email;
    final width = MediaQuery.sizeOf(context).width;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.slate,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 16,
              20,
              24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 2),
                      ),
                      child: const Icon(
                        LucideIcons.user,
                        color: AppColors.slate,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const Gap(2),
                          const Text(
                            'Skin check ready',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.mint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(20),
                SizedBox(
                  height: 168,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _HeroCard(
                        width: width * 0.42,
                        icon: LucideIcons.scanFace,
                        iconBg: AppColors.mint,
                        title: 'Scan Wajah',
                        subtitle: 'Ambil 3 selfie & dapatkan skor GEA',
                        onTap: () => context.push('/scan'),
                      ),
                      const Gap(12),
                      _HeroCard(
                        width: width * 0.42,
                        icon: LucideIcons.newspaper,
                        iconBg: AppColors.blush,
                        title: 'Artikel Kulit',
                        subtitle: 'Tips perawatan & edukasi jerawat',
                        onTap: () => context.read<HomeCubit>().setTab(1),
                      ),
                      const Gap(12),
                      _HeroCard(
                        width: width * 0.42,
                        icon: LucideIcons.shieldCheck,
                        iconBg: AppColors.sand,
                        title: 'Skala GEA',
                        subtitle: 'Pahami tingkat 0–5 secara singkat',
                        onTap: () => context.read<HomeCubit>().setTab(1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE5E9EF)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Siap analisis',
                          style: TextStyle(
                            color: Color(0xFF7A8494),
                            fontSize: 12,
                          ),
                        ),
                        Gap(6),
                        Text(
                          'Mulai Scan Kulitmu',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.slate,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  GestureDetector(
                    onTap: () => context.push('/scan'),
                    child: Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.mint,
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        'Go',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.slate,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Fitur untukmu',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.slate,
                    ),
                  ),
                ),
                GhostButton(
                  density: ButtonDensity.compact,
                  onPressed: () => context.push('/scan'),
                  child: const Text(
                    'More',
                    style: TextStyle(
                      color: AppColors.slate,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            delegate: SliverChildListDelegate([
              _FeatureTile(
                icon: LucideIcons.camera,
                color: AppColors.mint,
                title: 'Ambil Selfie',
                subtitle: 'Kamera depan live + cek posisi',
                onTap: () => context.push('/scan'),
              ),
              _FeatureTile(
                icon: LucideIcons.images,
                color: AppColors.sand,
                title: 'Unggah Foto',
                subtitle: 'Pakai foto dari galeri',
                onTap: () => context.push('/scan/upload'),
              ),
              _FeatureTile(
                icon: LucideIcons.messagesSquare,
                color: AppColors.blush,
                title: 'Interview',
                subtitle: 'Profil kulit chat singkat',
                onTap: () => context.push('/scan'),
              ),
              _FeatureTile(
                icon: LucideIcons.activity,
                color: const Color(0xFF8BC4C7),
                title: 'Hasil GEA',
                subtitle: 'Lihat tingkat 0–5',
                onTap: () => context.push('/scan'),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.width,
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width.clamp(150.0, 200.0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.slate, size: 20),
            ),
            const Gap(14),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.slate,
              ),
            ),
            const Gap(6),
            Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7A8494),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E9EF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.slate, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.slate,
              ),
            ),
            const Gap(4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7A8494),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AuthCubit>().state.user?.email ?? '-';
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 20,
        20,
        20,
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E9EF)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Akun (Mock)',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppColors.slate,
                ),
              ),
              const Gap(12),
              Text(
                'Email: $email',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.slate),
              ),
              const Gap(8),
              const Text(
                'Sesi login hanya tersimpan di memori aplikasi.',
                style: TextStyle(color: Color(0xFF7A8494)),
              ),
              const Gap(20),
              SizedBox(
                width: double.infinity,
                child: OutlineButton(
                  onPressed: () {
                    context.read<AuthCubit>().logout();
                    context.go('/welcome');
                  },
                  child: const Text('Keluar'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
