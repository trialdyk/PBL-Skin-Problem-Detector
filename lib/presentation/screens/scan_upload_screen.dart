import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/data/services/image_pick_service.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/selfie_slot.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ScanUploadScreen extends StatefulWidget {
  const ScanUploadScreen({super.key});

  @override
  State<ScanUploadScreen> createState() => _ScanUploadScreenState();
}

class _ScanUploadScreenState extends State<ScanUploadScreen> {
  final _picker = ImagePickService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ScanCubit>().startUpload();
    });
  }

  Future<void> _pick(SelfieAngle angle) async {
    final path = await _picker.pickFromGallery();
    if (!mounted || path == null) return;
    context.read<ScanCubit>().setPhoto(angle, path);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScanCubit, ScanState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.surface,
          headers: [
            AppBar(
              leading: [
                IconButton.ghost(
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: () => context.go('/scan'),
                ),
              ],
              title: const Text('Unggah 3 Selfie'),
            ),
          ],
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Pilih foto depan, kiri, dan kanan dari galeri.',
                  style: TextStyle(color: Color(0xFF7A8494)),
                ),
                const Gap(20),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: SelfieSlot(
                          angle: SelfieAngle.front,
                          path: state.session.frontPath,
                          onPick: () => _pick(SelfieAngle.front),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: SelfieSlot(
                          angle: SelfieAngle.left,
                          path: state.session.leftPath,
                          onPick: () => _pick(SelfieAngle.left),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: SelfieSlot(
                          angle: SelfieAngle.right,
                          path: state.session.rightPath,
                          onPick: () => _pick(SelfieAngle.right),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const Gap(8),
                  Text(
                    state.errorMessage!,
                    style: const TextStyle(color: AppColors.blush),
                  ),
                ],
                const Gap(16),
                PrimaryButton(
                  enabled: state.hasAllPhotos,
                  onPressed: () {
                    context.read<ScanCubit>().goToConfirm();
                    context.go('/scan/confirm');
                  },
                  child: const Text('LANJUTKAN'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
