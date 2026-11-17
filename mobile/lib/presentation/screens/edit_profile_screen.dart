import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_state.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Halaman ubah profil pengguna (nama lengkap dan email).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static final _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  late final TextEditingController _name;
  late final TextEditingController _email;
  String? _nameError;
  String? _emailError;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AuthCubit>();
    cubit.clearError();
    final user = cubit.state.user;
    final initialName = user?.fullName?.trim().isNotEmpty == true
        ? user!.fullName!.trim()
        : (user?.displayName ?? '');
    _name = TextEditingController(text: initialName);
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  void _validate() {
    final trimmedName = _name.text.trim();
    if (trimmedName.isEmpty) {
      _nameError = 'Nama lengkap tidak boleh kosong';
    } else if (trimmedName.length > 255) {
      _nameError = 'Nama lengkap maksimal 255 karakter';
    } else {
      _nameError = null;
    }

    final trimmedEmail = _email.text.trim();
    if (trimmedEmail.isEmpty) {
      _emailError = 'Email tidak boleh kosong';
    } else if (trimmedEmail.length > 255 ||
        !_emailPattern.hasMatch(trimmedEmail)) {
      _emailError = 'Format email tidak valid';
    } else {
      _emailError = null;
    }
  }

  void _onChanged(String _) {
    context.read<AuthCubit>().clearError();
    setState(() {
      if (_submitted) _validate();
    });
  }

  Future<void> _submit() async {
    final cubit = context.read<AuthCubit>();
    if (cubit.state.profileSaving) return;

    setState(() {
      _submitted = true;
      _validate();
    });
    if (_nameError != null || _emailError != null) return;

    final updated = await cubit.updateProfile(
      fullName: _name.text.trim(),
      email: _email.text.trim(),
    );
    if (!mounted || !updated) return;

    showAppAlert(
      context,
      'Profil berhasil diperbarui.',
      icon: LucideIcons.check,
    );
    _goBack();
  }

  void _goBack() {
    context.read<AuthCubit>().clearError();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewName = _name.text.trim().isNotEmpty
        ? _name.text.trim()
        : 'Pengguna';
    final initials = previewName
        .substring(0, previewName.length >= 2 ? 2 : 1)
        .toUpperCase();
    final previewEmail = _email.text.trim().isNotEmpty
        ? _email.text.trim().toLowerCase()
        : '-';

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final saving = state.profileSaving;
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
                          onPressed: saving ? null : _goBack,
                          child: const Icon(LucideIcons.arrowLeft, size: 18),
                        ),
                        const Gap(12),
                        Text(
                          'Edit Profil',
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
                              SoftSurface(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: AppColors.brandSoft,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        initials,
                                        style: appFont(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.brand,
                                        ),
                                      ),
                                    ),
                                    const Gap(14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            previewName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: appFont(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const Gap(3),
                                          Text(
                                            previewEmail,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: appFont(
                                              fontSize: 12.5,
                                              color: AppColors.inkMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (state.errorMessage != null) ...[
                                const Gap(14),
                                Alert.destructive(
                                  leading: const Icon(LucideIcons.circleAlert),
                                  title: Text(state.errorMessage!),
                                ),
                              ],
                              const Gap(18),
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
                                      'Nama Lengkap',
                                      style: appFont(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_nameError != null) ...[
                                      const Gap(6),
                                      _ErrorBadge(message: _nameError!),
                                    ],
                                    const Gap(8),
                                    TextField(
                                      key: const ValueKey('edit-profile-name'),
                                      controller: _name,
                                      enabled: !saving,
                                      placeholder: const Text(
                                        'Masukkan nama lengkap',
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 13,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      textInputAction: TextInputAction.next,
                                      onChanged: _onChanged,
                                      onSubmitted: (_) =>
                                          FocusScope.of(context).nextFocus(),
                                    ),
                                    const Gap(16),
                                    Text(
                                      'Email',
                                      style: appFont(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (_emailError != null) ...[
                                      const Gap(6),
                                      _ErrorBadge(message: _emailError!),
                                    ],
                                    const Gap(8),
                                    TextField(
                                      key: const ValueKey('edit-profile-email'),
                                      controller: _email,
                                      enabled: !saving,
                                      placeholder: const Text('nama@email.com'),
                                      keyboardType: TextInputType.emailAddress,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 13,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      textInputAction: TextInputAction.done,
                                      onChanged: _onChanged,
                                      onSubmitted: (_) => _submit(),
                                    ),
                                    const Gap(20),
                                    AppButton(
                                      label: 'Simpan Perubahan',
                                      height: 46,
                                      fontSize: 14,
                                      trailingIcon: LucideIcons.check,
                                      loading: saving,
                                      onTap: saving ? null : _submit,
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(12),
                              Text(
                                'Perubahan profil akan disimpan ke akun Anda.',
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
      },
    );
  }
}

class _ErrorBadge extends StatelessWidget {
  const _ErrorBadge({required this.message});

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
