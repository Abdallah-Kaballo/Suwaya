import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:suwaya/features/home/widgets/dial/dial_constants.dart';
import 'package:suwaya/features/home/widgets/dial/period_metrics.dart';
import 'package:suwaya_time/suwaya_time.dart';

import 'package:suwaya/core/notification/scheduler_service.dart';
import 'package:suwaya/models/settings_model.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/astro_engine/astro_provider.dart';
import '../../models/task_model.dart';
import '../tasks/tasks_provider.dart';
import '../settings/settings_provider.dart';
import '../routines/routines_provider.dart';
import '../../core/providers/ui_providers.dart';

import 'widgets/location_header.dart';
import 'widgets/premium_astro_dial.dart';
import 'widgets/dial/dial_models.dart';
import 'widgets/mini_astro_dial.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../shared/widgets/suwaya_time_text.dart';
import '../../core/theme/astro_ui_extensions.dart';
import 'package:go_router/go_router.dart';

Color getNeonColorForCategory(TaskCategory category) {
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _showDialItemDialog(
    BuildContext context,
    DialSelection selection,
    AstroState astroState,
    SettingsModel settings,
  ) async {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final civilColor = textColor.withValues(alpha: 0.82);
    AstroPeriod? selectedPeriod;
    if (selection.type == DialSelectionType.period) {
      final periodId = int.tryParse(selection.id);
      for (final period in astroState.periods) {
        if (period.id == periodId) {
          selectedPeriod = period;
          break;
        }
      }
    }
    final periodMetrics = selectedPeriod == null
        ? null
        : PeriodMetrics.fromPeriod(selectedPeriod);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(selection.title, style: TextStyle(color: textColor)),
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
      String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(label, style: TextStyle(color: labelColor, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Text(value,
            textAlign: TextAlign.end,
            style: TextStyle(
                color: valueColor, fontSize: 13, fontWeight: FontWeight.w700)),
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
  ) {
    final suwayaTime = astroState.toGlobalSuwayaTime(time);
    const baseStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: civilColor, fontSize: 13)),
        const SizedBox(width: 10),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ClockTimeText.civil(
              civilTime: time,
              civilTimeFormat: settings.civilTimeFormat,
              locale: context.locale.languageCode,
              style: baseStyle.copyWith(color: civilColor),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('/',
                  style: TextStyle(color: civilColor.withValues(alpha: 0.5))),
            ),
            ClockTimeText.suwaya(
              globalSuwayaIndex: suwayaTime.suwayaIndex,
              virtualMinute: suwayaTime.minute,
              style: baseStyle.copyWith(color: suwayaColor),
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
        return DateTime(nowInTarget.year, nowInTarget.month, nowInTarget.day,
            nowInTarget.hour, nowInTarget.minute, nowInTarget.second);
      } catch (_) {}
    }
    return DateTime.now();
  }

  Widget _buildTopHeader(BuildContext context, AstroState astroState,
      Color pColor, bool isDark, DateTime cityNow, SettingsModel settings) {
    DateTime? rawFajr, rawMaghrib;
    for (var p in astroState.periods) {
      if (p.id == 1) rawFajr = p.startTime;
      if (p.id == 5) rawMaghrib = p.startTime;
    }
    rawFajr ??= DateTime(cityNow.year, cityNow.month, cityNow.day, 4, 30);
    rawMaghrib ??= DateTime(cityNow.year, cityNow.month, cityNow.day, 18, 0);

    final DateTime todayFajr = DateTime(
        cityNow.year, cityNow.month, cityNow.day, rawFajr.hour, rawFajr.minute);
    final DateTime todayMaghrib = DateTime(cityNow.year, cityNow.month,
        cityNow.day, rawMaghrib.hour, rawMaghrib.minute);

    String dayNightStr = '';
    DateTime islamicDate = cityNow;
    bool isNight = false;
    final langCode = context.locale.languageCode;

    final safeIntl = (langCode == 'ff' || langCode == 'ug') ? 'en' : langCode;

    if (cityNow.isBefore(todayFajr)) {
      islamicDate = cityNow;
      isNight = true;
      dayNightStr =
          '${'home.night_of'.tr()} ${DateFormat('EEEE', safeIntl).format(islamicDate)}';
    } else if (cityNow.isBefore(todayMaghrib)) {
      islamicDate = cityNow;
      isNight = false;
      dayNightStr =
          '${'home.day_of'.tr()} ${DateFormat('EEEE', safeIntl).format(islamicDate)}';
    } else {
      islamicDate = cityNow.add(const Duration(days: 1));
      isNight = true;
      dayNightStr =
          '${'home.night_of'.tr()} ${DateFormat('EEEE', safeIntl).format(islamicDate)}';
    }

    final hijriDate = HijriCalendar.fromDate(islamicDate);
    final monthName = 'hijri.m${hijriDate.hMonth}'.tr();
    final hijriStr = '${hijriDate.hDay} $monthName ${hijriDate.hYear}';

    final gregorianDate = DateFormat('d MMMM yyyy', safeIntl).format(cityNow);
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
                    Icon(isNight ? LucideIcons.moon : LucideIcons.sun,
                        color: pColor, size: 24),
                    const SizedBox(width: 8),
                    Stack(
                      children: [
                        Text(dayNightStr,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Tajawal',
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 1.0
                                  ..color = Colors.white)),
                        Text(dayNightStr,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.normal,
                                fontFamily: 'Tajawal')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClockTimeText.civil(
                      civilTime: cityNow,
                      civilTimeFormat: settings.civilTimeFormat,
                      locale: safeIntl,
                      style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Tajawal'),
                    ),
                    Text(' • $gregorianDate',
                        style: TextStyle(
                            color: textColor.withValues(alpha: 0.6),
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Tajawal')),
                  ],
                ),
                const SizedBox(height: 6),
                Text('$hijriStr ${'common.ah'.tr()}',
                    style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Tajawal',
                        letterSpacing: 0.5)),
              ],
            ),
          ),
          MiniAstroDial(periods: astroState.periods, isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildLegendChip(String title, Color color, bool isDark,
      bool isHighlighted, VoidCallback? onTap) {
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
              width: isHighlighted ? 2.0 : 1.5),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2)
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
                              color: color, blurRadius: 8, spreadRadius: 2)
                        ]
                      : []),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationSchedulerProvider);
    final astroState = ref.watch(astroProvider);
    final routineArcs = ref.watch(routineArcsProvider);
    final settings = ref.watch(settingsProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF0D0D12) : Colors.white;
    final scaffoldBgColor = isDark ? Colors.black : const Color(0xFFF5F7FA);

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
                    foregroundColor: Colors.white),
              )
            ],
          )));
    }

    final pColor = astroState.currentPeriod.uiColor.adapt(context);
    final cityNow = _getCityTime(settings);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      drawer: const AppDrawer(),
      onDrawerChanged: (isOpen) =>
          ref.read(isDrawerOpenProvider.notifier).state = isOpen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(LucideIcons.menu,
                color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const LocationHeader(),
        actions: const [SizedBox(width: 48)],
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
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: _buildTopHeader(
                  context, astroState, pColor, isDark, cityNow, settings),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: LayoutBuilder(
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
              ),
            ),
            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  final todayTasks = ref.watch(tasksProvider).todayTasks;
                  final tasksForLegend =
                      todayTasks.where((t) => t.showOnDial).toList();

                  final routines = ref.watch(routinesProvider);
                  final todayWeekday = DateTime.now().weekday;
                  final activeRoutines = routines
                      .where((r) =>
                          r.isActive &&
                          (r.recurrenceDays == null ||
                              r.recurrenceDays!.isEmpty ||
                              r.recurrenceDays!.contains(todayWeekday)))
                      .toList();

                  if (activeRoutines.isEmpty && tasksForLegend.isEmpty) {
                    return const SizedBox(height: 100);
                  }

                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 🌟 تم تكبير الخط هنا إلى 16 وتكبير أيقونة القلم إلى 18
                            Text('home.dial_indicators'.tr(),
                                style: TextStyle(
                                    color: pColor,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
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
                                child: Icon(LucideIcons.pencil,
                                    color: pColor, size: 18),
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
                                  isHighlighted, () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(highlightedRoutineProvider.notifier)
                                    .state = r.id;
                                ref
                                    .read(highlightedTaskProvider.notifier)
                                    .state = null;
                                Future.delayed(const Duration(seconds: 3), () {
                                  if (ref.read(highlightedRoutineProvider) ==
                                      r.id) {
                                    ref
                                        .read(
                                            highlightedRoutineProvider.notifier)
                                        .state = null;
                                  }
                                });
                              });
                            }),
                            ...tasksForLegend.map((task) {
                              Color tColor =
                                  getNeonColorForCategory(task.category);
                              final isHighlighted =
                                  ref.watch(highlightedTaskProvider) == task.id;

                              return _buildLegendChip(
                                  task.title, tColor, isDark, isHighlighted,
                                  () {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(highlightedTaskProvider.notifier)
                                    .state = task.id;
                                ref
                                    .read(highlightedRoutineProvider.notifier)
                                    .state = null;
                                Future.delayed(const Duration(seconds: 3), () {
                                  if (ref.read(highlightedTaskProvider) ==
                                      task.id) {
                                    ref
                                        .read(highlightedTaskProvider.notifier)
                                        .state = null;
                                  }
                                });
                              });
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
            currentSuwaya: astroState.currentSuwaya),
      ),
    );
  }
}

class PremiumExpandableFab extends StatefulWidget {
  final Color color;
  final bool isDark;
  final int currentPeriodId;
  final int currentSuwaya;

  const PremiumExpandableFab(
      {super.key,
      required this.color,
      required this.isDark,
      required this.currentPeriodId,
      required this.currentSuwaya});

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
        context.push('/add-task', extra: {
          'currentPeriodId': widget.currentPeriodId,
          'currentSuwaya': widget.currentSuwaya,
        });
      },
      child: const Icon(LucideIcons.plus, size: 28),
    );
  }
}
