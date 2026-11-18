import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/data/models/history_item.dart';
import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/data/repositories/scan_repository.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/gea_diagnosis_service.dart';
import 'package:pbl_skin_problem_detector/data/services/history/history.dart';
import 'package:pbl_skin_problem_detector/data/services/ml/ml.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/diagnosis_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_theme.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

const _tinyPng = <int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0x0F, 0x00, 0x00,
  0x01, 0x01, 0x00, 0x05, 0x18, 0xD8, 0x4E, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

class _FakeMlPredictor implements MlPredictor {
  _FakeMlPredictor({this.grade = 2});

  final int grade;

  @override
  Future<MlPrediction> call(List<String> photoPaths) async {
    return MlPrediction(grade: grade, topLabel: 'IGA$grade', model: 'cnn-v1');
  }
}

class _FakeHistoryService extends HistoryService {
  _FakeHistoryService({
    required this.detailResponses,
    this.createError,
  }) : super(ApiClient());

  final List<HistoryItem> detailResponses;
  final Object? createError;

  int detailCalls = 0;
  int retryCalls = 0;

  @override
  Future<HistoryItem> create({
    required String frontPath,
    required String leftPath,
    required String rightPath,
    required int grade,
    required String gradeLabel,
    required String modelId,
    required String resultSource,
    required Map<String, Object?> interview,
    String? topLabel,
    Map<String, Object?>? aggregate,
  }) async {
    final err = createError;
    if (err != null) throw err;
    return _historyItem(status: RecommendationStatus.pending);
  }

  @override
  Future<HistoryItem> detail(String id) async {
    final index = detailCalls < detailResponses.length
        ? detailCalls
        : detailResponses.length - 1;
    detailCalls++;
    return detailResponses[index];
  }

  @override
  Future<HistoryItem> retryRecommendation(String id) async {
    retryCalls++;
    return _historyItem(status: RecommendationStatus.pending);
  }
}

HistoryItem _historyItem({
  required RecommendationStatus status,
  String? text,
}) {
  return HistoryItem(
    id: 'hist-1',
    createdAt: DateTime(2026, 11, 18, 14),
    modelId: 'cnn-v1',
    grade: 2,
    gradeLabel: 'Ringan',
    resultSource: 'ml',
    recommendation: HistoryRecommendation(status: status, text: text),
    photos: const HistoryPhotos(
      front: '/history/hist-1/photos/front',
      left: '/history/hist-1/photos/left',
      right: '/history/hist-1/photos/right',
    ),
  );
}

