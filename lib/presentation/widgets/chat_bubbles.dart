import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ChatBubbleBot extends StatelessWidget {
  const ChatBubbleBot({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 48),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const Gap(8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E9EF)),
              ),
              child: Text(
                text,
                style: const TextStyle(color: AppColors.slate, height: 1.4),
              ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 48),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.slate,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

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
    return Row(
      children: List.generate(total, (index) {
        final done = index < currentStep;
        final active = index == currentStep;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
            height: 6,
            decoration: BoxDecoration(
              color: done || active ? AppColors.mint : const Color(0xFFD5DBE3),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}
