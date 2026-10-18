import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_state.dart';
import 'package:pbl_skin_problem_detector/data/services/auth_service.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/google_logo.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _googleLoading = false;
  bool _rememberMe = false;

  /// Pesan galat inline per-field, dirender sebagai bubble di atas field.
  String? _emailError;
  String? _passwordError;

  /// Field baru menampilkan galat setelah "disentuh" (blur, submit, atau
  /// dikosongkan kembali) supaya tidak berkedip merah saat masih mengetik.
  bool _emailTouched = false;
  bool _passwordTouched = false;

  /// Nilai sebelumnya — dipakai mendeteksi field yang baru saja dikosongkan.
  String _previousEmail = '';
  String _previousPassword = '';

  /// Format email umum: `nama@domain.tld`.
  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  /// Tinggi desain acuan area konten (di bawah header). Di bawah ini konten
  /// mulai memadat secara proporsional.
  static const double _designHeight = 600;

  /// Batas bawah skala agar teks tidak menjadi terlalu kecil.
  static const double _minScale = 0.85;

  /// Tinggi area konten minimum agar halaman login muat **tanpa** pesan galat.
  ///
  /// Diukur dari skala efektif teks (pemadatan dinamis × pengecilan
  /// `FittedBox`): di bawah nilai ini konten lebih baik bisa digeser daripada
  /// mengecil sampai teks tak terbaca (mis. 320×568 → skala 0,75).
  static const double _minFitHeight = 570;

  /// Tinggi area konten minimum saat ada pesan galat. Blok galat (panel
  /// kredensial atau bubble inline) beserta jaraknya menambah tinggi konten,
  /// jadi ruang yang dibutuhkan ikut naik — kalau tidak, halaman menyusut
  /// sampai skala 0,60 (mis. panel galat di 320×568).
  static const double _minFitHeightWithError = 720;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_onEmailFocusChanged);
    _passwordFocus.addListener(_onPasswordFocusChanged);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // --- Validasi -------------------------------------------------------------

  static String? _validateEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return 'Email tidak boleh kosong';
    if (!_emailPattern.hasMatch(email)) return 'Format email tidak valid';
    return null;
  }

  static String? _validatePassword(String value) =>
      value.isEmpty ? 'Kata sandi tidak boleh kosong' : null;

  void _onEmailChanged(String value) {
    context.read<AuthCubit>().clearError();
    setState(() {
      // Mengosongkan field yang tadinya terisi = niat jelas; langsung cek.
      if (value.trim().isEmpty && _previousEmail.trim().isNotEmpty) {
        _emailTouched = true;
      }
      _previousEmail = value;
      _emailError = _emailTouched ? _validateEmail(value) : null;
    });
  }

  void _onPasswordChanged(String value) {
    context.read<AuthCubit>().clearError();
    setState(() {
      if (value.isEmpty && _previousPassword.isNotEmpty) {
        _passwordTouched = true;
      }
      _previousPassword = value;
      _passwordError = _passwordTouched ? _validatePassword(value) : null;
    });
  }

  void _onEmailFocusChanged() {
    if (_emailFocus.hasFocus) return;
    setState(() {
      _emailTouched = true;
      _emailError = _validateEmail(_emailController.text);
    });
  }

  void _onPasswordFocusChanged() {
    if (_passwordFocus.hasFocus) return;
    setState(() {
      _passwordTouched = true;
      _passwordError = _validatePassword(_passwordController.text);
    });
  }

  // --- Aksi -----------------------------------------------------------------

  Future<void> _submit(AuthCubit cubit) async {
    final emailError = _validateEmail(_emailController.text);
    final passwordError = _validatePassword(_passwordController.text);

    setState(() {
      _emailTouched = true;
      _passwordTouched = true;
      _emailError = emailError;
      _passwordError = passwordError;
    });

    // Ada field yang belum valid → cukup bubble inline. Service tidak
    // dipanggil supaya panel merah "kredensial salah" tidak ikut muncul.
    if (emailError != null || passwordError != null) return;

    cubit.togglePrivacy(true);
    cubit.toggleTerms(true);
    await cubit.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  /// Mock Google sign-in (prototipe, belum terhubung ke Google OAuth).
  Future<void> _signInWithGoogle(AuthCubit cubit) async {
    setState(() => _googleLoading = true);
    cubit.togglePrivacy(true);
    cubit.toggleTerms(true);
    await cubit.login(
      email: AuthService.demoEmail,
      password: 'google-oauth',
      viaGoogle: true,
    );
    if (mounted) setState(() => _googleLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go('/home');
        }
      },
      builder: (context, state) {
        final loading = state.status == AuthStatus.loading;
        final cubit = context.read<AuthCubit>();
        return Scaffold(
          backgroundColor: AppColors.page,
          // Body tidak dipotong keyboard: skala tata letak selalu dihitung dari
          // tinggi penuh, sehingga konten tidak menyusut/terangkat saat mengetik.
          resizeToAvoidBottomInset: false,
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _BackCircleButton(
                      onPressed: loading
                          ? null
                          : () => context.go('/splash'),
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Memadat di layar pendek, tidak membesar di layar tinggi.
                      final scale = (constraints.maxHeight / _designHeight)
                          .clamp(_minScale, 1.0);
                      double s(double value) => value * scale;

                      // Lebar mengikuti layar (dibatasi 420), sehingga FittedBox
                      // hanya mengecil karena tinggi — bukan karena lebar.
                      final contentWidth = math.min(
                        math.max(constraints.maxWidth - 32, 0.0),
                        420.0,
                      );

                      final content = Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Masuk ke Akun Anda',
                            textAlign: TextAlign.left,
                            style: appFont(
                              fontSize: s(24),
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              height: 1.2,
                            ),
                          ),
                          Gap(s(6)),
                          Text(
                            'Masukkan email dan kata sandi untuk melanjutkan.',
                            style: appFont(
                              fontSize: s(13.5),
                              color: AppColors.inkMuted,
                              height: 1.4,
                            ),
                          ),
                          // Panel galat kredensial dari service: berada di
                          // antara judul dan card form.
                          if (state.errorMessage != null) ...[
                            Gap(s(14)),
                            Alert.destructive(
                              leading: const Icon(LucideIcons.circleAlert),
                              title: Text(state.errorMessage!),
                            ),
                          ],
                          Gap(s(20)),
                          _buildFormCard(loading, cubit, s),
                          Gap(s(20)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Belum memiliki akun? ',
                                style: appFont(
                                  fontSize: s(14),
                                  color: AppColors.inkMuted,
                                ),
                              ),
                              AppTextLink(
                                'Daftar Sekarang',
                                fontSize: s(14),
                                onTap: loading
                                    ? null
                                    : () => showComingSoon(context),
                              ),
                            ],
                          ),
                        ],
                      );

                      // `FittedBox` baru benar-benar mengecil kalau tingginya
                      // dibatasi — penguncian itu dilakukan pemanggil di bawah
                      // (`SizedBox(height: maxHeight)`). Tanpa pengunci, tinggi
                      // yang diteruskan TAK TERBATAS sehingga `scaleDown` jadi
                      // no-op dan sisa konten terpotong diam-diam.
                      final fitted = Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, s(22), 16, s(24)),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: contentWidth,
                              child: content,
                            ),
                          ),
                        ),
                      );

                      // Terbaca karena `resizeToAvoidBottomInset: false`.
                      final keyboard = MediaQuery.viewInsetsOf(context).bottom;

                      // Struktur widget sengaja tetap sama (hanya `physics`,
                      // tinggi pengunci, dan padding yang berubah) agar
                      // `TextField` tidak dibuat ulang — kalau dibuat ulang,
                      // field kehilangan fokus dan keyboard ikut tertutup.
                      //
                      // Layar pendek: memaksa konten muat akan mengecilkan teks
                      // sampai tak terbaca, jadi konten dibiarkan pada skala
                      // terbaca dan bisa digeser. Blok galat menambah tinggi
                      // konten, jadi ambangnya ikut naik.
                      final hasInlineError =
                          state.errorMessage != null ||
                          _emailError != null ||
                          _passwordError != null;
                      final scrollable =
                          constraints.maxHeight <
                          (hasInlineError
                              ? _minFitHeightWithError
                              : _minFitHeight);

                      return Padding(
                        padding: EdgeInsets.only(bottom: keyboard),
                        child: SingleChildScrollView(
                          // Idle di layar cukup tinggi: terkunci (memang tidak
                          // ada sisa geser). Saat keyboard terbuka atau layar
                          // pendek: bisa digeser supaya field, tombol, dan
                          // tautan terbawah tetap terjangkau.
                          physics: (keyboard == 0 && !scrollable)
                              ? const NeverScrollableScrollPhysics()
                              : const ClampingScrollPhysics(),
                          // Mode "fit": tinggi anak DIKUNCI ke tinggi yang
                          // tersedia. Tanpa pengunci ini `SingleChildScrollView`
                          // meneruskan tinggi tak terbatas ke `FittedBox`,
                          // sehingga `BoxFit.scaleDown` tidak pernah mengecil
                          // dan elemen terbawah (mis. "Daftar Sekarang")
                          // terpotong tanpa error overflow.
                          // Mode "scroll": tinggi tidak dikunci (`null` → lolos
                          // apa adanya) sehingga konten memakai ukuran
                          // naturalnya dan bisa digeser sampai terbawah.
                          // `SizedBox` selalu dipakai (hanya `height` yang
                          // berubah) supaya jenis widget di bawah scroll view
                          // tetap sama saat mode berpindah.
                          child: SizedBox(
                            height: scrollable ? null : constraints.maxHeight,
                            child: fitted,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormCard(
    bool loading,
    AuthCubit cubit,
    double Function(double) s,
  ) {
    final fieldPadding = EdgeInsets.symmetric(
      horizontal: s(16),
      vertical: s(13),
    );
    final fieldRadius = BorderRadius.circular(s(14));

    return Container(
      padding: EdgeInsets.all(s(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(s(16)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Email',
            style: appFont(fontSize: s(14), fontWeight: FontWeight.w500),
          ),
          if (_emailError != null) ...[
            Gap(s(6)),
            _FieldErrorBubble(message: _emailError!),
          ],
          Gap(s(8)),
          TextField(
            controller: _emailController,
            focusNode: _emailFocus,
            placeholder: const Text('nama@email.com'),
            keyboardType: TextInputType.emailAddress,
            enabled: !loading,
            padding: fieldPadding,
            borderRadius: fieldRadius,
            onChanged: _onEmailChanged,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          Gap(s(16)),
          Text(
            'Kata Sandi',
            style: appFont(fontSize: s(14), fontWeight: FontWeight.w500),
          ),
          if (_passwordError != null) ...[
            Gap(s(6)),
            _FieldErrorBubble(message: _passwordError!),
          ],
          Gap(s(8)),
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            placeholder: const Text('Masukkan kata sandi'),
            obscureText: true,
            enabled: !loading,
            padding: fieldPadding,
            borderRadius: fieldRadius,
            features: const [InputFeature.passwordToggle()],
            onChanged: _onPasswordChanged,
            onSubmitted: (_) => _submit(cubit),
          ),
          Gap(s(14)),
          Row(
            children: [
              _RememberMe(
                value: _rememberMe,
                onChanged: loading
                    ? null
                    : (value) => setState(() => _rememberMe = value),
              ),
              const Spacer(),
              AppTextLink(
                'Lupa kata sandi?',
                fontSize: s(13.5),
                onTap: loading ? null : () => showComingSoon(context),
              ),
            ],
          ),
          Gap(s(18)),
          AppButton(
            label: 'Masuk ke Akun',
            height: s(44),
            fontSize: s(14),
            trailingIcon: LucideIcons.arrowRight,
            loading: loading && !_googleLoading,
            onTap: loading ? null : () => _submit(cubit),
          ),
          Gap(s(16)),
          _OrDivider(fontSize: s(11)),
          Gap(s(14)),
          AppButton(
            label: 'Lanjutkan dengan Google',
            height: s(44),
            fontSize: s(14),
            leading: GoogleLogo(size: s(20)),
            loading: _googleLoading,
            tonal: true,
            onTap: loading ? null : () => _signInWithGoogle(cubit),
          ),
          Gap(s(18)),
          Text.rich(
            TextSpan(
              style: appFont(
                fontSize: s(11),
                height: 1.6,
                color: AppColors.inkMuted,
              ),
              children: [
                const TextSpan(text: 'Dengan masuk, Anda menyetujui '),
                _linkSpan('Syarat & Ketentuan'),
                const TextSpan(text: ' serta '),
                _linkSpan('Kebijakan Privasi'),
                const TextSpan(text: ' aplikasi ini.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static TextSpan _linkSpan(String text) => TextSpan(
    text: text,
    style: appFont(color: AppColors.brand, fontWeight: FontWeight.w600),
  );
}

class _BackCircleButton extends StatelessWidget {
  const _BackCircleButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.45 : 1,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            LucideIcons.arrowLeft,
            size: 18,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Checkbox kecil proporsional dengan label "Ingat saya".
class _RememberMe extends StatelessWidget {
  const _RememberMe({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: value ? AppColors.brand : AppColors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? AppColors.brand : AppColors.border,
                width: 1.4,
              ),
            ),
            child: value
                ? const Icon(
                    LucideIcons.check,
                    size: 11,
                    color: AppColors.white,
                  )
                : null,
          ),
          const Gap(8),
          Text(
            'Ingat saya',
            style: appFont(fontSize: 13, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Garis pembatas dengan teks "atau lanjutkan dengan".
class _OrDivider extends StatelessWidget {
  const _OrDivider({this.fontSize = 11});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'atau lanjutkan dengan',
            style: appFont(fontSize: fontSize, color: AppColors.inkMuted),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

/// Bubble galat kecil yang muncul di atas field: pesan singkat + ekor
/// segitiga yang menunjuk ke field di bawahnya.
class _FieldErrorBubble extends StatelessWidget {
  const _FieldErrorBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final danger = Theme.of(context).colorScheme.destructive;
    // Latar merah muda + teks merah tua. Sebelumnya latar dan teks sama-sama
    // `danger`, sehingga teks tidak terlihat (merah di atas merah).
    final surface = AppColors.dangerSurface(danger);
    final ink = AppColors.dangerInk(danger);

    return Align(
      alignment: Alignment.centerLeft,
      child: CustomPaint(
        painter: _BubblePainter(color: surface),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.circleAlert, size: 13, color: ink),
              const Gap(6),
              Flexible(
                child: Text(
                  message,
                  style: appFont(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded-rect + ekor segitiga di tengah bawah (gaya balon percakapan).
class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.color});

  static const double _radius = 8;
  static const double _tail = 6;

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyHeight = size.height - _tail;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, bodyHeight),
          Radius.circular(_radius),
        ),
      )
      // Tumpang tindih 1px dengan badan agar tidak ada celah anti-aliasing.
      ..moveTo(16, bodyHeight - 1)
      ..lineTo(30, bodyHeight - 1)
      ..lineTo(23, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) => oldDelegate.color != color;
}
