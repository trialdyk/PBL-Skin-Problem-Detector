import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ChatBubbleBot extends StatelessWidget {
  const ChatBubbleBot({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const IconTile(
            icon: LucideIcons.sparkles,
            size: 32,
            iconSize: 16,
            circle: true,
          ),
          const Gap(8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.card,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                ),
                border: Border.all(color: scheme.border),
              ),
              child: Text(text).base,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubbleUser extends StatelessWidget {
  const ChatBubbleUser({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 56),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(text).base.medium.primaryForeground,
        ),
      ),
    );
  }
}

class ChatTypingBubble extends StatelessWidget {
  const ChatTypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const IconTile(
            icon: LucideIcons.sparkles,
            size: 32,
            iconSize: 16,
            circle: true,
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(),
                Gap(4),
                _Dot(),
                Gap(4),
                _Dot(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.inkMuted,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Progress interview: "Pertanyaan x dari n" + bar shadcn.
class InterviewStepProgress extends StatelessWidget {
  const InterviewStepProgress({
    super.key,
    required this.currentStep,
    this.total = 5,
  });

  final int currentStep;
  final int total;

  @override
  Widget build(BuildContext context) {
    final step = currentStep.clamp(0, total);
    final shown = (step + 1).clamp(1, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Pertanyaan $shown dari $total').small.muted),
            Text('${((step / total) * 100).round()}%').small.semiBold,
          ],
        ),
        const Gap(8),
        Progress(progress: step / total),
      ],
    );
  }
}
