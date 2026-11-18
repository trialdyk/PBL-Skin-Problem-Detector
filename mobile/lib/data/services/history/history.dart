/// History API services — import barrel ini dari app.
///
/// ```dart
/// import 'package:pbl_skin_problem_detector/data/services/history/history.dart';
///
/// final history = HistoryService(auth.api);
/// await history.list();
/// ```
library;

export 'history_create.dart';
export 'history_delete.dart';
export 'history_detail.dart';
export 'history_exception.dart';
export 'history_list.dart';
export 'history_retry_recommendation.dart';
export 'history_service.dart';
