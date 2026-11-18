import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/frequency_slider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  Widget buildTestableWidget({
    int initialIndex = 2,
    required void Function(FrequencyOptionItem) onConfirm,
  }) {
    return ShadcnApp(
      home: Scaffold(
        child: FrequencySlider(
          initialIndex: initialIndex,
          onConfirm: onConfirm,
        ),
      ),
    );
  }

  testWidgets('FrequencySlider renders all 5 labels and default selection', (tester) async {
    FrequencyOptionItem? selected;
    await tester.pumpWidget(buildTestableWidget(
      initialIndex: 2,
      onConfirm: (opt) => selected = opt,
    ));
    await tester.pumpAndSettle();

    // Check labels exist
    expect(find.text('Tidak\nPernah'), findsOneWidget);
    expect(find.text('Jarang'), findsOneWidget);
    expect(find.text('Kadang'), findsNWidgets(2)); // in badge and in slider label
    expect(find.text('Sering'), findsOneWidget);
    expect(find.text('Sangat\nSering'), findsOneWidget);
    expect(find.text('Konfirmasi (Kadang)'), findsOneWidget);

    // Tap confirm
    await tester.tap(find.text('Konfirmasi (Kadang)'));
    await tester.pumpAndSettle();
    expect(selected?.label, 'Kadang');
    expect(selected?.isOften, false);
  });

  testWidgets('FrequencySlider tapping another option updates selection', (tester) async {
    FrequencyOptionItem? selected;
    await tester.pumpWidget(buildTestableWidget(
      initialIndex: 0,
      onConfirm: (opt) => selected = opt,
    ));
    await tester.pumpAndSettle();

    // Tap 'Sering'
    await tester.tap(find.text('Sering'));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi (Sering)'), findsOneWidget);

    await tester.tap(find.text('Konfirmasi (Sering)'));
    await tester.pumpAndSettle();
    expect(selected?.label, 'Sering');
    expect(selected?.isOften, true);
  });
}

