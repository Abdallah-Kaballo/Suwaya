import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:suwaya_time/suwaya_time.dart';

import '../../../core/theme/astro_ui_extensions.dart';
import '../../../models/routine_model.dart';
import '../../../models/settings_model.dart';
import '../../../models/task_model.dart';
import '../../../shared/widgets/suwaya_time_text.dart';
import '../../tasks/routine_schedule_format.dart';
import '../../tasks/tasks_provider.dart';

String trCal(
  BuildContext context,
  String key,
  String arFallback,
  String enFallback,
) {
  final translated = key.tr();
  if (translated != key) return translated;
  return context.locale.languageCode == 'ar' ? arFallback : enFallback;
}

int resolveCalendarGlobalSuwaya(int pId, int sNum, List<AstroPeriod> periods) =>
    SuwayaCoordinateMapper.localToGlobal(pId, sNum, periods);

class FastingRecommendation {
  final String title;
  final String reason;
  final Color highlightColor;

  const FastingRecommendation({
    required this.title,
    required this.reason,
    required this.highlightColor,
  });
}

FastingRecommendation? getSeasonalFastingInfo(
  HijriCalendar hDate,
  String langCode,
) {
  final rec = IslamicEventsCatalog.evaluateFastingForHijri(
    hMonth: hDate.hMonth,
    hDay: hDate.hDay,
    langCode: langCode,
    localizedMonthName:
        'hijri.m${hDate.hMonth}'.tr() != 'hijri.m${hDate.hMonth}'
            ? 'hijri.m${hDate.hMonth}'.tr()
            : null,
  );
  if (rec == null) return null;
  return FastingRecommendation(
    title: rec.title,
    reason: rec.reason,
    highlightColor: Color(rec.highlightColorHex),
  );
}

class CalendarDayCellData {
  final DateTime gregorianDate;
  final HijriCalendar hijriDate;

  const CalendarDayCellData({
    required this.gregorianDate,
    required this.hijriDate,
  });
}

class CalendarDayAgenda extends ConsumerWidget {
  final DateTime selectedDate;
  final HijriCalendar selectedHijriDate;
  final AstroState astroState;
  final SettingsModel settings;
  final List<TaskModel> dayTasks;
  final List<RoutineModel> dayRoutines;

