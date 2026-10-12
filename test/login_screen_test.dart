import 'package:flutter_test/flutter_test.dart';
import 'package:pbl_skin_problem_detector/main.dart';
import 'package:pbl_skin_problem_detector/presentation/screens/login_screen.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_theme.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Rasio kontras WCAG 2.x antara dua warna (1:1 … 21:1).
double _contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Menjalankan aplikasi asli (Splash → Welcome → Login) agar `AuthCubit`
/// dan router ikut teruji seperti di produksi.
Future<void> _openLogin(WidgetTester tester) async {
  await tester.pumpWidget(const SkinProblemDetectorApp());
  await tester.pump(const Duration(milliseconds: 1900));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Mulai Sekarang'));
  await tester.pumpAndSettle();

  expect(find.text('Masuk ke Akun Anda'), findsOneWidget);
}

Finder get _emailField => find.byType(TextField).first;
Finder get _passwordField => find.byType(TextField).last;

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.tap(find.text('Masuk ke Akun'));
  await tester.pump();
}

/// Menunggu jeda mock `AuthService` (400 ms) selesai.
Future<void> _settleLogin(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle();
}

/// Skala efektif teks = pemadatan dinamis (`LayoutBuilder`) × pengecilan
/// `FittedBox`. Lebar label tombol ikut ter-transform, jadi rasionya terhadap
/// lebar pada skala desain penuh adalah skala efektifnya.
double _effectiveScale(WidgetTester tester, double baseLabelWidth) =>
    tester.getRect(find.text('Masuk ke Akun')).width / baseLabelWidth;

/// Skala efektif minimum agar teks masih nyaman dibaca — sejalan dengan
/// `_minScale` di `login_screen.dart`.
const double _readableScale = 0.85;

/// Sisi bawah widget pada layar — `getRect()` ikut menerapkan transform
/// `FittedBox`, jadi nilainya mencerminkan posisi akhir yang terlihat.
double _bottomOf(WidgetTester tester, Finder finder) =>
    tester.getRect(finder).bottom;

/// Kotak viewport scroll halaman login.
Rect _loginViewport(WidgetTester tester) =>
    tester.getRect(find.byType(SingleChildScrollView));

/// `ScrollPosition` milik scroll view halaman login — bukan scroll internal
/// `TextField`, yang juga memakai `Scrollable`.
ScrollPosition _loginScrollPosition(WidgetTester tester) {
  return tester
      .state<ScrollableState>(
        find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Scrollable),
            )
            .first,
      )
      .position;
}

/// Elemen terbawah halaman login (paling gampang terpotong).
Finder get _bottomMostElement => find.text('Daftar Sekarang');

/// Mengatur ukuran layar lalu membuka halaman login.
Future<void> _resizeAndOpenLogin(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  // Tree dikosongkan dulu supaya router kembali ke /splash tiap iterasi.
  await tester.pumpWidget(const SizedBox());
  await _openLogin(tester);
}

/// Lebar label tombol pada skala desain penuh (layar tinggi) — acuan
/// `_effectiveScale`.
Future<double> _baseLabelWidth(WidgetTester tester) async {
  await _resizeAndOpenLogin(tester, const Size(412, 915));
  return tester.getRect(find.text('Masuk ke Akun')).width;
}

/// Memastikan seluruh konten login benar-benar terjangkau dan tetap terbaca.
///
/// Mode "fit" (`NeverScrollableScrollPhysics`): konten **wajib muat** — tidak
/// boleh ada sisa jangkauan geser dan elemen terbawah harus di dalam viewport.
/// Mode "scroll" (`ClampingScrollPhysics`): konten boleh lebih tinggi, tetapi
/// harus benar-benar bisa digeser sampai elemen terbawah.
///
/// Pemeriksaan ini menangkap konten yang ter-*clip*: `SingleChildScrollView`
/// memotong tanpa melempar overflow error, dan widget ter-*clip* tetap
/// ditemukan `find.text(...)`, sehingga `takeException()`/`findsOneWidget`
/// saja tidak cukup.
Future<void> _expectLoginContentReachable(
  WidgetTester tester,
  String reason,
) async {
  final viewport = _loginViewport(tester);
  final physics = tester
      .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
      .physics;
  final position = _loginScrollPosition(tester);

  if (physics is NeverScrollableScrollPhysics) {
    expect(
      position.maxScrollExtent,
      0,
      reason: 'Mode fit harus benar-benar muat (tidak ada sisa geser): $reason',
    );
  } else if (position.maxScrollExtent > 0) {
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
  }

  expect(
    _bottomOf(tester, _bottomMostElement),
    lessThanOrEqualTo(viewport.bottom + 0.5),
    reason: 'Elemen terbawah terpotong: $reason',
  );
}

