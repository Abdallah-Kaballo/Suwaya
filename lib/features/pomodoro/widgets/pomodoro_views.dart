import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya_time/suwaya_time.dart';

import '../../../core/astro_engine/astro_provider.dart';
import '../../../core/theme/astro_ui_extensions.dart';
import '../../../core/utils/time_formatters.dart';
import '../../../models/settings_model.dart';
import '../../settings/settings_provider.dart';
import '../../tasks/widgets/add_screen_pickers.dart';
import '../pomodoro_provider.dart';
import 'pomodoro_shared_widgets.dart';

class ModeSelectorView extends ConsumerWidget {
  const ModeSelectorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final dailyCount = ref.watch(
      pomodoroProvider.select((s) => s.dailyCompletedSessions),
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.flame, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  context.locale.languageCode == 'ar'
                      ? 'إنجاز اليوم: $dailyCount جلسات تركيز'
                      : 'Completed Today: $dailyCount focus sessions',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'pomodoro.choose_mode'.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          LinkedTaskBar(accentColor: primaryColor),
          const SizedBox(height: 24),
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
            ),
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

class TraditionalTimerView extends ConsumerWidget {
  const TraditionalTimerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final isDark =
        state.isFullScreen || Theme.of(context).brightness == Brightness.dark;
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
      PomodoroPhase.longBreak => trPomodoro(
          context,
          'pomodoro.long_break',
          'راحة طويلة',
          'Long Break',
        ),
    };

    final totalCycles = state.traditionalSettings.cyclesBeforeLongBreak;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget buildControls() {
      if (state.status == PomodoroStatus.idle) {
        return SizedBox(
          width: 220,
          height: 54,
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
              trPomodoro(context, 'pomodoro.start', 'بدء', 'Start'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              padding: const EdgeInsets.all(15),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              notifier.resetTraditional();
            },
            icon: Icon(LucideIcons.rotate_ccw, color: textColor, size: 21),
          ),
          const SizedBox(width: 18),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
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
                size: 21,
              ),
              label: Text(
                state.status == PomodoroStatus.running
                    ? trPomodoro(context, 'pomodoro.pause', 'إيقاف مؤقت', 'Pause')
                    : trPomodoro(context, 'pomodoro.resume', 'استئناف', 'Resume'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 18),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              padding: const EdgeInsets.all(15),
            ),
            onPressed: notifier.skipTraditionalPhase,
            icon: Icon(LucideIcons.skip_forward, color: textColor, size: 21),
          ),
        ],
      );
    }

    Widget buildCycleDots() {
      return Row(
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
            margin: const EdgeInsets.symmetric(horizontal: 4),
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
      );
    }

    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: LargeZenTimerDial(
                  progress: state.phaseProgress,
                  minutesStr: m,
                  secondsStr: s,
                  phaseLabel: phaseLabel,
                  isBreak: state.isBreak,
                  activeColor: activeColor,
                  isDark: isDark,
                  forcedSize: 250,
                  onDoubleTap: () {
                    HapticFeedback.lightImpact();
                    notifier.toggleFullScreen();
                  },
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LinkedTaskBar(accentColor: activeColor, isCompact: true),
                  const SizedBox(height: 16),
                  buildCycleDots(),
                  const SizedBox(height: 24),
                  buildControls(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        state.isFullScreen ? 16 : 8,
        20,
        state.isFullScreen ? 24 : 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
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
          const SizedBox(height: 12),
          LinkedTaskBar(accentColor: activeColor, isCompact: true),
          SizedBox(height: state.isFullScreen ? 28 : 18),
          LargeZenTimerDial(
            progress: state.phaseProgress,
            minutesStr: m,
            secondsStr: s,
            phaseLabel: phaseLabel,
            isBreak: state.isBreak,
            activeColor: activeColor,
            isDark: isDark,
            onDoubleTap: () {
              HapticFeedback.lightImpact();
              notifier.toggleFullScreen();
            },
          ),
          const SizedBox(height: 20),
          buildCycleDots(),
          const SizedBox(height: 28),
          buildControls(),
        ],
      ),
    );
  }
}

class SuwayaSetupView extends ConsumerStatefulWidget {
  const SuwayaSetupView({super.key});

  @override
  ConsumerState<SuwayaSetupView> createState() => _SuwayaSetupViewState();
}

class _SuwayaSetupViewState extends ConsumerState<SuwayaSetupView> {
  late final DateTime _anchoredStartTime;
  bool? _localStartUseAstroOverride;
  bool _useDefaultNextPrayer = true;
  DateTime? _customEndTime;
  String _nextPrayerName = '';
  DateTime? _nextPrayerTime;
  int _selectedOptionIndex = 0;

  @override
  void initState() {
    super.initState();
    final cityNow = virtualDateTimeNotifier.value;
    _anchoredStartTime = DateTime.utc(
      cityNow.year,
      cityNow.month,
      cityNow.day,
      cityNow.hour,
      cityNow.minute,
    );
  }

