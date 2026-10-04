import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/data/models/interview_answers.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
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
          backgroundColor: AppColors.surface,
          headers: [
            AppBar(
              title: const Text('PROFIL KULIT ANDA'),
              trailing: [
                GhostButton(
                  onPressed: () => context.read<ScanCubit>().skipInterview(),
                  child: const Text('Lewati'),
                ),
              ],
            ),
          ],
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
                    if (state.isTyping)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          '•••',
                          style: TextStyle(
                            color: Color(0xFF9AA3B0),
                            fontSize: 22,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E9EF))),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map(
              (option) => SecondaryButton(
                onPressed: option.onTap,
                child: Text(option.label),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Option {
  const _Option(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
}
