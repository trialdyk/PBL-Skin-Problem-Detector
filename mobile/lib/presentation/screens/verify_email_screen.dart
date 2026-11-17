import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_state.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.email});

  final String? email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _code = TextEditingController();
  String? _fieldError;
  String? _infoMessage;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cubit = context.read<AuthCubit>();
    if (cubit.state.status == AuthStatus.loading) return;
    final code = _code.text.trim();
    setState(() {
      _infoMessage = null;
      _fieldError = RegExp(r'^\d{6}$').hasMatch(code)
          ? null
          : 'Masukkan 6 digit kode dari email';
    });
    if (_fieldError != null) return;
    await cubit.verifyEmail(code: code);
  }

  Future<void> _resend() async {
    final cubit = context.read<AuthCubit>();
    if (cubit.state.status == AuthStatus.loading) return;
    setState(() => _infoMessage = null);
    await cubit.resendVerification();
    if (!mounted) return;
    if (cubit.state.errorMessage == null) {
      setState(() {
        _infoMessage =
            'Kode baru dikirim. Periksa kotak masuk atau folder spam.';
      });
    }
  }

  void _backToLogin() {
    context.read<AuthCubit>().clearError();
    context.go('/login');
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
        final email = state.pendingEmail ?? widget.email ?? '';
        return Scaffold(
          backgroundColor: AppColors.page,
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: OutlineButton(
                      onPressed: loading ? null : _backToLogin,
                      child: const Icon(LucideIcons.arrowLeft, size: 18),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Verifikasi Email',
                              style: appFont(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                height: 1.2,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              email.isEmpty
                                  ? 'Masukkan kode 6 digit yang kami kirim ke email Anda.'
                                  : 'Kami mengirim kode 6 digit ke $email. Masukkan kode di bawah untuk mengaktifkan akun.',
                              style: appFont(
                                fontSize: 13.5,
                                color: AppColors.inkMuted,
                                height: 1.4,
                              ),
                            ),
                            if (state.errorMessage != null) ...[
                              const Gap(14),
                              Alert.destructive(
                                leading: const Icon(LucideIcons.circleAlert),
                                title: Text(state.errorMessage!),
                              ),
                            ],
                            if (_infoMessage != null) ...[
                              const Gap(14),
                              Alert(
                                leading: const Icon(LucideIcons.mailCheck),
                                title: Text(_infoMessage!),
                              ),
                            ],
                            const Gap(20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Kode Verifikasi',
                                    style: appFont(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_fieldError != null) ...[
                                    const Gap(6),
                                    Text(
                                      _fieldError!,
                                      style: appFont(
                                        fontSize: 12.5,
                                        color: const Color(0xFFB42318),
                                      ),
                                    ),
                                  ],
                                  const Gap(8),
                                  TextField(
                                    controller: _code,
                                    placeholder: const Text('6 digit'),
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.done,
                                    enabled: !loading,
                                    onChanged: (_) {
                                      context.read<AuthCubit>().clearError();
                                      if (_fieldError != null) {
                                        setState(() => _fieldError = null);
                                      }
                                    },
                                    onSubmitted: (_) => _submit(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 13,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                  ),
                                  const Gap(18),
                                  AppButton(
                                    label: 'Verifikasi',
                                    height: 44,
                                    fontSize: 14,
                                    trailingIcon: LucideIcons.shieldCheck,
                                    loading: loading,
                                    onTap: loading ? null : _submit,
                                  ),
                                  const Gap(12),
                                  AppTextLink(
                                    'Kirim ulang kode',
                                    fontSize: 14,
                                    onTap: loading ? null : _resend,
                                  ),
                                ],
                              ),
                            ),
                            const Gap(20),
                            Center(
                              child: AppTextLink(
                                'Kembali ke masuk',
                                fontSize: 14,
                                onTap: loading ? null : _backToLogin,
                              ),
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
}
