/// ML API services — import this barrel from the rest of the app.
///
/// ```dart
/// import 'package:pbl_skin_problem_detector/data/services/ml/ml.dart';
///
/// final ml = MlPredict(auth.api);
/// final prediction = await ml(['/path/front.jpg', '/path/left.jpg']);
/// print(prediction.grade); // 0–5 (GEA)
/// ```
library;

export 'ml_exception.dart';
export 'ml_prediction.dart';
export 'ml_predict.dart';
