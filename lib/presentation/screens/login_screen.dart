import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/auth_state.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final horizontal = (size.width * 0.06).clamp(20.0, 32.0);

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          context.go('/home');
        }
      },
      builder: (context, state) {
        final loading = state.status == AuthStatus.loading;

        return Scaffold(
          backgroundColor: AppColors.white,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GhostButton(
                            onPressed:
                                loading ? null : () => context.go('/welcome'),
                            density: ButtonDensity.compact,
                            leading: const Icon(
                              LucideIcons.arrowLeft,
                              color: AppColors.slate,
                            ),
                            child: const Text(
                              'Kembali',
                              style: TextStyle(
                                color: AppColors.slate,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Gap(20),
                          const Text(
                            'Masuk',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate,
                            ),
                          ),
                          const Gap(8),
                          const Text(
                            'Gunakan email dan password untuk mulai analisis kulit.',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7A8494),
                              height: 1.4,
                            ),
                          ),
                          const Gap(32),
                          _UnderlineField(
                            label: 'Email',
                            child: TextField(
                              controller: _emailController,
                              placeholder: const Text('nama@email.com'),
                              keyboardType: TextInputType.emailAddress,
                              enabled: !loading,
                            ),
                          ),
                          const Gap(20),
                          _UnderlineField(
                            label: 'Password',
                            child: TextField(
                              controller: _passwordController,
                              placeholder: const Text('Password'),
                              obscureText: true,
                              enabled: !loading,
                              features: const [
                                InputFeature.passwordToggle(),
                              ],
                            ),
                          ),
                          if (state.errorMessage != null) ...[
                            const Gap(14),
                            Text(
                              state.errorMessage!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.blush,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          const Spacer(),
                          const Gap(28),
                          Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7A8494),
                                height: 1.4,
                              ),
                              children: const [
                                TextSpan(
                                  text:
                                      "Dengan menekan 'Setuju', Anda menyetujui ",
                                ),
                                TextSpan(
                                  text: 'Ketentuan Layanan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate,
                                  ),
                                ),
                                TextSpan(text: ' dan '),
                                TextSpan(
                                  text: 'Kebijakan Privasi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate,
                                  ),
                                ),
                                TextSpan(text: '.'),
                              ],
                            ),
                          ),
                          const Gap(16),
                          SizedBox(
                            width: double.infinity,
                            child: PrimaryButton(
                              enabled: !loading,
                              onPressed: () =>
                                  _submit(context.read<AuthCubit>()),
                              child: Text(
                                loading ? 'Memproses...' : 'Setuju dan Lanjut',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const Gap(10),
                          const Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Prototipe: email & password apa saja diterima.',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9AA3B0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _UnderlineField extends StatelessWidget {
  const _UnderlineField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF7A8494),
          ),
        ),
        const Gap(6),
        child,
      ],
    );
  }
}
