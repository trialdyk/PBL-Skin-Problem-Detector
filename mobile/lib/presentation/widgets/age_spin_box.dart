import 'dart:async';
import 'package:flutter/services.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Komponen Spin Box / Numeric Up-Down untuk memilih umur pengguna pada sesi wawancara.
class AgeSpinBox extends StatefulWidget {
  const AgeSpinBox({
    super.key,
    this.initialValue = 20,
    this.min = 10,
    this.max = 100,
    required this.onConfirm,
  });

  final int initialValue;
  final int min;
  final int max;
  final ValueChanged<int> onConfirm;

  @override
  State<AgeSpinBox> createState() => _AgeSpinBoxState();
}

class _AgeSpinBoxState extends State<AgeSpinBox> {
  late int _age;
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _age = widget.initialValue.clamp(widget.min, widget.max);
    _controller = TextEditingController(text: '$_age');
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _normalizeInput();
    }
  }

  int _normalizeInput() {
    final parsed = int.tryParse(_controller.text.trim());
    final finalAge = (parsed ?? _age).clamp(widget.min, widget.max);
    _updateAge(finalAge);
    return finalAge;
  }

  void _updateAge(int newAge) {
    if (_age != newAge || _controller.text != '$newAge') {
      setState(() {
        _age = newAge;
        _controller.text = '$_age';
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
    }
  }

  void _increment() {
    if (_age < widget.max) {
      HapticFeedback.selectionClick();
      _updateAge(_age + 1);
    }
  }

  void _decrement() {
    if (_age > widget.min) {
      HapticFeedback.selectionClick();
      _updateAge(_age - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canDecrement = _age > widget.min;
    final canIncrement = _age < widget.max;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.page,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tombol Kurang (-) dengan hold-to-repeat
              _StepButton(
                icon: LucideIcons.minus,
                enabled: canDecrement,
                onStep: _decrement,
              ),

              // Bagian input & display angka
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        textAlign: TextAlign.center,
                        border: const Border(),
                        padding: EdgeInsets.zero,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        onChanged: (val) {
                          final parsed = int.tryParse(val);
                          if (parsed != null) {
                            setState(() {
                              _age = parsed.clamp(widget.min, widget.max);
                            });
                          }
                        },
                        onSubmitted: (_) {
                          _focusNode.unfocus();
                          _normalizeInput();
                        },
                        style: appFont(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brand,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Text(
                      'tahun',
                      style: appFont(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Tombol Tambah (+) dengan hold-to-repeat
              _StepButton(
                icon: LucideIcons.plus,
                enabled: canIncrement,
                onStep: _increment,
              ),
            ],
          ),
        ),
        const Gap(6),
        Center(
          child: Text(
            'Rentang umur: ${widget.min} – ${widget.max} tahun',
            style: appFont(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.inkMuted.withValues(alpha: 0.7),
            ),
          ),
        ),
        const Gap(10),
        AppButton(
          label: 'Konfirmasi ($_age tahun)',
          trailingIcon: LucideIcons.arrowRight,
          height: 48,
          fontSize: 14,
          onTap: () {
            _focusNode.unfocus();
            final finalAge = _normalizeInput();
            widget.onConfirm(finalAge);
          },
        ),
      ],
    );
  }
}

class _StepButton extends StatefulWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onStep,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onStep;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  bool _pressed = false;
  Timer? _initialHoldTimer;
  Timer? _repeatTimer;

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }

  void _stopTimers() {
    _initialHoldTimer?.cancel();
    _initialHoldTimer = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _startContinuousHold() {
    _stopTimers();
    _initialHoldTimer = Timer(const Duration(milliseconds: 320), () {
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 75), (_) {
        if (!mounted || !widget.enabled) {
          _stopTimers();
          return;
        }
        widget.onStep();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled
          ? (_) {
              setState(() => _pressed = true);
              _startContinuousHold();
            }
          : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              _stopTimers();
            }
          : null,
      onTapCancel: () {
        if (mounted) setState(() => _pressed = false);
        _stopTimers();
      },
      onTap: widget.enabled ? widget.onStep : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: widget.enabled
                ? (_pressed ? AppColors.brandSoft : AppColors.white)
                : AppColors.muted.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.enabled
                  ? (_pressed ? AppColors.brandLight : AppColors.border)
                  : AppColors.border.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            widget.icon,
            size: 20,
            color: widget.enabled
                ? AppColors.brand
                : AppColors.inkMuted.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}
