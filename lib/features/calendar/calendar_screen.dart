import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../core/astro_engine/astro_provider.dart';
import '../../core/providers/ui_providers.dart';
import '../../models/routine_model.dart';
import '../../models/task_model.dart';
import '../../shared/widgets/app_drawer.dart';
import '../routines/routines_provider.dart';
import '../settings/settings_provider.dart';
import '../tasks/tasks_provider.dart';
import 'widgets/calendar_day_agenda.dart';

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

class CalendarDayCellData {
  final DateTime gregorianDate;
  final HijriCalendar hijriDate;

  const CalendarDayCellData({
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

  // 🌟 دوال مساعدة لتحويل التاريخ مع مراعاة تصحيح التاريخ الهجري (hijriOffsetDays)
  HijriCalendar _toHijri(DateTime gregorianDate) {
    final offsetDays = ref.read(settingsProvider).hijriOffsetDays;
    return HijriCalendar.fromDate(
      gregorianDate.add(Duration(days: offsetDays)),
    );
  }

  DateTime _fromHijri(int hYear, int hMonth, int hDay) {
    final offsetDays = ref.read(settingsProvider).hijriOffsetDays;
    final rawGreg = HijriCalendar().hijriToGregorian(hYear, hMonth, hDay);
    return DateTime(
      rawGreg.year,
      rawGreg.month,
      rawGreg.day,
    ).subtract(Duration(days: offsetDays));
  }

  void _syncFocusedMonthToDate(DateTime date) {
    _focusedGregorianYear = date.year;
    _focusedGregorianMonth = date.month;
    final hDate = _toHijri(date);
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

        final firstGreg = _fromHijri(
          _focusedHijriYear,
          _focusedHijriMonth,
          1,
        );
        _focusedGregorianYear = firstGreg.year;
        _focusedGregorianMonth = firstGreg.month;
        _selectedDate = firstGreg;
      } else {
        final nextGreg = DateTime(
          _focusedGregorianYear,
          _focusedGregorianMonth + delta,
          1,
        );
        _focusedGregorianYear = nextGreg.year;
        _focusedGregorianMonth = nextGreg.month;

        final midHijri = _toHijri(
          DateTime(_focusedGregorianYear, _focusedGregorianMonth, 15),
        );
        _focusedHijriYear = midHijri.hYear;
        _focusedHijriMonth = midHijri.hMonth;
        _selectedDate = nextGreg;
      }
    });
  }

  List<CalendarDayCellData> _generateMonthCells(bool isHijriPrimary) {
    final List<CalendarDayCellData> cells = [];

    if (isHijriPrimary) {
      final hCal = HijriCalendar();
      final daysCount = hCal.getDaysInMonth(
        _focusedHijriYear,
        _focusedHijriMonth,
      );
      for (int d = 1; d <= daysCount; d++) {
        final cleanGDate = _fromHijri(
          _focusedHijriYear,
          _focusedHijriMonth,
          d,
        );
        final hObj = HijriCalendar()
          ..hYear = _focusedHijriYear
          ..hMonth = _focusedHijriMonth
          ..hDay = d;
        cells.add(
          CalendarDayCellData(gregorianDate: cleanGDate, hijriDate: hObj),
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
        final hObj = _toHijri(cleanGDate);
        cells.add(
          CalendarDayCellData(gregorianDate: cleanGDate, hijriDate: hObj),
        );
      }
    }

    return cells;
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
          trCal(context, 'nav.calendar', 'التقويم', 'Calendar'),
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
              trCal(context, 'calendar.today', 'اليوم', 'Today'),
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
                trCal(
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
          // 🌟 داخل body -> Column -> Expanded في CalendarScreen:
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
              child: CalendarDayAgenda(
                selectedDate: _selectedDate,
                selectedHijriDate: _toHijri(_selectedDate),
                astroState: astroState,
                settings: settings,
                dayTasks: _getTasksForDay(_selectedDate, allTasks),
                dayRoutines: _getRoutinesForDay(_selectedDate, allRoutines),
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
    List<CalendarDayCellData> cells,
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
    List<CalendarDayCellData> cells,
    bool isHijriPrimary,
    List<TaskModel> allTasks,
    Color primaryColor,
    Color textColor,
    bool isDark,
  ) {
    if (cells.isEmpty) return const SizedBox.shrink();

    final int leadingEmptyCount = cells.first.gregorianDate.weekday % 7;
    final List<CalendarDayCellData?> fullPaddedSlots = [
      ...List<CalendarDayCellData?>.filled(leadingEmptyCount, null),
      ...cells,
    ];
    while (fullPaddedSlots.length % 7 != 0) {
      fullPaddedSlots.add(null);
    }

    // 🌟 التعديل 6: عند طيّ التقويم، نعرض صف الأسبوع الذي يحتوي على اليوم المختار فقط
    List<CalendarDayCellData?> visibleSlots = fullPaddedSlots;
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
            .map((t) => t.category.uiColor(isDark))
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
}