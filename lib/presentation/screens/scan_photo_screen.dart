import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_cubit.dart';
import 'package:pbl_skin_problem_detector/business/cubit/scan_state.dart';
import 'package:pbl_skin_problem_detector/data/models/scan_session.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_bottom_nav.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/spotlight_coach.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Langkah 1 — pengambilan foto 3 sudut (depan, kiri, kanan).
class ScanPhotoScreen extends StatefulWidget {
  const ScanPhotoScreen({super.key});

  static const _order = [
    SelfieAngle.front,
    SelfieAngle.left,
    SelfieAngle.right,
  ];

  @override
  State<ScanPhotoScreen> createState() => _ScanPhotoScreenState();
}

class _ScanPhotoScreenState extends State<ScanPhotoScreen> {
  final _scroll = ScrollController();
  final _continueKey = GlobalKey();
  final _rootKey = GlobalKey();

  bool _coachArmed = false;
  bool _showCoach = false;
  Rect? _highlightRect;
  int _lastDone = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _open(SelfieAngle angle) {
    context.push('/scan/capture?angle=${angle.name}');
  }

  void _continue(ScanState state) {
    if (!state.session.hasAllPhotos) {
      showHint(context, 'Ambil ketiga foto wajah terlebih dahulu.');
      return;
    }
    setState(() => _showCoach = false);
    context.read<ScanCubit>().continueToInterview();
    context.go('/scan/interview');
  }

