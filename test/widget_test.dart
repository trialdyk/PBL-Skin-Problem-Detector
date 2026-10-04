import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_skin_problem_detector/main.dart';

void main() {
  testWidgets('Splash screen renders', (tester) async {
    await tester.pumpWidget(const SkinProblemDetectorApp());
    await tester.pump();

    expect(find.textContaining('Skin Problem Detector'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.textContaining('Scan, Analisis'), findsOneWidget);
  });
}