ScanRepository _buildRepo({
  HistoryService? historyService,
  String frontPath = '/tmp/front.jpg',
}) {
  final repo = ScanRepository(
    GeaDiagnosisService(),
    mlPredict: _FakeMlPredictor(grade: 2),
    historyService: historyService,
  );
  repo.setPhoto(SelfieAngle.front, frontPath);
  repo.setPhoto(SelfieAngle.left, frontPath);
  repo.setPhoto(SelfieAngle.right, frontPath);
  return repo;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('ScanCubit polling menunggu status pending sampai ready', () async {
    final history = _FakeHistoryService(
      detailResponses: [
        _historyItem(status: RecommendationStatus.pending),
        _historyItem(
          status: RecommendationStatus.ready,
          text:
              '### Ringkasan Kondisi\n- Pakai cleanser lembut\n- **Wajib** sunscreen',
        ),
      ],
    );
    final cubit = ScanCubit(
      _buildRepo(historyService: history),
      pollInterval: const Duration(milliseconds: 5),
      maxPollAttempts: 5,
    );
    addTearDown(cubit.close);

    await cubit.skipInterview();
    expect(cubit.state.phase, ScanPhase.result);
    expect(cubit.state.result?.grade, 2);

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(history.detailCalls, 2);
    expect(cubit.state.isLoadingRecommendation, isFalse);
    expect(cubit.state.recommendation?.status, RecommendationStatus.ready);
    expect(cubit.state.recommendation?.text, contains('Pakai cleanser lembut'));
  });

  test('ScanCubit menangani error persistHistory tanpa stuck loading', () async {
    final history = _FakeHistoryService(
      detailResponses: const [],
      createError: HistoryException('offline'),
    );
    final cubit = ScanCubit(
      _buildRepo(historyService: history),
      pollInterval: const Duration(milliseconds: 5),
    );
    addTearDown(cubit.close);

    await cubit.skipInterview();

    expect(cubit.state.phase, ScanPhase.result);
    expect(cubit.state.result?.grade, 2);
    expect(cubit.state.historySaveFailed, isTrue);
    expect(cubit.state.isLoadingRecommendation, isFalse);
  });

  test('ScanCubit retryRecommendation meminta ulang saat status failed', () async {
    final history = _FakeHistoryService(
      detailResponses: [
        _historyItem(status: RecommendationStatus.failed),
        _historyItem(
          status: RecommendationStatus.ready,
          text: 'Rekomendasi baru dari LLM.',
        ),
      ],
    );
    final cubit = ScanCubit(
      _buildRepo(historyService: history),
      pollInterval: const Duration(milliseconds: 5),
      maxPollAttempts: 3,
    );
    addTearDown(cubit.close);

    await cubit.skipInterview();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(cubit.state.recommendation?.status, RecommendationStatus.failed);

    final err = await cubit.retryRecommendation();
    expect(err, isNull);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(history.retryCalls, 1);
    expect(cubit.state.recommendation?.status, RecommendationStatus.ready);
    expect(cubit.state.recommendation?.text, 'Rekomendasi baru dari LLM.');
  });

  testWidgets('DiagnosisScreen menampilkan tingkat IGA dan rekomendasi LLM', (
    tester,
  ) async {
    late Directory tempDir;
    late File photoFile;
    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('dermascan_test_');
      photoFile = File('${tempDir.path}/front.png');
      await photoFile.writeAsBytes(_tinyPng);
    });
    addTearDown(() async {
      PaintingBinding.instance.imageCache.clear();
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    final history = _FakeHistoryService(
      detailResponses: [
        _historyItem(
          status: RecommendationStatus.ready,
          text: '### 1. Ringkasan Kondisi\n- Jerawat ringan terdeteksi.',
        ),
      ],
    );
    final cubit = ScanCubit(
      _buildRepo(historyService: history, frontPath: photoFile.path),
      pollInterval: const Duration(milliseconds: 5),
      maxPollAttempts: 3,
    );
    addTearDown(cubit.close);

    await tester.runAsync(() async {
      await cubit.skipInterview();
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });

    await tester.pumpWidget(
      BlocProvider<ScanCubit>.value(
        value: cubit,
        child: ShadcnApp(
          theme: AppTheme.light,
          home: const DiagnosisScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tingkat IGA Anda'), findsOneWidget);
    expect(find.text('Ringan'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Rekomendasi perawatan'), findsOneWidget);
    expect(find.text('1. Ringkasan Kondisi'), findsOneWidget);
    expect(find.textContaining('Jerawat ringan terdeteksi.'), findsOneWidget);
  });

  testWidgets('DiagnosisScreen menampilkan tombol Coba lagi saat rekomendasi gagal', (
    tester,
  ) async {
    late Directory tempDir;
    late File photoFile;
    await tester.runAsync(() async {
      tempDir = await Directory.systemTemp.createTemp('dermascan_retry_');
      photoFile = File('${tempDir.path}/front.png');
      await photoFile.writeAsBytes(_tinyPng);
    });
    addTearDown(() async {
      PaintingBinding.instance.imageCache.clear();
      try {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    });

    final history = _FakeHistoryService(
      detailResponses: [
        _historyItem(status: RecommendationStatus.failed),
        _historyItem(
          status: RecommendationStatus.ready,
          text: 'Rekomendasi setelah retry berhasil.',
        ),
      ],
    );
    final cubit = ScanCubit(
      _buildRepo(historyService: history, frontPath: photoFile.path),
      pollInterval: const Duration(milliseconds: 5),
      maxPollAttempts: 3,
    );
    addTearDown(cubit.close);

    await tester.runAsync(() async {
      await cubit.skipInterview();
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });

    await tester.pumpWidget(
      BlocProvider<ScanCubit>.value(
        value: cubit,
        child: ShadcnApp(
          theme: AppTheme.light,
          home: const DiagnosisScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.drag(find.byType(ListView), const Offset(0, -450));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Coba lagi'), findsOneWidget);

    await tester.ensureVisible(find.text('Coba lagi'));
    await tester.pump();
    await tester.runAsync(() async {
      await tester.tap(find.text('Coba lagi'));
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(history.retryCalls, 1);
    expect(find.text('Rekomendasi setelah retry berhasil.'), findsOneWidget);
  });
}
