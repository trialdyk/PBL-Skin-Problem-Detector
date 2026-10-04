import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/data/models/interview_answers.dart';
import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/data/repositories/scan_repository.dart';

class ScanCubit extends Cubit<ScanState> {
  ScanCubit(this._repository) : super(const ScanState());

  final ScanRepository _repository;
  int _msgCounter = 0;

  void startCapture() {
    emit(state.copyWith(
      phase: ScanPhase.capturing,
      currentAngle: SelfieAngle.front,
      clearError: true,
    ));
  }

  void startUpload() {
    emit(state.copyWith(phase: ScanPhase.uploading, clearError: true));
  }

  void setPhoto(SelfieAngle angle, String path) {
    _repository.setPhoto(angle, path);
    final session = _repository.session;

    if (state.phase == ScanPhase.capturing) {
      final next = _nextAngle(angle);
      if (next == null) {
        emit(state.copyWith(session: session, phase: ScanPhase.confirming));
      } else {
        emit(state.copyWith(session: session, currentAngle: next));
      }
      return;
    }

    emit(state.copyWith(session: session));
    if (session.hasAllPhotos && state.phase == ScanPhase.uploading) {
      emit(state.copyWith(phase: ScanPhase.confirming));
    }
  }

  SelfieAngle? _nextAngle(SelfieAngle current) {
    return switch (current) {
      SelfieAngle.front => SelfieAngle.left,
      SelfieAngle.left => SelfieAngle.right,
      SelfieAngle.right => null,
    };
  }

  void retakePhotos() {
    _repository.clearPhotos();
    emit(state.copyWith(
      session: _repository.session,
      phase: ScanPhase.intro,
      currentAngle: SelfieAngle.front,
      clearError: true,
    ));
  }

  void goToConfirm() {
    if (!_repository.session.hasAllPhotos) {
      emit(state.copyWith(errorMessage: 'Unggah 3 foto terlebih dahulu.'));
      return;
    }
    emit(state.copyWith(
      session: _repository.session,
      phase: ScanPhase.confirming,
      clearError: true,
    ));
  }

  Future<void> continueToInterview() async {
    emit(state.copyWith(
      phase: ScanPhase.interviewing,
      interviewStep: 0,
      messages: const [],
      clearError: true,
    ));
    await _pushBot(
      'Halo! Saya akan membantu membuat profil kulit Anda. '
      'Jawaban ini membantu diagnosa GEA lebih akurat.',
    );
    await _askCurrentQuestion();
  }

  Future<void> skipInterview() async {
    final answers = const InterviewAnswers(skipped: true);
    _repository.setInterview(answers);
    emit(state.copyWith(session: _repository.session));
    await _runDiagnosis();
  }

  Future<void> answerGender(GenderOption value) async {
    final label = switch (value) {
      GenderOption.male => 'Saya laki-laki',
      GenderOption.female => 'Saya perempuan',
      GenderOption.preferNotToSay => 'Lebih memilih tidak menjawab',
    };
    await _answer(
      key: 'gender',
      label: label,
      update: (a) => a.copyWith(gender: value),
    );
  }

  Future<void> answerAge(int age) async {
    await _answer(
      key: 'age',
      label: 'Saya berumur $age tahun',
      update: (a) => a.copyWith(age: age),
    );
  }

  Future<void> answerSunscreen(bool value) async {
    await _answer(
      key: 'sunscreen',
      label: value ? 'Saya memakai sunscreen' : 'Saya jarang/tidak memakai sunscreen',
      update: (a) => a.copyWith(usesSunscreen: value),
    );
  }

  Future<void> answerSkinType(SkinTypeOption value) async {
    final label = switch (value) {
      SkinTypeOption.oily => 'Kulit berminyak',
      SkinTypeOption.dry => 'Kulit kering',
      SkinTypeOption.combination => 'Kulit kombinasi',
      SkinTypeOption.sensitive => 'Kulit sensitif',
      SkinTypeOption.normal => 'Kulit normal',
    };
    await _answer(
      key: 'skinType',
      label: label,
      update: (a) => a.copyWith(skinType: value),
    );
  }

  Future<void> answerUnhealthyFood(bool value) async {
    await _answer(
      key: 'food',
      label: value
          ? 'Sering konsumsi makanan pemicu (gorengan, manis, dll)'
          : 'Jarang konsumsi makanan pemicu',
      update: (a) => a.copyWith(unhealthyFoodOften: value),
    );
  }

  Future<void> _answer({
    required String key,
    required String label,
    required InterviewAnswers Function(InterviewAnswers) update,
  }) async {
    final updated = update(state.session.interview);
    _repository.setInterview(updated);

    final messages = [
      ...state.messages,
      ChatMessage(
        id: 'u-${_msgCounter++}',
        fromBot: false,
        text: label,
        editableKey: key,
      ),
    ];

    emit(state.copyWith(
      session: _repository.session,
      messages: messages,
      interviewStep: state.interviewStep + 1,
    ));

    if (state.interviewStep >= 5) {
      await _pushBot('Terima kasih. Saya sedang menganalisis profil kulit Anda...');
      await _runDiagnosis();
      return;
    }

    await _askCurrentQuestion();
  }

  Future<void> _askCurrentQuestion() async {
    final step = state.interviewStep;
    final question = switch (step) {
      0 => 'Jenis kelamin Anda?',
      1 => 'Berapa umur Anda? Usia membantu menyesuaikan penilaian kulit.',
      2 => 'Apakah Anda rutin memakai sunscreen?',
      3 => 'Bagaimana tipe kulit Anda?',
      4 =>
        'Seberapa sering Anda konsumsi makanan tidak sehat yang bisa memicu masalah kulit?',
      _ => null,
    };
    if (question != null) {
      await _pushBot(question);
    }
  }

  Future<void> _pushBot(String text) async {
    emit(state.copyWith(isTyping: true));
    await Future<void>.delayed(const Duration(milliseconds: 450));
    emit(state.copyWith(
      isTyping: false,
      messages: [
        ...state.messages,
        ChatMessage(id: 'b-${_msgCounter++}', fromBot: true, text: text),
      ],
    ));
  }

  Future<void> _runDiagnosis() async {
    emit(state.copyWith(phase: ScanPhase.diagnosing, clearError: true));
    try {
      await _repository.diagnose();
      emit(state.copyWith(
        session: _repository.session,
        phase: ScanPhase.result,
      ));
    } catch (_) {
      emit(state.copyWith(
        phase: ScanPhase.interviewing,
        errorMessage: 'Gagal membuat diagnosa. Coba lagi.',
      ));
    }
  }

  void resetFlow() {
    _repository.reset();
    _msgCounter = 0;
    emit(const ScanState());
  }
}
