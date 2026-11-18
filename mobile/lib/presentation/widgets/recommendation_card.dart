import 'package:pbl_skin_problem_detector/data/models/history_item.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Card yang menampilkan status dan isi rekomendasi perawatan dari LLM.
class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    this.recommendation,
    this.isLoading = false,
    this.unavailableMessage,
    this.onRetry,
    this.onRefresh,
    this.title = 'Rekomendasi perawatan',
  });

  final HistoryRecommendation? recommendation;
  final bool isLoading;
  final String? unavailableMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onRefresh;
  final String title;

  @override
  Widget build(BuildContext context) {
    final rec = recommendation;
    final status = rec?.status ?? RecommendationStatus.pending;
    final text = rec?.text?.trim();
    final showPendingLoading =
        unavailableMessage == null &&
        (isLoading || (rec != null && status == RecommendationStatus.pending && onRefresh == null));

    return SoftSurface(
      color: showPendingLoading ? AppColors.brandSoft : AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.sparkles,
                size: 16,
                color: AppColors.brand,
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  title,
                  style: appFont(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              if (status == RecommendationStatus.ready && text != null && text.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'AI',
                    style: appFont(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brand,
                    ),
                  ),
                ),
            ],
          ),
          const Gap(12),
          if (unavailableMessage != null)
            Text(
              unavailableMessage!,
              style: appFont(
                fontSize: 13.5,
                color: AppColors.inkMuted,
                height: 1.45,
              ),
            )
          else if (showPendingLoading)
            _PendingSkeleton(
              message: isLoading
                  ? 'Menyusun rekomendasi personal sesuai tingkat IGA dan profil kulit Anda...'
                  : 'Rekomendasi personal segera tersedia setelah layanan AI aktif.',
            )
          else if (status == RecommendationStatus.ready &&
              text != null &&
              text.isNotEmpty)
            _FormattedRecommendationText(text: text)
          else if (status == RecommendationStatus.pending)
            _ActionFallback(
              message:
                  'Rekomendasi masih diproses atau layanan AI belum aktif di server.',
              actionLabel: onRefresh != null ? 'Muat ulang' : null,
              actionIcon: LucideIcons.refreshCw,
              onAction: onRefresh,
            )
          else
            _ActionFallback(
              message: 'Rekomendasi belum tersedia untuk sesi ini.',
              actionLabel: onRetry != null ? 'Coba lagi' : null,
              actionIcon: LucideIcons.refreshCw,
              onAction: onRetry,
            ),
        ],
      ),
    );
  }
}

class _PendingSkeleton extends StatelessWidget {
  const _PendingSkeleton({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const Gap(8),
        Container(
          height: 12,
          width: MediaQuery.sizeOf(context).width * 0.55,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const Gap(12),
        Text(
          message,
          style: appFont(
            fontSize: 13,
            color: AppColors.inkMuted,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _ActionFallback extends StatelessWidget {
  const _ActionFallback({
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message,
          style: appFont(
            fontSize: 13.5,
            color: AppColors.inkMuted,
            height: 1.45,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const Gap(12),
          OutlineButton(
            density: ButtonDensity.compact,
            leading: actionIcon != null ? Icon(actionIcon, size: 14) : null,
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}

/// Merender teks markdown ringan dari LLM (`###` heading, `-`/`*` bullet, `**bold**`).
class _FormattedRecommendationText extends StatelessWidget {
  const _FormattedRecommendationText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final children = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i].trimRight();
      final trimmed = raw.trim();
      if (trimmed.isEmpty) {
        if (children.isNotEmpty) {
          children.add(const Gap(6));
        }
        continue;
      }

      if (trimmed.startsWith('#')) {
        final heading = trimmed.replaceFirst(RegExp(r'^#+\s*'), '');
        if (children.isNotEmpty) children.add(const Gap(6));
        children.add(
          _InlineBoldText(
            text: heading,
            baseStyle: appFont(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              height: 1.45,
            ),
          ),
        );
        continue;
      }

      final bulletMatch = RegExp(r'^[-*•]\s+(.+)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: appFont(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                    height: 1.5,
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: _InlineBoldText(
                    text: bulletMatch.group(1)!,
                    baseStyle: appFont(
                      fontSize: 13.5,
                      color: AppColors.ink,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: _InlineBoldText(
            text: trimmed,
            baseStyle: appFont(
              fontSize: 13.5,
              color: AppColors.ink,
              height: 1.55,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _InlineBoldText extends StatelessWidget {
  const _InlineBoldText({required this.text, required this.baseStyle});

  final String text;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    var cursor = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        ),
      );
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
    );
  }
}
