import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/data/models/history_item.dart';
import 'package:pbl_skin_problem_detector/data/models/interview_answers.dart';
import 'package:pbl_skin_problem_detector/data/models/result_source.dart';
import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/data/repositories/scan_repository.dart';

class ScanCubit extends Cubit<ScanState> {
  ScanCubit(
    this._repository, {
    this.pollInterval = const Duration(seconds: 2),
    this.maxPollAttempts = 20,
  }) : super(const ScanState());

  final ScanRepository _repository;
  final Duration pollInterval;
  final int maxPollAttempts;
  int _msgCounter = 0;
  int _pollToken = 0;

  /// Tanda yaw saat foto sisi kiri diambil; dipakai untuk memvalidasi sisi
  /// kanan (harus berlawanan) walau foto diambil di layar kamera terpisah.
  int? leftYawSign;

  void startCapture() {
    emit(state.copyWith(
      phase: ScanPhase.capturing,
      currentAngle: SelfieAngle.front,
      clearError: true,
    ));
  }

  /// Mulai ambil satu sudut saja (dari layar hub Foto).
  void selectAngle(SelfieAngle angle) {
    emit(state.copyWith(
      phase: ScanPhase.capturing,
      currentAngle: angle,
      clearError: true,
    ));
  }

  /// Simpan satu foto tanpa auto-lanjut ke sudut berikutnya.
  void setSinglePhoto(SelfieAngle angle, String path) {
    _repository.setPhoto(angle, path);
    emit(state.copyWith(
      session: _repository.session,
      phase: ScanPhase.intro,
      currentAngle: angle,
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
    leftYawSign = null;
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
      'Jawaban ini membantu diagnosa IGA lebih akurat.',
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

  Future<void> answerUnhealthyFood(bool value, {String? customLabel}) async {
    final defaultLabel = value
        ? 'Sering konsumsi makanan pemicu (gorengan, manis, dll)'
        : 'Jarang konsumsi makanan pemicu';
    await _answer(
      key: 'food',
      label: customLabel ?? defaultLabel,
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
    final token = ++_pollToken;
    emit(state.copyWith(
      phase: ScanPhase.diagnosing,
      isLoadingRecommendation: _repository.hasHistoryService,
      historySaveFailed: false,
      clearError: true,
    ));
    try {
      final result = await _repository.diagnose();
      emit(state.copyWith(
        session: _repository.session,
        phase: ScanPhase.result,
      ));

      // Foto ada tapi hasilnya rule-based = CNN gagal; beri tahu pengguna
      // supaya hasil tidak disangka berasal dari analisis foto.
      if (result.source == ResultSource.ruleBased &&
          _repository.session.photoPaths.isNotEmpty) {
        await _pushBot(
          'Analisis foto sedang tidak tersedia, jadi hasil ini memakai '
          'jawaban interview Anda.',
        );
      }

      if (!_repository.hasHistoryService ||
          !_repository.session.hasAllPhotos) {
        if (!isClosed && token == _pollToken) {
          emit(state.copyWith(isLoadingRecommendation: false));
        }
        return;
      }

      // One-shot persist ke server (tidak memblokir layar hasil).
      try {
        final saved = await _repository.persistHistory();
        if (isClosed || token != _pollToken) return;

        emit(state.copyWith(
          session: _repository.session,
          historySaveFailed: saved == null,
          isLoadingRecommendation:
              saved != null &&
              saved.recommendation.status == RecommendationStatus.pending,
        ));

        if (saved != null &&
            saved.recommendation.status == RecommendationStatus.pending) {
          unawaited(_pollRecommendation(saved.id, token));
        }
      } catch (error) {
        debugPrint('Gagal menyimpan riwayat: $error');
        if (!isClosed && token == _pollToken) {
          emit(state.copyWith(
            isLoadingRecommendation: false,
            historySaveFailed: true,
          ));
        }
      }
    } catch (_) {
      emit(state.copyWith(
        phase: ScanPhase.interviewing,
        isLoadingRecommendation: false,
        errorMessage: 'Gagal membuat diagnosa. Coba lagi.',
      ));
    }
  }

  /// Polling singkat ke `GET /history/{id}` sampai rekomendasi LLM siap/gagal.
  Future<void> _pollRecommendation(String historyId, int token) async {
    for (var attempt = 0; attempt < maxPollAttempts; attempt++) {
      await Future<void>.delayed(pollInterval);
      if (isClosed || token != _pollToken) return;

      try {
        final rec = await _repository.refreshRecommendation(historyId);
        if (isClosed || token != _pollToken) return;

        if (rec == null || rec.status != RecommendationStatus.pending) {
          emit(state.copyWith(
            session: _repository.session,
            isLoadingRecommendation: false,
          ));
          return;
        }
        emit(state.copyWith(session: _repository.session));
      } catch (error) {
        debugPrint('Polling rekomendasi gagal (percobaan ${attempt + 1}): $error');
      }
    }

    if (!isClosed && token == _pollToken) {
      emit(state.copyWith(isLoadingRecommendation: false));
    }
  }

  /// Cek ulang status rekomendasi untuk sesi saat ini.
  Future<void> refreshRecommendation() async {
    final historyId = state.historyId;
    if (historyId == null) return;
    final token = ++_pollToken;
    emit(state.copyWith(isLoadingRecommendation: true));
    try {
      final rec = await _repository.refreshRecommendation(historyId);
      if (isClosed || token != _pollToken) return;
      emit(state.copyWith(
        session: _repository.session,
        isLoadingRecommendation:
            rec?.status == RecommendationStatus.pending,
      ));
      if (rec?.status == RecommendationStatus.pending) {
        unawaited(_pollRecommendation(historyId, token));
      }
    } catch (_) {
      if (!isClosed && token == _pollToken) {
        emit(state.copyWith(isLoadingRecommendation: false));
      }
    }
  }

  /// Minta ulang generasi rekomendasi LLM jika sebelumnya gagal/terhenti.
  Future<String?> retryRecommendation() async {
    final historyId = state.historyId;
    if (historyId == null) return 'Riwayat belum tersimpan.';
    final token = ++_pollToken;
    emit(state.copyWith(isLoadingRecommendation: true));
    try {
      final rec = await _repository.retryRecommendation(historyId);
      if (isClosed || token != _pollToken) return null;
      final stillPending = rec?.status == RecommendationStatus.pending;
      emit(state.copyWith(
        session: _repository.session,
        isLoadingRecommendation: stillPending,
      ));
      if (stillPending) {
        unawaited(_pollRecommendation(historyId, token));
      }
      return null;
    } catch (error) {
      if (!isClosed && token == _pollToken) {
        emit(state.copyWith(isLoadingRecommendation: false));
      }
      return error.toString();
    }
  }

  void resetFlow() {
    _pollToken++;
    _repository.reset();
    leftYawSign = null;
    _msgCounter = 0;
    emit(const ScanState());
  }

  @override
  Future<void> close() {
    _pollToken++;
    return super.close();
  }
}
