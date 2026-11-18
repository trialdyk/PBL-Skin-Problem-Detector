import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/history_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/history_state.dart';
import 'package:pbl_skin_problem_detector/data/models/history_item.dart';
import 'package:pbl_skin_problem_detector/data/services/history/history.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/auth_network_image.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/gea_scale_bar.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/recommendation_card.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.historyId});

  final String historyId;

  @override
  Widget build(BuildContext context) {
    final history = context.read<HistoryService>();
    return BlocProvider(
      create: (_) => HistoryCubit(history)..loadDetail(historyId),
      child: _HistoryDetailView(historyId: historyId),
    );
  }
}

class _HistoryDetailView extends StatelessWidget {
  const _HistoryDetailView({required this.historyId});

  final String historyId;

  void _confirmDelete(BuildContext context) {
    showOverlay<void>(
      context,
      const DialogConfiguration(),
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus riwayat?'),
        content: const Text(
          'Foto dan hasil scan ini akan dihapus permanen dari server.',
        ),
        actions: [
          OutlineButton(
            onPressed: () => closeOverlay(dialogContext),
            child: const Text('Batal'),
          ),
          PrimaryButton(
            onPressed: () async {
              closeOverlay(dialogContext);
              final ok = await context.read<HistoryCubit>().deleteCurrent();
              if (!context.mounted) return;
              if (ok) {
                showHint(context, 'Riwayat dihapus.');
                context.go('/history');
              } else {
                final msg = context.read<HistoryCubit>().state.errorMessage;
                showHint(context, msg ?? 'Gagal menghapus.');
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      child: SoftPageBackground(
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            final item = state.detail;
            return Column(
              children: [
                _DetailHeader(
                  title: item == null
                      ? 'Detail riwayat'
                      : _dateTitle(item.createdAt),
                  onBack: () => context.pop(),
                  onDelete: item == null ? null : () => _confirmDelete(context),
                  deleting: state.deleting,
                ),
                Expanded(
                  child: switch (state.status) {
                    HistoryStatus.loading when item == null => const Center(
                        child: CircularProgressIndicator(size: 32),
                      ),
                    HistoryStatus.failure when item == null => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                state.errorMessage ?? 'Riwayat tidak ditemukan',
                                textAlign: TextAlign.center,
                                style: appFont(
                                  fontSize: 14,
                                  color: AppColors.inkMuted,
                                ),
                              ),
                              const Gap(16),
                              AppButton(
                                label: 'Coba lagi',
                                onTap: () => context
                                    .read<HistoryCubit>()
                                    .loadDetail(historyId),
                              ),
                            ],
                          ),
                        ),
                      ),
                    _ when item != null => ListView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                        children: [
                          _GradeHero(item: item),
                          const Gap(18),
                          _PhotoStrip(item: item),
                          const Gap(18),
                          RecommendationCard(
                            recommendation: item.recommendation,
                            isLoading: state.retryingRecommendation,
                            onRefresh: !state.retryingRecommendation &&
                                    item.recommendation.status ==
                                        RecommendationStatus.pending
                                ? () => context
                                    .read<HistoryCubit>()
                                    .loadDetail(historyId)
                                : null,
                            onRetry: !state.retryingRecommendation &&
                                    item.recommendation.status ==
                                        RecommendationStatus.failed
                                ? () async {
                                    final err = await context
                                        .read<HistoryCubit>()
                                        .retryRecommendation();
                                    if (err != null && context.mounted) {
                                      showHint(context, err);
                                    }
                                  }
                                : null,
                          ),
                          const Gap(14),
                          _InterviewBlock(interview: item.interview),
                          const Gap(14),
                          SoftSurface(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detail teknis',
                                  style: appFont(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Gap(8),
                                Text(
                                  'Model · ${item.modelId}',
                                  style: appFont(
                                    fontSize: 12.5,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                                const Gap(4),
                                Text(
                                  'Sumber · ${item.resultSource == 'ml' ? 'Analisis CNN' : 'Rule-based interview'}',
                                  style: appFont(
                                    fontSize: 12.5,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.title,
    required this.onBack,
    this.onDelete,
    this.deleting = false,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.paddingOf(context).top + 8,
        12,
        8,
      ),
      child: Row(
        children: [
          IconButton.ghost(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              style: appFont(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          if (onDelete != null)
            IconButton.ghost(
              icon: deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(size: 18),
                    )
                  : const Icon(LucideIcons.trash2, color: AppColors.brand),
              onPressed: deleting ? null : onDelete,
            ),
        ],
      ),
    );
  }
}

class _GradeHero extends StatelessWidget {
  const _GradeHero({required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.gradeColor(item.grade);
    return SoftSurface(
      child: Column(
        children: [
          Text(
            'Tingkat IGA',
            style: appFont(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
          const Gap(8),
          Text(
            '${item.grade}',
            style: appFont(
              fontSize: 56,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
          const Gap(6),
          Text(
            item.gradeLabel,
            style: appFont(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const Gap(16),
          GeaScaleBar(activeGrade: item.grade),
        ],
      ),
    );
  }
}

class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.item});

  final HistoryItem item;

  @override
  Widget build(BuildContext context) {
    const labels = ['Depan', 'Kiri', 'Kanan'];
    final paths = item.photos.all;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto scan',
          style: appFont(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const Gap(10),
        Row(
          children: [
            for (var i = 0; i < paths.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 0.85,
                      child: AuthNetworkImage(
                        path: paths[i],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const Gap(6),
                    Text(
                      labels[i],
                      style: appFont(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < paths.length - 1) const Gap(8),
            ],
          ],
        ),
      ],
    );
  }
}

class _InterviewBlock extends StatelessWidget {
  const _InterviewBlock({required this.interview});

  final Map<String, dynamic> interview;

  @override
  Widget build(BuildContext context) {
    final skipped = interview['skipped'] == true;
    final rows = skipped
        ? const [('Status', 'Wawancara dilewati')]
        : [
            ('Jenis kelamin', _labelGender(interview['gender'])),
            ('Umur', interview['age']?.toString() ?? '—'),
            (
              'Sunscreen',
              interview['uses_sunscreen'] == true
                  ? 'Ya'
                  : interview['uses_sunscreen'] == false
                      ? 'Tidak'
                      : '—'
            ),
            ('Tipe kulit', _labelSkin(interview['skin_type'])),
            (
              'Makanan pemicu',
              interview['unhealthy_food_often'] == true
                  ? 'Sering'
                  : interview['unhealthy_food_often'] == false
                      ? 'Jarang'
                      : '—'
            ),
          ];

    return SoftSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil wawancara',
            style: appFont(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const Gap(12),
          for (final row in rows) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    row.$1,
                    style: appFont(fontSize: 12.5, color: AppColors.inkMuted),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.$2,
                    style: appFont(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            if (row != rows.last) const Gap(10),
          ],
        ],
      ),
    );
  }
}

String _dateTitle(DateTime value) {
  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]} · $h:$m';
}

String _labelGender(Object? value) {
  return switch (value) {
    'male' => 'Laki-laki',
    'female' => 'Perempuan',
    'prefer_not_to_say' => 'Tidak disebutkan',
    _ => '—',
  };
}

String _labelSkin(Object? value) {
  return switch (value) {
    'oily' => 'Berminyak',
    'dry' => 'Kering',
    'combination' => 'Kombinasi',
    'sensitive' => 'Sensitif',
    'normal' => 'Normal',
    _ => '—',
  };
}
