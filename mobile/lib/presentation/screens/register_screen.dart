import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_state.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _errors = <String, String>{};
  bool _accepted = false;
  bool _submitted = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _validate() {
    _errors.clear();
    if (_name.text.trim().isEmpty) {
      _errors['name'] = 'Nama lengkap tidak boleh kosong';
    } else if (_name.text.trim().length > 255) {
      _errors['name'] = 'Nama lengkap maksimal 255 karakter';
    }
    final email = _email.text.trim();
    if (email.isEmpty) {
      _errors['email'] = 'Email tidak boleh kosong';
    } else if (email.length > 255 ||
        !RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      _errors['email'] = 'Format email tidak valid';
    }
    if (_password.text.length < 8 || _password.text.length > 128) {
      _errors['password'] = 'Kata sandi harus 8–128 karakter';
    }
    if (_confirmation.text.isEmpty) {
      _errors['confirmation'] = 'Konfirmasi kata sandi tidak boleh kosong';
    } else if (_confirmation.text != _password.text) {
      _errors['confirmation'] = 'Konfirmasi kata sandi tidak cocok';
    }
    if (!_accepted) {
      _errors['consent'] =
          'Setujui syarat dan kebijakan privasi untuk mendaftar';
    }
  }

  void _changed(String _) {
    context.read<AuthCubit>().clearError();
    if (_submitted) setState(_validate);
  }

  Future<void> _submit() async {
    final cubit = context.read<AuthCubit>();
    if (cubit.state.status == AuthStatus.loading) return;
    setState(() {
      _submitted = true;
      _validate();
    });
    if (_errors.isNotEmpty) return;
    cubit.toggleTerms(_accepted);
    cubit.togglePrivacy(_accepted);
    await cubit.register(
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
    );
  }

  void _openLogin() {
    context.read<AuthCubit>().clearError();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) context.go('/home');
      },
      builder: (context, state) {
        final loading = state.status == AuthStatus.loading;
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
                      onPressed: loading ? null : _openLogin,
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
                              'Buat Akun Anda',
                              style: appFont(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                height: 1.2,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              'Daftar untuk mulai merawat kesehatan kulit Anda.',
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
                                  _field(
                                    'name',
                                    'Nama Lengkap',
                                    'Masukkan nama lengkap',
                                    _name,
                                    loading,
                                  ),
                                  const Gap(16),
                                  _field(
                                    'email',
                                    'Email',
                                    'nama@email.com',
                                    _email,
                                    loading,
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const Gap(16),
                                  _field(
                                    'password',
                                    'Kata Sandi',
                                    'Minimal 8 karakter',
                                    _password,
                                    loading,
                                    secret: true,
                                  ),
                                  const Gap(16),
                                  _field(
                                    'confirmation',
                                    'Konfirmasi Kata Sandi',
                                    'Ulangi kata sandi',
                                    _confirmation,
                                    loading,
                                    secret: true,
                                    last: true,
                                  ),
                                  const Gap(18),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        state: _accepted
                                            ? CheckboxState.checked
                                            : CheckboxState.unchecked,
                                        onChanged: loading
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  _accepted =
                                                      value ==
                                                      CheckboxState.checked;
                                                  if (_submitted) _validate();
                                                });
                                                context
                                                    .read<AuthCubit>()
                                                    .clearError();
                                              },
                                      ),
                                      const Gap(8),
                                      Expanded(
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            Text(
                                              'Saya menyetujui',
                                              style: appFont(
                                                fontSize: 12,
                                                color: AppColors.inkMuted,
                                              ),
                                            ),
                                            AppTextLink(
                                              'Syarat & Ketentuan',
                                              fontSize: 12,
                                              onTap: loading
                                                  ? null
                                                  : () =>
                                                        context.push('/terms'),
                                            ),
                                            Text(
                                              'dan',
                                              style: appFont(
                                                fontSize: 12,
                                                color: AppColors.inkMuted,
                                              ),
                                            ),
                                            AppTextLink(
                                              'Kebijakan Privasi',
                                              fontSize: 12,
                                              onTap: loading
                                                  ? null
                                                  : () => context.push(
                                                      '/privacy',
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (_errors['consent'] != null) ...[
                                    const Gap(6),
                                    _error(_errors['consent']!),
                                  ],
                                  const Gap(18),
                                  AppButton(
                                    label: 'Daftar Akun',
                                    height: 44,
                                    fontSize: 14,
                                    trailingIcon: LucideIcons.arrowRight,
                                    loading: loading,
                                    onTap: loading ? null : _submit,
                                  ),
                                ],
                              ),
                            ),
                            const Gap(20),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                Text(
                                  'Sudah memiliki akun?',
                                  style: appFont(
                                    fontSize: 14,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                                AppTextLink(
                                  'Masuk Sekarang',
                                  fontSize: 14,
                                  onTap: loading ? null : _openLogin,
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

  Widget _field(
    String id,
    String label,
    String placeholder,
    TextEditingController controller,
    bool loading, {
    bool secret = false,
    bool last = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: appFont(fontSize: 14, fontWeight: FontWeight.w500)),
        if (_errors[id] != null) ...[const Gap(6), _error(_errors[id]!)],
        const Gap(8),
        TextField(
          key: ValueKey('register-$id'),
          controller: controller,
          placeholder: Text(placeholder),
          keyboardType: keyboardType,
          obscureText: secret,
          enabled: !loading,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          borderRadius: BorderRadius.circular(14),
          features: secret ? const [InputFeature.passwordToggle()] : const [],
          textInputAction: last ? TextInputAction.done : TextInputAction.next,
          onChanged: _changed,
          onSubmitted: (_) {
            if (last) {
              _submit();
            } else {
              FocusScope.of(context).nextFocus();
            }
          },
        ),
      ],
    );
  }

  Widget _error(String message) {
    final danger = Theme.of(context).colorScheme.destructive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.dangerSurface(danger),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: appFont(
          fontSize: 11.5,
          color: AppColors.dangerInk(danger),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
