import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:suwaya/core/notification/scheduler_service.dart';
import 'package:suwaya/models/settings_model.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/astro_engine/astro_provider.dart';
import '../../core/astro_engine/astro_models.dart';
import '../../models/task_model.dart';
import '../tasks/tasks_provider.dart';
import '../settings/settings_provider.dart';
import '../routines/routines_provider.dart'; 

import '../../shared/widgets/task_card.dart';
import 'widgets/location_header.dart'; 
import '../settings/settings_screen.dart';
import '../tasks/screens/universal_add_screen.dart'; 
import 'widgets/premium_astro_dial.dart'; 
import 'widgets/period_details_sheet.dart';
import '../routines/widgets/routines_list_sheet.dart';
import 'widgets/mini_astro_dial.dart';

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

  DateTime _getCityTime(SettingsModel settings) {
    final loc = settings.activeLocation;
    if (loc != null && loc.isAutoLocation == false && loc.timezone != null) {
      try {
        final location = tz.getLocation(loc.timezone!);
        final nowInTarget = tz.TZDateTime.now(location);
        return DateTime(nowInTarget.year, nowInTarget.month, nowInTarget.day, nowInTarget.hour, nowInTarget.minute, nowInTarget.second);
      } catch (_) {}
    }
    return DateTime.now();
  }

  Widget _buildTopHeader(BuildContext context, AstroState astroState, Color pColor, bool isDark, DateTime cityNow) {
    DateTime? rawFajr, rawMaghrib;
    for (var p in astroState.periods) {
      if (p.id == 1) rawFajr = p.startTime;
      if (p.id == 5) rawMaghrib = p.startTime;
    }
    rawFajr ??= DateTime(cityNow.year, cityNow.month, cityNow.day, 4, 30);
    rawMaghrib ??= DateTime(cityNow.year, cityNow.month, cityNow.day, 18, 0);

    final DateTime todayFajr = DateTime(cityNow.year, cityNow.month, cityNow.day, rawFajr.hour, rawFajr.minute);
    final DateTime todayMaghrib = DateTime(cityNow.year, cityNow.month, cityNow.day, rawMaghrib.hour, rawMaghrib.minute);

    String dayNightStr = '';
    DateTime islamicDate = cityNow;
    bool isNight = false;
    final langCode = context.locale.languageCode;
    // 🌟 آلية الأمان لتجنب انهيار التواريخ
    final safeIntl = (langCode == 'ff' || langCode == 'ug') ? 'en' : langCode;

    if (cityNow.isBefore(todayFajr)) {
      islamicDate = cityNow;
      isNight = true;
      dayNightStr = '${'home.night_of'.tr()} ${DateFormat('EEEE', safeIntl).format(islamicDate)}'; // 🌟
    } else if (cityNow.isBefore(todayMaghrib)) {
      islamicDate = cityNow;
      isNight = false;
      dayNightStr = '${'home.day_of'.tr()} ${DateFormat('EEEE', safeIntl).format(islamicDate)}'; // 🌟
    } else {
      islamicDate = cityNow.add(const Duration(days: 1));
      isNight = true;
      dayNightStr = '${'home.night_of'.tr()} ${DateFormat('EEEE', safeIntl).format(islamicDate)}'; // 🌟
    }
    
    final hijriDate = HijriCalendar.fromDate(islamicDate); 
    final monthName = 'hijri.m${hijriDate.hMonth}'.tr();
    final hijriStr = '${hijriDate.hDay} $monthName ${hijriDate.hYear}';

    final gregorianDate = DateFormat('d MMMM yyyy', safeIntl).format(cityNow); // 🌟
    final civilTime = DateFormat('hh:mm a', safeIntl).format(cityNow); // 🌟
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isNight ? LucideIcons.moon : LucideIcons.sun, color: pColor, size: 16),
                    const SizedBox(width: 8),
                    Text(dayNightStr, style: TextStyle(color: pColor, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(' • $gregorianDate', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('$hijriStr ${'common.ah'.tr()}', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Tajawal', letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: pColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: pColor.withValues(alpha: 0.3))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('home.civil_time'.tr(), style: TextStyle(color: textColor.withValues(alpha: 0.5), fontSize: 9)),
                          Text(civilTime, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: pColor, borderRadius: BorderRadius.circular(8), boxShadow: [BoxShadow(color: pColor.withValues(alpha: 0.3), blurRadius: 4)]),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('home.astro_time'.tr(), style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 9)),
                          Text(astroState.currentFormattedVirtualTime, style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          MiniAstroDial(periods: astroState.periods, isDark: isDark),
        ],
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
      return Scaffold(backgroundColor: scaffoldBgColor, body: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)));
    }

    final pColor = astroState.currentPeriod.color.adapt(context);
    final cityNow = _getCityTime(settings); 

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, title: const LocationHeader(), 
        actions: [
          IconButton(icon: Icon(LucideIcons.settings, color: isDark ? Colors.white70 : Colors.black87), onPressed: () { HapticFeedback.selectionClick(); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: pColor, backgroundColor: surfaceColor,
        onRefresh: () async { HapticFeedback.mediumImpact(); ref.read(astroProvider.notifier).resetToRealTime(); await ref.read(settingsProvider.notifier).refreshDynamicLocationIfNeeded(); },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: _buildTopHeader(context, astroState, pColor, isDark, cityNow), 
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
                        onPeriodTapped: (period) {
                          showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => PeriodDetailsSheet(period: period, astroState: ref.read(astroProvider), tasks: ref.read(tasksProvider).todayTasks));
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  final tasksForLegend = ref.watch(tasksProvider).todayTasks.where((t) => t.showOnDial).toList();
                  if (tasksForLegend.isEmpty) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('home.dial_indicators'.tr(), style: TextStyle(color: pColor, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 10,
                          children: tasksForLegend.map((task) {
                            Color tColor = getNeonColorForCategory(task.category); 
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF13131A) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: tColor.withValues(alpha: 0.3), width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12, height: 12,
                                    decoration: BoxDecoration(color: tColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: tColor.withValues(alpha: 0.6), blurRadius: 6)]),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(task.title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: pColor.withValues(alpha: 0.1)),
                      ],
                    ),
                  );
                },
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [Text('home.period_tasks'.tr(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: pColor)), const SizedBox(width: 8), Icon(LucideIcons.list_todo, color: pColor.withValues(alpha: 0.5), size: 20)]),
                    TextButton.icon(
                      onPressed: () { HapticFeedback.selectionClick(); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const RoutinesListSheet()); },
                      icon: Icon(LucideIcons.layers, color: pColor, size: 18), label: Text('home.manage_periods'.tr(), style: TextStyle(color: pColor, fontWeight: FontWeight.bold, fontSize: 13)),
                      style: TextButton.styleFrom(backgroundColor: pColor.withValues(alpha: 0.1), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                    ),
                  ],
                ),
              ),
            ),
            const _SliverTasksSection(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: PremiumExpandableFab(color: pColor, isDark: isDark, currentPeriodId: astroState.currentPeriod.id, currentSuwaya: astroState.currentSuwaya),
    );
  }
}

class _SliverTasksSection extends ConsumerWidget {
  const _SliverTasksSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final astro = ref.watch(astroProvider);
    final tasksAsync = ref.watch(currentTasksProvider);
    if (tasksAsync.isLoading) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: Colors.amber)));
    final tasks = (tasksAsync.valueOrNull ?? []).where((t) => t.targetPeriodId == astro.currentPeriod.id || t.type == TaskType.permanent).toList();
    if (tasks.isEmpty) return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('home.no_tasks'.tr(), style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38)))));
    return SliverPadding(padding: const EdgeInsets.symmetric(horizontal: 24), sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TaskCard(task: tasks[index])), childCount: tasks.length)));
  }
}

final currentTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final state = ref.watch(tasksProvider); return state.nowTasks;
});

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
    required this.currentSuwaya
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => UniversalAddScreen(currentPeriodId: widget.currentPeriodId, currentSuwaya: widget.currentSuwaya)));
      },
      child: const Icon(LucideIcons.plus, size: 28),
    );
  }
}