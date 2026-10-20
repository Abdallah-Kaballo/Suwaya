import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:suwaya_time/suwaya_time.dart';

import '../../core/astro_engine/astro_provider.dart';
import '../../core/providers/ui_providers.dart';
import '../../models/routine_model.dart';
import '../../models/settings_model.dart';
import '../../models/task_model.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/suwaya_time_text.dart';
import '../routines/routines_provider.dart';
import '../settings/settings_provider.dart';
import '../tasks/routine_schedule_format.dart';
import '../tasks/tasks_provider.dart';

String _trCal(
  BuildContext context,
  String key,
  String arFallback,
  String enFallback,
) {
  final translated = key.tr();
  if (translated != key) return translated;
  return context.locale.languageCode == 'ar' ? arFallback : enFallback;
}

Color _getCategoryNeonColor(TaskCategory category) {
  final catStr = category.toString().toLowerCase();
  if (catStr.contains('work')) return const Color(0xFF00E5FF);
  if (catStr.contains('study')) return const Color(0xFF00E676);
  if (catStr.contains('sport')) return const Color(0xFFFF3D00);
  if (catStr.contains('worship')) return const Color(0xFFFFC400);
  if (catStr.contains('entertainment')) return const Color(0xFFFF4081);
  if (catStr.contains('personal')) return const Color(0xFFD500F9);
  if (catStr.contains('social')) return const Color(0xFF76FF03);
  return const Color(0xFF18FFFF);
}

int _resolveGlobalSuwaya(int pId, int sNum, List<AstroPeriod> periods) {
  int global = 0;
  for (final p in periods) {
    if (p.id == pId) {
      final count = p.suwayasCount > 0 ? p.suwayasCount : 1;
      return global + (sNum - 1).clamp(0, count - 1);
    }
    global += p.suwayasCount;
  }
  return 0;
}

/// 🌟 بيانات استحباب الصيام للأيام الهجرية الموسمية (الأيام البيض + عاشوراء + عرفة)
class _FastingRecommendation {
  final String title;
  final String reason;
  final Color highlightColor;

  const _FastingRecommendation({
    required this.title,
    required this.reason,
    required this.highlightColor,
  });
}

_FastingRecommendation? _getSeasonalFastingInfo(
  HijriCalendar hDate,
  String langCode,
) {
  final isAr = langCode == 'ar';

  // 1. يوم عرفة (9 ذو الحجة)
  if (hDate.hMonth == 12 && hDate.hDay == 9) {
    return _FastingRecommendation(
      title: isAr ? 'صيام يوم عرفة (9 ذو الحجة)' : 'Fasting Day of Arafah (9 Dhu al-Hijjah)',
      reason: isAr
          ? 'يُستحب صيامه لغير الحاج؛ يكفّر السنة الماضية والباقية.'
          : 'Recommended for non-pilgrims; expiates sins of the previous and coming year.',
      highlightColor: const Color(0xFF10B981),
    );
  }

  // 2. يوم عاشوراء (10 محرم) وتاسوعاء (9 محرم)
  if (hDate.hMonth == 1 && hDate.hDay == 10) {
    return _FastingRecommendation(
      title: isAr ? 'صيام يوم عاشوراء (10 محرم)' : 'Fasting Day of Ashura (10 Muharram)',
      reason: isAr
          ? 'صيام يوم عاشوراء يكفّر السنة التي قبله.'
          : 'Recommended fast; expiates the sins of the preceding year.',
      highlightColor: const Color(0xFF10B981),
    );
  }
  if (hDate.hMonth == 1 && hDate.hDay == 9) {
    return _FastingRecommendation(
      title: isAr ? 'صيام يوم تاسوعاء (9 محرم)' : 'Fasting Tasu\'a (9 Muharram)',
      reason: isAr
          ? 'يُستحب صيامه مع يوم عاشوراء.'
          : 'Recommended to fast along with the Day of Ashura.',
      highlightColor: const Color(0xFF10B981),
    );
  }

  // 3. الأيام البيض (13 و 14 و 15 من كل شهر هجري، باستثناء 13 ذي الحجة لأنه من أيام التشريق، واستثناء شهر رمضان)
  if (hDate.hMonth != 9 &&
      (hDate.hDay == 13 || hDate.hDay == 14 || hDate.hDay == 15)) {
    if (hDate.hMonth == 12 && hDate.hDay == 13) {
      return null; // 13 ذو الحجة من أيام التشريق التي لا يُصام فيها تطوعاً
    }
    return _FastingRecommendation(
      title: isAr
          ? 'من الأيام البيض (${hDate.hDay} ${'hijri.m${hDate.hMonth}'.tr()})'
          : 'White Days Fast (${hDate.hDay} ${'hijri.m${hDate.hMonth}'.tr()})',
      reason: isAr
          ? 'يُندب صيام الأيام البيض (13 و14 و15) من كل شهر هجري، وصيامها كصيام الدهر.'
          : 'Recommended monthly fast on the 13th, 14th, and 15th of the Hijri month.',
      highlightColor: const Color(0xFF10B981),
    );
  }

  return null;
}

