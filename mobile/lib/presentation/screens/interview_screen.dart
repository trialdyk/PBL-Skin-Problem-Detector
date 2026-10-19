import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/data/models/interview_answers.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/chat_bubbles.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  /// Id pesan bot terakhir yang sudah selesai di-stream.
  String? _streamedBotId;

  void _onBotStreamComplete(String messageId) {
    if (!mounted) return;
    // Abaikan complete dari pesan lama (race saat bot kirim 2 pesan beruntun).
    final lastBot = context
        .read<ScanCubit>()
        .state
        .messages
        .where((m) => m.fromBot)
        .lastOrNull;
    if (lastBot == null || lastBot.id != messageId) return;
    setState(() => _streamedBotId = messageId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanCubit, ScanState>(
      listenWhen: (prev, next) =>
          prev.phase != next.phase ||
          prev.messages.length != next.messages.length,
      listener: (context, state) {
        if (state.phase == ScanPhase.result ||
            state.phase == ScanPhase.diagnosing) {
          context.go('/scan/result');
        }
      },
      builder: (context, state) {
        final lastBot = state.messages.where((m) => m.fromBot).lastOrNull;
        final botStreamDone =
            lastBot == null || _streamedBotId == lastBot.id;
        final showAnswers = !state.isTyping &&
            state.phase == ScanPhase.interviewing &&
            botStreamDone;

        return Scaffold(
          backgroundColor: AppColors.page,
          child: SoftPageBackground(
            child: Column(
              children: [
                _InterviewHeader(
                  onSkip: () => context.read<ScanCubit>().skipInterview(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: InterviewStepProgress(
                    currentStep: state.interviewStep,
                  ),
                ),
                Expanded(
                  child: ListView(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    children: [
                      if (state.isTyping) const ChatTypingBubble(),
                      for (final message in state.messages.reversed)
                        message.fromBot
                            ? ChatBubbleBot(
                                key: ValueKey(message.id),
                                text: message.text,
                                stream: message.id == lastBot?.id &&
                                    _streamedBotId != message.id,
                                onStreamComplete: () =>
                                    _onBotStreamComplete(message.id),
                              )
                            : ChatBubbleUser(
                                key: ValueKey(message.id),
                                text: message.text,
                              ),
                    ],
                  ),
                ),
                if (showAnswers) _AnswerPanel(step: state.interviewStep),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InterviewHeader extends StatelessWidget {
  const _InterviewHeader({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + 12,
        12,
        8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil Kulit Anda',
                  style: appFont(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    height: 1.15,
                  ),
                ),
                const Gap(4),
                Text(
                  'Interview singkat',
                  style: appFont(fontSize: 13, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSkip,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lewati',
                    style: appFont(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const Gap(4),
                  const Icon(
                    LucideIcons.skipForward,
                    size: 14,
                    color: AppColors.inkMuted,
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

class _AnswerPanel extends StatefulWidget {
  const _AnswerPanel({required this.step});

  final int step;

  @override
  State<_AnswerPanel> createState() => _AnswerPanelState();
}

class _AnswerPanelState extends State<_AnswerPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _AnswerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ScanCubit>();
    final options = switch (widget.step) {
      0 => [
          _Option('Saya laki-laki', () => cubit.answerGender(GenderOption.male)),
          _Option(
            'Saya perempuan',
            () => cubit.answerGender(GenderOption.female),
          ),
          _Option(
            'Lebih memilih tidak menjawab',
            () => cubit.answerGender(GenderOption.preferNotToSay),
          ),
        ],
      1 => [
          _Option('18 tahun', () => cubit.answerAge(18)),
          _Option('20 tahun', () => cubit.answerAge(20)),
          _Option('25 tahun', () => cubit.answerAge(25)),
          _Option('30 tahun', () => cubit.answerAge(30)),
          _Option('35+ tahun', () => cubit.answerAge(36)),
        ],
      2 => [
          _Option('Ya, rutin', () => cubit.answerSunscreen(true)),
          _Option('Tidak / jarang', () => cubit.answerSunscreen(false)),
        ],
      3 => [
          _Option(
            'Berminyak',
            () => cubit.answerSkinType(SkinTypeOption.oily),
          ),
          _Option('Kering', () => cubit.answerSkinType(SkinTypeOption.dry)),
          _Option(
            'Kombinasi',
            () => cubit.answerSkinType(SkinTypeOption.combination),
          ),
          _Option(
            'Sensitif',
            () => cubit.answerSkinType(SkinTypeOption.sensitive),
          ),
          _Option('Normal', () => cubit.answerSkinType(SkinTypeOption.normal)),
        ],
      4 => [
          _Option('Sering', () => cubit.answerUnhealthyFood(true)),
          _Option('Jarang', () => cubit.answerUnhealthyFood(false)),
        ],
      _ => <_Option>[],
    };

    if (options.isEmpty) return const SizedBox.shrink();

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.18),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _enter, curve: Curves.easeOut),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: const Border(top: BorderSide(color: AppColors.border)),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pilih jawabanmu',
                  style: appFont(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
                  ),
                ),
                const Gap(12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < options.length; i++)
                      _AnswerChip(
                        label: options[i].label,
                        onTap: options[i].onTap,
                        index: i,
                        enter: _enter,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerChip extends StatefulWidget {
  const _AnswerChip({
    required this.label,
    required this.onTap,
    required this.index,
    required this.enter,
  });

  final String label;
  final VoidCallback onTap;
  final int index;
  final Animation<double> enter;

  @override
  State<_AnswerChip> createState() => _AnswerChipState();
}

class _AnswerChipState extends State<_AnswerChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final start = (0.18 + widget.index * 0.08).clamp(0.0, 0.7);
    final end = (start + 0.35).clamp(0.0, 1.0);
    final stagger = CurvedAnimation(
      parent: widget.enter,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: stagger,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(stagger),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _pressed ? AppColors.brandSoft : AppColors.page,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _pressed ? AppColors.brandLight : AppColors.border,
                ),
              ),
              child: Text(
                widget.label,
                style: appFont(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _pressed ? AppColors.brand : AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Option {
  const _Option(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
}
