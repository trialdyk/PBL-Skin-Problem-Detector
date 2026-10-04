import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/data/services/face_scan_analyzer.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/selfie_angle_progress.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class ScanCaptureScreen extends StatefulWidget {
  const ScanCaptureScreen({super.key});

  @override
  State<ScanCaptureScreen> createState() => _ScanCaptureScreenState();
}

class _ScanCaptureScreenState extends State<ScanCaptureScreen> {
  CameraController? _controller;
  final _analyzer = FaceScanAnalyzer();

  String? _error;
  bool _initializing = true;
  bool _capturing = false;
  bool _streaming = false;

  bool _lightingOk = false;
  bool _faceOk = false;
  bool _angleOk = false;

  int? _countdown;
  Timer? _countdownTimer;
  DateTime _lastAnalyze = DateTime.fromMillisecondsSinceEpoch(0);
  SelfieAngle _targetAngle = SelfieAngle.front;
  double? _lastYaw;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ScanCubit>().startCapture();
    });
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        front,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _initializing = false;
      });
      await _startStream();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _error = 'Tidak bisa membuka kamera depan. Izinkan akses kamera.';
      });
    }
  }

  Future<void> _startStream() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _streaming) {
      return;
    }
    _streaming = true;
    await controller.startImageStream(_onFrame);
  }

  Future<void> _stopStream() async {
    final controller = _controller;
    if (controller == null || !_streaming) return;
    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    _streaming = false;
  }

  Future<void> _onFrame(CameraImage image) async {
    if (!mounted || _capturing) return;
    final now = DateTime.now();
    if (now.difference(_lastAnalyze).inMilliseconds < 280) return;
    _lastAnalyze = now;

    final controller = _controller;
    if (controller == null) return;

    final status = await _analyzer.analyze(
      image: image,
      camera: controller.description,
      targetAngle: _targetAngle,
      sensorOrientation: controller.description.sensorOrientation,
    );

    if (!mounted) return;
    setState(() {
      _lightingOk = status.lightingOk;
      _faceOk = status.facePresent;
      _angleOk = status.angleOk;
      _lastYaw = status.headYaw;
    });

    _syncCountdown(status.ready);
  }

  void _syncCountdown(bool ready) {
    if (!ready) {
      _countdownTimer?.cancel();
      _countdownTimer = null;
      if (_countdown != null) {
        setState(() => _countdown = null);
      }
      return;
    }

    if (_countdownTimer != null || _capturing) return;

    setState(() => _countdown = 3);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_lightingOk || !_faceOk || !_angleOk) {
        timer.cancel();
        _countdownTimer = null;
        setState(() => _countdown = null);
        return;
      }

      final next = (_countdown ?? 1) - 1;
      if (next <= 0) {
        timer.cancel();
        _countdownTimer = null;
        setState(() => _countdown = null);
        _capturePhoto();
      } else {
        setState(() => _countdown = next);
      }
    });
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || _capturing || !controller.value.isInitialized) {
      return;
    }

    setState(() => _capturing = true);
    try {
      await _stopStream();
      final file = await controller.takePicture();
      if (!mounted) return;

      final cubit = context.read<ScanCubit>();
      final angle = cubit.state.currentAngle;
      if (angle == SelfieAngle.left) {
        // Ambil yaw terakhir dari status stream tidak tersedia di sini —
        // gunakan tanda dari analyzer saat frame terakhir ready.
        _analyzer.rememberLeftYaw(_lastYaw);
      }
      cubit.setPhoto(angle, file.path);

      if (!mounted) return;
      if (cubit.state.phase == ScanPhase.confirming) {
        context.go('/scan/confirm');
        return;
      }

      // Lanjut sudut berikutnya — restart stream.
      setState(() {
        _lightingOk = false;
        _faceOk = false;
        _angleOk = false;
        _countdown = null;
      });
      await _startStream();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Gagal mengambil foto. Coba lagi.');
      await _startStream();
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  String _angleLabel(SelfieAngle angle) => switch (angle) {
        SelfieAngle.front => 'LIHAT DEPAN',
        SelfieAngle.left => 'LIHAT KIRI',
        SelfieAngle.right => 'LIHAT KANAN',
      };

  String _hint(SelfieAngle angle) => switch (angle) {
        SelfieAngle.front => 'Hadapkan wajah lurus ke kamera di dalam oval',
        SelfieAngle.left => 'Putar wajah ke samping (±30°) sampai indikator aktif',
        SelfieAngle.right =>
          'Putar wajah ke sisi berlawanan dari foto sebelumnya',
      };

  @override
  void dispose() {
    _countdownTimer?.cancel();
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      if (controller.value.isStreamingImages) {
        controller.stopImageStream().whenComplete(controller.dispose);
      } else {
        controller.dispose();
      }
    }
    _analyzer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanCubit, ScanState>(
      listenWhen: (prev, next) => prev.currentAngle != next.currentAngle,
      listener: (context, state) {
        _targetAngle = state.currentAngle;
        _countdownTimer?.cancel();
        _countdownTimer = null;
        setState(() {
          _countdown = null;
          _lightingOk = false;
          _faceOk = false;
          _angleOk = false;
        });
      },
      builder: (context, state) {
        _targetAngle = state.currentAngle;
        final ready = _lightingOk && _faceOk && _angleOk;
        return Scaffold(
          backgroundColor: AppColors.cameraBg,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton.ghost(
                        icon: const Icon(LucideIcons.x, color: AppColors.white),
                        onPressed: () => context.go('/scan'),
                      ),
                      Expanded(
                        child: Text(
                          'Foto ${_angleLabel(state.currentAngle)}',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const Gap(12),
                  Row(
                    children: [
                      _StatusChip(label: 'PENCAHAYAAN', ok: _lightingOk),
                      const Gap(8),
                      _StatusChip(label: 'POSISI WAJAH', ok: _faceOk),
                      const Gap(8),
                      _StatusChip(
                        label: _angleLabel(state.currentAngle),
                        ok: _angleOk,
                      ),
                    ],
                  ),
                  const Gap(10),
                  Text(
                    _hint(state.currentAngle),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ready ? AppColors.mint : const Color(0xFF9AA3B0),
                      fontSize: 12,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.cameraOverlay,
                              border: Border.all(
                                color: ready
                                    ? AppColors.mint
                                    : const Color(0xFF5A6473),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (_controller != null &&
                                    _controller!.value.isInitialized)
                                  FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _controller!
                                          .value.previewSize!.height,
                                      height:
                                          _controller!.value.previewSize!.width,
                                      child: CameraPreview(_controller!),
                                    ),
                                  )
                                else
                                  Center(
                                    child: Text(
                                      _initializing
                                          ? 'Membuka kamera depan...'
                                          : (_error ?? 'Kamera tidak siap'),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                Center(
                                  child: Container(
                                    width: 220,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: AppColors.white
                                            .withValues(alpha: 0.85),
                                        width: 2,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                        Radius.elliptical(140, 180),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_countdown != null)
                                  Center(
                                    child: Text(
                                      '$_countdown',
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 72,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                if (_capturing)
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Gap(16),
                  SelfieAngleProgress(
                    current: state.currentAngle,
                    session: state.session,
                  ),
                  const Gap(16),
                  PrimaryButton(
                    enabled: ready && !_capturing && !_initializing,
                    onPressed: _capturePhoto,
                    child: Text(
                      _capturing
                          ? 'Menyimpan...'
                          : (ready ? 'AMBIL FOTO' : 'SESUEKAN POSISI'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: ok ? AppColors.mint : const Color(0xFF9AA3B0),
          ),
          borderRadius: BorderRadius.circular(6),
          color: ok ? AppColors.mint.withValues(alpha: 0.12) : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: ok ? AppColors.mint : const Color(0xFF9AA3B0),
          ),
        ),
      ),
    );
  }
}
