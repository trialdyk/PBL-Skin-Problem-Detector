import 'package:pbl_skin_problem_detector/data/models/history_item.dart';
import 'package:pbl_skin_problem_detector/data/services/api_client.dart';
import 'package:pbl_skin_problem_detector/data/services/history/history_create.dart';
import 'package:pbl_skin_problem_detector/data/services/history/history_delete.dart';
import 'package:pbl_skin_problem_detector/data/services/history/history_detail.dart';
import 'package:pbl_skin_problem_detector/data/services/history/history_list.dart';

/// Facade endpoint `/history`.
class HistoryService {
  HistoryService(this.api)
      : _create = HistoryCreate(api),
        _list = HistoryList(api),
        _detail = HistoryDetail(api),
        _delete = HistoryDelete(api);

  final ApiClient api;
  final HistoryCreate _create;
  final HistoryList _list;
  final HistoryDetail _detail;
  final HistoryDelete _delete;

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
  }) {
    return _create(
      frontPath: frontPath,
      leftPath: leftPath,
      rightPath: rightPath,
      grade: grade,
      gradeLabel: gradeLabel,
      modelId: modelId,
      resultSource: resultSource,
      interview: interview,
      topLabel: topLabel,
      aggregate: aggregate,
    );
  }

  Future<HistoryListResult> list({int limit = 50, int offset = 0}) {
    return _list(limit: limit, offset: offset);
  }

  Future<HistoryItem> detail(String id) => _detail(id);

  Future<void> delete(String id) => _delete(id);
}