  const CalendarDayAgenda({
    super.key,
    required this.selectedDate,
    required this.selectedHijriDate,
    required this.astroState,
    required this.settings,
    required this.dayTasks,
    required this.dayRoutines,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isTaskInNightPhase(TaskModel task) {
    return SuwayaScheduleEngine.isScheduleItemInNightPhase(
      isAstroTime: task.isAstroTime,
      periodId: task.targetPeriodId,
      civilClock: task.targetCivilClock,
      astroState: astroState,
    );
  }

  bool _isRoutineInNightPhase(RoutineModel routine) {
    return SuwayaScheduleEngine.isScheduleItemInNightPhase(
      isAstroTime: routine.isAstroTime,
      periodId: routine.startPeriodId,
      civilClock: routine.startCivilClock,
      astroState: astroState,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final langCode = context.locale.languageCode;
    final safeLocale = (langCode == 'ff' || langCode == 'ug') ? 'en' : langCode;

    final dayName = DateFormat('EEEE', safeLocale).format(selectedDate);
    final hDateStr =
        '${selectedHijriDate.hDay} ${'hijri.m${selectedHijriDate.hMonth}'.tr()} ${selectedHijriDate.hYear} ${'common.ah'.tr()}';
    final gDateStr = DateFormat('d MMMM yyyy', safeLocale).format(selectedDate);

    final fastingInfo = getSeasonalFastingInfo(selectedHijriDate, langCode);

    final nightTasks = dayTasks.where(_isTaskInNightPhase).toList();
    final dayPhaseTasks =
        dayTasks.where((t) => !_isTaskInNightPhase(t)).toList();

    final nightRoutines = dayRoutines.where(_isRoutineInNightPhase).toList();
    final dayPhaseRoutines =
        dayRoutines.where((r) => !_isRoutineInNightPhase(r)).toList();

    final bool hasAnyItems = dayTasks.isNotEmpty || dayRoutines.isNotEmpty;

    final String nightHeaderTitle =
        'home.night_of'.tr(args: [dayName]) != 'home.night_of'
            ? 'home.night_of'.tr(args: [dayName])
            : (langCode == 'ar' ? 'ليلة $dayName' : 'Night of $dayName');

    final String dayHeaderTitle =
        'home.day_of'.tr(args: [dayName]) != 'home.day_of'
            ? 'home.day_of'.tr(args: [dayName])
            : (langCode == 'ar' ? 'نهار $dayName' : 'Day of $dayName');

    return ListView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$dayName · $hDateStr',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                gDateStr,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.55),
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (fastingInfo != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12, top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: fastingInfo.highlightColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: fastingInfo.highlightColor.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: fastingInfo.highlightColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.moon_star,
                    color: fastingInfo.highlightColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fastingInfo.title,
                        style: TextStyle(
                          color: fastingInfo.highlightColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        fastingInfo.reason,
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.8),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (!hasAnyItems)
          Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  LucideIcons.calendar_plus,
                  size: 46,
                  color: textColor.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                Text(
                  'tasks.empty_tasks'.tr(),
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.45),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else ...[
          _buildPhaseSectionCard(
            context: context,
            ref: ref,
            title: '$nightHeaderTitle SuwayaPhaseBadge(isNight: true, size: 20)',
            icon: LucideIcons.moon,
            phaseColor: const Color(0xFF7986CB),
            tasks: nightTasks,
            routines: nightRoutines,
            surfaceColor: surfaceColor,
            textColor: textColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildPhaseSectionCard(
            context: context,
            ref: ref,
            title: '$dayHeaderTitle SuwayaPhaseBadge(isNight: false, size: 20)',
            icon: LucideIcons.sun,
            phaseColor:
                isDark ? const Color(0xFFFFB300) : const Color(0xFFB25000),
            tasks: dayPhaseTasks,
            routines: dayPhaseRoutines,
            surfaceColor: surfaceColor,
            textColor: textColor,
            isDark: isDark,
          ),
        ],
      ],
    );
  }

  Widget _buildPhaseSectionCard({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required IconData icon,
    required Color phaseColor,
    required List<TaskModel> tasks,
    required List<RoutineModel> routines,
    required Color surfaceColor,
    required Color textColor,
    required bool isDark,
  }) {
    final isEmpty = tasks.isEmpty && routines.isEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: phaseColor.withValues(alpha: 0.28),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: phaseColor, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: phaseColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${tasks.length + routines.length}',
                  style: TextStyle(
                    color: phaseColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          if (isEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                trCal(
                  context,
                  'calendar.no_items_in_phase',
                  'لا توجد مهام مجدولة في هذه الفترة',
                  'No tasks scheduled in this phase',
                ),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.4),
                  fontSize: 12.5,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            ...tasks.map(
              (task) => _buildCalendarTaskTile(
                context: context,
                ref: ref,
                task: task,
                textColor: textColor,
                isDark: isDark,
              ),
            ),
            ...routines.map(
              (routine) => _buildCalendarRoutineTile(
                context: context,
                ref: ref,
                routine: routine,
                textColor: textColor,
                isDark: isDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalendarTaskTile({
    required BuildContext context,
    required WidgetRef ref,
    required TaskModel task,
    required Color textColor,
    required bool isDark,
  }) {
    final catColor = task.category.uiColor(isDark);
    final langCode = context.locale.languageCode;
    final periods = astroState.periods;

    final bool isCompletedOnSelectedDate = task.type == TaskType.casual
        ? task.isCompleted
        : task.completionHistory.any((d) => _isSameDay(d, selectedDate));

    final clockStyle = TextStyle(
      color: task.isAstroTime ? suwayaTimeContrastColor(context) : textColor,
      fontSize: 14.5,
      fontWeight: FontWeight.w700,
      fontFamily: 'Inter',
    );

    Widget timeWidget = Text('--:--', style: clockStyle);
    if (!task.isAstroTime && task.targetCivilClock != null) {
      timeWidget = ClockTimeText.civilClock(
        civilClock: task.targetCivilClock!,
        civilTimeFormat: settings.civilTimeFormat,
        locale: langCode,
        style: clockStyle,
      );
    } else if (task.isAstroTime &&
        task.targetPeriodId != null &&
        periods.isNotEmpty) {
      final globalSuwaya = SuwayaCoordinateMapper.localToGlobal(
        task.targetPeriodId,
        task.targetSuwayas.isNotEmpty ? task.targetSuwayas.first : 1,
        periods,
      );
      timeWidget = ClockTimeText.suwaya(
        globalSuwayaIndex: globalSuwaya,
        virtualMinute: task.targetVirtualMinute,
        style: clockStyle,
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(
          '/add-task',
          extra: {
            'currentPeriodId': astroState.currentPeriod.id,
            'currentSuwaya': astroState.currentSuwayaTime.periodLocalSlotNumber,
            'existingTask': task,
            'initialTab': task.type == TaskType.permanent ? 1 : 0,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: catColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Semantics(
              button: true,
              checked: isCompletedOnSelectedDate,
              label: task.title,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  ref.read(tasksProvider.notifier).toggleTaskStatus(task);
                },
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: catColor, width: 2),
                        color: isCompletedOnSelectedDate
                            ? catColor
                            : Colors.transparent,
                      ),
                      child: isCompletedOnSelectedDate
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color:
                          isCompletedOnSelectedDate ? Colors.grey : textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      decoration: isCompletedOnSelectedDate
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          task.category.displayName,
                          style: TextStyle(
                            color: catColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (task.type == TaskType.permanent) ...[
                        const SizedBox(width: 6),
                        Icon(
                          LucideIcons.repeat,
                          size: 11,
                          color: textColor.withValues(alpha: 0.45),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: timeWidget,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarRoutineTile({
    required BuildContext context,
    required WidgetRef ref,
    required RoutineModel routine,
    required Color textColor,
    required bool isDark,
  }) {
    final rColor = Color(routine.colorValue);
    final locale = context.locale.languageCode;
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    final periods = astroState.periods;

    final clockStyle = TextStyle(
      color: routine.isAstroTime ? suwayaTimeContrastColor(context) : textColor,
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      fontFamily: 'Inter',
    );

    Widget buildEndpoint({
      required int? periodId,
      required int? suwaya,
      required int? virtualMin,
      required int? civilMins,
    }) {
      if (routine.isAstroTime && periodId != null && periods.isNotEmpty) {
        return ClockTimeText.suwaya(
          globalSuwayaIndex:
              resolveCalendarGlobalSuwaya(periodId, suwaya ?? 1, periods),
          virtualMinute: virtualMin ?? 0,
          style: clockStyle,
        );
      }
      if (!routine.isAstroTime && civilMins != null) {
        return Text(formatCivilRoutineTime(civilMins, locale),
            style: clockStyle);
      }
      return Text('--:--', style: clockStyle);
    }

    final startWidget = buildEndpoint(
      periodId: routine.startPeriodId,
      suwaya: routine.startSuwaya,
      virtualMin: routine.startVirtualMinute,
      civilMins: routine.startTimeMinutes,
    );

    final endWidget = buildEndpoint(
      periodId: routine.endPeriodId ?? routine.startPeriodId,
      suwaya: routine.endSuwaya ?? routine.startSuwaya,
      virtualMin: routine.endVirtualMinute,
      civilMins: routine.endTimeMinutes,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.selectionClick();
        context.push(
          '/add-task',
          extra: {
            'currentPeriodId': astroState.currentPeriod.id,
            'currentSuwaya': astroState.currentSuwayaTime.periodLocalSlotNumber,
            'existingRoutine': routine,
            'initialTab': 2,
          },
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: rColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: rColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                routine.title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Directionality(
              textDirection:
                  isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  startWidget,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      isRTL ? LucideIcons.arrow_left : LucideIcons.arrow_right,
                      size: 13,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                  endWidget,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
