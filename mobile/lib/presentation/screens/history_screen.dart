import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/history_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/history_state.dart';
import 'package:pbl_skin_problem_detector/data/models/history_item.dart';
import 'package:pbl_skin_problem_detector/data/services/history/history.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_bottom_nav.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/auth_network_image.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.read<HistoryService>();
    return BlocProvider(
      create: (_) => HistoryCubit(history)..loadList(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      footers: [
        AppBottomNav(
          currentIndex: NavIndex.interview,
          onChanged: (index) => handleBottomNavTap(
            context,
            index,
            current: NavIndex.interview,
          ),
          onProfile: () => context.go('/home'),
        ),
      ],
      child: SoftPageBackground(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 12,
                20,
                8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Riwayat',
                  style: appFont(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<HistoryCubit, HistoryState>(
                builder: (context, state) {
                  if (state.status == HistoryStatus.loading &&
                      state.items.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(size: 32),
                    );
                  }
                  if (state.status == HistoryStatus.failure &&
                      state.items.isEmpty) {
                    return _EmptyOrError(
                      title: 'Gagal memuat',
                      subtitle: state.errorMessage ?? 'Coba lagi nanti.',
                      actionLabel: 'Muat ulang',
                      onAction: () => context.read<HistoryCubit>().loadList(),
                    );
                  }
                  if (state.items.isEmpty) {
                    return _EmptyOrError(
                      title: 'Belum ada riwayat',
                      subtitle:
                          'Selesaikan scan wajah untuk melihat hasil di sini.',
                      actionLabel: 'Mulai scan',
                      onAction: () => context.push('/scan'),
                    );
                  }

                  final groups = _groupItems(state.items);
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index > 0) const Gap(18),
                          Text(
                            group.label,
                            style: appFont(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.inkMuted,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const Gap(10),
                          for (final item in group.items) ...[
                            _HistoryCard(
                              item: item,
                              onTap: () =>
                                  context.push('/history/${item.id}'),
                            ),
                            const Gap(10),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryGroup {
  const _HistoryGroup(this.label, this.items);
  final String label;
  final List<HistoryItem> items;
}

List<_HistoryGroup> _groupItems(List<HistoryItem> items) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final weekStart = todayStart.subtract(const Duration(days: 7));

  final today = <HistoryItem>[];
  final week = <HistoryItem>[];
  final older = <HistoryItem>[];

  for (final item in items) {
    final local = item.createdAt.toLocal();
    if (!local.isBefore(todayStart)) {
      today.add(item);
    } else if (!local.isBefore(weekStart)) {
      week.add(item);
    } else {
      older.add(item);
    }
  }

  return [
    if (today.isNotEmpty) _HistoryGroup('Hari ini', today),
    if (week.isNotEmpty) _HistoryGroup('7 hari terakhir', week),
    if (older.isNotEmpty) _HistoryGroup('Lebih lama', older),
  ];
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.onTap});

  final HistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gradeColor = AppColors.gradeColor(item.grade);
    final rec = item.recommendation;

    return GestureDetector(
      onTap: onTap,
      child: SoftSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'IGA ${item.grade} · ${item.gradeLabel}',
                    style: appFont(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: gradeColor,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _timeLabel(item.createdAt),
                  style: appFont(fontSize: 12, color: AppColors.inkMuted),
                ),
              ],
            ),
            const Gap(12),
            Row(
              children: [
                for (final path in item.photos.all) ...[
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: AuthNetworkImage(
                        path: path,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (path != item.photos.right) const Gap(8),
                ],
              ],
            ),
            const Gap(12),
            Text(
              switch (rec.status) {
                RecommendationStatus.ready =>
                  (rec.text?.trim().isNotEmpty == true)
                      ? rec.text!.trim()
                      : 'Rekomendasi siap dilihat',
                RecommendationStatus.failed =>
                  'Rekomendasi belum tersedia',
                RecommendationStatus.pending =>
                  'Rekomendasi segera tersedia',
              },
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: appFont(
                fontSize: 13,
                color: rec.status == RecommendationStatus.ready
                    ? AppColors.ink
                    : AppColors.inkMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _timeLabel(DateTime value) {
  final local = value.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class _EmptyOrError extends StatelessWidget {
  const _EmptyOrError({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.clipboardList,
              size: 40,
              color: AppColors.brandLight,
            ),
            const Gap(14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: appFont(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const Gap(8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: appFont(
                fontSize: 13.5,
                color: AppColors.inkMuted,
                height: 1.45,
              ),
            ),
            const Gap(20),
            AppButton(label: actionLabel, onTap: onAction),
          ],
        ),
      ),
    );
  }
}
