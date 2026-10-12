import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_state.dart';
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
  bool _googleLoading = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthCubit cubit) async {
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
    await cubit.login(email: 'pengguna@gmail.com', password: 'google-oauth');
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
          child: SafeArea(
            child: Column(
              children: [
                _Header(
                  onBack: loading ? null : () => context.go('/welcome'),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Align(child: _ClinicalBadge()),
                            const Gap(12),
                            Text(
                              'Masuk ke Akun Anda',
                              textAlign: TextAlign.center,
                              style: appFont(
                                fontSize: 21.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Gap(8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Akses riwayat deteksi lesi kulit, arsip '
                                'dermoskopik, dan laporan skala GEA Anda.',
                                textAlign: TextAlign.center,
                                style: appFont(
                                  fontSize: 12,
                                  color: AppColors.inkMuted,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const Gap(22),
                            _buildFormCard(state, loading, cubit),
                            const Gap(22),
                            const _EncryptionNote(),
                            const Gap(20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Belum memiliki akun? ',
                                  style: appFont(
                                    fontSize: 14,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                                AppTextLink(
                                  'Daftar Sekarang',
                                  onTap: loading
                                      ? null
                                      : () => showComingSoon(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormCard(AuthState state, bool loading, AuthCubit cubit) {
    const fieldPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 13);
    final fieldRadius = BorderRadius.circular(14);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14BE185D),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Email').small.medium,
          const Gap(8),
          TextField(
            controller: _emailController,
            placeholder: const Text('nama@email.com'),
            keyboardType: TextInputType.emailAddress,
            enabled: !loading,
            padding: fieldPadding,
            borderRadius: fieldRadius,
          ),
          const Gap(16),
          const Text('Kata Sandi').small.medium,
          const Gap(8),
          TextField(
            controller: _passwordController,
            placeholder: const Text('Masukkan kata sandi'),
            obscureText: true,
            enabled: !loading,
            padding: fieldPadding,
            borderRadius: fieldRadius,
            features: const [InputFeature.passwordToggle()],
          ),
          const Gap(14),
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
                fontSize: 13.5,
                onTap: loading ? null : () => showComingSoon(context),
              ),
            ],
          ),
          if (state.errorMessage != null) ...[
            const Gap(16),
            Alert.destructive(
              leading: const Icon(LucideIcons.circleAlert),
              title: Text(state.errorMessage!),
            ),
          ],
          const Gap(18),
          AppButton(
            label: 'Masuk ke Akun',
            height: 44,
            fontSize: 14,
            trailingIcon: LucideIcons.arrowRight,
            loading: loading && !_googleLoading,
            onTap: loading ? null : () => _submit(cubit),
          ),
          const Gap(16),
          const _OrDivider(),
          const Gap(14),
          AppButton(
            label: 'Lanjutkan dengan Google',
            height: 44,
            fontSize: 14,
            leading: const GoogleLogo(size: 20),
            loading: _googleLoading,
            tonal: true,
            onTap: loading ? null : () => _signInWithGoogle(cubit),
          ),
          const Gap(18),
          Text.rich(
            TextSpan(
              style: appFont(
                fontSize: 11,
                height: 1.6,
                color: AppColors.inkMuted,
              ),
              children: [
                const TextSpan(text: 'Dengan masuk, Anda menyetujui '),
                _linkSpan('Syarat & Ketentuan'),
                const TextSpan(text: ' serta '),
                _linkSpan('Kebijakan Privasi'),
                const TextSpan(text: ' SkinScan ID.'),
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
        style: appFont(
          color: AppColors.brand,
          fontWeight: FontWeight.w600,
        ),
      );
}

/// Header blush dengan garis tipis; tombol kembali + identitas aplikasi.
class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.page,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GhostButton(
            onPressed: onBack,
            density: ButtonDensity.icon,
            child: const Icon(LucideIcons.arrowLeft),
          ),
          const Spacer(),
          const Text('SkinScan ID').semiBold,
          const Gap(12),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.user,
              size: 20,
              color: AppColors.white,
            ),
          ),
          const Gap(4),
        ],
      ),
    );
  }
}

/// Chip pink "Pemeriksaan klinis skala GEA".
class _ClinicalBadge extends StatelessWidget {
  const _ClinicalBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.badgeCheck, size: 16, color: AppColors.brand),
          const Gap(8),
          Text(
            'PEMERIKSAAN KLINIS SKALA GEA',
            style: appFont(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: AppColors.brand,
            ),
          ),
        ],
      ),
    );
  }
}

/// Checkbox bulat pink + label "Ingat saya".
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
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: value ? AppColors.brand : AppColors.brandSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: value ? AppColors.brand : AppColors.border,
              ),
            ),
            child: value
                ? const Icon(
                    LucideIcons.check,
                    size: 14,
                    color: AppColors.white,
                  )
                : null,
          ),
          const Gap(10),
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
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'atau lanjutkan dengan',
            style: appFont(fontSize: 11, color: AppColors.inkMuted),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

/// Pil blush ber-border: catatan enkripsi data medis.
class _EncryptionNote extends StatelessWidget {
  const _EncryptionNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.shield, size: 16, color: AppColors.brand),
          const Gap(12),
          Expanded(
            child: Text(
              'Enkripsi Data Medis End-to-End '
              '(HIPAA & Permenkes RI Compliant)',
              style: appFont(
                fontSize: 11,
                height: 1.4,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
