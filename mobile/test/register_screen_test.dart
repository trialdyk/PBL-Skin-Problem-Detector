import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth.dart';
import 'package:pbl_skin_problem_detector/main.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Future<void> openRegister(WidgetTester tester) async {
  await tester.pumpWidget(const SkinProblemDetectorApp());
  await tester.pump();
  await tester.tap(find.text('Mulai'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text('Daftar Sekarang'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Daftar Sekarang'));
  await tester.pumpAndSettle();
  expect(find.text('Buat Akun Anda'), findsOneWidget);
}

Future<void> submit(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Daftar Akun'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Daftar Akun'));
  await tester.pump();
}

Future<void> fill(WidgetTester tester, String id, String value) async {
  final field = find.byKey(ValueKey('register-$id'));
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
}

void main() {
  setUp(() => AuthService.mockRemoteAuth = true);
  tearDown(() => AuthService.mockRemoteAuth = false);

  testWidgets('form kosong menampilkan validasi tanpa mengirim registrasi', (
    tester,
  ) async {
    await openRegister(tester);
    await submit(tester);
    expect(find.text('Nama lengkap tidak boleh kosong'), findsOneWidget);
    expect(find.text('Email tidak boleh kosong'), findsOneWidget);
    expect(find.text('Kata sandi harus 8–128 karakter'), findsOneWidget);
    expect(
      find.text('Setujui syarat dan kebijakan privasi untuk mendaftar'),
      findsOneWidget,
    );
    expect(find.byType(Alert), findsNothing);
  });

  testWidgets('konfirmasi berbeda mencegah pendaftaran', (tester) async {
    await openRegister(tester);
    await fill(tester, 'name', 'Budi Santoso');
    await fill(tester, 'email', 'budi@gmail.com');
    await fill(tester, 'password', 'rahasia123');
    await fill(tester, 'confirmation', 'berbeda123');
    await submit(tester);
    expect(find.text('Konfirmasi kata sandi tidak cocok'), findsOneWidget);
  });

  testWidgets('registrasi berhasil membuka beranda', (tester) async {
    await openRegister(tester);
    await fill(tester, 'name', 'Budi Santoso');
    await fill(tester, 'email', 'budi@gmail.com');
    await fill(tester, 'password', 'rahasia123');
    await fill(tester, 'confirmation', 'rahasia123');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await submit(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Mari rawat kulitmu hari ini'), findsOneWidget);
  });

  testWidgets('tautan kebijakan mempertahankan isian dan kembali ke login', (
    tester,
  ) async {
    await openRegister(tester);
    await fill(tester, 'name', 'Budi');
    await tester.ensureVisible(find.text('Kebijakan Privasi'));
    await tester.tap(find.text('Kebijakan Privasi'));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.text('Kebijakan Privasi').first)).pop();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('register-name')))
          .controller!
          .text,
      'Budi',
    );
    await tester.ensureVisible(find.text('Masuk Sekarang'));
    await tester.tap(find.text('Masuk Sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
  });

  testWidgets('layar kecil dan keyboard tetap dapat menjangkau tombol', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await openRegister(tester);
    tester.view.viewInsets = const FakeViewPadding(bottom: 200);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.ensureVisible(find.text('Daftar Akun'));
    expect(find.text('Daftar Akun').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
