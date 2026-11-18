import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Halaman ubah kata sandi akun pengguna.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _errors = <String, String>{};
  bool _submitted = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _validate() {
    _errors.clear();
    final currentText = _current.text;
    final nextText = _next.text;
    final confirmText = _confirm.text;

    if (currentText.isEmpty) {
      _errors['current'] = 'Kata sandi saat ini tidak boleh kosong';
    }

    if (nextText.isNotEmpty &&
        currentText.isNotEmpty &&
        nextText == currentText) {
      _errors['new'] =
          'Kata sandi baru tidak boleh sama dengan kata sandi saat ini';
    } else if (nextText.length < 8 || nextText.length > 128) {
      _errors['new'] = 'Kata sandi baru harus 8–128 karakter';
    }

    if (confirmText.isEmpty) {
      _errors['confirm'] = 'Konfirmasi kata sandi tidak boleh kosong';
    } else if (confirmText != nextText) {
      _errors['confirm'] = 'Konfirmasi kata sandi tidak cocok';
    }
  }

  void _onChanged(String _) {
    context.read<AuthCubit>().clearError();
    if (_submitted || _errors.isNotEmpty) {
      setState(_validate);
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _validate();
    });
    if (_errors.isNotEmpty) return;

    final ok = await context.read<AuthCubit>().changePassword(
      currentPassword: _current.text,
      newPassword: _next.text,
    );
    if (!mounted || !ok) return;

    showAppAlert(
      context,
      'Kata sandi berhasil diperbarui.',
      icon: LucideIcons.check,
    );
    _goBack();
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      child: SoftPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    OutlineButton(
                      onPressed: _goBack,
                      child: const Icon(LucideIcons.arrowLeft, size: 18),
                    ),
                    const Gap(12),
                    Text(
                      'Ubah Kata Sandi',
                      style: appFont(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                                _passwordField(
                                  id: 'current',
                                  label: 'Kata Sandi Saat Ini',
                                  placeholder: 'Masukkan kata sandi saat ini',
                                  controller: _current,
                                ),
                                const Gap(16),
                                _passwordField(
                                  id: 'new',
                                  label: 'Kata Sandi Baru',
                                  placeholder: 'Minimal 8 karakter',
                                  controller: _next,
                                ),
                                const Gap(16),
                                _passwordField(
                                  id: 'confirm',
                                  label: 'Konfirmasi Kata Sandi Baru',
                                  placeholder: 'Ulangi kata sandi baru',
                                  controller: _confirm,
                                  last: true,
                                ),
                                const Gap(20),
                                AppButton(
                                  label: 'Simpan Kata Sandi',
                                  height: 46,
                                  fontSize: 14,
                                  trailingIcon: LucideIcons.check,
                                  onTap: _submit,
                                ),
                              ],
                            ),
                          ),
                          const Gap(12),
                          Text(
                            'Perubahan kata sandi sementara tersimpan di sesi aplikasi.',
                            textAlign: TextAlign.center,
                            style: appFont(
                              fontSize: 11.5,
                              color: AppColors.inkMuted,
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
      ),
    );
  }

  Widget _passwordField({
    required String id,
    required String label,
    required String placeholder,
    required TextEditingController controller,
    bool last = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: appFont(fontSize: 14, fontWeight: FontWeight.w500)),
        if (_errors[id] != null) ...[
          const Gap(6),
          _PasswordErrorBadge(message: _errors[id]!),
        ],
        const Gap(8),
        TextField(
          key: ValueKey('change-password-$id'),
          controller: controller,
          placeholder: Text(placeholder),
          obscureText: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          borderRadius: BorderRadius.circular(14),
          features: const [InputFeature.passwordToggle()],
          textInputAction: last ? TextInputAction.done : TextInputAction.next,
          onChanged: _onChanged,
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
}

class _PasswordErrorBadge extends StatelessWidget {
  const _PasswordErrorBadge({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
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