  void _showGuide() {
    showOverlay<void>(
      context,
      const DialogConfiguration(),
      builder: (dialogContext) => AlertDialog(
        title: const Text('Panduan Ulang Foto'),
        content: const Text(
          'Hapus makeup dan lepas kacamata, pastikan rambut tidak menutupi '
          'wajah, gunakan ekspresi netral, dan cari pencahayaan yang cukup.',
        ),
        actions: [
          OutlineButton(
            onPressed: () {
              closeOverlay(dialogContext);
              context.read<ScanCubit>().startUpload();
              context.push('/scan/upload');
            },
            child: const Text('Unggah dari Galeri'),
          ),
          PrimaryButton(
            onPressed: () => closeOverlay(dialogContext),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _onDoneChanged(int done) {
    if (done < 3) {
      _lastDone = done;
      return;
    }
    // Trigger sekali saat baru lengkap (2 → 3), bukan tiap rebuild.
    if (_lastDone < 3 && !_coachArmed) {
      _coachArmed = true;
      _lastDone = done;
      WidgetsBinding.instance.addPostFrameCallback((_) => _runCoachSequence());
      return;
    }
    _lastDone = done;
  }

  Future<void> _runCoachSequence() async {
    if (!mounted || !_scroll.hasClients) return;

    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final box =
        _continueKey.currentContext?.findRenderObject() as RenderBox?;
    final rootBox =
        _rootKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || rootBox == null) return;

    // Koordinat relatif root Stack (nutupin scaffold + bottom nav).
    final global = box.localToGlobal(Offset.zero);
    final local = rootBox.globalToLocal(global);
    setState(() {
      _highlightRect = local & box.size;
      _showCoach = true;
    });
  }

  /// Nama sisi yang harus selesai dulu agar [angle] bisa diambil.
  static String _lockedBy(SelfieAngle angle, SelfieAngle? active) {
    return switch (angle) {
      SelfieAngle.front => '',
      SelfieAngle.left => 'tampak depan',
      SelfieAngle.right =>
        active == SelfieAngle.front ? 'tampak depan' : 'sisi kiri',
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanCubit, ScanState>(
      listenWhen: (prev, next) {
        int count(ScanSession s) => ScanPhotoScreen._order
            .where((a) => s.pathFor(a) != null)
            .length;
        return count(prev.session) != count(next.session);
      },
      listener: (context, state) {
        final done = ScanPhotoScreen._order
            .where((a) => state.session.pathFor(a) != null)
            .length;
        _onDoneChanged(done);
      },
      builder: (context, state) {
        final session = state.session;
        final done = ScanPhotoScreen._order
            .where((a) => session.pathFor(a) != null)
            .length;
        final active = ScanPhotoScreen._order
            .where((a) => session.pathFor(a) == null)
            .firstOrNull;

        return Stack(
          key: _rootKey,
          fit: StackFit.expand,
          children: [
            Scaffold(
              backgroundColor: AppColors.page,
              footers: [
                AppBottomNav(
                  currentIndex: NavIndex.photo,
                  onChanged: (index) => handleBottomNavTap(
                    context,
                    index,
                    current: NavIndex.photo,
                  ),
                ),
              ],
              child: SoftPageBackground(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(height: AppHeader.barHeight(context) + 6),
                        Expanded(
                          child: ListView(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            children: [
                              _StepProgress(done: done),
                              const Gap(20),
                              Text(
                                'Ambil 3 Sudut Foto Wajah',
                                style: appFont(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  height: 1.2,
                                ),
                              ),
                              const Gap(8),
                              Text(
                                'Posisikan wajah Anda pada pencahayaan alami tanpa '
                                'makeup atau filter untuk hasil kalkulasi skala GEA '
                                'yang akurat.',
                                style: appFont(
                                  fontSize: 13.5,
                                  color: AppColors.inkMuted,
                                  height: 1.5,
                                ),
                              ),
                              const Gap(18),
                              for (final angle in ScanPhotoScreen._order) ...[
                                _AngleCard(
                                  angle: angle,
                                  path: session.pathFor(angle),
                                  isActive: angle == active,
                                  lockedBy: _lockedBy(angle, active),
                                  onTap: () => _open(angle),
                                  onLockedTap: () => showHint(
                                    context,
                                    'Selesaikan ${_lockedBy(angle, active)} terlebih '
                                    'dahulu.',
                                  ),
                                ),
                                const Gap(12),
                              ],
                              const Gap(4),
                              const _QualityProtocol(),
                              const Gap(12),
                              const _GeaTip(),
                              const Gap(20),
                              KeyedSubtree(
                                key: _continueKey,
                                child: AppButton(
                                  label: 'Lanjut ke Kuesioner (Langkah 2)',
                                  trailingIcon: LucideIcons.arrowRight,
                                  height: 48,
                                  fontSize: 14,
                                  dimmed: !session.hasAllPhotos,
                                  onTap: () => _continue(state),
                                ),
                              ),
                              const Gap(10),
                              AppButton(
                                label: 'Panduan Ulang Foto',
                                leading: const Icon(
                                  LucideIcons.circleHelp,
                                  size: 16,
                                  color: AppColors.ink,
                                ),
                                tonal: true,
                                height: 44,
                                fontSize: 13,
                                onTap: _showGuide,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AppHeader(backgroundColor: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
            // Di atas scaffold supaya bottom nav ikut gelap.
            if (_showCoach && _highlightRect != null)
              Positioned.fill(
                child: SpotlightCoach(
                  target: _highlightRect!,
                  title: 'Lanjut ke langkah berikutnya',
                  body:
                      'Ketiga sudut sudah siap. Ketuk tombol ini untuk '
                      'masuk ke interview singkat (langkah 2).',
                  onDismiss: () => setState(() => _showCoach = false),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ──────────────────────────── Progress ────────────────────────────

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.done});

  final int done;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Langkah 1 dari 3: Pengambilan Foto',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: appFont(fontSize: 11, color: AppColors.inkMuted),
              ),
            ),
            const Gap(8),
            _SmallPill(
              label: '$done / 3 Selesai',
              background: AppColors.brandSoft,
              foreground: AppColors.brand,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
        const Gap(8),
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < done ? AppColors.brand : AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (i != 2) const Gap(6),
            ],
          ],
        ),
      ],
    );
  }
}

/// Pil kecil berisi teks (status kartu, penghitung, dll).
class _SmallPill extends StatelessWidget {
  const _SmallPill({
    required this.label,
    required this.background,
    required this.foreground,
    this.leading,
    this.fontWeight = FontWeight.w600,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Widget? leading;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const Gap(4)],
          Text(
            label,
            style: appFont(
              fontSize: 10,
              fontWeight: fontWeight,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────── Kartu sudut ────────────────────────────

class _AngleInfo {
  const _AngleInfo(this.title, this.detail, this.savedNote, this.hint);

  final String title;
  final String detail;
  final String savedNote;
  final String hint;
}

const _info = <SelfieAngle, _AngleInfo>{
  SelfieAngle.front: _AngleInfo(
    'Tampak Depan',
    'Frontal',
    'Sudut frontal 90° tegak lurus',
    'Hadapkan wajah lurus ke kamera di dalam oval.',
  ),
  SelfieAngle.left: _AngleInfo(
    'Sisi Kiri',
    'Profil 45° Kiri',
    'Profil 45° sisi kiri wajah',
    'Hadapkan wajah 45° ke kanan untuk merekam pipi kiri.',
  ),
  SelfieAngle.right: _AngleInfo(
    'Sisi Kanan',
    'Profil 45° Kanan',
    'Profil 45° sisi kanan wajah',
    'Hadapkan wajah 45° ke kiri untuk merekam pipi kanan.',
  ),
};

class _AngleCard extends StatelessWidget {
  const _AngleCard({
    required this.angle,
    required this.path,
    required this.isActive,
    required this.lockedBy,
    required this.onTap,
    required this.onLockedTap,
  });

  final SelfieAngle angle;
  final String? path;
  final bool isActive;
  final String lockedBy;
  final VoidCallback onTap;
  final VoidCallback onLockedTap;

  @override
  Widget build(BuildContext context) {
    final info = _info[angle]!;

    if (path != null) {
      return _SavedCard(info: info, path: path!, onTap: onTap);
    }
    if (isActive) {
      return _ActiveCard(info: info, onTap: onTap);
    }
    return _LockedCard(
      info: info,
      note: 'Tersedia setelah $lockedBy terunggah',
      onTap: onLockedTap,
    );
  }
}

/// Foto sudah tersimpan.
class _SavedCard extends StatelessWidget {
  const _SavedCard({
    required this.info,
    required this.path,
    required this.onTap,
  });

  final _AngleInfo info;
  final String path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftSurface(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: kIsWeb
                      ? const ColoredBox(color: AppColors.brandSoft)
                      : Image.file(
                          File(path),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const ColoredBox(color: AppColors.brandSoft),
                        ),
                ),
                Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      size: 14,
                      color: AppColors.brand,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: info.title,
                        style: appFont(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: '  (${info.detail.split(' ').first})',
                        style: appFont(
                          fontSize: 11,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(3),
                Text(
                  info.savedNote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: appFont(fontSize: 11, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          const Gap(8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SmallPill(
                label: 'Tersimpan',
                background: AppColors.brandSoft,
                foreground: AppColors.brand,
                leading: const Icon(
                  LucideIcons.circleCheck,
                  size: 12,
                  color: AppColors.brand,
                ),
              ),
              const Gap(8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.rotateCw,
                    size: 12,
                    color: AppColors.inkMuted,
                  ),
                  const Gap(4),
                  Text(
                    'Ganti',
                    style: appFont(fontSize: 11, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sudut yang sedang diambil — area putus-putus untuk membuka kamera.
class _ActiveCard extends StatelessWidget {
  const _ActiveCard({required this.info, required this.onTap});

  final _AngleInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SoftSurface(
      padding: const EdgeInsets.all(14),
      border: Border.all(color: AppColors.brandLight, width: 1.4),
      onTap: onTap,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${info.title} (${info.detail})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appFont(fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                ),
                const Gap(8),
                const _SmallPill(
                  label: 'Siap Diambil',
                  background: AppColors.brand,
                  foreground: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ],
            ),
            const Gap(10),
            CustomPaint(
              painter: _DashedRRectPainter(
                color: AppColors.brandLight,
                radius: 12,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.muted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.camera,
                        size: 18,
                        color: AppColors.brand,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Ketuk untuk Buka Kamera',
                      style: appFont(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brand,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      info.hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: appFont(fontSize: 10, color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    );
  }
}

/// Sudut yang belum bisa diambil.
class _LockedCard extends StatelessWidget {
  const _LockedCard({
    required this.info,
    required this.note,
    required this.onTap,
  });

  final _AngleInfo info;
  final String note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.72,
      child: SoftSurface(
        padding: const EdgeInsets.all(12),
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.brandSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                LucideIcons.lock,
                size: 18,
                color: AppColors.inkMuted,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: info.title,
                          style: appFont(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkMuted,
                          ),
                        ),
                        TextSpan(
                          text: '  (${info.detail})',
                          style: appFont(
                            fontSize: 11,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(3),
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: appFont(fontSize: 11, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            const Gap(8),
            const _SmallPill(
              label: 'Menunggu',
              background: AppColors.muted,
              foreground: AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Garis tepi putus-putus untuk rounded-rect.
class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}

// ──────────────────────────── Panduan ────────────────────────────

class _QualityProtocol extends StatelessWidget {
  const _QualityProtocol();

  static const _rules = <(String, String)>[
    (
      'Pencahayaan cukup:',
      'Gunakan sinar matahari pagi atau lampu terang, hindari bayangan '
          'backlight.',
    ),
    (
      'Wajah bersih:',
      'Bebas dari riasan tebal, bedak, krim tabir surya berpewarna, atau '
          'filter kamera.',
    ),
    (
      'Jarak ideal:',
      'Rentangkan kamera sejauh 30–40 cm dengan fokus tajam pada lesi wajah.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SoftSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.badgeCheck,
                size: 18,
                color: AppColors.brand,
              ),
              const Gap(8),
              Text(
                'Protokol Kualitas Foto Medis',
                style: appFont(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const Gap(14),
          for (var i = 0; i < _rules.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    LucideIcons.circleCheck,
                    size: 16,
                    color: AppColors.brand,
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${_rules[i].$1} ',
                          style: appFont(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        TextSpan(
                          text: _rules[i].$2,
                          style: appFont(
                            fontSize: 13,
                            color: AppColors.inkMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (i != _rules.length - 1) const Gap(12),
          ],
        ],
      ),
    );
  }
}

class _GeaTip extends StatelessWidget {
  const _GeaTip();

  @override
  Widget build(BuildContext context) {
    return SoftSurface(
      color: AppColors.brandSoft,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.lightbulb,
              size: 18,
              color: AppColors.brand,
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Algoritma GEA',
                  style: appFont(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const Gap(3),
                Text(
                  'Foto beresolusi tajam meningkatkan akurasi deteksi '
                  'komedo & papula hingga 94.8%.',
                  style: appFont(
                    fontSize: 12,
                    color: AppColors.inkMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
