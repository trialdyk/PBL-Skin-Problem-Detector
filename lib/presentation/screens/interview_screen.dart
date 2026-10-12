import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/data/models/interview_answers.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/chat_bubbles.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class InterviewScreen extends StatelessWidget {
  const InterviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanCubit, ScanState>(
      listenWhen: (prev, next) => prev.phase != next.phase,
      listener: (context, state) {
        if (state.phase == ScanPhase.result ||
            state.phase == ScanPhase.diagnosing) {
          context.go('/scan/result');
        }
      },
      builder: (context, state) {
        return Scaffold(
          headers: [
            AppBar(
              title: const Text('Profil Kulit Anda'),
              subtitle: const Text('Interview singkat'),
              trailing: [
                GhostButton(
                  onPressed: () => context.read<ScanCubit>().skipInterview(),
                  trailing: const Icon(LucideIcons.skipForward),
                  child: const Text('Lewati'),
                ),
              ],
            ),
            const Divider(),
          ],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: InterviewStepProgress(currentStep: state.interviewStep),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final message in state.messages)
                      message.fromBot
                          ? ChatBubbleBot(text: message.text)
                          : ChatBubbleUser(text: message.text),
                    if (state.isTyping) const ChatTypingBubble(),
                  ],
                ),
              ),
              if (!state.isTyping && state.phase == ScanPhase.interviewing)
                _AnswerPanel(step: state.interviewStep),
            ],
          ),
        );
      },
    );
  }
}

class _AnswerPanel extends StatelessWidget {
  const _AnswerPanel({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ScanCubit>();
    final options = switch (step) {
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

    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: scheme.card,
        border: Border(top: BorderSide(color: scheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pilih jawabanmu').xSmall.muted,
            const Gap(10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options
                  .map(
                    (option) => OutlineButton(
                      onPressed: option.onTap,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
            ),
          ],
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
