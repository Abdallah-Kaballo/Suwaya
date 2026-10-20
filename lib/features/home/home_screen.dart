import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya/features/home/widgets/dial/dial_constants.dart';
import 'package:suwaya/features/home/widgets/dial/period_metrics.dart';
import 'package:suwaya_time/suwaya_time.dart';

import 'package:suwaya/core/notification/scheduler_service.dart';
import 'package:suwaya/models/settings_model.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/astro_engine/astro_provider.dart';
import '../tasks/tasks_provider.dart';
import '../settings/settings_provider.dart';
import '../routines/routines_provider.dart';
import '../ibadat/ibadat_screen.dart';
import '../../core/providers/ui_providers.dart';
import '../../core/utils/time_formatters.dart';

import 'widgets/location_header.dart';
import 'widgets/premium_astro_dial.dart';
import 'widgets/dial/dial_models.dart';
import 'widgets/mini_astro_dial.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../core/theme/astro_ui_extensions.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ({int globalIndex, int minute}) _getDynamicOrFixedAstroTime(
    DialSelection selection,
    AstroState state,
    DateTime time,
    bool isEnd,
  ) {
    if (selection.type == DialSelectionType.prayer ||
        selection.type == DialSelectionType.period) {
      return getFixedAstroTime(selection.id, state, isEnd: isEnd);
    } else {
      DateTime evalTime =
          isEnd ? time.subtract(const Duration(microseconds: 1)) : time;
      final mockState = SuwayaTimeEngine.calculateCurrentState(
        SuwayaDay(
          ibadatTimings: state.ibadatTimings,
          cycleAnchors: state.cycleAnchors,
          periods: state.periods,
        ),
        evalTime,
      );
      int global = 0;
      if (mockState.currentSuwayaTime.phase == SuwayaPhase.day) {
        global = 12 + mockState.currentSuwayaTime.phaseSlotNumber - 1;
      } else {
        global = mockState.currentSuwayaTime.phaseSlotNumber - 1;
      }
      return (
        globalIndex: global,
        minute: mockState.currentSuwayaTime.virtualMinute,
      );
    }
  }


  /// 🌟 حساب عدد السويعات لأجزاء الليل الخمسة
  int? _getNightPartSuwayasCount(String id) {
    final sid = id.toLowerCase();
    if (sid.contains('half_2')) return 6;
    if (sid.contains('third_3')) return 4;
    if (sid.contains('sixth_4') ||
        sid.contains('sixth_5') ||
        sid.contains('sixth_6')) {
      return 2;
    }
    return null;
  }

  Future<void> _showDialItemDialog(
    BuildContext context,
    DialSelection selection,
    AstroState astroState,
    SettingsModel settings,
  ) async {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final civilColor = textColor.withValues(alpha: 0.82);

    PeriodMetrics? periodMetrics;

    if (selection.type == DialSelectionType.period) {
      final periodId = int.tryParse(selection.id);
      for (final period in astroState.periods) {
        if (period.id == periodId) {
          periodMetrics = PeriodMetrics.fromPeriod(period);
          break;
        }
      }
    } else if (selection.endTime != null) {
      // 🌟 التعديل 10: حساب مقاييس (عدد السويعات، طول السويعة، وسرعة التدفق) لأوقات الليل الخمسة
      final nightSuwayas = _getNightPartSuwayasCount(selection.id);
      if (nightSuwayas != null && nightSuwayas > 0) {
        final tempPeriod = AstroPeriod(
          id: 3,
          periodKey: PeriodKey.nightMidnightFajr,
          nameKey: selection.id,
          startTime: selection.startTime,
          endTime: selection.endTime!,
          suwayasCount: nightSuwayas,
          colorValue: selection.color.toARGB32(),
        );
        periodMetrics = PeriodMetrics.fromPeriod(tempPeriod);
      }
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          selection.title,
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialTimeRow(
              context,
              'details.start'.tr(),
              selection.startTime,
              astroState,
              settings,
              civilColor,
              selection.color,
              selection,
              false,
            ),
            if (selection.endTime != null) ...[
              const SizedBox(height: 12),
              _buildDialTimeRow(
                context,
                'details.end'.tr(),
                selection.endTime!,
                astroState,
                settings,
                civilColor,
                selection.color,
                selection,
                true,
              ),
            ],
            if (periodMetrics != null) ...[
              const SizedBox(height: 16),
              _buildPeriodMetricRow(
                'home.suwayas_count'.tr(),
                '${periodMetrics.suwayaCount} ${'details.suwayas'.tr()}',
                civilColor,
                selection.color,
              ),
              const SizedBox(height: 10),
              _buildPeriodMetricRow(
                'details.suwaya_length'.tr(),
                _formatSuwayaDuration(periodMetrics.actualSuwayaDuration),
                civilColor,
                selection.color,
              ),
              const SizedBox(height: 10),
              _buildPeriodMetricRow(
                'details.flow_speed'.tr(),
                '${periodMetrics.flowSpeed.toStringAsFixed(2)}x',
                civilColor,
                selection.color,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.done'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodMetricRow(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label, style: TextStyle(color: labelColor, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatSuwayaDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes ${'details.minute'.tr()} $seconds ${'details.sec'.tr()}';
  }

  Widget _buildDialTimeRow(
    BuildContext context,
    String label,
    DateTime time,
    AstroState astroState,
    SettingsModel settings,
    Color civilColor,
    Color suwayaColor,
    DialSelection selection,
    bool isEnd,
  ) {
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    const baseStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
    );

    final fixedTime =
        _getDynamicOrFixedAstroTime(selection, astroState, time, isEnd);
    final formattedSuwaya = formatSuwayaTime(
      fixedTime.globalIndex,
      fixedTime.minute,
      separator: '|',
      isRTL: isRTL,
      iconMode: settings.suwayaIconMode,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: civilColor, fontSize: 13)),
        const SizedBox(width: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Text(
                formatCivilTime(
                  time,
                  format: settings.civilTimeFormat,
                  locale: context.locale.languageCode,
                  context: context,
                ),
                style: baseStyle.copyWith(color: civilColor),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '/',
                style: TextStyle(color: civilColor.withValues(alpha: 0.5)),
              ),
            ),
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Text(
                formattedSuwaya,
                style: baseStyle.copyWith(color: suwayaColor),
              ),
            ),
          ],
        ),
      ],
    );
  }

  DateTime _getCityTime(SettingsModel settings) {
    final loc = settings.activeLocation;
    if (loc != null && loc.isAutoLocation == false && loc.timezone != null) {
      try {
        final location = tz.getLocation(loc.timezone!);
        final nowInTarget = tz.TZDateTime.now(location);
        return DateTime(
          nowInTarget.year,
          nowInTarget.month,
          nowInTarget.day,
          nowInTarget.hour,
          nowInTarget.minute,
          nowInTarget.second,
        );
      } catch (_) {}
    }
    return DateTime.now();
  }

  /// 🌟 دالة مساعدة تضمن ظهور كلمة (نهار/ليلة) متبوعة باسم يوم الأسبوع دائماً في كل اللغات
  String _formatDayNightTitle(BuildContext context, bool isNight, String dayName) {
    final key = isNight ? 'home.night_of' : 'home.day_of';
    final translated = key.tr(args: [dayName]);

    // إذا كانت الترجمة موجودة وتحتوي بالفعل على اسم اليوم
    if (translated != key && translated.contains(dayName)) {
      return translated;
    }
    // إذا كانت الترجمة موجودة ككلمة (نهار / ليلة) بدون {} نلحق بها اسم اليوم
    if (translated != key) {
      return '$translated $dayName';
    }

    // نص احتياطي فوري
    final isAr = context.locale.languageCode == 'ar';
    if (isAr) {
      return isNight ? 'ليلة $dayName' : 'نهار $dayName';
    }
    return isNight ? 'Night of $dayName' : 'Day of $dayName';
  }

  Widget _buildTopHeader(
    BuildContext context,
    AstroState astroState,
    Color pColor,
    bool isDark,
    DateTime cityNow,
    SettingsModel settings,
  ) {
    DateTime? rawFajr, rawMaghrib;
    for (var p in astroState.periods) {
      if (p.periodKey == PeriodKey.nightMidnightFajr) rawFajr = p.endTime;
      if (p.periodKey == PeriodKey.nightMaghribIsha) rawMaghrib = p.startTime;
    }
    rawFajr ??= DateTime(cityNow.year, cityNow.month, cityNow.day, 4, 30);
    rawMaghrib ??= DateTime(cityNow.year, cityNow.month, cityNow.day, 18, 0);

    final DateTime todayFajr = DateTime(
      cityNow.year,
      cityNow.month,
      cityNow.day,
      rawFajr.hour,
      rawFajr.minute,
    );
    final DateTime todayMaghrib = DateTime(
      cityNow.year,
      cityNow.month,
      cityNow.day,
      rawMaghrib.hour,
      rawMaghrib.minute,
    );

    final langCode = context.locale.languageCode;
    final safeIntl = (langCode == 'ff' || langCode == 'ug') ? 'en' : langCode;

    // 🌟 التعديل 3: تحديد التاريخ الإسلامي أولاً ثم استخراج اسم يوم الأسبوع وإظهاره بجانب نهار/ليلة
    late final DateTime islamicDate;
    late final bool isNight;

    if (cityNow.isBefore(todayFajr)) {
      islamicDate = cityNow;
      isNight = true;
    } else if (cityNow.isBefore(todayMaghrib)) {
      islamicDate = cityNow;
      isNight = false;
    } else {
      islamicDate = cityNow.add(const Duration(days: 1));
      isNight = true;
    }

    final String dayName = DateFormat('EEEE', safeIntl).format(islamicDate);
    final String dayNightStr = _formatDayNightTitle(context, isNight, dayName);

    final hijriDate = HijriCalendar.fromDate(islamicDate);
    final monthName = 'hijri.m${hijriDate.hMonth}'.tr();
    final hijriStr = '${hijriDate.hDay} $monthName ${hijriDate.hYear}';

    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      isNight ? LucideIcons.moon : LucideIcons.sun,
                      color: pColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Stack(
                      children: [
                        Text(
                          dayNightStr,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Tajawal',
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 1.0
                              ..color = textColor,
                          ),
                        ),
                        Text(
                          dayNightStr,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$hijriStr ${'common.ah'.tr()}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Tajawal',
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          MiniAstroDial(periods: astroState.periods, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildLegendChip(
    String title,
    Color color,
    bool isDark,
    bool isHighlighted,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF13131A) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isHighlighted ? color : color.withValues(alpha: 0.3),
            width: isHighlighted ? 2.0 : 1.5,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: color,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.watch(notificationSchedulerProvider);
    final astroState = ref.watch(astroProvider);
    final routineArcs = ref.watch(routineArcsProvider);
    final settings = ref.watch(settingsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF0D0D12) : Colors.white;
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;

    if (astroState.periods.isEmpty) {
      return Scaffold(
        backgroundColor: scaffoldBgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(astroProvider.notifier).resetToRealTime(),
                icon: const Icon(Icons.refresh),
                label: Text('common.retry'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pColor = astroState.currentPeriod.uiColor.adapt(context);
    final cityNow = _getCityTime(settings);

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
        scrolledUnderElevation: 0,
        titleSpacing: 4,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(
              LucideIcons.menu,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const LocationHeader(),
        actions: [
          // 🌟 مفتاح التبديل (Switch) للوقت السُويعي في الشريط العلوي
          Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(settingsProvider);
              final primaryColor = Theme.of(context).primaryColor;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'common.suwaya_time'.tr(),
                    style: TextStyle(
                      color: settings.useAstroTimeForIbadat
                          ? primaryColor
                          : (isDark ? Colors.white70 : Colors.black54),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.75,
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
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: pColor,
        backgroundColor: surfaceColor,
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          ref.read(astroProvider.notifier).resetToRealTime();
          await ref
              .read(settingsProvider.notifier)
              .refreshDynamicLocationIfNeeded();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: _buildTopHeader(
                context,
                astroState,
                pColor,
                isDark,
                cityNow,
                settings,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    // 🌟 زر تعديل القرص في أعلى يسار القرص (عند اللغات RTL) وأعلى يمينه (عند اللغات LTR)
                    // 🌟 التعديل 2: وضع زر تخصيص القرص على اليمين في اللغات RTL وعلى اليسار في اللغات LTR
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        start: 20,
                        bottom: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => showDialAndIbadatMarkersSheet(
                              context,
                              astroState,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: pColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: pColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.sliders_horizontal,
                                    color: pColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'home.edit_dial'.tr() != 'home.edit_dial'
                                        ? 'home.edit_dial'.tr()
                                        : (context.locale.languageCode == 'ar'
                                            ? 'تخصيص القرص'
                                            : 'Customize Dial'),
                                    style: TextStyle(
                                      color: pColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final maxSize = constraints.maxWidth;
                        return RepaintBoundary(
                          child: PremiumAstroDial(
                            size: maxSize,
                            routineArcs: routineArcs,
                            onItemTapped: (selection) => _showDialItemDialog(
                              context,
                              selection,
                              astroState,
                              settings,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  final todayTasks = ref.watch(tasksProvider).todayTasks;
                  final tasksForLegend =
                      todayTasks.where((t) => t.showOnDial).toList();

      
                  final routines = ref.watch(routinesProvider);
                  final activeRoutines = routines.where((r) {
                    if (!r.isActive) return false;
                    if (r.recurrenceDays == null || r.recurrenceDays!.isEmpty) {
                      return true;
                    }
                    final logicalDate = getLogicalDateForMode(
                      isAstroTime: r.isAstroTime,
                      astroState: astroState,
                      civilReference: cityNow,
                    );
                    return r.recurrenceDays!.contains(logicalDate.weekday);
                  }).toList();

                  if (activeRoutines.isEmpty && tasksForLegend.isEmpty) {
                    return const SizedBox(height: 100);
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'home.dial_indicators'.tr(),
                              style: TextStyle(
                                color: pColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                context.go('/tasks?tab=periods');
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: pColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  LucideIcons.pencil,
                                  color: pColor,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 10,
                          children: [
                            ...activeRoutines.map((r) {
                              final isHighlighted =
                                  ref.watch(highlightedRoutineProvider) == r.id;
                              return _buildLegendChip(
                                r.title,
                                Color(r.colorValue),
                                isDark,
                                isHighlighted,
                                () {
                                  HapticFeedback.lightImpact();
                                  ref
                                      .read(highlightedRoutineProvider.notifier)
                                      .state = r.id;
                                  ref
                                      .read(highlightedTaskProvider.notifier)
                                      .state = null;
                                  Future.delayed(
                                    const Duration(seconds: 3),
                                    () {
                                      if (ref.read(
                                              highlightedRoutineProvider) ==
                                          r.id) {
                                        ref
                                            .read(
                                              highlightedRoutineProvider
                                                  .notifier,
                                            )
                                            .state = null;
                                      }
                                    },
                                  );
                                },
                              );
                            }),
                            ...tasksForLegend.map((task) {
                              Color tColor =
                                  getNeonColorForCategory(task.category);
                              final isHighlighted =
                                  ref.watch(highlightedTaskProvider) == task.id;

                              return _buildLegendChip(
                                task.title,
                                tColor,
                                isDark,
                                isHighlighted,
                                () {
                                  HapticFeedback.lightImpact();
                                  ref
                                      .read(highlightedTaskProvider.notifier)
                                      .state = task.id;
                                  ref
                                      .read(highlightedRoutineProvider.notifier)
                                      .state = null;
                                  Future.delayed(
                                    const Duration(seconds: 3),
                                    () {
                                      if (ref.read(highlightedTaskProvider) ==
                                          task.id) {
                                        ref
                                            .read(
                                              highlightedTaskProvider.notifier,
                                            )
                                            .state = null;
                                      }
                                    },
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 112.0),
        child: PremiumExpandableFab(
          color: pColor,
          isDark: isDark,
          currentPeriodId: astroState.currentPeriod.id,
          currentSuwaya: astroState.currentSuwayaTime.periodLocalSlotNumber,
        ),
      ),
    );
  }
}

class PremiumExpandableFab extends StatefulWidget {
  final Color color;
  final bool isDark;
  final int currentPeriodId;
  final int currentSuwaya;

  const PremiumExpandableFab({
    super.key,
    required this.color,
    required this.isDark,
    required this.currentPeriodId,
    required this.currentSuwaya,
  });

  @override
  State<PremiumExpandableFab> createState() => _PremiumExpandableFabState();
}

class _PremiumExpandableFabState extends State<PremiumExpandableFab> {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: null,
      backgroundColor: widget.color,
      foregroundColor: widget.isDark ? Colors.black : Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        HapticFeedback.lightImpact();
        context.push(
          '/add-task',
          extra: {
            'currentPeriodId': widget.currentPeriodId,
            'currentSuwaya': widget.currentSuwaya,
          },
        );
      },
      child: const Icon(LucideIcons.plus, size: 28),
    );
  }
}