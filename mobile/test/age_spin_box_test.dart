import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/age_spin_box.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  Widget buildTestableWidget({
    int initialValue = 20,
    int min = 10,
    int max = 100,
    required ValueChanged<int> onConfirm,
  }) {
    return ShadcnApp(
      home: Scaffold(
        child: AgeSpinBox(
          initialValue: initialValue,
          min: min,
          max: max,
          onConfirm: onConfirm,
        ),
      ),
    );
  }

  testWidgets('AgeSpinBox displays initial age', (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      initialValue: 25,
      onConfirm: (_) {},
    ));
    await tester.pumpAndSettle();

    expect(find.text('25'), findsOneWidget);
    expect(find.text('Konfirmasi (25 tahun)'), findsOneWidget);
  });

  testWidgets('AgeSpinBox increment and decrement buttons work', (tester) async {
    int? confirmedAge;
    await tester.pumpWidget(buildTestableWidget(
      initialValue: 20,
      min: 18,
      max: 22,
      onConfirm: (age) => confirmedAge = age,
    ));
    await tester.pumpAndSettle();

    // Tap plus
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
    expect(find.text('21'), findsOneWidget);
    expect(find.text('Konfirmasi (21 tahun)'), findsOneWidget);

    // Tap minus
    await tester.tap(find.byIcon(LucideIcons.minus));
    await tester.pumpAndSettle();
    expect(find.text('20'), findsOneWidget);

    // Confirm
    await tester.tap(find.text('Konfirmasi (20 tahun)'));
    await tester.pumpAndSettle();
    expect(confirmedAge, 20);
  });

  testWidgets('AgeSpinBox respects min and max limits', (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      initialValue: 10,
      min: 10,
      max: 12,
      onConfirm: (_) {},
    ));
    await tester.pumpAndSettle();

    // Trying to decrement below min
    await tester.tap(find.byIcon(LucideIcons.minus));
    await tester.pumpAndSettle();
    expect(find.text('10'), findsOneWidget);

    // Increment up to max
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
    expect(find.text('11'), findsOneWidget);

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);

    // Increment beyond max
    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
  });
}