class _CalendarDayCellData {
  final DateTime gregorianDate;
  final HijriCalendar hijriDate;

  const _CalendarDayCellData({
    required this.gregorianDate,
    required this.hijriDate,
  });
}

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late int _focusedGregorianYear;
  late int _focusedGregorianMonth;
  late int _focusedHijriYear;
  late int _focusedHijriMonth;

  bool? _manualHijriPrimaryOverride;

  /// 🌟 التعديل 6: حالة طيّ وتضييق الرزنامة لإظهار المهام أسفلها بمساحة أكبر
  bool _isCalendarCollapsed = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _syncFocusedMonthToDate(_selectedDate);
  }

  void _syncFocusedMonthToDate(DateTime date) {
    _focusedGregorianYear = date.year;
    _focusedGregorianMonth = date.month;
    final hDate = HijriCalendar.fromDate(date);
    _focusedHijriYear = hDate.hYear;
    _focusedHijriMonth = hDate.hMonth;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _jumpToToday() {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _syncFocusedMonthToDate(_selectedDate);
    });
  }

  void _navigateMonth(int delta, bool isHijriPrimary) {
    HapticFeedback.selectionClick();
    setState(() {
      if (isHijriPrimary) {
        int newMonth = _focusedHijriMonth + delta;
        int newYear = _focusedHijriYear;
        if (newMonth > 12) {
          newMonth = 1;
          newYear++;
        } else if (newMonth < 1) {
          newMonth = 12;
          newYear--;
        }
        _focusedHijriYear = newYear;
        _focusedHijriMonth = newMonth;

        final firstGreg = HijriCalendar().hijriToGregorian(
          _focusedHijriYear,
          _focusedHijriMonth,
          1,
        );
        _focusedGregorianYear = firstGreg.year;
        _focusedGregorianMonth = firstGreg.month;
        _selectedDate = DateTime(
          firstGreg.year,
          firstGreg.month,
          firstGreg.day,
        );
      } else {
        final nextGreg = DateTime(
          _focusedGregorianYear,
          _focusedGregorianMonth + delta,
          1,
        );
        _focusedGregorianYear = nextGreg.year;
        _focusedGregorianMonth = nextGreg.month;

        final midHijri = HijriCalendar.fromDate(
          DateTime(_focusedGregorianYear, _focusedGregorianMonth, 15),
        );
        _focusedHijriYear = midHijri.hYear;
        _focusedHijriMonth = midHijri.hMonth;
        _selectedDate = nextGreg;
      }
    });
  }

  List<_CalendarDayCellData> _generateMonthCells(bool isHijriPrimary) {
    final List<_CalendarDayCellData> cells = [];

    if (isHijriPrimary) {
      final hCal = HijriCalendar();
      final daysCount = hCal.getDaysInMonth(
        _focusedHijriYear,
        _focusedHijriMonth,
      );
      for (int d = 1; d <= daysCount; d++) {
        final gDate = hCal.hijriToGregorian(
          _focusedHijriYear,
          _focusedHijriMonth,
          d,
        );
        final cleanGDate = DateTime(gDate.year, gDate.month, gDate.day);
        final hObj = HijriCalendar()
          ..hYear = _focusedHijriYear
          ..hMonth = _focusedHijriMonth
          ..hDay = d;
        cells.add(
          _CalendarDayCellData(gregorianDate: cleanGDate, hijriDate: hObj),
        );
      }
    } else {
      final daysCount = DateTime(
        _focusedGregorianYear,
        _focusedGregorianMonth + 1,
        0,
      ).day;
      for (int d = 1; d <= daysCount; d++) {
        final cleanGDate = DateTime(
          _focusedGregorianYear,
          _focusedGregorianMonth,
          d,
        );
        final hObj = HijriCalendar.fromDate(cleanGDate);
        cells.add(
          _CalendarDayCellData(gregorianDate: cleanGDate, hijriDate: hObj),
        );
      }
    }

    return cells;
  }

  bool _isTaskInNightPhase(TaskModel task, AstroState astroState) {
    if (task.isAstroTime && task.targetPeriodId != null) {
      return task.targetPeriodId! >= 1 && task.targetPeriodId! <= 4;
    }
    if (!task.isAstroTime && task.targetCivilTimeMinutes != null) {
      final mins = task.targetCivilTimeMinutes!;
      final sunriseMins = astroState.periods.isNotEmpty
          ? (astroState.ibadatTimings.sunrise.hour * 60 +
              astroState.ibadatTimings.sunrise.minute)
          : 360;
      final maghribMins = astroState.periods.isNotEmpty
          ? (astroState.ibadatTimings.maghrib.hour * 60 +
              astroState.ibadatTimings.maghrib.minute)
          : 1080;
      return mins >= maghribMins || mins < sunriseMins;
    }
    return false;
  }

  bool _isRoutineInNightPhase(RoutineModel routine, AstroState astroState) {
    if (routine.isAstroTime && routine.startPeriodId != null) {
      return routine.startPeriodId! >= 1 && routine.startPeriodId! <= 4;
    }
    if (!routine.isAstroTime && routine.startTimeMinutes != null) {
      final mins = routine.startTimeMinutes!;
      final sunriseMins = astroState.periods.isNotEmpty
          ? (astroState.ibadatTimings.sunrise.hour * 60 +
              astroState.ibadatTimings.sunrise.minute)
          : 360;
      final maghribMins = astroState.periods.isNotEmpty
          ? (astroState.ibadatTimings.maghrib.hour * 60 +
              astroState.ibadatTimings.maghrib.minute)
          : 1080;
      return mins >= maghribMins || mins < sunriseMins;
    }
    return false;
  }

  List<TaskModel> _getTasksForDay(DateTime date, List<TaskModel> allTasks) {
    final weekday = date.weekday;
    return allTasks.where((task) {
      if (task.type == TaskType.permanent) {
        final days = task.recurrenceDays;
        return days == null || days.isEmpty || days.contains(weekday);
      } else {
        if (task.targetDate == null) return false;
        return _isSameDay(task.targetDate!, date);
      }
    }).toList();
  }

  List<RoutineModel> _getRoutinesForDay(
    DateTime date,
    List<RoutineModel> allRoutines,
  ) {
    final weekday = date.weekday;
    return allRoutines.where((r) {
      if (!r.isActive) return false;
      final days = r.recurrenceDays;
      return days == null || days.isEmpty || days.contains(weekday);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final astroState = ref.watch(astroProvider);
    final allTasks = ref.watch(tasksProvider).allTasks;
    final allRoutines = ref.watch(routinesProvider);

    ref.listen<bool>(
      settingsProvider.select((s) => s.useAstroTimeForIbadat),
      (prev, next) {
        if (prev != next) {
          setState(() {
            _manualHijriPrimaryOverride = null;
            _syncFocusedMonthToDate(_selectedDate);
          });
        }
      },
    );

    final bool isHijriPrimary =
        _manualHijriPrimaryOverride ?? settings.useAstroTimeForIbadat;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).colorScheme.onSurface;

    final monthCells = _generateMonthCells(isHijriPrimary);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.15,
      drawer: const AppDrawer(),
      onDrawerChanged: (isOpen) =>
          ref.read(isDrawerOpenProvider.notifier).state = isOpen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        titleSpacing: 4,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(LucideIcons.menu, color: textColor),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          _trCal(context, 'nav.calendar', 'التقويم', 'Calendar'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 17,
          ),
        ),
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: _jumpToToday,
            icon: Icon(
              LucideIcons.calendar_check,
              size: 15,
              color: primaryColor,
            ),
            label: Text(
              _trCal(context, 'calendar.today', 'اليوم', 'Today'),
              style: TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _trCal(
                  context,
                  'common.suwaya_time',
                  'الوقت السُويعي',
                  'Suwaya Time',
                ),
                style: TextStyle(
                  color: settings.useAstroTimeForIbadat
                      ? primaryColor
                      : (isDark ? Colors.white70 : Colors.black54),
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Transform.scale(
                scale: 0.72,
                child: Switch(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  value: settings.useAstroTimeForIbadat,
                  activeThumbColor: isDark ? Colors.black : Colors.white,
                  activeTrackColor: primaryColor,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    ref
                        .read(settingsProvider.notifier)
                        .updateUseAstroTimeForIbadat(val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // 🌟 1. بطاقة الرزنامة القابلة للسحب والتضييق (Collapsible Calendar Card)
          GestureDetector(
            onVerticalDragEnd: (details) {
              final vy = details.primaryVelocity ?? 0;
              if (vy < -150 && !_isCalendarCollapsed) {
                HapticFeedback.selectionClick();
                setState(() => _isCalendarCollapsed = true);
              } else if (vy > 150 && _isCalendarCollapsed) {
                HapticFeedback.selectionClick();
                setState(() => _isCalendarCollapsed = false);
              }
            },
            child: AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMonthHeader(
                      context,
                      monthCells,
                      isHijriPrimary,
                      primaryColor,
                      textColor,
                    ),
                    const SizedBox(height: 8),
                    _buildWeekdayHeaders(context, textColor),
                    const SizedBox(height: 6),
                    _buildCalendarGrid(
                      context,
                      monthCells,
                      isHijriPrimary,
                      allTasks,
                      primaryColor,
                      textColor,
                      isDark,
                    ),
                    // 🌟 مقبض سحب/طيّ الرزنامة لأعلى أو أسفل
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(
                          () => _isCalendarCollapsed = !_isCalendarCollapsed,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: textColor.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _isCalendarCollapsed
                                  ? LucideIcons.chevron_down
                                  : LucideIcons.chevron_up,
                              size: 14,
                              color: textColor.withValues(alpha: 0.45),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 🌟 2. قسم المهام أسفل التقويم (يتوسع تلقائياً عند سحب القائمة لأعلى)
          Expanded(
            child: NotificationListener<UserScrollNotification>(
              onNotification: (notification) {
                if (notification.direction == ScrollDirection.reverse &&
                    !_isCalendarCollapsed) {
                  setState(() => _isCalendarCollapsed = true);
                } else if (notification.direction == ScrollDirection.forward &&
                    notification.metrics.pixels <= 0 &&
                    _isCalendarCollapsed) {
                  setState(() => _isCalendarCollapsed = false);
                }
                return false;
              },
              child: _buildSelectedDayAgenda(
                context: context,
                astroState: astroState,
                settings: settings,
                allTasks: allTasks,
                allRoutines: allRoutines,
                primaryColor: primaryColor,
                surfaceColor: surfaceColor,
                textColor: textColor,
                isDark: isDark,
              ),
            ),
          ),
        ],
      ),
      // 🌟 التعديل 7: زر الإضافة مطابق للشاشة الرئيسية (+ فقط بدون نص ومرفوع بـ 112.0)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 112.0),
        child: FloatingActionButton(
          heroTag: null,
          backgroundColor: primaryColor,
          foregroundColor: isDark ? Colors.black : Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push(
              '/add-task',
              extra: {
                'currentPeriodId': astroState.currentPeriod.id,
                'currentSuwaya':
                    astroState.currentSuwayaTime.periodLocalSlotNumber,
                'initialDate': _selectedDate,
              },
            );
          },
          child: const Icon(LucideIcons.plus, size: 28),
        ),
      ),
    );
  }

  Widget _buildMonthHeader(
    BuildContext context,
    List<_CalendarDayCellData> cells,
    bool isHijriPrimary,
    Color primaryColor,
    Color textColor,
  ) {
    final langCode = context.locale.languageCode;
    final safeLocale = (langCode == 'ff' || langCode == 'ug') ? 'en' : langCode;
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    String primaryTitle;
    String secondarySubtitle;

    if (isHijriPrimary) {
      final hMonthName = 'hijri.m$_focusedHijriMonth'.tr();
      primaryTitle = '$hMonthName $_focusedHijriYear${'common.ah'.tr()}';

      if (cells.isNotEmpty) {
        final firstG = cells.first.gregorianDate;
        final lastG = cells.last.gregorianDate;
        final m1 = DateFormat('MMMM', safeLocale).format(firstG);
        final m2 = DateFormat('MMMM', safeLocale).format(lastG);
        if (firstG.month == lastG.month) {
          secondarySubtitle = '$m1${firstG.year}';
        } else if (firstG.year == lastG.year) {
          secondarySubtitle = '$m1 - $m2${firstG.year}';
        } else {
          secondarySubtitle = '$m1${firstG.year} - $m2${lastG.year}';
        }
      } else {
        secondarySubtitle = '';
      }
    } else {
      final gDate = DateTime(_focusedGregorianYear, _focusedGregorianMonth, 1);
      primaryTitle = DateFormat('MMMM yyyy', safeLocale).format(gDate);

      if (cells.isNotEmpty) {
        final firstH = cells.first.hijriDate;
        final lastH = cells.last.hijriDate;
        final hm1 = 'hijri.m${firstH.hMonth}'.tr();
        final hm2 = 'hijri.m${lastH.hMonth}'.tr();
        if (firstH.hMonth == lastH.hMonth) {
          secondarySubtitle = '$hm1 ${firstH.hYear}${'common.ah'.tr()}';
        } else if (firstH.hYear == lastH.hYear) {
          secondarySubtitle =
              '$hm1 -$hm2 ${firstH.hYear}${'common.ah'.tr()}';
        } else {
          secondarySubtitle =
              '$hm1 ${firstH.hYear} -$hm2 ${lastH.hYear}${'common.ah'.tr()}';
        }
      } else {
        secondarySubtitle = '';
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(
            isRTL ? LucideIcons.chevron_right : LucideIcons.chevron_left,
            color: textColor,
          ),
          onPressed: () => _navigateMonth(-1, isHijriPrimary),
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _manualHijriPrimaryOverride = !isHijriPrimary;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          primaryTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        LucideIcons.arrow_up_down,
                        size: 13,
                        color: primaryColor.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                  if (secondarySubtitle.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      secondarySubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.55),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(
            isRTL ? LucideIcons.chevron_left : LucideIcons.chevron_right,
            color: textColor,
          ),
          onPressed: () => _navigateMonth(1, isHijriPrimary),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders(BuildContext context, Color textColor) {
    final langCode = context.locale.languageCode;
    final safeLocale = (langCode == 'ff' || langCode == 'ug') ? 'en' : langCode;
    final baseSunday = DateTime(2026, 10, 18);

    return Row(
      children: List.generate(7, (index) {
        final dayDate = baseSunday.add(Duration(days: index));
        final dayLabel = DateFormat('E', safeLocale).format(dayDate);
        return Expanded(
          child: Center(
            child: Text(
              dayLabel,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.55),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCalendarGrid(
    BuildContext context,
    List<_CalendarDayCellData> cells,
    bool isHijriPrimary,
    List<TaskModel> allTasks,
    Color primaryColor,
    Color textColor,
    bool isDark,
  ) {
    if (cells.isEmpty) return const SizedBox.shrink();

    final int leadingEmptyCount = cells.first.gregorianDate.weekday % 7;
    final List<_CalendarDayCellData?> fullPaddedSlots = [
      ...List<_CalendarDayCellData?>.filled(leadingEmptyCount, null),
      ...cells,
    ];
    while (fullPaddedSlots.length % 7 != 0) {
      fullPaddedSlots.add(null);
    }

    // 🌟 التعديل 6: عند طيّ التقويم، نعرض صف الأسبوع الذي يحتوي على اليوم المختار فقط
    List<_CalendarDayCellData?> visibleSlots = fullPaddedSlots;
    if (_isCalendarCollapsed) {
      int selectedSlotIdx = fullPaddedSlots.indexWhere(
        (c) => c != null && _isSameDay(c.gregorianDate, _selectedDate),
      );
      if (selectedSlotIdx == -1) selectedSlotIdx = leadingEmptyCount;
      final int weekRowStart = (selectedSlotIdx ~/ 7) * 7;
      visibleSlots = fullPaddedSlots.sublist(weekRowStart, weekRowStart + 7);
    }

    final today = DateTime.now();
    final langCode = context.locale.languageCode;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visibleSlots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 1.06,
      ),
      itemBuilder: (context, index) {
        final cell = visibleSlots[index];
        if (cell == null) {
          return const SizedBox.shrink();
        }

        final isSelected = _isSameDay(cell.gregorianDate, _selectedDate);
        final isToday = _isSameDay(cell.gregorianDate, today);

        // 🌟 التعديل 11: فحص ما إذا كان اليوم من الأيام الموسمية التي يُندب صيامها
        final fastingInfo = _getSeasonalFastingInfo(cell.hijriDate, langCode);
        final bool isFastingDay = fastingInfo != null;
        const fastingEmerald = Color(0xFF10B981);

        final int primaryNum =
            isHijriPrimary ? cell.hijriDate.hDay : cell.gregorianDate.day;
        final int secondaryNum =
            isHijriPrimary ? cell.gregorianDate.day : cell.hijriDate.hDay;

        final dayTasks = _getTasksForDay(cell.gregorianDate, allTasks);
        final dotColors = dayTasks
            .map((t) => _getCategoryNeonColor(t.category))
            .toSet()
            .take(3)
            .toList();

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedDate = cell.gregorianDate;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withValues(alpha: 0.22)
                  : (isFastingDay
                      ? fastingEmerald.withValues(alpha: isDark ? 0.14 : 0.10)
                      : (isToday
                          ? primaryColor.withValues(alpha: 0.08)
                          : Colors.transparent)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? primaryColor
                    : (isFastingDay
                        ? fastingEmerald.withValues(alpha: 0.55)
                        : (isToday
                            ? primaryColor.withValues(alpha: 0.45)
                            : Colors.transparent)),
                width: isSelected ? 1.8 : 1.1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isFastingDay)
                      const Icon(
                        LucideIcons.moon_star,
                        size: 8.5,
                        color: fastingEmerald,
                      )
                    else
                      const SizedBox(width: 8),
                    Text(
                      '$secondaryNum',
                      style: TextStyle(
                        color: isSelected
                            ? primaryColor
                            : (isFastingDay
                                ? fastingEmerald
                                : textColor.withValues(alpha: 0.42)),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$primaryNum',
                  style: TextStyle(
                    color: isSelected
                        ? primaryColor
                        : (isFastingDay
                            ? fastingEmerald
                            : (isToday ? primaryColor : textColor)),
                    fontSize: 14.5,
                    fontWeight: (isSelected || isToday || isFastingDay)
                        ? FontWeight.w900
                        : FontWeight.w700,
                    fontFamily: 'Inter',
                    height: 1.05,
                  ),
                ),
                SizedBox(
                  height: 5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: dotColors
                        .map(
                          (c) => Container(
                            width: 4.5,
                            height: 4.5,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

Widget _buildSelectedDayAgenda({
    required BuildContext context,
    required AstroState astroState,
    required SettingsModel settings,
    required List<TaskModel> allTasks,
    required List<RoutineModel> allRoutines,
    required Color primaryColor,
    required Color surfaceColor,
    required Color textColor,
    required bool isDark,
  }) {
    final langCode = context.locale.languageCode;
    final safeLocale = (langCode == 'ff' || langCode == 'ug') ? 'en' : langCode;

    final dayName = DateFormat('EEEE', safeLocale).format(_selectedDate);
    final hSelected = HijriCalendar.fromDate(_selectedDate);
    final hDateStr =
        '${hSelected.hDay} ${'hijri.m${hSelected.hMonth}'.tr()} ${hSelected.hYear} ${'common.ah'.tr()}';
    final gDateStr = DateFormat('d MMMM yyyy', safeLocale).format(_selectedDate);

    // 🌟 التعديل 11: استخراج سبب تظليل الصيام لليوم المختار إن وجد (الأيام البيض + عاشوراء + عرفة)
    final fastingInfo = _getSeasonalFastingInfo(hSelected, langCode);

    final dayTasks = _getTasksForDay(_selectedDate, allTasks);
    final dayRoutines = _getRoutinesForDay(_selectedDate, allRoutines);

    final nightTasks =
        dayTasks.where((t) => _isTaskInNightPhase(t, astroState)).toList();
    final dayPhaseTasks =
        dayTasks.where((t) => !_isTaskInNightPhase(t, astroState)).toList();

    final nightRoutines =
        dayRoutines.where((r) => _isRoutineInNightPhase(r, astroState)).toList();
    final dayPhaseRoutines = dayRoutines
        .where((r) => !_isRoutineInNightPhase(r, astroState))
        .toList();

    final bool hasAnyItems = dayTasks.isNotEmpty || dayRoutines.isNotEmpty;

    final String nightHeaderTitle = 'home.night_of'.tr(args: [dayName]) !=
            'home.night_of'
        ? 'home.night_of'.tr(args: [dayName])
        : (langCode == 'ar' ? 'ليلة $dayName' : 'Night of $dayName');

    final String dayHeaderTitle = 'home.day_of'.tr(args: [dayName]) !=
            'home.day_of'
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

        // 🌟 التعديل 11: بطاقة سبب تظليل الصيام (تظهر عند الضغط على يوم من الأيام البيض أو عاشوراء أو عرفة)
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
            title: '$nightHeaderTitle 🌑',
            icon: LucideIcons.moon,
            phaseColor: const Color(0xFF7986CB),
            tasks: nightTasks,
            routines: nightRoutines,
            periods: astroState.periods,
            settings: settings,
            surfaceColor: surfaceColor,
            textColor: textColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildPhaseSectionCard(
            context: context,
            title: '$dayHeaderTitle ☀️',
            icon: LucideIcons.sun,
            phaseColor: const Color(0xFFFFB300),
            tasks: dayPhaseTasks,
            routines: dayPhaseRoutines,
            periods: astroState.periods,
            settings: settings,
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
    required String title,
    required IconData icon,
    required Color phaseColor,
    required List<TaskModel> tasks,
    required List<RoutineModel> routines,
    required List<AstroPeriod> periods,
    required SettingsModel settings,
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
                _trCal(
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
                task: task,
                periods: periods,
                settings: settings,
                textColor: textColor,
                isDark: isDark,
              ),
            ),
            ...routines.map(
              (routine) => _buildCalendarRoutineTile(
                context: context,
                routine: routine,
                periods: periods,
                settings: settings,
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
    required TaskModel task,
    required List<AstroPeriod> periods,
    required SettingsModel settings,
    required Color textColor,
    required bool isDark,
  }) {
    final catColor = _getCategoryNeonColor(task.category);
    final langCode = context.locale.languageCode;

    final bool isCompletedOnSelectedDate = task.type == TaskType.casual
        ? task.isCompleted
        : task.completionHistory.any((d) => _isSameDay(d, _selectedDate));

    final clockStyle = TextStyle(
      color: task.isAstroTime ? const Color(0xFFF2C94C) : textColor,
      fontSize: 14.5,
      fontWeight: FontWeight.w700,
      fontFamily: 'Inter',
    );

    Widget timeWidget = Text('--:--', style: clockStyle);
    if (!task.isAstroTime && task.targetCivilTimeMinutes != null) {
      final mins = task.targetCivilTimeMinutes!;
      timeWidget = ClockTimeText.civil(
        civilTime: DateTime(2000, 1, 1, mins ~/ 60, mins % 60),
        civilTimeFormat: settings.civilTimeFormat,
        locale: langCode,
        style: clockStyle,
      );
    } else if (task.isAstroTime &&
        task.targetPeriodId != null &&
        periods.isNotEmpty) {
      final globalSuwaya = _resolveGlobalSuwaya(
        task.targetPeriodId!,
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
        final astro = ref.read(astroProvider);
        context.push(
          '/add-task',
          extra: {
            'currentPeriodId': astro.currentPeriod.id,
            'currentSuwaya': astro.currentSuwayaTime.periodLocalSlotNumber,
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
            GestureDetector(
              onTap: () {
                HapticFeedback.heavyImpact();
                ref.read(tasksProvider.notifier).toggleTaskStatus(task);
              },
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: catColor, width: 2),
                  color:
                      isCompletedOnSelectedDate ? catColor : Colors.transparent,
                ),
                child: isCompletedOnSelectedDate
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
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
    required RoutineModel routine,
    required List<AstroPeriod> periods,
    required SettingsModel settings,
    required Color textColor,
    required bool isDark,
  }) {
    final rColor = Color(routine.colorValue);
    final locale = context.locale.languageCode;
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    final clockStyle = TextStyle(
      color: routine.isAstroTime ? const Color(0xFFF2C94C) : textColor,
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
              _resolveGlobalSuwaya(periodId, suwaya ?? 1, periods),
          virtualMinute: virtualMin ?? 0,
          style: clockStyle,
        );
      }
      if (!routine.isAstroTime && civilMins != null) {
        return Text(formatCivilRoutineTime(civilMins, locale), style: clockStyle);
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
        final astro = ref.read(astroProvider);
        context.push(
          '/add-task',
          extra: {
            'currentPeriodId': astro.currentPeriod.id,
            'currentSuwaya': astro.currentSuwayaTime.periodLocalSlotNumber,
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
              decoration: BoxDecoration(
                color: rColor,
                shape: BoxShape.circle,
              ),
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
              textDirection: isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
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