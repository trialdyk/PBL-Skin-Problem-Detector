import 'package:pbl_skin_problem_detector/presentation/theme/app_colors.dart';
import 'package:pbl_skin_problem_detector/presentation/theme/app_font.dart';
import 'package:pbl_skin_problem_detector/presentation/widgets/app_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Bubble bot dengan efek streaming teks (chunk demi chunk).
class ChatBubbleBot extends StatefulWidget {
  const ChatBubbleBot({
    super.key,
    required this.text,
    this.stream = true,
    this.onStreamComplete,
  });

  final String text;

  /// Jika false, tampilkan teks penuh langsung (pesan lama).
  final bool stream;
  final VoidCallback? onStreamComplete;

  @override
  State<ChatBubbleBot> createState() => _ChatBubbleBotState();
}

class _ChatBubbleBotState extends State<ChatBubbleBot> {
  String _visible = '';
  bool _done = false;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    if (widget.stream) {
      _startStream();
    } else {
      _visible = widget.text;
      _done = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onStreamComplete?.call();
      });
    }
  }

  @override
  void didUpdateWidget(covariant ChatBubbleBot oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Bukan pesan aktif lagi → batalkan stream, jangan panggil onComplete.
    if (oldWidget.stream && !widget.stream) {
      _cancelled = true;
      _visible = widget.text;
      _done = true;
      return;
    }
    if (oldWidget.text != widget.text) {
      _cancelled = true;
      _visible = widget.stream ? '' : widget.text;
      _done = !widget.stream;
      if (widget.stream) {
        _cancelled = false;
        _startStream();
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onStreamComplete?.call();
        });
      }
    }
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  Future<void> _startStream() async {
    final full = widget.text;
    final chunks = _chunkText(full);
    _visible = '';
    _done = false;

    for (final chunk in chunks) {
      if (!mounted || _cancelled) return;
      setState(() => _visible += chunk);
      final delay = chunk.trim().isEmpty
          ? 18
          : chunk.length >= 4
              ? 36
              : 24;
      await Future<void>.delayed(Duration(milliseconds: delay));
    }

    if (!mounted || _cancelled) return;
    setState(() {
      _visible = full;
      _done = true;
    });
    // Post-frame supaya tidak setState parent di tengah build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_cancelled) widget.onStreamComplete?.call();
    });
  }

  /// Pecah teks jadi chunk kecil (mirip streaming AI).
  static List<String> _chunkText(String text) {
    if (text.isEmpty) return const [];
    final chunks = <String>[];
    final wordRe = RegExp(r'\S+\s*|\s+');
    for (final match in wordRe.allMatches(text)) {
      final word = match.group(0)!;
      if (word.length <= 5) {
        chunks.add(word);
      } else {
        // Kata panjang dipecah 2–3 huruf.
        var i = 0;
        while (i < word.length) {
          final end = (i + 2).clamp(0, word.length);
          chunks.add(word.substring(i, end));
          i = end;
        }
      }
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    return _ChatAppear(
      fromLeft: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14, right: 36),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const IconTile(
              icon: LucideIcons.sparkles,
              background: AppColors.brandSoft,
              foreground: AppColors.brand,
              size: 34,
              iconSize: 16,
              circle: true,
            ),
            const Gap(10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    bottomLeft: Radius.circular(6),
                  ),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text.rich(
                  TextSpan(
                    style: appFont(
                      fontSize: 14,
                      color: AppColors.ink,
                      height: 1.45,
                    ),
                    children: [
                      TextSpan(text: _visible),
                      if (!_done)
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: _StreamingCaret(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreamingCaret extends StatefulWidget {
  @override
  State<_StreamingCaret> createState() => _StreamingCaretState();
}

class _StreamingCaretState extends State<_StreamingCaret>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _blink,
      child: Container(
        margin: const EdgeInsets.only(left: 1),
        width: 2,
        height: 14,
        decoration: BoxDecoration(
          color: AppColors.brand,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

class ChatBubbleUser extends StatelessWidget {
  const ChatBubbleUser({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return _ChatAppear(
      fromLeft: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14, left: 56),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              style: appFont(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
                height: 1.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fade + slide masuk untuk bubble chat.
class _ChatAppear extends StatefulWidget {
  const _ChatAppear({required this.child, required this.fromLeft});

  final Widget child;
  final bool fromLeft;

  @override
  State<_ChatAppear> createState() => _ChatAppearState();
}

class _ChatAppearState extends State<_ChatAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: Offset(widget.fromLeft ? -0.06 : 0.06, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class ChatTypingBubble extends StatefulWidget {
  const ChatTypingBubble({super.key});

  @override
  State<ChatTypingBubble> createState() => _ChatTypingBubbleState();
}

class _ChatTypingBubbleState extends State<ChatTypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ChatAppear(
      fromLeft: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            const IconTile(
              icon: LucideIcons.sparkles,
              background: AppColors.brandSoft,
              foreground: AppColors.brand,
              size: 34,
              iconSize: 16,
              circle: true,
            ),
            const Gap(10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const Gap(5),
                        _TypingDot(phase: i / 3, controller: _pulse),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  const _TypingDot({required this.phase, required this.controller});

  final double phase;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    // Wave bounce: tiap titik delay beda.
    final t = (controller.value + phase) % 1.0;
    final bounce = Curves.easeInOut.transform(
      t < 0.5 ? t * 2 : (1 - t) * 2,
    );
    final y = -4.0 * bounce;
    final scale = 0.85 + 0.25 * bounce;
    final alpha = 0.35 + 0.65 * bounce;

    return Transform.translate(
      offset: Offset(0, y),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: alpha),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Progress interview: "Pertanyaan x dari n" + bar brand.
class InterviewStepProgress extends StatelessWidget {
  const InterviewStepProgress({
    super.key,
    required this.currentStep,
    this.total = 5,
  });

  final int currentStep;
  final int total;

  @override
  Widget build(BuildContext context) {
    final step = currentStep.clamp(0, total);
    final shown = (step + 1).clamp(1, total);
    final progress = (step / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Pertanyaan $shown dari $total',
                style: appFont(fontSize: 12, color: AppColors.inkMuted),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: appFont(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
          ],
        ),
        const Gap(10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.brandSoft,
            color: AppColors.brand,
          ),
        ),
      ],
    );
  }
}
