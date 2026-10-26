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

class LargeZenTimerDial extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
            forcedSize ?? (availableWidth * 0.88).clamp(260.0, 390.0);

        final clockColor = isDark
            ? const Color(0xFFF8FAFC)
            : const Color(0xFF0F172A);

        // 🌟 النمط الثاني: الرقمي الخالص (Pure Digital Typography)
        if (isFullScreen && zenMode == PomodoroZenMode.digital) {
          return GestureDetector(
            onDoubleTap: onDoubleTap,
            child: Container(
              width: dialSize,
              height: dialSize * 0.85,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Text(
                        '$minutesStr:$secondsStr',
                        style: TextStyle(
                          fontSize: 124,
                          fontWeight: FontWeight.w900,
                          color: clockColor,
                          fontFamily: 'Inter',
                          letterSpacing: 3.0,
                          height: 1.0,
                          fontFeatures: const [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    phaseLabel,
                    style: TextStyle(
                      color: activeColor.withValues(alpha: 0.85),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 🌟 النمط الثالث: النبض المحيطي الهادئ (Ambient Breath)
        if (isFullScreen && zenMode == PomodoroZenMode.ambient) {
          return GestureDetector(
            onDoubleTap: onDoubleTap,
            child: Container(
              width: dialSize,
              height: dialSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    activeColor.withValues(alpha: 0.24),
                    activeColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Text(
                      '$minutesStr:$secondsStr',
                      style: TextStyle(
                        fontSize: 86,
                        fontWeight: FontWeight.w300,
                        color: Colors.white.withValues(alpha: 0.92),
                        fontFamily: 'Inter',
                        letterSpacing: 4.0,
                        fontFeatures: const [ui.FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    phaseLabel,
                    style: TextStyle(
                      color: activeColor.withValues(alpha: 0.75),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 🌟 النمط الأول (الافتراضي): حلقة الصفاء المتوازنة (Zen Ring)
        final double timeFontSize = (dialSize * 0.26).clamp(72.0, 104.0);

        return GestureDetector(
          onDoubleTap: onDoubleTap,
          child: SizedBox(
            width: dialSize,
            height: dialSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: dialSize,
                  height: dialSize,
                  child: CustomPaint(
                    painter: ZenTimerPainter(
                      progress: progress,
                      activeColor: activeColor,
                      isDark: isDark,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: dialSize * 0.10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: Text(
                            '$minutesStr:$secondsStr',
                            style: TextStyle(
                              fontSize: timeFontSize,
                              fontWeight: FontWeight.w800,
                              color: clockColor,
                              fontFamily: 'Inter',
                              letterSpacing: 1.5,
                              height: 1.05,
                              fontFeatures: const [
                                ui.FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBreak ? LucideIcons.coffee : LucideIcons.sparkles,
                            color: activeColor,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            phaseLabel,
                            style: TextStyle(
                              color: activeColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
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
      },
    );
  }
}

class ZenTimerPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final bool isDark;

  ZenTimerPainter({
    required this.progress,
    required this.activeColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;

    final trackPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawCircle(center, radius, trackPaint);

    final safeProgress = progress.clamp(0.0, 1.0);

    if (safeProgress > 0) {
      final progressPaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        safeProgress * 2 * pi,
        false,
        progressPaint,
      );

      final knobAngle = -pi / 2 + (safeProgress * 2 * pi);
      final knobCenter = Offset(
        center.dx + cos(knobAngle) * radius,
        center.dy + sin(knobAngle) * radius,
      );
      canvas.drawCircle(knobCenter, 6.5, Paint()..color = activeColor);
    }
  }

  @override
  bool shouldRepaint(covariant ZenTimerPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.isDark != isDark;
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
