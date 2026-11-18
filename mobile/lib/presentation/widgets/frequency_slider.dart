import 'package:flutter/services.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class FrequencyOptionItem {
  const FrequencyOptionItem({
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.isOften,
  });

  final String label;
  final String shortLabel;
  final String description;
  final bool isOften;
}

/// Slider 5 titik yang bisa di-drag / tap untuk frekuensi konsumsi makanan tidak sehat.
class FrequencySlider extends StatefulWidget {
  const FrequencySlider({
    super.key,
    this.initialIndex = 2,
    required this.onConfirm,
  });

  final int initialIndex;
  final void Function(FrequencyOptionItem option) onConfirm;

  static const List<FrequencyOptionItem> defaultOptions = [
    FrequencyOptionItem(
      label: 'Tidak Pernah',
      shortLabel: 'Tidak\nPernah',
      description: 'Menghindari gorengan, makanan manis, & makanan instan',
      isOften: false,
    ),
    FrequencyOptionItem(
      label: 'Jarang',
      shortLabel: 'Jarang',
      description: 'Sekitar 1 kali seminggu atau kurang',
      isOften: false,
    ),
    FrequencyOptionItem(
      label: 'Kadang',
      shortLabel: 'Kadang',
      description: 'Sekitar 2–3 kali dalam seminggu',
      isOften: false,
    ),
    FrequencyOptionItem(
      label: 'Sering',
      shortLabel: 'Sering',
      description: '4–5 kali dalam seminggu',
      isOften: true,
    ),
    FrequencyOptionItem(
      label: 'Sangat Sering',
      shortLabel: 'Sangat\nSering',
      description: 'Hampir setiap hari mengonsumsi makanan pemicu',
      isOften: true,
    ),
  ];

  @override
  State<FrequencySlider> createState() => _FrequencySliderState();
}

class _FrequencySliderState extends State<FrequencySlider> {
  late int _selectedIndex;
  bool _isDragging = false;
  double? _dragFraction;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, FrequencySlider.defaultOptions.length - 1);
  }

  void _updateIndex(int newIndex) {
    if (newIndex != _selectedIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedIndex = newIndex;
      });
    }
  }

  void _handleDrag(double localDx, double totalWidth, double padding) {
    final effectiveWidth = totalWidth - (2 * padding);
    if (effectiveWidth <= 0) return;
    final clampedX = (localDx - padding).clamp(0.0, effectiveWidth);
    final fraction = clampedX / effectiveWidth;
    final nearest = (fraction * (FrequencySlider.defaultOptions.length - 1)).round();
    setState(() {
      _dragFraction = fraction;
    });
    if (nearest != _selectedIndex) {
      _updateIndex(nearest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = FrequencySlider.defaultOptions;
    final count = options.length;
    final activeOption = options[_selectedIndex];

    const double horizontalPadding = 32.0;
    const double thumbRadius = 14.0;
    const double dotRadius = 7.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Box informasi pilihan yang sedang aktif (Pink Card)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.page,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.brandLight.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandSoft.withValues(alpha: 0.6),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFEEF3), Color(0xFFFFDDE7)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.brandLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.brand,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      activeOption.label,
                      style: appFont(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              Text(
                activeOption.description,
                textAlign: TextAlign.center,
                style: appFont(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkMuted,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        const Gap(16),

        // Track Slider interaktif dengan 5 dots dan label di bawahnya
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final effectiveWidth = totalWidth - (2 * horizontalPadding);
            final double currentFraction = _isDragging && _dragFraction != null
                ? _dragFraction!
                : _selectedIndex / (count - 1);

            final double thumbX = horizontalPadding + (currentFraction * effectiveWidth);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) {
                setState(() => _isDragging = true);
                _handleDrag(details.localPosition.dx, totalWidth, horizontalPadding);
              },
              onHorizontalDragUpdate: (details) {
                _handleDrag(details.localPosition.dx, totalWidth, horizontalPadding);
              },
              onHorizontalDragEnd: (_) {
                setState(() {
                  _isDragging = false;
                  _dragFraction = null;
                });
              },
              onTapDown: (details) {
                _handleDrag(details.localPosition.dx, totalWidth, horizontalPadding);
                setState(() {
                  _dragFraction = null;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    // Area Track + Dots + Thumb
                    SizedBox(
                      height: 40,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          // 1. Garis dasar track pink (inactive track)
                          Positioned(
                            left: horizontalPadding,
                            right: horizontalPadding,
                            top: (40 - 6) / 2,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD5E2),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 0.8,
                                ),
                              ),
                            ),
                          ),

                          // 2. Garis aktif gradien pink (active track)
                          Positioned(
                            left: horizontalPadding,
                            width: (thumbX - horizontalPadding).clamp(0.0, effectiveWidth),
                            top: (40 - 6) / 2,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF472B6),
                                    AppColors.brand,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.brand.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // 3. Titik-titik (5 Dots sesuai diagram)
                          for (int i = 0; i < count; i++) ...[
                            Builder(
                              builder: (context) {
                                final dotX = horizontalPadding + (i / (count - 1)) * effectiveWidth;
                                final isPassed = i <= _selectedIndex;

                                return Positioned(
                                  left: dotX - dotRadius,
                                  top: (40 / 2) - dotRadius,
                                  child: Container(
                                    width: dotRadius * 2,
                                    height: dotRadius * 2,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isPassed ? AppColors.brand : AppColors.white,
                                      border: Border.all(
                                        color: isPassed ? AppColors.brand : AppColors.brandLight,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.brand.withValues(alpha: 0.15),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],

                          // 4. Thumb draggable pink (lingkaran yang digeser)
                          AnimatedPositioned(
                            duration: _isDragging ? Duration.zero : const Duration(milliseconds: 160),
                            curve: Curves.easeOutCubic,
                            left: thumbX - thumbRadius,
                            top: (40 / 2) - thumbRadius,
                            child: AnimatedScale(
                              scale: _isDragging ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 120),
                              child: Container(
                                width: thumbRadius * 2,
                                height: thumbRadius * 2,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFE11D48),
                                      AppColors.brand,
                                    ],
                                  ),
                                  border: Border.all(color: AppColors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brand.withValues(alpha: 0.45),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(6),

                    // Label teks presisi di bawah masing-masing bulatan
                    SizedBox(
                      height: 32,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (int i = 0; i < count; i++) ...[
                            Builder(
                              builder: (context) {
                                final isSelected = i == _selectedIndex;
                                final dotX = horizontalPadding + (i / (count - 1)) * effectiveWidth;
                                const colWidth = 64.0;
                                final left = (dotX - (colWidth / 2)).clamp(0.0, totalWidth - colWidth);

                                return Positioned(
                                  left: left,
                                  top: 0,
                                  width: colWidth,
                                  child: GestureDetector(
                                    onTap: () => _updateIndex(i),
                                    behavior: HitTestBehavior.opaque,
                                    child: Text(
                                      options[i].shortLabel,
                                      textAlign: TextAlign.center,
                                      style: appFont(
                                        fontSize: 10.5,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? AppColors.brand : AppColors.inkMuted,
                                        height: 1.15,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const Gap(16),

        // Tombol konfirmasi
        AppButton(
          label: 'Konfirmasi (${activeOption.label})',
          trailingIcon: LucideIcons.arrowRight,
          height: 48,
          fontSize: 14,
          onTap: () {
            widget.onConfirm(activeOption);
          },
        ),
      ],
    );
  }
}
