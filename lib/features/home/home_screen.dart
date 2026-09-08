import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:suwaya/core/astro_engine/astro_models.dart';

import 'package:suwaya/core/notification/scheduler_service.dart';
import 'package:suwaya/models/settings_model.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/astro_engine/astro_provider.dart';
import '../../models/task_model.dart';
import '../tasks/tasks_provider.dart';
import '../settings/settings_provider.dart';
import '../routines/routines_provider.dart'; 
import '../../core/providers/ui_providers.dart'; 

import '../../shared/widgets/task_card.dart';
import 'widgets/location_header.dart'; 
import 'widgets/premium_astro_dial.dart'; 
import '../routines/widgets/routines_list_sheet.dart';
import 'widgets/mini_astro_dial.dart';
import '../../shared/widgets/app_drawer.dart';
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

// 🌟 دالة مساعدة للحصول على ألوان الفترات بأمان
Color _getSafePeriodColor(int id) {
  switch (id) {
    case 1: return const Color(0xFF64B5F6);
    case 2: return Colors.orangeAccent;
    case 3: return const Color(0xFFFFCA28);
    case 4: return const Color(0xFFFF9800);
    case 5: return const Color(0xFFE53935);
    case 6: return const Color(0xFF3F51B5);
    case 7: return const Color(0xFF1A237E);
    default: return Colors.grey;
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _buildInfoRow(String title, String value, Color textColor, Color pColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 14)),
          Text(value, style: TextStyle(color: pColor, fontSize: 14, fontWeight: FontWeight.normal)),
        ],
      ),
    );
  }

  // 🌟 شاشة Info الجديدة للقرص (تستبدل الشاشة السفلية القديمة)
  void _showPeriodInfoDialog(BuildContext context, AstroPeriod period, AstroState astroState) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final surfaceColor = Theme.of(context).cardColor;
    
    final pColor = _getSafePeriodColor(period.id);

    // حساب الطول الفعلي والسرعة
    final durationMicro = period.endTime.difference(period.startTime).inMicroseconds;
    final suwayaMicro = durationMicro ~/ (period.suwayasCount > 0 ? period.suwayasCount : 1);
    final durationSecs = suwayaMicro ~/ 1000000;
    final sMins = durationSecs ~/ 60;
    final sSecs = durationSecs % 60;
    final actualLengthStr = '${sMins.toString().padLeft(2, '0')}:${sSecs.toString().padLeft(2, '0')}';

    final periodMins = durationMicro ~/ 60000000;
    final virtualMins = period.suwayasCount * 30.0;
    double speed = periodMins > 0 ? (virtualMins / periodMins) : 1.0;

    // حساب السويعة التراكمية الصحيحة
    int startGlobalSuwaya = 0;
    for (var p in astroState.periods) {
      if (p.id == period.id) break;
      startGlobalSuwaya += p.suwayasCount;
    }
    int endGlobalSuwaya = startGlobalSuwaya + period.suwayasCount - 1;

    String periodName = '';
    switch(period.id) {
      case 1: periodName = 'periods.fajr'.tr(); break;
      case 2: periodName = 'periods.duha'.tr(); break;
      case 3: periodName = 'periods.dhuhr'.tr(); break;
      case 4: periodName = 'periods.asr'.tr(); break;
      case 5: periodName = 'periods.maghrib'.tr(); break;
      case 6: periodName = 'periods.middle_third'.tr(); break;
      case 7: periodName = 'periods.last_third'.tr(); break;
      default: periodName = period.nameKey.tr();
    }

    final langCode = context.locale.languageCode;
    final safeIntl = (langCode == 'ff' || langCode == 'ug') ? 'en' : langCode;
    final startCivil = DateFormat('hh:mm a', safeIntl).format(period.startTime);
    final endCivil = DateFormat('hh:mm a', safeIntl).format(period.endTime);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.info, color: pColor, size: 32),
              const SizedBox(height: 16),
              Text('home.period_info'.tr(), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildInfoRow('common.period'.tr(), periodName, textColor, pColor),
              _buildInfoRow('home.suwayas_count'.tr(), period.suwayasCount.toString(), textColor, pColor),
              _buildInfoRow('pomodoro.actual_length'.tr(), actualLengthStr, textColor, pColor),
              _buildInfoRow('pomodoro.time_speed'.tr(), '${speed.toStringAsFixed(2)}x', textColor, pColor),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Colors.white12),
              ),
              _buildInfoRow('details.start'.tr(), '${'common.suwaya'.tr()} ${startGlobalSuwaya.toString().padLeft(2, '0')} / $startCivil', textColor, pColor),
              _buildInfoRow('details.end'.tr(), '${'common.suwaya'.tr()} ${endGlobalSuwaya.toString().padLeft(2, '0')} / $endCivil', textColor, pColor),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: pColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('common.done'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

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
    
    final safeIntl = (langCode == 'ff' || langCode == 'ug') ? 'en' : langCode;

    if (cityNow.isBefore(todayFajr)) {
      islamicDate = cityNow;
      isNight = true;
      dayNightStr = '${'home.night_of'.tr()} ${DateFormat('EEEE', safeIntl).format(islamicDate)}'; 
    } else if (cityNow.isBefore(todayMaghrib)) {
      islamicDate = cityNow;
      isNight = false;
      dayNightStr = '${'home.day_of'.tr()} ${DateFormat('EEEE', safeIntl).format(islamicDate)}'; 
    } else {
      islamicDate = cityNow.add(const Duration(days: 1));
      isNight = true;
      dayNightStr = '${'home.night_of'.tr()} ${DateFormat('EEEE', safeIntl).format(islamicDate)}'; 
    }
    
    final hijriDate = HijriCalendar.fromDate(islamicDate); 
    final monthName = 'hijri.m${hijriDate.hMonth}'.tr();
    final hijriStr = '${hijriDate.hDay} $monthName ${hijriDate.hYear}';

    final gregorianDate = DateFormat('d MMMM yyyy', safeIntl).format(cityNow); 
    final civilTime = DateFormat('hh:mm a', safeIntl).format(cityNow); 
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
                    Icon(isNight ? LucideIcons.moon : LucideIcons.sun, color: pColor, size: 24), 
                    const SizedBox(width: 8),
                    Stack(
                      children: [
                        Text(dayNightStr, style: TextStyle(fontSize: 22, fontWeight: FontWeight.normal, fontFamily: 'Tajawal', foreground: Paint()..style=PaintingStyle.stroke..strokeWidth=1.0..color=Colors.white)),
                        Text(dayNightStr, style: TextStyle(color: pColor, fontSize: 22, fontWeight: FontWeight.normal, fontFamily: 'Tajawal')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                
                Stack(
                  children: [
                    Text('$civilTime • $gregorianDate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, fontFamily: 'Tajawal', foreground: Paint()..style=PaintingStyle.stroke..strokeWidth=1.0..color=Colors.white)),
                    Text('$civilTime • $gregorianDate', style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 16, fontWeight: FontWeight.normal, fontFamily: 'Tajawal')),
                  ],
                ),
                const SizedBox(height: 6),
                
                Text('$hijriStr ${'common.ah'.tr()}', style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Tajawal', letterSpacing: 0.5)),
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

    final pColor = astroState.currentPeriod.uiColor.adapt(context);
    final cityNow = _getCityTime(settings); 

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      drawer: const AppDrawer(), 
      onDrawerChanged: (isOpen) => ref.read(isDrawerOpenProvider.notifier).state = isOpen,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        scrolledUnderElevation: 0, 
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(LucideIcons.menu, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const LocationHeader(), 
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
                        // 🌟 تم استبدال الشاشة السفلية بـ Dialog النافذة المنبثقة
                        onPeriodTapped: (period) {
                          _showPeriodInfoDialog(context, period, astroState);
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
                            final isHighlighted = ref.watch(highlightedTaskProvider) == task.id;
                            
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                ref.read(highlightedTaskProvider.notifier).state = task.id;
                                Future.delayed(const Duration(seconds: 3), () {
                                  if (ref.read(highlightedTaskProvider) == task.id) {
                                    ref.read(highlightedTaskProvider.notifier).state = null;
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF13131A) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isHighlighted ? tColor : tColor.withValues(alpha: 0.3), 
                                    width: isHighlighted ? 2.0 : 1.5
                                  ),
                                  boxShadow: isHighlighted ? [BoxShadow(color: tColor.withValues(alpha: 0.4), blurRadius: 12, spreadRadius: 2)] : [],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 12, height: 12,
                                      decoration: BoxDecoration(
                                        color: tColor, 
                                        shape: BoxShape.circle, 
                                        boxShadow: isHighlighted ? [BoxShadow(color: tColor, blurRadius: 8, spreadRadius: 2)] : []
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(task.title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), 
        child: PremiumExpandableFab(color: pColor, isDark: isDark, currentPeriodId: astroState.currentPeriod.id, currentSuwaya: astroState.currentSuwaya),
      ),
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
        context.push('/add-task', extra: {
          'currentPeriodId': widget.currentPeriodId,
          'currentSuwaya': widget.currentSuwaya,
        });
      },
      child: const Icon(LucideIcons.plus, size: 28),
    );
  }
}