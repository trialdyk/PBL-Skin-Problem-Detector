import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_skin_problem_detector/data/services/auth/auth.dart';
import 'package:pbl_skin_problem_detector/data/services/user/user.dart';
import 'package:pbl_skin_problem_detector/main.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Future<void> _loginToProfile(WidgetTester tester) async {
  await tester.pumpWidget(const SkinProblemDetectorApp());
  await tester.pump();

  await tester.tap(find.text('Mulai'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byType(TextField).first, AuthService.demoEmail);
  await tester.enterText(find.byType(TextField).last, AuthService.demoPassword);
  await tester.tap(find.text('Masuk ke Akun'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Profil'));
  await tester.pumpAndSettle();
  expect(find.text('Edit profil'), findsOneWidget);
}

void main() {
  setUp(() {
    AuthService.mockRemoteAuth = true;
    UserService.mockRemoteUser = true;
  });
  tearDown(() {
    AuthService.mockRemoteAuth = false;
    UserService.mockRemoteUser = false;
  });

  testWidgets('ProfileScreen fokus pada edit nama, email, dan kata sandi', (
    tester,
  ) async {
    await _loginToProfile(tester);

    expect(find.text('Kelola langganan'), findsNothing);
    expect(find.text('Pulihkan pembelian'), findsNothing);
    expect(find.text('PRO'), findsNothing);
    expect(find.text('Preferensi'), findsNothing);
    expect(find.text('Pengaturan aplikasi'), findsNothing);
    expect(find.text('Privasi & keamanan'), findsNothing);
    expect(find.text('Notifikasi'), findsNothing);
    expect(find.text('Bahasa'), findsNothing);

    expect(find.text('Edit nama & email'), findsOneWidget);
    expect(find.text('Ubah kata sandi'), findsOneWidget);
  });

  testWidgets('EditProfileScreen memvalidasi dan menyimpan nama serta email', (
    tester,
  ) async {
    await _loginToProfile(tester);

    await tester.tap(find.text('Edit nama & email'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profil'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-name')),
      '   ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-email')),
      'bukan-email',
    );
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();

    expect(find.text('Nama lengkap tidak boleh kosong'), findsOneWidget);
    expect(find.text('Format email tidak valid'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-name')),
      'Budi Santoso',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-profile-email')),
      'Budi@Example.com',
    );
    await tester.ensureVisible(find.text('Simpan Perubahan'));
    await tester.tap(find.text('Simpan Perubahan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Edit profil'), findsOneWidget);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('budi@example.com'), findsOneWidget);
    expect(find.text('BU'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.house));
    await tester.pumpAndSettle();
    expect(find.text('Halo, Budi Santoso'), findsOneWidget);
  });

  testWidgets('ChangePasswordScreen memvalidasi dan menyimpan kata sandi baru', (
    tester,
  ) async {
    await _loginToProfile(tester);

    await tester.tap(find.text('Ubah kata sandi'));
    await tester.pumpAndSettle();

    expect(find.text('Ubah Kata Sandi'), findsOneWidget);

    await tester.ensureVisible(find.text('Simpan Kata Sandi'));
    await tester.tap(find.text('Simpan Kata Sandi'));
    await tester.pump();

    expect(find.text('Kata sandi saat ini tidak boleh kosong'), findsOneWidget);
    expect(find.text('Kata sandi baru harus 8–128 karakter'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi tidak boleh kosong'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('change-password-current')),
      'skinscan123',
    );
    await tester.enterText(
      find.byKey(const ValueKey('change-password-new')),
      'baru12345',
    );
    await tester.enterText(
      find.byKey(const ValueKey('change-password-confirm')),
      'beda12345',
    );
    await tester.ensureVisible(find.text('Simpan Kata Sandi'));
    await tester.tap(find.text('Simpan Kata Sandi'));
    await tester.pump();

    expect(find.text('Konfirmasi kata sandi tidak cocok'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('change-password-confirm')),
      'baru12345',
    );
    await tester.ensureVisible(find.text('Simpan Kata Sandi'));
    await tester.tap(find.text('Simpan Kata Sandi'));
    await tester.pumpAndSettle();

    expect(find.text('Edit profil'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });
}