  String _formatSessionsCount(BuildContext context, int count) {
    final lang = context.locale.languageCode;
    if (lang == 'ar') {
      if (count == 1) return '1 جلسة';
      if (count == 2) return '2 جلستان';
      if (count >= 3 && count <= 10) return '$count جلسات';
      return '$count جلسة';
    }
    return count == 1 ? '1 Session' : '$count Sessions';
  }

  void _resolveNextPrayer(AstroState astro) {
    final now = virtualDateTimeNotifier.value;
    final referenceTime =
        now.isAfter(_anchoredStartTime) ? now : _anchoredStartTime;

    final resolved = SuwayaFlowPlanner.resolveNextCyclePrayer(
      anchors: astro.cycleAnchors,
      referenceTime: referenceTime,
    );

    _nextPrayerTime = resolved.time;
    _nextPrayerName = switch (resolved.prayerKey) {
      PrayerKey.fajr => 'periods.fajr'.tr(),
      PrayerKey.dhuhr => 'periods.dhuhr'.tr(),
      PrayerKey.asr => 'periods.asr'.tr(),
      PrayerKey.maghrib => 'periods.maghrib'.tr(),
      PrayerKey.isha => 'prayers.isha'.tr(),
      PrayerKey.sunrise => 'ibadat.sunrise'.tr(),
    };
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
      return formatCivilClock(
        CivilWallClock.fromDateTime(time),
        format: settings.civilTimeFormat,
        locale: context.locale.languageCode,
        context: context,
      );
    }
    final parts = SuwayaFlowPlanner.dateTimeToAstroParts(time, astroState);
    return formatSuwayaTime(
      parts.globalIndex,
      parts.minute,
      separator: '|',
      isRTL: isRTL,
      iconMode: settings.suwayaIconMode,
    );
  }

  ({bool isValid, String? errorMessage}) _validateEndTime({
    required DateTime candidateEnd,
    required AstroState astroState,
    required bool isAstroMode,
  }) {
    final result = SuwayaFlowPlanner.validateSessionWindow(
      anchoredStart: _anchoredStartTime,
      candidateEnd: candidateEnd,
    );

    if (result.isValid) return (isValid: true, errorMessage: null);

    return switch (result.error) {
      SuwayaFlowValidationError.endBeforeStart => (
          isValid: false,
          errorMessage: trPomodoro(
            context,
            'pomodoro.end_must_be_after_start',
            'يجب أن يكون وقت النهاية بعد وقت البداية',
            'End time must be after start time',
          ),
        ),
      SuwayaFlowValidationError.tooShort => (
          isValid: false,
          errorMessage: 'pomodoro.time_too_short'.tr(),
        ),
      SuwayaFlowValidationError.exceedsMaxHours => (
          isValid: false,
          errorMessage: trPomodoro(
            context,
            'pomodoro.max_12_hours',
            'لا يمكن أن تزيد المدة عن 12 ساعة',
            'Duration cannot exceed 12 hours',
          ),
        ),
      SuwayaFlowValidationError.none => (isValid: true, errorMessage: null),
    };
  }


  bool _isCivil12HourActive(BuildContext context, String civilTimeFormat) {
    if (civilTimeFormat == civilTimeFormat12Hour) return true;
    if (civilTimeFormat == civilTimeFormat24Hour) return false;
    return !(MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false);
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
    final use12Hour = _isCivil12HourActive(context, settings.civilTimeFormat);

    int pickerTimeMode = settings.useAstroTimeForIbadat ? 0 : 1;
    final initialAstro =
        SuwayaFlowPlanner.dateTimeToAstroParts(currentEffectiveEnd, astroState);
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
                        tempGlobalSuwaya =
                            SuwayaCoordinateMapper.uiPhaseToGlobal(h, night);
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
                      is12HourMode: use12Hour,
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
                              candidate =
                                  SuwayaFlowPlanner.astroPartsToDateTime(
                                globalIndex: tempGlobalSuwaya,
                                virtualMinute: tempVirtualMinute,
                                anchoredStartTime: _anchoredStartTime,
                                astroState: astroState,
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
    final suwayaColor = suwayaTimeContrastColor(context);

    if (astroState.periods.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    _resolveNextPrayer(astroState);

    final DateTime effectiveEndTime = _useDefaultNextPrayer
        ? _nextPrayerTime!
        : (_customEndTime ?? _nextPrayerTime!);

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
          LinkedTaskBar(accentColor: primaryColor, isCompact: true),
          const SizedBox(height: 14),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
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
                              color: startDisplayAstro ? suwayaColor : textColor,
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
                        Icon(
                          LucideIcons.moon_star,
                          size: 16,
                          color: primaryColor,
                        ),
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
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text(
                            trPomodoro(
                              context,
                              'ibadat.next_prayer',
                              'الصلاة القادمة',
                              'Next Prayer',
                            ),
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
                            trPomodoro(
                              context,
                              'pomodoro.custom_time',
                              'وقت مخصص',
                              'Custom Time',
                            ),
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
                                  ? 'pomodoro.ends_at'.tr(
                                      args: [_nextPrayerName],
                                    )
                                  : trPomodoro(
                                      context,
                                      'add_screen.end_time',
                                      'وقت النهاية المحدد',
                                      'Selected End Time',
                                    ),
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
                                  color:
                                      endDisplayAstro ? suwayaColor : textColor,
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
          if (!validation.isValid || flowOptions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.clock,
                    color: Colors.redAccent,
                    size: 32,
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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

              final String subtitleText = switch (opt.tag) {
                'recommended' => trPomodoro(
                    context,
                    'pomodoro.recommended_closest',
                    'الافتراضي (الأقرب لسرعة 1.00x)',
                    'Default (Closest to 1.00x speed)',
                  ),
                'slower' => trPomodoro(
                    context,
                    'pomodoro.slower_option',
                    'سرعة أقل (إيقاع أهدأ)',
                    'Lower speed (Calmer pace)',
                  ),
                _ => trPomodoro(
                    context,
                    'pomodoro.faster_option',
                    'سرعة أعلى (إنجاز مكثف)',
                    'Higher speed (Intensive focus)',
                  ),
              };

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedOptionIndex = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
                         '${_formatSessionsCount(context, opt.pomodoroCount)} · ${opt.flowSpeed.toStringAsFixed(2)}x',
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
                  final endLabel =
                      _useDefaultNextPrayer ? _nextPrayerName : endFormatted;

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

class SuwayaActiveTimerView extends ConsumerWidget {
  const SuwayaActiveTimerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final config = state.suwayaConfig;

    // 🌟 الاستماع لتغير حالة الانتهاء مرة واحدة فقط لمنع تكدس نوافذ الحوار أثناء إعادة البناء
    ref.listen<bool>(
      pomodoroProvider.select((s) => s.isFinished),
      (previous, isFinished) {
        if (isFinished && previous != true && context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: Text(
                'pomodoro.time_up_prayer'.tr(),
                textAlign: TextAlign.center,
              ),
              content: Text(
                'pomodoro.time_up_desc'.tr(),
                textAlign: TextAlign.center,
              ),
              actions: [
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      notifier.acknowledgeFinish();
                    },
                    child: Text(
                      'common.done'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );

    if (config == null) return const SizedBox.shrink();

    final isDark =
        state.isFullScreen || Theme.of(context).brightness == Brightness.dark;
    final int remInt = state.remainingSeconds.ceil();
    final String m = (remInt ~/ 60).toString().padLeft(2, '0');
    final String s = (remInt % 60).toString().padLeft(2, '0');

    final Color activeColor =
        state.isBreak ? const Color(0xFF64B5F6) : const Color(0xFFE53935);
    final String phaseLabel = state.isBreak
        ? 'pomodoro.deep_relaxation'.tr()
        : 'pomodoro.in_flow'.tr();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget buildPrePrayerWarningBanner() {
      if (!state.isPrePrayerWarningActive) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.bell_ring, color: Colors.amber, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.locale.languageCode == 'ar'
                    ? 'اقترب الميقات (${config.endLabel}) — اختم فكرتك بهدوء'
                    : 'Approaching ${config.endLabel} — wrap up your current thought',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildEndSessionButton() {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          notifier.backToSelector();
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
      );
    }

    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: LargeZenTimerDial(
                  progress: state.phaseProgress,
                  minutesStr: m,
                  secondsStr: s,
                  phaseLabel: phaseLabel,
                  isBreak: state.isBreak,
                  activeColor: activeColor,
                  isDark: isDark,
                  forcedSize: 250,
                  onDoubleTap: () {
                    HapticFeedback.lightImpact();
                    notifier.toggleFullScreen();
                  },
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildPrePrayerWarningBanner(),
                  LinkedTaskBar(accentColor: activeColor, isCompact: true),
                  const SizedBox(height: 20),
                  buildEndSessionButton(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        state.isFullScreen ? 16 : 8,
        20,
        state.isFullScreen ? 24 : 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
          const SizedBox(height: 10),
          buildPrePrayerWarningBanner(),
          LinkedTaskBar(accentColor: activeColor, isCompact: true),
          SizedBox(height: state.isFullScreen ? 28 : 18),
          LargeZenTimerDial(
            progress: state.phaseProgress,
            minutesStr: m,
            secondsStr: s,
            phaseLabel: phaseLabel,
            isBreak: state.isBreak,
            activeColor: activeColor,
            isDark: isDark,
            onDoubleTap: () {
              HapticFeedback.lightImpact();
              notifier.toggleFullScreen();
            },
          ),
          const SizedBox(height: 28),
          buildEndSessionButton(),
        ],
      ),
    );
  }
}