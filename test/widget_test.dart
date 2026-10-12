import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_skin_problem_detector/main.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/welcome_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_theme.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Widget _welcomeApp() =>
    ShadcnApp(theme: AppTheme.light, home: const WelcomeScreen());

void main() {
  testWidgets('Splash screen renders lalu menuju welcome', (tester) async {
    await tester.pumpWidget(const SkinProblemDetectorApp());
    await tester.pump();

    expect(find.textContaining('Skin Problem Detector'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.text('Mulai Sekarang'), findsOneWidget);
  });

  testWidgets('Welcome muat tanpa overflow di berbagai ukuran layar', (
    tester,
  ) async {
    const sizes = [
      Size(320, 480), // sangat pendek
      Size(320, 568), // layar kecil (mis. iPhone SE)
      Size(360, 640), // Android compact
      Size(390, 844), // iPhone 14
      Size(412, 915), // Pixel 7
      Size(640, 360), // landscape
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_welcomeApp());
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Terjadi overflow pada ukuran ${size.width}x${size.height}',
      );
      expect(
        find.text('Mulai Sekarang'),
        findsOneWidget,
        reason: 'Tombol CTA harus tetap terlihat pada ${size.height}px',
      );
    }
  });

  testWidgets('Welcome tidak scrollable', (tester) async {
    await tester.pumpWidget(_welcomeApp());
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(WelcomeScreen),
        matching: find.byType(Scrollable),
      ),
      findsNothing,
    );
    expect(find.byType(SingleChildScrollView), findsNothing);
  });
}