/// Memastikan teks tidak mengecil melewati batas terbaca.
void _expectReadableScale(
  WidgetTester tester,
  double baseLabelWidth,
  String reason,
) {
  final scale = _effectiveScale(tester, baseLabelWidth);
  expect(
    scale,
    greaterThanOrEqualTo(_readableScale - 0.01),
    reason:
        'Skala efektif ${scale.toStringAsFixed(3)} di bawah batas terbaca '
        '$_readableScale: $reason',
  );
}

void main() {
  testWidgets('Email & kata sandi kosong → bubble inline, bukan panel', (
    tester,
  ) async {
    await _openLogin(tester);
    await _tapSubmit(tester);

    expect(find.text('Email tidak boleh kosong'), findsOneWidget);
    expect(find.text('Kata sandi tidak boleh kosong'), findsOneWidget);
    expect(
      find.byType(Alert),
      findsNothing,
      reason: 'Validasi field tidak boleh memunculkan panel kredensial',
    );
  });

  testWidgets('Teks bubble galat terlihat (bukan merah di atas merah)', (
    tester,
  ) async {
    await _openLogin(tester);
    await _tapSubmit(tester);

    const message = 'Email tidak boleh kosong';
    expect(find.text(message), findsOneWidget);

    final danger = AppTheme.brandLightScheme.destructive;
    final surface = AppColors.dangerSurface(danger);
    final ink = AppColors.dangerInk(danger);

    final rendered = tester.widget<Text>(find.text(message)).style!.color;
    expect(
      rendered,
      ink,
      reason: 'Teks bubble harus memakai warna tinta, bukan warna destructive',
    );
    expect(
      rendered,
      isNot(danger),
      reason:
          'Teks tidak boleh sewarna dengan latar bubble (jadi tak terlihat)',
    );
    expect(
      _contrastRatio(ink, surface),
      greaterThanOrEqualTo(4.5),
      reason: 'Kontras teks terhadap latar bubble minimal 4,5:1 (WCAG AA)',
    );
  });

  testWidgets('Format email salah → bubble format, bukan panel', (
    tester,
  ) async {
    await _openLogin(tester);
    await tester.enterText(_emailField, 'abc');
    await tester.enterText(_passwordField, 'rahasia');
    await _tapSubmit(tester);

    expect(find.text('Format email tidak valid'), findsOneWidget);
    expect(find.text('Email tidak boleh kosong'), findsNothing);
    expect(find.byType(Alert), findsNothing);
  });

  testWidgets('Bubble muncul langsung begitu field ditinggalkan', (
    tester,
  ) async {
    await _openLogin(tester);

    await tester.enterText(_emailField, 'abc');
    await tester.pump();
    expect(
      find.text('Format email tidak valid'),
      findsNothing,
      reason: 'Belum blur → belum boleh menampilkan galat',
    );

    // Memindahkan fokus ke field kata sandi membuat field email blur.
    await tester.tap(_passwordField);
    await tester.pump();
    expect(find.text('Format email tidak valid'), findsOneWidget);
  });

  testWidgets('Kata sandi salah → panel merah di antara judul dan card', (
    tester,
  ) async {
    await _openLogin(tester);
    await tester.enterText(_emailField, 'pengguna@gmail.com');
    await tester.enterText(_passwordField, 'salahbanget');
    await _tapSubmit(tester);
    await _settleLogin(tester);

    expect(
      find.text('Email atau kata sandi salah. Periksa kembali.'),
      findsOneWidget,
    );
    expect(find.byType(Alert), findsOneWidget);
    expect(
      find.text('Format email tidak valid'),
      findsNothing,
      reason: 'Field valid → tidak boleh ada bubble',
    );

    final alertTop = tester.getTopLeft(find.byType(Alert)).dy;
    final titleTop = tester.getTopLeft(find.text('Masuk ke Akun Anda')).dy;
    final cardTop = tester.getTopLeft(find.text('Email')).dy;

    expect(alertTop, greaterThan(titleTop));
    expect(alertTop, lessThan(cardTop));
  });

  testWidgets('Panel galat hilang saat pengguna mengetik ulang', (
    tester,
  ) async {
    await _openLogin(tester);
    await tester.enterText(_emailField, 'pengguna@gmail.com');
    await tester.enterText(_passwordField, 'salahbanget');
    await _tapSubmit(tester);
    await _settleLogin(tester);
    expect(find.byType(Alert), findsOneWidget);

    await tester.enterText(_passwordField, 'skinscan12');
    await tester.pump();

    expect(find.byType(Alert), findsNothing);
  });

  testWidgets('Kredensial benar → masuk ke Beranda', (tester) async {
    await _openLogin(tester);
    await tester.enterText(_emailField, 'pengguna@gmail.com');
    await tester.enterText(_passwordField, 'skinscan123');
    await _tapSubmit(tester);
    await _settleLogin(tester);

    expect(find.text('Masuk ke Akun Anda'), findsNothing);
    expect(find.text('Mulai Analisis Kulit'), findsOneWidget);
  });

  testWidgets('Lanjutkan dengan Google tetap berhasil', (tester) async {
    await _openLogin(tester);

    await tester.tap(find.text('Lanjutkan dengan Google'));
    await tester.pump();
    await _settleLogin(tester);

    expect(find.text('Masuk ke Akun Anda'), findsNothing);
    expect(find.text('Mulai Analisis Kulit'), findsOneWidget);
  });

  testWidgets('Login terkunci saat idle di layar normal', (tester) async {
    // Layar tinggi: konten benar-benar muat, jadi tidak ada yang perlu digeser.
    await _resizeAndOpenLogin(tester, const Size(412, 915));

    final scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(
      scrollView.physics,
      isA<NeverScrollableScrollPhysics>(),
      reason: 'Saat keyboard tertutup, konten tidak boleh bisa digeser',
    );
    expect(
      _loginScrollPosition(tester).maxScrollExtent,
      0,
      reason: 'Di layar normal tidak boleh ada sisa tinggi yang bisa digeser',
    );
    expect(
      find.descendant(
        of: find.byType(LoginScreen),
        matching: find.byType(FittedBox),
      ),
      findsWidgets,
      reason: 'Pembatas tinggi dinamis (FittedBox) harus ada',
    );
  });

  testWidgets('Keyboard terbuka: layout tidak menyusut & scroll aktif', (
    tester,
  ) async {
    // Layar tinggi: idle terkunci, lalu keyboard membuatnya bisa digeser tanpa
    // mengubah skala konten.
    await _resizeAndOpenLogin(tester, const Size(412, 915));

    final idleLabel = tester.getRect(find.text('Masuk ke Akun')).width;

    // Mensimulasikan keyboard setinggi 300 dp.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();

    final keyboardLabel = tester.getRect(find.text('Masuk ke Akun')).width;

    expect(
      keyboardLabel,
      idleLabel,
      reason: 'Keyboard tidak boleh mengubah skala/posisi konten',
    );
    expect(
      tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .physics,
      isA<ClampingScrollPhysics>(),
      reason: 'Saat keyboard terbuka, konten harus bisa digeser',
    );
    expect(
      tester.takeException(),
      isNull,
      reason: 'Tidak boleh ada overflow saat keyboard terbuka',
    );
  });

  testWidgets('Bubble galat muncul tanpa membuat field kehilangan fokus', (
    tester,
  ) async {
    // Di 360×640 mode idle = fit, dan begitu bubble galat muncul mode berpindah
    // ke scroll. Perpindahan itu (termasuk penyisipan bubble ke dalam card)
    // tidak boleh sampai melepas fokus dari field yang sedang diisi — fokus
    // dipegang `FocusNode` milik `_LoginScreenState`.
    await _resizeAndOpenLogin(tester, const Size(360, 640));

    await tester.enterText(_emailField, 'abc');
    await tester.pump();

    expect(
      tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .physics,
      isA<NeverScrollableScrollPhysics>(),
      reason: 'Prasyarat: sebelum galat muncul, halaman dalam mode fit',
    );
    expect(
      tester.widget<TextField>(_emailField).focusNode?.hasFocus,
      isTrue,
      reason: 'Prasyarat: field email harus fokus sebelum submit',
    );

    // Mengisi format salah tidak menyentuh status loading, jadi tidak ada
    // field yang di-`disable` saat galat muncul.
    await _tapSubmit(tester);
    await tester.pump();

    expect(find.text('Format email tidak valid'), findsOneWidget);
    expect(
      tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .physics,
      isA<ClampingScrollPhysics>(),
      reason: 'Mode harus berpindah ke scroll saat bubble galat muncul',
    );
    expect(
      tester.widget<TextField>(_emailField).focusNode?.hasFocus,
      isTrue,
      reason: 'Fokus tidak boleh hilang saat bubble galat muncul',
    );
  });

  testWidgets('Login muat tanpa overflow di berbagai ukuran layar', (
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

    final base = await _baseLabelWidth(tester);

    for (final size in sizes) {
      await _resizeAndOpenLogin(tester, size);

      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow pada ukuran ${size.width}x${size.height}',
      );
      expect(
        find.text('Masuk ke Akun'),
        findsOneWidget,
        reason: 'Tombol submit harus tetap terlihat pada ${size.height}px',
      );
      // `takeException()` di atas tidak menangkap klip: scroll view memotong
      // konten tanpa melempar error, dan widget ter-klip tetap ditemukan
      // finder. Jadi posisi elemen terbawah dan skala teks diperiksa langsung.
      final reason = 'login idle pada ${size.width}x${size.height}';
      await _expectLoginContentReachable(tester, reason);
      _expectReadableScale(tester, base, reason);
    }
  });

  testWidgets('Login tetap muat saat panel galat kredensial muncul', (
    tester,
  ) async {
    for (final size in [const Size(320, 480), const Size(360, 640)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const SizedBox());
      await _openLogin(tester);
      await tester.enterText(_emailField, 'pengguna@gmail.com');
      await tester.enterText(_passwordField, 'salahbanget');
      await _tapSubmit(tester);
      await _settleLogin(tester);

      expect(find.byType(Alert), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow saat panel galat tampil pada ${size.height}px',
      );
    }
  });

  testWidgets('Konten login benar-benar mengecil di layar pendek', (
    tester,
  ) async {
    // getRect() ikut menerapkan transform FittedBox, jadi lebar yang
    // terukur mencerminkan hasil skala akhir.
    final tall = await _baseLabelWidth(tester);

    await _resizeAndOpenLogin(tester, const Size(320, 480));
    final short = tester.getRect(find.text('Masuk ke Akun')).width;

    expect(
      short,
      lessThan(tall),
      reason: 'Layar pendek harus memakai skala lebih kecil (pembatas dinamis)',
    );
  });

  testWidgets('Panel galat kredensial tidak memotong konten', (tester) async {
    final base = await _baseLabelWidth(tester);

    for (final size in [
      const Size(320, 568), // layar kecil: panel → mode scroll
      const Size(360, 640), // Android compact: panel → mode scroll
      const Size(412, 915), // Pixel 7: panel tetap muat (mode fit)
    ]) {
      await _resizeAndOpenLogin(tester, size);
      await tester.enterText(_emailField, 'pengguna@gmail.com');
      await tester.enterText(_passwordField, 'salahbanget');
      await _tapSubmit(tester);
      await _settleLogin(tester);

      expect(find.byType(Alert), findsOneWidget);

      final reason = 'panel galat pada ${size.width}x${size.height}';
      final viewport = _loginViewport(tester);
      expect(
        _bottomOf(tester, find.byType(Alert)),
        lessThanOrEqualTo(viewport.bottom + 0.5),
        reason: 'Panel galat terpotong: $reason',
      );
      await _expectLoginContentReachable(tester, reason);
      _expectReadableScale(tester, base, reason);
    }
  });

  testWidgets('Bubble galat field tidak memotong konten', (tester) async {
    final base = await _baseLabelWidth(tester);

    // Dua bubble sekaligus = penambahan tinggi terbesar dari validasi inline.
    for (final size in [const Size(320, 568), const Size(360, 640)]) {
      await _resizeAndOpenLogin(tester, size);
      await _tapSubmit(tester);

      expect(find.text('Email tidak boleh kosong'), findsOneWidget);
      expect(find.text('Kata sandi tidak boleh kosong'), findsOneWidget);

      final reason = 'dua bubble galat field pada ${size.width}x${size.height}';
      await _expectLoginContentReachable(tester, reason);
      _expectReadableScale(tester, base, reason);
    }
  });

  testWidgets('Layar sangat pendek: konten bisa digeser, teks tidak mengecil', (
    tester,
  ) async {
    final base = await _baseLabelWidth(tester);

    for (final size in [const Size(320, 480), const Size(640, 360)]) {
      await _resizeAndOpenLogin(tester, size);

      // Memaksa konten muat di layar ini akan mengecilkan teks sampai tak
      // terbaca, jadi mode scroll dipakai — dan isinya harus benar-benar
      // bisa dijangkau sampai elemen terbawah.
      expect(
        tester
            .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
            .physics,
        isA<ClampingScrollPhysics>(),
        reason: 'Layar ${size.width}x${size.height} harus bisa digeser',
      );

      final reason = 'layar sangat pendek ${size.width}x${size.height}';
      await _expectLoginContentReachable(tester, reason);

      // Pembanding: tanpa mode scroll, `FittedBox` akan menyusut sampai ~0,49
      // lebar aslinya. Di sini skala minimum 0,85 harus dipertahankan.
      expect(
        _effectiveScale(tester, base),
        closeTo(_readableScale, 0.03),
        reason: 'Teks harus tetap pada skala terbaca: $reason',
      );
    }
  });
}
