import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Tab Profil — menampilkan ringkasan akun, menu preferensi, dan tombol keluar.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthCubit>().state.user;
    final email = user?.email.isNotEmpty == true ? user!.email : '-';
    final name = user?.displayName ?? 'Pengguna';

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.muted, AppColors.page, Color(0xFFFFF8FA)],
        ),
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + 16,
          20,
          24,
        ),
        children: [
          Text(
            'Profil',
            style: appFont(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const Gap(20),
          _ProfileSummaryCard(
            name: name,
            email: email,
            onEditProfile: () => context.push('/profile/edit'),
          ),
          const Gap(24),
          Text(
            'Akun',
            style: appFont(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const Gap(10),
          _ProfileMenuCard(
            children: [
              _ProfileMenuTile(
                icon: LucideIcons.user,
                label: 'Edit nama & email',
                onTap: () => context.push('/profile/edit'),
              ),
              const _ProfileMenuDivider(),
              _ProfileMenuTile(
                icon: LucideIcons.lock,
                label: 'Ubah kata sandi',
                onTap: () => context.push('/profile/password'),
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

String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({
    required this.name,
    required this.email,
    required this.onEditProfile,
  });

  final String name;
  final String email;
  final VoidCallback onEditProfile;

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
                      style: appFont(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const Gap(3),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: appFont(fontSize: 12.5, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(18),
          GestureDetector(
            onTap: onEditProfile,
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
  const _ProfileMenuTile({required this.label, required this.onTap, this.icon});

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
