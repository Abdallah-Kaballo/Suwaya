import 'dart:math' show pi, cos, sin;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../../models/task_model.dart';
import '../../tasks/tasks_provider.dart';
import '../pomodoro_provider.dart';

String trPomodoro(
  BuildContext context,
  String key,
  String arFallback,
  String enFallback,
) {
  final translated = key.tr();
  if (translated != key) return translated;
  return context.locale.languageCode == 'ar' ? arFallback : enFallback;
}

class LinkedTaskBar extends ConsumerWidget {
  final Color accentColor;
  final bool isCompact;

  const LinkedTaskBar({
    super.key,
    required this.accentColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedTaskId = ref.watch(
      pomodoroProvider.select((s) => s.linkedTaskId),
    );
    final tasksState = ref.watch(tasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    TaskModel? linkedTask;
    if (linkedTaskId != null) {
      for (final t in tasksState.allTasks) {
        if (t.id == linkedTaskId) {
          linkedTask = t;
          break;
        }
      }
    }

    return GestureDetector(
      onTap: () => _showTaskPickerSheet(context, ref),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isCompact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: linkedTask != null
                ? accentColor.withValues(alpha: 0.45)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.target,
              size: 16,
              color: linkedTask != null
                  ? accentColor
                  : textColor.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                linkedTask != null
                    ? linkedTask.title
                    : trPomodoro(
                        context,
                        'pomodoro.select_focus_task',
                        'اختر مهمة للتركيز عليها (اختياري)',
                        'Select a task to focus on (optional)',
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: linkedTask != null
                      ? textColor
                      : textColor.withValues(alpha: 0.55),
                  fontSize: 13,
                  fontWeight: linkedTask != null
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ),
            if (linkedTask != null) ...[
              const SizedBox(width: 10),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.heavyImpact();
                  ref
                      .read(tasksProvider.notifier)
                      .toggleTaskStatus(linkedTask!);
                  ref.read(pomodoroProvider.notifier).selectLinkedTask(null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        trPomodoro(
                          context,
                          'pomodoro.task_completed_msg',
                          'تم إنجاز المهمة بنجاح! 🎯',
                          'Task completed! 🎯',
                        ),
                      ),
                      backgroundColor: const Color(0xFF2E7D32),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.check,
                        size: 13,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'common.done'.tr(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 6),
              Icon(
                LucideIcons.chevron_down,
                size: 15,
                color: textColor.withValues(alpha: 0.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTaskPickerSheet(BuildContext context, WidgetRef ref) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;

    final todayTasks = ref.read(tasksProvider).todayTasks;
    final currentLinkedId = ref.read(pomodoroProvider).linkedTaskId;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                trPomodoro(
                  context,
                  'pomodoro.select_focus_task',
                  'اختر مهمة للتركيز عليها',
                  'Select a Task to Focus On',
                ),
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (todayTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'tasks.empty_tasks'.tr(),
                    style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: todayTasks.length,
                    itemBuilder: (context, index) {
                      final task = todayTasks[index];
                      final isSelected = task.id == currentLinkedId;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? LucideIcons.circle_check
                              : LucideIcons.circle,
                          color: isSelected ? primaryColor : Colors.grey,
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          task.category.displayName,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(pomodoroProvider.notifier)
                              .selectLinkedTask(task.id);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              if (currentLinkedId != null) ...[
                const Divider(),
                TextButton.icon(
                  onPressed: () {
                    ref.read(pomodoroProvider.notifier).selectLinkedTask(null);
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(LucideIcons.x, color: Colors.redAccent),
                  label: Text(
                    trPomodoro(
                      context,
                      'pomodoro.unlink_task',
                      'إلغاء ربط المهمة',
                      'Unlink Task',
                    ),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class LargeZenTimerDial extends ConsumerStatefulWidget {
  final double progress;
  final String minutesStr;
  final String secondsStr;
  final String phaseLabel;
  final bool isBreak;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onDoubleTap;
  final double? forcedSize;

  const LargeZenTimerDial({
    super.key,
    required this.progress,
    required this.minutesStr,
    required this.secondsStr,
    required this.phaseLabel,
    required this.isBreak,
    required this.activeColor,
    required this.isDark,
    required this.onDoubleTap,
    this.forcedSize,
  });

  @override
  ConsumerState<LargeZenTimerDial> createState() => _LargeZenTimerDialState();
}

class _LargeZenTimerDialState extends ConsumerState<LargeZenTimerDial>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final Animation<double> _breathAnim;

  late final AnimationController _progressController;
  late Animation<double> _progressAnim;
  double _lastTargetProgress = 0.0;

  late final AnimationController _phaseTransitionController;
  late final Animation<double> _phaseScaleAnim;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    )..repeat(reverse: true);

    _breathAnim = CurvedAnimation(
      parent: _breathController,
      curve: Curves.easeInOutSine,
    );

    _lastTargetProgress = widget.progress.clamp(0.0, 1.0);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _progressAnim =
        Tween<double>(
          begin: _lastTargetProgress,
          end: _lastTargetProgress,
        ).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );

    _phaseTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _phaseScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 55,
      ),
    ]).animate(_phaseTransitionController);
  }

  @override
  void didUpdateWidget(covariant LargeZenTimerDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newTarget = widget.progress.clamp(0.0, 1.0);
    if ((newTarget - _lastTargetProgress).abs() > 0.0001) {
      _progressAnim = Tween<double>(begin: _progressAnim.value, end: newTarget)
          .animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeOutCubic,
            ),
          );
      _progressController.forward(from: 0.0);
      _lastTargetProgress = newTarget;
    }

    if (widget.isBreak != oldWidget.isBreak ||
        widget.phaseLabel != oldWidget.phaseLabel) {
      _phaseTransitionController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    _progressController.dispose();
    _phaseTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zenMode = ref.watch(pomodoroProvider.select((s) => s.zenMode));
    final isFullScreen = ref.watch(
      pomodoroProvider.select((s) => s.isFullScreen),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width - 40;
        final double dialSize =
            widget.forcedSize ?? (availableWidth * 0.88).clamp(260.0, 390.0);

        final clockColor = widget.isDark
            ? const Color(0xFFF8FAFC)
            : const Color(0xFF0F172A);

        return ScaleTransition(
          scale: _phaseScaleAnim,
          child: AnimatedBuilder(
            animation: Listenable.merge([_breathAnim, _progressAnim]),
            builder: (context, child) {
              // 🌟 النمط الثاني: الرقمي الخالص (Pure Digital Typography)
              if (isFullScreen && zenMode == PomodoroZenMode.digital) {
                return _buildDigitalView(dialSize, clockColor);
              }

              // 🌟 النمط الثالث: النبض المحيطي الهادئ (Ambient Breath Orb)
              if (isFullScreen && zenMode == PomodoroZenMode.ambient) {
                return _buildAmbientView(dialSize, clockColor);
              }

              // 🌟 النمط الأول (الافتراضي): حلقة الصفاء الدقيقة والساحرة (Zen Precision Ring)
              return _buildRingView(dialSize, clockColor);
            },
          ),
        );
      },
    );
  }

  Widget _buildDigitalView(double dialSize, Color clockColor) {
    final progressVal = _progressAnim.value.clamp(0.0, 1.0);
    final percentStr = '${(progressVal * 100).toInt()}%';

    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: dialSize,
        height: dialSize * 0.88,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Big crisp digital typography with subtle glow
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Text(
                  '${widget.minutesStr}:${widget.secondsStr}',
                  style: TextStyle(
                    fontSize: 122,
                    fontWeight: FontWeight.w900,
                    color: clockColor,
                    fontFamily: 'Inter',
                    letterSpacing: 3.5,
                    height: 1.0,
                    fontFeatures: const [ui.FontFeature.tabularFigures()],
                    shadows: [
                      Shadow(
                        color: widget.activeColor.withValues(alpha: 0.28),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Minimalist horizontal progress track
            SizedBox(
              width: dialSize * 0.72,
              child: Column(
                children: [
                  Container(
                    height: 5.5,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: progressVal > 0 ? progressVal : 0.01,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.activeColor.withValues(alpha: 0.8),
                              widget.activeColor,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: widget.activeColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isBreak
                                ? LucideIcons.coffee
                                : LucideIcons.sparkles,
                            color: widget.activeColor,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.phaseLabel,
                            style: TextStyle(
                              color: widget.activeColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                      Text(
                        percentStr,
                        style: TextStyle(
                          color: clockColor.withValues(alpha: 0.45),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientView(double dialSize, Color clockColor) {
    final breath = _breathAnim.value; // 0.0 -> 1.0
    final scale = 0.94 + (0.09 * breath);
    final auraAlpha = 0.16 + (0.16 * breath);

    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: dialSize,
          height: dialSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.activeColor.withValues(alpha: auraAlpha),
                widget.activeColor.withValues(alpha: auraAlpha * 0.45),
                widget.activeColor.withValues(alpha: 0.02),
                Colors.transparent,
              ],
              stops: const [0.0, 0.48, 0.78, 1.0],
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            width: dialSize * 0.72,
            height: dialSize * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isDark
                  ? const Color(0xFF0F141C).withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.65),
              border: Border.all(
                color: widget.activeColor.withValues(
                  alpha: 0.22 + 0.18 * breath,
                ),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.activeColor.withValues(alpha: 0.18 * breath),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    '${widget.minutesStr}:${widget.secondsStr}',
                    style: TextStyle(
                      fontSize: 68,
                      fontWeight: FontWeight.w300,
                      color: clockColor.withValues(alpha: 0.95),
                      fontFamily: 'Inter',
                      letterSpacing: 4.0,
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: widget.activeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.activeColor,
                          boxShadow: [
                            BoxShadow(color: widget.activeColor, blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.phaseLabel,
                        style: TextStyle(
                          color: widget.activeColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.locale.languageCode == 'ar'
                      ? 'تنفّس بعمق · وحافظ على سكونك'
                      : 'Breathe deeply · Stay present',
                  style: TextStyle(
                    color: clockColor.withValues(alpha: 0.38),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRingView(double dialSize, Color clockColor) {
    final double timeFontSize = (dialSize * 0.25).clamp(68.0, 98.0);

    return GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: dialSize,
        height: dialSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The Precision Horological Painter
            SizedBox(
              width: dialSize,
              height: dialSize,
              child: CustomPaint(
                painter: ZenRingPainter(
                  progress: _progressAnim.value,
                  activeColor: widget.activeColor,
                  isDark: widget.isDark,
                  breathValue: _breathAnim.value,
                ),
              ),
            ),
            // Center content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: dialSize * 0.12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Text(
                        '${widget.minutesStr}:${widget.secondsStr}',
                        style: TextStyle(
                          fontSize: timeFontSize,
                          fontWeight: FontWeight.w800,
                          color: clockColor,
                          fontFamily: 'Inter',
                          letterSpacing: 1.5,
                          height: 1.05,
                          fontFeatures: const [ui.FontFeature.tabularFigures()],
                          shadows: [
                            Shadow(
                              color: widget.activeColor.withValues(alpha: 0.20),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.activeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: widget.activeColor.withValues(alpha: 0.25),
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isBreak
                              ? LucideIcons.coffee
                              : LucideIcons.sparkles,
                          color: widget.activeColor,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.phaseLabel,
                          style: TextStyle(
                            color: widget.activeColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ZenRingPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final bool isDark;
  final double breathValue; // 0.0 -> 1.0

  ZenRingPainter({
    required this.progress,
    required this.activeColor,
    required this.isDark,
    required this.breathValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 18;
    if (radius <= 0) return;

    // 1. Subtle smooth track
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.07);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Horological clock ticks around the circle
    const int tickCount = 60;
    final double tickInnerR = radius - 15;
    final double tickOuterR = radius - 10;
    final double majorTickInnerR = radius - 19;

    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < tickCount; i++) {
      final bool isMajor = (i % 5 == 0);
      final double angle = (i * 2 * pi / tickCount) - (pi / 2);
      final double rIn = isMajor ? majorTickInnerR : tickInnerR;
      final p1 = Offset(
        center.dx + cos(angle) * rIn,
        center.dy + sin(angle) * rIn,
      );
      final p2 = Offset(
        center.dx + cos(angle) * tickOuterR,
        center.dy + sin(angle) * tickOuterR,
      );

      final double tickProgress = i / tickCount;
      final bool isElapsed = tickProgress <= progress;

      if (isElapsed) {
        tickPaint.color = activeColor.withValues(alpha: isMajor ? 0.70 : 0.40);
        tickPaint.strokeWidth = isMajor ? 2.0 : 1.2;
      } else {
        tickPaint.color = isDark
            ? Colors.white.withValues(alpha: isMajor ? 0.20 : 0.08)
            : Colors.black.withValues(alpha: isMajor ? 0.18 : 0.07);
        tickPaint.strokeWidth = isMajor ? 1.6 : 0.9;
      }
      canvas.drawLine(p1, p2, tickPaint);
    }

    final double safeProgress = progress.clamp(0.0, 1.0);
    if (safeProgress > 0.002) {
      final double sweepAngle = safeProgress * 2 * pi;
      final arcRect = Rect.fromCircle(center: center, radius: radius);

      // 3. Animated breathing glow layer behind progress arc
      final double glowAlpha = (0.22 + 0.18 * breathValue).clamp(0.0, 1.0);
      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: glowAlpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawArc(arcRect, -pi / 2, sweepAngle, false, glowPaint);

      // 4. Main progress arc
      final sweepGradient = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + sweepAngle,
        colors: [activeColor.withValues(alpha: 0.88), activeColor],
      );

      final progressPaint = Paint()
        ..shader = sweepGradient.createShader(arcRect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9.0
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(arcRect, -pi / 2, sweepAngle, false, progressPaint);

      // 5. Precision Knob at current angle
      final double knobAngle = -pi / 2 + sweepAngle;
      final knobCenter = Offset(
        center.dx + cos(knobAngle) * radius,
        center.dy + sin(knobAngle) * radius,
      );

      // Knob shadow
      canvas.drawCircle(
        knobCenter + const Offset(0, 1.5),
        8.0,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Knob outer ring
      canvas.drawCircle(knobCenter, 7.5, Paint()..color = activeColor);

      // Knob core dot
      canvas.drawCircle(knobCenter, 3.0, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant ZenRingPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.isDark != isDark ||
      old.breathValue != breathValue;
}

// Backwards compatibility alias
class ZenTimerPainter extends ZenRingPainter {
  ZenTimerPainter({
    required super.progress,
    required super.activeColor,
    required super.isDark,
    super.breathValue = 0.5,
  });
}

/// 🎊 نافذة الاحتفال بإتمام جلسة التركيز
void showPomodoroCelebrationDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String title,
  required String subtitle,
  required VoidCallback onContinue,
  VoidCallback? onFinish,
}) {
  HapticFeedback.heavyImpact();
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Celebration',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (ctx, anim1, anim2) {
      return _PomodoroCelebrationContent(
        title: title,
        subtitle: subtitle,
        onContinue: () {
          Navigator.of(ctx).pop();
          onContinue();
        },
        onFinish: onFinish != null
            ? () {
                Navigator.of(ctx).pop();
                onFinish();
              }
            : null,
      );
    },
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: curved,
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
  );
}

class _PomodoroCelebrationContent extends StatefulWidget {
  final String title;
  final String subtitle;
  final VoidCallback onContinue;
  final VoidCallback? onFinish;

  const _PomodoroCelebrationContent({
    required this.title,
    required this.subtitle,
    required this.onContinue,
    this.onFinish,
  });

  @override
  State<_PomodoroCelebrationContent> createState() =>
      _PomodoroCelebrationContentState();
}

class _PomodoroCelebrationContentState
    extends State<_PomodoroCelebrationContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = isDark ? const Color(0xFF1E232F) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Confetti particle overlay
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, _) => CustomPaint(
                    painter: _ConfettiPainter(
                      progress: _confettiController.value,
                    ),
                  ),
                ),
              ),
            ),
            // Dialog card
            Container(
              width: 320,
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.22),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Celebration badge
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withValues(alpha: 0.25),
                          primaryColor.withValues(alpha: 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      LucideIcons.sparkles,
                      color: primaryColor,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.65),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: widget.onContinue,
                      child: Text(
                        trPomodoro(
                          context,
                          'common.continue',
                          'استمرار',
                          'Continue',
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (widget.onFinish != null) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: widget.onFinish,
                      child: Text(
                        trPomodoro(
                          context,
                          'pomodoro.done_for_now',
                          'اكتفيت لليوم',
                          'Done for Now',
                        ),
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.60),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;

  _ConfettiPainter({required this.progress});

  static final List<
    ({double x, double speed, double size, Color color, double rot})
  >
  _particles = List.generate(36, (i) {
    final colors = [
      const Color(0xFFE53935),
      const Color(0xFF64B5F6),
      const Color(0xFF00E676),
      const Color(0xFFFFD54F),
      const Color(0xFFAB47BC),
      const Color(0xFFFF7043),
    ];
    final seed = (i * 37) % 100 / 100.0;
    return (
      x: seed,
      speed: 0.6 + ((i * 13) % 40) / 40.0,
      size: 4.0 + ((i * 7) % 5),
      color: colors[i % colors.length],
      rot: ((i * 23) % 360) * pi / 180,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    for (final p in _particles) {
      final y = (p.speed * progress * size.height * 1.1) - 40;
      final x = p.x * size.width + sin(progress * 4 * pi + p.rot) * 20;
      final alpha = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + progress * 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size * 1.8,
            height: p.size,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}

void showTraditionalSettingsSheet(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceColor = Theme.of(context).cardColor;
  final textColor = isDark ? Colors.white : Colors.black87;
  final primaryColor = Theme.of(context).primaryColor;

  const workOptions = [25, 30, 35, 40, 45, 50, 55, 60];
  const shortBreakOptions = [5, 10];
  const longBreakOptions = [20, 25, 30, 35, 40];
  const cyclesOptions = [1, 2, 3, 4, 5, 6];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final currentSettings = ref
              .watch(pomodoroProvider)
              .traditionalSettings;
          final notifier = ref.read(pomodoroProvider.notifier);

          Widget buildChipSelector({
            required String title,
            required List<int> options,
            required int selectedValue,
            required String unit,
            required ValueChanged<int> onSelect,
          }) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((val) {
                      final isSelected = val == selectedValue;
                      return ChoiceChip(
                        label: Text(unit.isEmpty ? '$val' : '$val $unit'),
                        selected: isSelected,
                        selectedColor: primaryColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? primaryColor : textColor,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          onSelect(val);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }

          final minUnit = 'details.minute'.tr();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        trPomodoro(
                          context,
                          'pomodoro.traditional_settings',
                          'إعدادات البومودورو التقليدي',
                          'Traditional Pomodoro Settings',
                        ),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    buildChipSelector(
                      title: trPomodoro(
                        context,
                        'pomodoro.work_duration',
                        'طول البومودورو (العمل الصافي)',
                        'Pomodoro Duration (Work)',
                      ),
                      options: workOptions,
                      selectedValue: currentSettings.workMinutes,
                      unit: minUnit,
                      onSelect: (val) => notifier.updateTraditionalSettings(
                        currentSettings.copyWith(workMinutes: val),
                      ),
                    ),
                    buildChipSelector(
                      title: trPomodoro(
                        context,
                        'pomodoro.short_break_duration',
                        'طول الراحة القصيرة',
                        'Short Break Duration',
                      ),
                      options: shortBreakOptions,
                      selectedValue: currentSettings.shortBreakMinutes,
                      unit: minUnit,
                      onSelect: (val) => notifier.updateTraditionalSettings(
                        currentSettings.copyWith(shortBreakMinutes: val),
                      ),
                    ),
                    buildChipSelector(
                      title: trPomodoro(
                        context,
                        'pomodoro.long_break_duration',
                        'طول الراحة الطويلة',
                        'Long Break Duration',
                      ),
                      options: longBreakOptions,
                      selectedValue: currentSettings.longBreakMinutes,
                      unit: minUnit,
                      onSelect: (val) => notifier.updateTraditionalSettings(
                        currentSettings.copyWith(longBreakMinutes: val),
                      ),
                    ),
                    buildChipSelector(
                      title: trPomodoro(
                        context,
                        'pomodoro.cycles_before_long_break',
                        'الراحة الطويلة بعد كل (عدد البومودورو)',
                        'Long Break After Every',
                      ),
                      options: cyclesOptions,
                      selectedValue: currentSettings.cyclesBeforeLongBreak,
                      unit: '',
                      onSelect: (val) => notifier.updateTraditionalSettings(
                        currentSettings.copyWith(cyclesBeforeLongBreak: val),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'common.done'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
    },
  );
}
