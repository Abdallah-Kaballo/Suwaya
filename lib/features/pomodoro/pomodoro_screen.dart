import 'dart:math' show pi, cos, sin;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya_time/suwaya_time.dart';

import '../../core/astro_engine/astro_provider.dart';
import '../../core/notification/routine_time_resolver.dart';
import '../../core/providers/ui_providers.dart';
import '../../core/utils/time_formatters.dart';
import '../../models/settings_model.dart';
import '../../shared/widgets/app_drawer.dart';
import '../settings/settings_provider.dart';
import '../tasks/widgets/add_screen_pickers.dart';
import 'pomodoro_provider.dart';

/// دالة ترجمة ذكية مع نص احتياطي فوري لضمان عدم ظهور أي مفاتيح خام في الواجهة
String _tr(BuildContext context, String key, String arFallback, String enFallback) {
  final translated = key.tr();
  if (translated != key) return translated;
  final isAr = context.locale.languageCode == 'ar';
  return isAr ? arFallback : enFallback;
}

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoroState = ref.watch(pomodoroProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;

    final isSubView = pomodoroState.currentView != PomodoroView.selector;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      drawerEnableOpenDragGesture: !isSubView,
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.15,
      drawer: const AppDrawer(),
      onDrawerChanged: (isOpen) =>
          ref.read(isDrawerOpenProvider.notifier).state = isOpen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: isSubView
            ? IconButton(
                icon: Icon(
                  context.locale.languageCode == 'ar'
                      ? LucideIcons.arrow_right
                      : LucideIcons.arrow_left,
                  color: textColor,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(pomodoroProvider.notifier).backToSelector();
                },
              )
            : Builder(
                builder: (ctx) => IconButton(
                  icon: Icon(LucideIcons.menu, color: textColor),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        title: Text(
          'nav.pomodoro'.tr(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          // 🌟 زر إعدادات البومودورو التقليدي في الأعلى عند فتح الوضع التقليدي
          if (pomodoroState.currentView == PomodoroView.traditional)
            IconButton(
              tooltip: _tr(context, 'settings.title', 'الإعدادات', 'Settings'),
              icon: Icon(LucideIcons.settings_2, color: primaryColor),
              onPressed: () {
                HapticFeedback.selectionClick();
                _showTraditionalSettingsSheet(context, ref);
              },
            ),

          // 🌟 زر التحويل العالمي بين التوقيت السويعي والتوقيت المدني (مماثل للرئيسية والعبادات)
          IconButton(
            icon: Icon(
              settings.useAstroTimeForIbadat
                  ? LucideIcons.clock
                  : LucideIcons.moon_star,
              color: primaryColor,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref
                  .read(settingsProvider.notifier)
                  .updateUseAstroTimeForIbadat(!settings.useAstroTimeForIbadat);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: _buildCurrentView(pomodoroState.currentView),
        ),
      ),
    );
  }

  Widget _buildCurrentView(PomodoroView view) {
    switch (view) {
      case PomodoroView.selector:
        return const _ModeSelectorView(key: ValueKey('selector'));
      case PomodoroView.traditional:
        return const _TraditionalTimerView(key: ValueKey('traditional'));
      case PomodoroView.suwayaSetup:
        return const _SuwayaSetupView(key: ValueKey('suwaya_setup'));
      case PomodoroView.suwayaActive:
        return const _SuwayaActiveTimerView(key: ValueKey('suwaya_active'));
    }
  }
}

// ============================================================================
// 1. شاشة الاختيار الرئيسية (بومودورو سُويعي / بومودورو تقليدي)
// ============================================================================
class _ModeSelectorView extends ConsumerWidget {
  const _ModeSelectorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Text(
            'pomodoro.choose_mode'.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
          // 🌟 خيار البومودورو السُويعي
          _buildModeCard(
            context: context,
            title: 'pomodoro.suwaya_mode'.tr(),
            subtitle: 'pomodoro.suwaya_mode_desc'.tr(),
            icon: LucideIcons.moon_star,
            color: const Color(0xFFE53935),
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(pomodoroProvider.notifier).openSuwayaSetup();
            },
          ),
          const SizedBox(height: 16),
          // 🌟 خيار البومودورو التقليدي
          _buildModeCard(
            context: context,
            title: 'pomodoro.traditional'.tr(),
            subtitle: 'pomodoro.traditional_desc'.tr(),
            icon: LucideIcons.clock,
            color: const Color(0xFF64B5F6),
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(pomodoroProvider.notifier).openTraditionalMode();
            },
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D24) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. شاشة البومودورو التقليدي + نافذة إعداداته المخصصة
// ============================================================================
class _TraditionalTimerView extends ConsumerWidget {
  const _TraditionalTimerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    final int remInt = state.remainingSeconds.ceil();
    final String m = (remInt ~/ 60).toString().padLeft(2, '0');
    final String s = (remInt % 60).toString().padLeft(2, '0');

    final Color activeColor = switch (state.phase) {
      PomodoroPhase.work => const Color(0xFFE53935),
      PomodoroPhase.shortBreak => const Color(0xFF64B5F6),
      PomodoroPhase.longBreak => const Color(0xFF00E676),
    };

    final String phaseLabel = switch (state.phase) {
      PomodoroPhase.work => 'pomodoro.in_flow'.tr(),
      PomodoroPhase.shortBreak => 'pomodoro.deep_relaxation'.tr(),
      PomodoroPhase.longBreak => _tr(
          context, 'pomodoro.long_break', 'راحة طويلة', 'Long Break'),
    };

    final totalCycles = state.traditionalSettings.cyclesBeforeLongBreak;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // شريط معلومات النظام والدورات
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'pomodoro.traditional'.tr(),
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.traditionalSettings.workMinutes}/${state.traditionalSettings.shortBreakMinutes} · ${state.currentCycle}/$totalCycles',
                  style: TextStyle(
                    color: activeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // حلقة المؤقت
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 300,
                height: 300,
                child: CustomPaint(
                  painter: _ZenTimerPainter(
                    progress: state.phaseProgress,
                    activeColor: activeColor,
                    isDark: isDark,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$m:$s',
                          style: TextStyle(
                            fontSize: 76,
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Playfair Display',
                            foreground: Paint()
                              ..style = PaintingStyle.stroke
                              ..strokeWidth = 3.5
                              ..color = Colors.white,
                          ),
                        ),
                        Text(
                          '$m:$s',
                          style: const TextStyle(
                            fontSize: 76,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFFF2C94C),
                            fontFamily: 'Playfair Display',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.isBreak
                            ? LucideIcons.coffee
                            : LucideIcons.sparkles,
                        color: activeColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        phaseLabel,
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // مؤشر الدورات البصري (Cycle Dots)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalCycles, (index) {
              final cycleNum = index + 1;
              final isCompleted = cycleNum < state.currentCycle ||
                  (cycleNum == state.currentCycle &&
                      state.phase == PomodoroPhase.longBreak);
              final isCurrent = cycleNum == state.currentCycle &&
                  state.phase != PomodoroPhase.longBreak;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: isCurrent ? 22 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: (isCompleted || isCurrent)
                      ? activeColor
                      : textColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),

          const SizedBox(height: 36),

          // 🌟 أزرار التحكم: قبل البدء يظهر زر البدء، وبعد البدء تظهر أزرار الإيقاف والتخطي
          if (state.status == PomodoroStatus.idle)
            SizedBox(
              width: 220,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 4,
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  notifier.startTraditional();
                },
                icon: const Icon(LucideIcons.play, size: 20),
                label: Text(
                  _tr(context, 'pomodoro.start', 'بدء', 'Start'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // زر الإيقاف / إعادة الضبط
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    notifier.resetTraditional();
                  },
                  icon: Icon(LucideIcons.rotate_ccw, color: textColor, size: 22),
                  tooltip: _tr(context, 'pomodoro.reset', 'إيقاف وإعادة', 'Stop & Reset'),
                ),
                const SizedBox(width: 20),

                // زر الإيقاف المؤقت / الاستئناف
                SizedBox(
                  height: 60,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: activeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (state.status == PomodoroStatus.running) {
                        notifier.pauseTraditional();
                      } else {
                        notifier.resumeTraditional();
                      }
                    },
                    icon: Icon(
                      state.status == PomodoroStatus.running
                          ? LucideIcons.pause
                          : LucideIcons.play,
                      size: 22,
                    ),
                    label: Text(
                      state.status == PomodoroStatus.running
                          ? _tr(context, 'pomodoro.pause', 'إيقاف مؤقت', 'Pause')
                          : _tr(context, 'pomodoro.resume', 'استئناف', 'Resume'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // زر التخطي (Skip)
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: notifier.skipTraditionalPhase,
                  icon:
                      Icon(LucideIcons.skip_forward, color: textColor, size: 22),
                  tooltip: _tr(context, 'pomodoro.skip', 'تخطي', 'Skip'),
                ),
              ],
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

void _showTraditionalSettingsSheet(BuildContext context, WidgetRef ref) {
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
          final currentSettings =
              ref.watch(pomodoroProvider).traditionalSettings;
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
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
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
                        _tr(context, 'pomodoro.traditional_settings',
                            'إعدادات البومودورو التقليدي', 'Traditional Pomodoro Settings'),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    buildChipSelector(
                      title: _tr(context, 'pomodoro.work_duration',
                          'طول البومودورو (العمل الصافي)', 'Pomodoro Duration (Work)'),
                      options: workOptions,
                      selectedValue: currentSettings.workMinutes,
                      unit: minUnit,
                      onSelect: (val) => notifier.updateTraditionalSettings(
                        currentSettings.copyWith(workMinutes: val),
                      ),
                    ),
                    buildChipSelector(
                      title: _tr(context, 'pomodoro.short_break_duration',
                          'طول الراحة القصيرة', 'Short Break Duration'),
                      options: shortBreakOptions,
                      selectedValue: currentSettings.shortBreakMinutes,
                      unit: minUnit,
                      onSelect: (val) => notifier.updateTraditionalSettings(
                        currentSettings.copyWith(shortBreakMinutes: val),
                      ),
                    ),
                    buildChipSelector(
                      title: _tr(context, 'pomodoro.long_break_duration',
                          'طول الراحة الطويلة', 'Long Break Duration'),
                      options: longBreakOptions,
                      selectedValue: currentSettings.longBreakMinutes,
                      unit: minUnit,
                      onSelect: (val) => notifier.updateTraditionalSettings(
                        currentSettings.copyWith(longBreakMinutes: val),
                      ),
                    ),
                    buildChipSelector(
                      title: _tr(context, 'pomodoro.cycles_before_long_break',
                          'الراحة الطويلة بعد كل (عدد البومودورو)', 'Long Break After Every'),
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

// ============================================================================
// 3. شاشة إعداد البومودورو السُويعي (_SuwayaSetupView)
// ============================================================================
class _SuwayaSetupView extends ConsumerStatefulWidget {
  const _SuwayaSetupView({super.key});

  @override
  ConsumerState<_SuwayaSetupView> createState() => _SuwayaSetupViewState();
}

class _SuwayaSetupViewState extends ConsumerState<_SuwayaSetupView> {
  late final DateTime _anchoredStartTime; // دقيقة البداية عند فتح الصفحة
  bool? _localStartUseAstroOverride; // يتيح للمستخدم تبديل عرض وقت البداية للموازي المدني/السويعي

  bool _useDefaultNextPrayer = true;
  DateTime? _customEndTime;
  String _nextPrayerName = '';
  DateTime? _nextPrayerTime;

  int _selectedOptionIndex = 0;

  @override
  void initState() {
    super.initState();
    // 🌟 تثبيت دقيقة البداية لحظة دخول المستخدم لهذه الصفحة
    final cityNow = virtualDateTimeNotifier.value;
    _anchoredStartTime = DateTime.utc(
      cityNow.year,
      cityNow.month,
      cityNow.day,
      cityNow.hour,
      cityNow.minute,
    );
  }

  /// استخراج الفهرس العالمي (0..23) والدقيقة الافتراضية (0..59) لأي وقت فعلي
  ({int globalIndex, int minute}) _dateTimeToAstroParts(
      DateTime time, AstroState astroState) {
    if (astroState.periods.isEmpty) return (globalIndex: 0, minute: 0);
    final mockState = SuwayaTimeEngine.calculateCurrentState(
      SuwayaDay(
        ibadatTimings: astroState.ibadatTimings,
        cycleAnchors: astroState.cycleAnchors,
        periods: astroState.periods,
      ),
      time,
    );
    final int global = mockState.currentSuwayaTime.phase == SuwayaPhase.day
        ? 12 + mockState.currentSuwayaTime.phaseSlotNumber - 1
        : mockState.currentSuwayaTime.phaseSlotNumber - 1;
    return (
      globalIndex: global.clamp(0, 23),
      minute: mockState.currentSuwayaTime.virtualMinute.clamp(0, 59),
    );
  }

  /// تحويل الفهرس العالمي (0..23) والدقيقة الافتراضية (0..59) إلى وقت فعلي DateTime
  DateTime _astroPartsToDateTime(
      int globalIndex, int virtualMinute, AstroState astroState) {
    int remaining = globalIndex.clamp(0, 23);
    AstroPeriod targetPeriod = astroState.periods.last;
    int localSuwaya = targetPeriod.suwayasCount;

    for (final p in astroState.periods) {
      if (remaining < p.suwayasCount) {
        targetPeriod = p;
        localSuwaya = remaining + 1;
        break;
      }
      remaining -= p.suwayasCount;
    }

    DateTime resolved = resolveAstroRoutineTime(
      period: targetPeriod,
      localSuwaya: localSuwaya,
      virtualMinute: virtualMinute.clamp(0, 59),
    );

    if (!resolved.isAfter(_anchoredStartTime)) {
      resolved = resolved.add(const Duration(days: 1));
    }
    return resolved;
  }

  /// تحديد الصلاة القادمة من الصلوات الخمس المفروضة
  void _resolveNextPrayer(AstroState astro) {
    final ibadat = astro.ibadatTimings;
    final candidates = [
      (name: 'periods.fajr'.tr(), time: ibadat.fajr),
      (name: 'periods.dhuhr'.tr(), time: ibadat.dhuhr),
      (name: 'periods.asr'.tr(), time: ibadat.asr),
      (name: 'periods.maghrib'.tr(), time: ibadat.maghrib),
      (name: 'prayers.isha'.tr(), time: ibadat.isha),
      (name: 'periods.fajr'.tr(), time: ibadat.nextFajr),
    ];

    // نرتب الصلوات زمنياً ونختار أول صلاة تأتي بعد وقت البداية
    final sorted = List.of(candidates)
      ..sort((a, b) => a.time.compareTo(b.time));

    for (final p in sorted) {
      if (p.time.isAfter(_anchoredStartTime)) {
        _nextPrayerName = p.name;
        _nextPrayerTime = p.time;
        return;
      }
    }

    // احتياطي إذا تجاوز الكل
    _nextPrayerName = sorted.first.name;
    _nextPrayerTime = sorted.first.time.add(const Duration(days: 1));
  }

  String _formatDisplayedTime({
    required BuildContext context,
    required DateTime time,
    required AstroState astroState,
    required SettingsModel settings,
    required bool useAstro,
  }) {
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    if (!useAstro) {
      return formatCivilTime(
        time,
        format: settings.civilTimeFormat,
        locale: context.locale.languageCode,
        context: context,
      );
    }
    final parts = _dateTimeToAstroParts(time, astroState);
    return formatSuwayaTime(
      parts.globalIndex,
      parts.minute,
      separator: '|',
      isRTL: isRTL,
      iconMode: settings.suwayaIconMode,
    );
  }

  /// التحقق من شرط المدة (لا يقل عن 15 دقيقة ولا يزيد عن 12 ساعة/سويعة)
  ({bool isValid, String? errorMessage}) _validateEndTime({
    required DateTime candidateEnd,
    required AstroState astroState,
    required bool isAstroMode,
  }) {
    if (!candidateEnd.isAfter(_anchoredStartTime)) {
      return (
        isValid: false,
        errorMessage: _tr(
          context,
          'pomodoro.end_must_be_after_start',
          'يجب أن يكون وقت النهاية بعد وقت البداية',
          'End time must be after start time',
        ),
      );
    }

    if (isAstroMode) {
      final startParts = _dateTimeToAstroParts(_anchoredStartTime, astroState);
      final endParts = _dateTimeToAstroParts(candidateEnd, astroState);
      final startVirtualMins = startParts.globalIndex * 60 + startParts.minute;
      final endVirtualMins = endParts.globalIndex * 60 + endParts.minute;
      int diffVirtualMins = endVirtualMins - startVirtualMins;
      if (diffVirtualMins <= 0) diffVirtualMins += 1440;

      // كما نتحقق من الوقت الفعلي الموازي لضمان عدم تجاوز 12 ساعة
      final actualMins = candidateEnd.difference(_anchoredStartTime).inMinutes;
      if (diffVirtualMins < 15 || actualMins < 15) {
        return (
          isValid: false,
          errorMessage: 'pomodoro.time_too_short'.tr(),
        );
      }
      if (diffVirtualMins > 720 || actualMins > 720) {
        return (
          isValid: false,
          errorMessage: _tr(
            context,
            'pomodoro.max_12_hours',
            'لا يمكن أن تزيد المدة عن 12 سويعة / ساعة',
            'Duration cannot exceed 12 Suwayas / hours',
          ),
        );
      }
    } else {
      final diffActualMins =
          candidateEnd.difference(_anchoredStartTime).inMinutes;
      if (diffActualMins < 15) {
        return (
          isValid: false,
          errorMessage: 'pomodoro.time_too_short'.tr(),
        );
      }
      if (diffActualMins > 720) {
        return (
          isValid: false,
          errorMessage: _tr(
            context,
            'pomodoro.max_12_hours',
            'لا يمكن أن تزيد المدة عن 12 ساعة',
            'Duration cannot exceed 12 hours',
          ),
        );
      }
    }

    return (isValid: true, errorMessage: null);
  }

  Future<void> _showEndTimePickerDialog({
    required BuildContext context,
    required AstroState astroState,
    required SettingsModel settings,
    required DateTime currentEffectiveEnd,
  }) async {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).cardColor;
    final text = isDark ? Colors.white : Colors.black87;
    final pColor = Theme.of(context).primaryColor;

    // 0: سويعي، 1: مدني (يبدأ حسب ما ثبته المستخدم في التطبيق)
    int pickerTimeMode = settings.useAstroTimeForIbadat ? 0 : 1;

    final initialAstro =
        _dateTimeToAstroParts(currentEffectiveEnd, astroState);
    int tempGlobalSuwaya = initialAstro.globalIndex;
    int tempVirtualMinute = initialAstro.minute;

    int tempCivilHour = currentEffectiveEnd.hour;
    int tempCivilMinute = currentEffectiveEnd.minute;

    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isNight = tempGlobalSuwaya < 12;
          final uiHour = isNight ? tempGlobalSuwaya + 1 : tempGlobalSuwaya - 11;

          return Dialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'add_screen.select_end_time'.tr(),
                    style: TextStyle(
                      color: text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // التبديل بين السويعي والمدني داخل النافذة
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(
                        value: 0,
                        label: Text('ibadat.astro_time'.tr()),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('add_screen.civil'.tr()),
                      ),
                    ],
                    selected: {pickerTimeMode},
                    onSelectionChanged: (set) {
                      HapticFeedback.selectionClick();
                      setDialogState(() {
                        pickerTimeMode = set.first;
                        dialogError = null;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? pColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? pColor
                            : text.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (pickerTimeMode == 0)
                    AstroTimePicker(
                      initialHour: uiHour,
                      initialMinute: tempVirtualMinute,
                      initialIsNight: isNight,
                      textColor: text,
                      surfaceColor: surface,
                      accentColor: pColor,
                      iconMode: settings.suwayaIconMode,
                      onChanged: (h, m, night) {
                        tempGlobalSuwaya = night ? (h - 1) : (h + 11);
                        tempVirtualMinute = m;
                        if (dialogError != null) {
                          setDialogState(() => dialogError = null);
                        }
                      },
                    )
                  else
                    DoubleWheelPicker(
                      label1: 'add_screen.civil_hour'.tr(),
                      label2: 'add_screen.minute'.tr(),
                      initialVal1: tempCivilHour,
                      initialVal2: tempCivilMinute,
                      min1: 0,
                      max1: 23,
                      max2: 59,
                      textColor: text,
                      surfaceColor: surface,
                      onChanged: (h, m) {
                        tempCivilHour = h;
                        tempCivilMinute = m;
                        if (dialogError != null) {
                          setDialogState(() => dialogError = null);
                        }
                      },
                    ),

                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      dialogError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'common.cancel'.tr(),
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pColor,
                          ),
                          onPressed: () {
                            DateTime candidate;
                            if (pickerTimeMode == 0) {
                              candidate = _astroPartsToDateTime(
                                tempGlobalSuwaya,
                                tempVirtualMinute,
                                astroState,
                              );
                            } else {
                              candidate = DateTime.utc(
                                _anchoredStartTime.year,
                                _anchoredStartTime.month,
                                _anchoredStartTime.day,
                                tempCivilHour,
                                tempCivilMinute,
                              );
                              if (!candidate.isAfter(_anchoredStartTime)) {
                                candidate =
                                    candidate.add(const Duration(days: 1));
                              }
                            }

                            final validation = _validateEndTime(
                              candidateEnd: candidate,
                              astroState: astroState,
                              isAstroMode: pickerTimeMode == 0,
                            );

                            if (!validation.isValid) {
                              HapticFeedback.heavyImpact();
                              setDialogState(
                                () => dialogError = validation.errorMessage,
                              );
                              return;
                            }

                            setState(() {
                              _useDefaultNextPrayer = false;
                              _customEndTime = candidate;
                              _selectedOptionIndex = 0;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            'common.confirm'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final astroState = ref.watch(astroProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;
    final cardBg = isDark ? const Color(0xFF1A1D24) : Colors.white;

    if (astroState.periods.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    _resolveNextPrayer(astroState);

    final DateTime effectiveEndTime =
        _useDefaultNextPrayer ? _nextPrayerTime! : (_customEndTime ?? _nextPrayerTime!);

    final bool startDisplayAstro =
        _localStartUseAstroOverride ?? settings.useAstroTimeForIbadat;
    final bool endDisplayAstro = settings.useAstroTimeForIbadat;

    final String startFormatted = _formatDisplayedTime(
      context: context,
      time: _anchoredStartTime,
      astroState: astroState,
      settings: settings,
      useAstro: startDisplayAstro,
    );

    final String startParallelFormatted = _formatDisplayedTime(
      context: context,
      time: _anchoredStartTime,
      astroState: astroState,
      settings: settings,
      useAstro: !startDisplayAstro,
    );

    final String endFormatted = _formatDisplayedTime(
      context: context,
      time: effectiveEndTime,
      astroState: astroState,
      settings: settings,
      useAstro: endDisplayAstro,
    );

    final validation = _validateEndTime(
      candidateEnd: effectiveEndTime,
      astroState: astroState,
      isAstroMode: settings.useAstroTimeForIbadat,
    );

    final List<SuwayaFlowOption> flowOptions = validation.isValid
        ? PomodoroEngine.calculateSuwayaFlowOptions(
            _anchoredStartTime,
            effectiveEndTime,
          )
        : [];

    if (_selectedOptionIndex >= flowOptions.length) {
      _selectedOptionIndex = 0;
    }

    final int actualMinutes =
        effectiveEndTime.difference(_anchoredStartTime).inMinutes;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🌟 1. بطاقة البداية (الوقت الحالي بالسويعي مع إمكانية التبديل للمدني الموازي)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.play, size: 15, color: primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'details.start'.tr(),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'pomodoro.starts_now'.tr(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _localStartUseAstroOverride = !startDisplayAstro;
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: Text(
                            startFormatted,
                            style: TextStyle(
                              color: startDisplayAstro
                                  ? const Color(0xFFF2C94C)
                                  : textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: Text(
                            '⇄ $startParallelFormatted',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 🌟 2. بطاقة النهاية (الافتراضي: الصلاة القادمة، أو تخصيص وقت بين 15 د و 12 س)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.moon_star,
                            size: 16, color: primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'details.end'.tr(),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // أزرار التبديل بين (الصلاة القادمة) و (تحديد يدوي)
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text(
                            _tr(context, 'ibadat.next_prayer',
                                'الصلاة القادمة', 'Next Prayer'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: _useDefaultNextPrayer,
                          selectedColor: primaryColor.withValues(alpha: 0.2),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _useDefaultNextPrayer = true;
                              _selectedOptionIndex = 0;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(
                            _tr(context, 'astro_calc.custom', 'مخصص', 'Custom'),
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: !_useDefaultNextPrayer,
                          selectedColor: primaryColor.withValues(alpha: 0.2),
                          onSelected: (_) {
                            _showEndTimePickerDialog(
                              context: context,
                              astroState: astroState,
                              settings: settings,
                              currentEffectiveEnd: effectiveEndTime,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showEndTimePickerDialog(
                    context: context,
                    astroState: astroState,
                    settings: settings,
                    currentEffectiveEnd: effectiveEndTime,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _useDefaultNextPrayer
                                  ? 'pomodoro.ends_at'
                                      .tr(args: [_nextPrayerName])
                                  : _tr(context, 'add_screen.end_time',
                                      'وقت النهاية المحدد', 'Selected End Time'),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$actualMinutes ${'pomodoro.actual_minutes_avail'.tr()}',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.55),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Directionality(
                              textDirection: ui.TextDirection.ltr,
                              child: Text(
                                endFormatted,
                                style: TextStyle(
                                  color: endDisplayAstro
                                      ? const Color(0xFFF2C94C)
                                      : textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              LucideIcons.pencil,
                              size: 16,
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 🌟 3. قسم خيارات التقسيم وسرعة التدفق (25/5 بين 0.5x و 2.0x)
          if (!validation.isValid || flowOptions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.clock,
                      color: Colors.redAccent, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    validation.errorMessage ?? 'pomodoro.time_too_short'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'pomodoro.flow_speed'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '25/5 (30 ${'details.minute'.tr()})',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...List.generate(flowOptions.length, (index) {
              final opt = flowOptions[index];
              final isSelected = _selectedOptionIndex == index;

              String subtitleText;
              if (opt.tag == 'recommended') {
                subtitleText = _tr(
                  context,
                  'pomodoro.recommended_closest',
                  'الافتراضي (الأقرب لسرعة 1.00x)',
                  'Default (Closest to 1.00x speed)',
                );
              } else if (opt.tag == 'slower') {
                subtitleText = _tr(
                  context,
                  'pomodoro.slower_option',
                  'سرعة أقل (إيقاع أهدأ)',
                  'Lower speed (Calmer pace)',
                );
              } else {
                subtitleText = _tr(
                  context,
                  'pomodoro.faster_option',
                  'سرعة أعلى (إنجاز مكثف)',
                  'Higher speed (Intensive focus)',
                );
              }

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedOptionIndex = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.12)
                        : cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : textColor.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? LucideIcons.circle_check
                            : LucideIcons.circle,
                        color: isSelected
                            ? primaryColor
                            : textColor.withValues(alpha: 0.4),
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${opt.pomodoroCount} ${'nav.pomodoro'.tr()} · ${opt.flowSpeed.toStringAsFixed(2)}x',
                              style: TextStyle(
                                color: isSelected ? primaryColor : textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitleText,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.55),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 20),

            // 🌟 4. زر التأكيد والبدء (مع خصم وقت الإعداد من البومودورو الأول)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  final selectedOpt = flowOptions[_selectedOptionIndex];
                  final endLabel = _useDefaultNextPrayer
                      ? _nextPrayerName
                      : endFormatted;

                  ref.read(pomodoroProvider.notifier).startSuwayaSession(
                        SuwayaSessionConfig(
                          anchoredStartTime: _anchoredStartTime,
                          endTime: effectiveEndTime,
                          endLabel: endLabel,
                          totalPomodoros: selectedOpt.pomodoroCount,
                          flowSpeed: selectedOpt.flowSpeed,
                        ),
                      );
                },
                icon: const Icon(LucideIcons.check, size: 20),
                label: Text(
                  'pomodoro.start_session'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 4. شاشة المؤقت السُويعي النشط (_SuwayaActiveTimerView)
// ============================================================================
class _SuwayaActiveTimerView extends ConsumerWidget {
  const _SuwayaActiveTimerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final config = state.suwayaConfig;

    if (config == null) return const SizedBox.shrink();

    // إشعار انتهاء الجلسة عند بلوغ وقت النهاية / الصلاة
    if (state.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title:
                Text('pomodoro.time_up_prayer'.tr(), textAlign: TextAlign.center),
            content:
                Text('pomodoro.time_up_desc'.tr(), textAlign: TextAlign.center),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(pomodoroProvider.notifier).acknowledgeFinish();
                  },
                  child: Text(
                    'common.done'.tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        );
      });
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int remInt = state.remainingSeconds.ceil();
    final String m = (remInt ~/ 60).toString().padLeft(2, '0');
    final String s = (remInt % 60).toString().padLeft(2, '0');

    final Color activeColor =
        state.isBreak ? const Color(0xFF64B5F6) : const Color(0xFFE53935);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'pomodoro.suwaya_mode'.tr()} (${state.currentCycle}/${config.totalPomodoros})',
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${config.flowSpeed.toStringAsFixed(2)}x',
                  style: TextStyle(
                    color: activeColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(flex: 2),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 310,
              height: 310,
              child: CustomPaint(
                painter: _ZenTimerPainter(
                  progress: state.phaseProgress,
                  activeColor: activeColor,
                  isDark: isDark,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$m:$s',
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Playfair Display',
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 4.0
                            ..color = Colors.white,
                        ),
                      ),
                      Text(
                        '$m:$s',
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.normal,
                          color: Color(0xFFF2C94C),
                          fontFamily: 'Playfair Display',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.isBreak
                          ? LucideIcons.coffee
                          : LucideIcons.sparkles,
                      color: activeColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      state.isBreak
                          ? 'pomodoro.deep_relaxation'.tr()
                          : 'pomodoro.in_flow'.tr(),
                      style: TextStyle(
                        color: activeColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ref.read(pomodoroProvider.notifier).backToSelector();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black12,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.x,
                  color: isDark ? Colors.white70 : Colors.black87,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'pomodoro.end_session'.tr(),
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(flex: 3),
      ],
    );
  }
}

// ============================================================================
// رسام حلقة المؤقت (_ZenTimerPainter)
// ============================================================================
class _ZenTimerPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final bool isDark;

  _ZenTimerPainter({
    required this.progress,
    required this.activeColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final trackPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, trackPaint);

    final safeProgress = progress.clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.5
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
    canvas.drawCircle(knobCenter, 8, Paint()..color = activeColor);
    canvas.drawCircle(
      knobCenter,
      4,
      Paint()..color = isDark ? Colors.black : Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _ZenTimerPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.isDark != isDark;
}