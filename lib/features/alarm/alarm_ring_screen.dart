import 'dart:async';
import 'dart:ui' as ui;
import 'package:alarm/utils/alarm_set.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:alarm/alarm.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya_time/suwaya_time.dart';

import '../../core/astro_engine/astro_provider.dart';
import '../../core/services/alarm_service.dart';
import '../../core/utils/time_formatters.dart';
import '../../features/settings/settings_provider.dart';
import '../../models/settings_model.dart';
import '../../shared/widgets/suwaya_time_text.dart';

class AlarmRingScreen extends ConsumerStatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  @override
  ConsumerState<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends ConsumerState<AlarmRingScreen>
    with SingleTickerProviderStateMixin {
  late final ParsedAlarmData parsedData;
  late final String taskTitle;
  late final String taskBody;
  late final Color rawAccentColor;
  late final Color highContrastAccent;
  late final int snoozeCount;

  double _dragPosition = 0.0;
  final double _maxDragThreshold = 110.0;
  bool _isProcessingAction = false;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  StreamSubscription<AlarmSet>? _ringingSub;
  StreamSubscription<void>? _hardwareVolumeSub;

  /// ضمان تباين عالٍ جداً (WCAG AAA) للون المميز فوق الخلفية الداكنة (#0B0F19)
  Color _ensureHighContrastOnDark(Color color) {
    final hsl = HSLColor.fromColor(color);
    final safeLightness = hsl.lightness < 0.72
        ? 0.74
        : hsl.lightness.clamp(0.72, 0.90);
    final safeSaturation = hsl.saturation.clamp(0.65, 1.0);
    return hsl
        .withLightness(safeLightness)
        .withSaturation(safeSaturation)
        .toColor();
  }

  @override
  void initState() {
    super.initState();
    _enableLockScreenAndAlarmStream();
    _hardwareVolumeSub = AlarmService.onHardwareVolumeAction.listen((_) {
      _onHardwareVolumePressed();
    });
    HardwareKeyboard.instance.addHandler(_handleHardwareKey);

    _ringingSub = Alarm.ringing.listen((alarmSet) {
      final stillRinging = alarmSet.alarms.any(
        (a) => a.id == widget.alarmSettings.id,
      );
      if (!stillRinging && mounted && !_isProcessingAction) {
        _closeRingScreen();
      }
    });

    parsedData = AlarmService.parseAlarmSettings(widget.alarmSettings);
    taskTitle = SuwayaTimeFormatter.toEnglishDigits(parsedData.title);
    taskBody = SuwayaTimeFormatter.toEnglishDigits(parsedData.body);
    rawAccentColor = Color(parsedData.colorValue);
    highContrastAccent = _ensureHighContrastOnDark(rawAccentColor);
    snoozeCount = parsedData.snoozeCount;

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.16, end: 0.45).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  bool _handleHardwareKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.audioVolumeDown ||
            event.logicalKey == LogicalKeyboardKey.audioVolumeUp)) {
      _onHardwareVolumePressed();
      return true;
    }
    return false;
  }

  void _onHardwareVolumePressed() {
    if (!mounted || _isProcessingAction) return;
    final settings = ref.read(settingsProvider);
    final maxSnoozes = settings.maxSnoozeCount > 0
        ? settings.maxSnoozeCount
        : parsedData.maxSnoozes;
    final isPrayer = parsedData.kind == AlarmEventKind.prayer;
    final canSnooze =
        !isPrayer && parsedData.snoozeAllowed && snoozeCount < maxSnoozes;

    if (canSnooze) {
      _triggerSnooze();
    } else {
      _triggerStop();
    }
  }

  @override
  void dispose() {
    _ringingSub?.cancel();
    _hardwareVolumeSub?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleHardwareKey);
    _disableLockScreenAndRestoreStream();
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _enableLockScreenAndAlarmStream() async {
    try {
      await AlarmService.lockscreenChannel.invokeMethod('showOnLockScreen');
      await AlarmService.lockscreenChannel.invokeMethod(
        'setAlarmVolumeControl',
        {'enabled': true},
      );
    } catch (e) {
      debugPrint('Lockscreen/Volume channel note: $e');
    }
  }

  Future<void> _disableLockScreenAndRestoreStream() async {
    try {
      await AlarmService.lockscreenChannel.invokeMethod(
        'setAlarmVolumeControl',
        {'enabled': false},
      );
      await AlarmService.lockscreenChannel.invokeMethod('hideFromLockScreen');
    } catch (e) {
      debugPrint('Lockscreen/Volume restore note: $e');
    }
  }

  void _closeRingScreen() {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      SystemNavigator.pop();
    }
  }

  void _showErrorFeedback(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Inter', color: Colors.white),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _triggerSnooze() async {
    if (_isProcessingAction) return;

    final settings = ref.read(settingsProvider);
    final maxSnoozes = settings.maxSnoozeCount > 0
        ? settings.maxSnoozeCount
        : parsedData.maxSnoozes;
    final snoozeMins = settings.snoozeDurationMinutes > 0
        ? settings.snoozeDurationMinutes
        : parsedData.snoozeDurationMinutes;

    if (!parsedData.snoozeAllowed || snoozeCount >= maxSnoozes) return;

    setState(() => _isProcessingAction = true);
    HapticFeedback.heavyImpact();

    final result = await AlarmService.snooze(
      widget.alarmSettings,
      snoozeMinutesOverride: snoozeMins,
      maxSnoozesOverride: maxSnoozes,
    );

    if (result.success) {
      _closeRingScreen();
    } else {
      if (mounted) {
        setState(() {
          _isProcessingAction = false;
          _dragPosition = 0.0;
        });
        final isAr = context.locale.languageCode == 'ar';
        _showErrorFeedback(
          isAr
              ? 'تعذر تفعيل الغفوة، يرجى المحاولة مرة أخرى أو إيقاف التنبيه.'
              : 'Could not activate snooze. Please try again or stop the alert.',
        );
      }
    }
  }

  Future<void> _triggerStop() async {
    if (_isProcessingAction) return;
    setState(() => _isProcessingAction = true);
    HapticFeedback.heavyImpact();

    try {
      final stopped = await Alarm.stop(widget.alarmSettings.id);
      if (stopped) {
        _closeRingScreen();
        return;
      }
    } catch (_) {}

    try {
      await Alarm.stop(widget.alarmSettings.id);
    } catch (_) {}
    _closeRingScreen();
  }

  String _kindBadgeLabel(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    switch (parsedData.kind) {
      case AlarmEventKind.prayer:
        return isAr ? 'ميقات الصلاة والأذان' : 'Prayer & Adhan Time';
      case AlarmEventKind.qiyam:
        return 'ibadat.qiyam_tab'.tr();
      case AlarmEventKind.routine:
        return 'tasks.tab_routines'.tr();
      case AlarmEventKind.habit:
        return 'tasks.tab_habits'.tr();
      case AlarmEventKind.task:
      case AlarmEventKind.unknown:
        return 'tasks.tab_casual'.tr();
    }
  }

  IconData _kindIcon() {
    switch (parsedData.kind) {
      case AlarmEventKind.prayer:
        return LucideIcons.moon_star;
      case AlarmEventKind.qiyam:
        return LucideIcons.sparkles;
      case AlarmEventKind.routine:
        return LucideIcons.repeat;
      case AlarmEventKind.habit:
      case AlarmEventKind.task:
      case AlarmEventKind.unknown:
        return LucideIcons.alarm_clock;
    }
  }

  /// بناء عرض الوقت السويعي بأرقام إنجليزية وخط Inter
  Widget _buildSuwayaClockDisplay({
    required AstroState astroState,
    required SettingsModel settings,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    final ct = astroState.currentSuwayaTime;
    final globalIdx = ct.phase.isNight
        ? (ct.phaseSlotNumber - 1)
        : (12 + ct.phaseSlotNumber - 1);
    final sStr = ct.phaseSlotNumber.toString().padLeft(2, '0');
    final mStr = ct.virtualMinute.toString().padLeft(2, '0');
    final isNight = globalIdx < 12;
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    final badge = SuwayaPhaseBadge(
      isNight: isNight,
      size: (fontSize * 0.62).clamp(20.0, 44.0),
      iconMode: settings.suwayaIconMode,
      isRTL: isRTL,
      textStyle: TextStyle(
        color: color,
        fontSize: fontSize * 0.55,
        fontWeight: FontWeight.w800,
        fontFamily: 'Inter',
      ),
    );

    final digits = Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Text(
        '$sStr|$mStr',
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'Inter',
          letterSpacing: 1.0,
          height: 1.05,
          fontFeatures: const [ui.FontFeature.tabularFigures()],
        ),
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: isRTL
          ? [badge, const SizedBox(width: 10), digits]
          : [digits, const SizedBox(width: 10), badge],
    );
  }

  /// بناء عرض الوقت المدني بأرقام إنجليزية وخط Inter
  Widget _buildCivilClockDisplay({
    required DateTime civilNow,
    required SettingsModel settings,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    final formatted = SuwayaTimeFormatter.toEnglishDigits(
      formatCivilTime(
        civilNow,
        format: settings.civilTimeFormat,
        locale: context.locale.languageCode,
        context: context,
        numberStyle: 'english',
      ),
    );

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Text(
        formatted,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'Inter',
          letterSpacing: 1.0,
          height: 1.05,
          fontFeatures: const [ui.FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final astroState = ref.watch(astroProvider);
    final maxSnoozes = settings.maxSnoozeCount > 0
        ? settings.maxSnoozeCount
        : parsedData.maxSnoozes;
    final snoozeMins = settings.snoozeDurationMinutes > 0
        ? settings.snoozeDurationMinutes
        : parsedData.snoozeDurationMinutes;

    final bool isPrayer = parsedData.kind == AlarmEventKind.prayer;
    final bool canSnooze =
        !isPrayer && parsedData.snoozeAllowed && snoozeCount < maxSnoozes;

    final bool isAstroPrimary = parsedData.isAstroScheduled;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF070A12),
        body: Stack(
          alignment: Alignment.center,
          children: [
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.0, -0.2),
                        radius: 1.25,
                        colors: [
                          rawAccentColor.withValues(
                            alpha: _glowAnimation.value,
                          ),
                          const Color(0xFF070A12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            RepaintBoundary(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 🌟 القسم العلوي: شارة نوع الحدث + الوقت الأساسي الكبير جداً + الوقت الثانوي الأصغر بفرق واضح + العنوان
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: highContrastAccent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: highContrastAccent.withValues(
                                  alpha: 0.55,
                                ),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _kindIcon(),
                                  color: highContrastAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _kindBadgeLabel(context),
                                  style: TextStyle(
                                    color: highContrastAccent,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // 🌟 عرض الوقت المجدول به بخط كبير جداً (66pt) والثاني بخط كبير وواضح ولكن أصغر بفرق واضح (32pt)
                          ValueListenableBuilder<DateTime>(
                            valueListenable: virtualDateTimeNotifier,
                            builder: (context, liveCivilNow, _) {
                              final primaryWidget = isAstroPrimary
                                  ? _buildSuwayaClockDisplay(
                                      astroState: astroState,
                                      settings: settings,
                                      fontSize: 66,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFFFF6D6),
                                    )
                                  : _buildCivilClockDisplay(
                                      civilNow: liveCivilNow,
                                      settings: settings,
                                      fontSize: 66,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    );

                              final secondaryWidget = isAstroPrimary
                                  ? _buildCivilClockDisplay(
                                      civilNow: liveCivilNow,
                                      settings: settings,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFE2E8F0),
                                    )
                                  : _buildSuwayaClockDisplay(
                                      astroState: astroState,
                                      settings: settings,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFDE68A),
                                    );

                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: primaryWidget,
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.18,
                                        ),
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: secondaryWidget,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 20),
                          Text(
                            taskTitle,
                            style: TextStyle(
                              color: highContrastAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Inter',
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (taskBody.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              taskBody,
                              style: const TextStyle(
                                color: Color(0xFFE2E8F0),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (canSnooze)
                            Text(
                              '${'alarm.snooze'.tr()} +$snoozeMins ${'details.minute'.tr()} (${snoozeCount + 1}/$maxSnoozes)',
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            )
                          else if (!isPrayer &&
                              parsedData.snoozeAllowed &&
                              snoozeCount >= maxSnoozes)
                            Text(
                              'alarm.max_snoozes_reached'.tr(),
                              style: const TextStyle(
                                color: Color(0xFFFF8A80),
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                        ],
                      ),

                      // 🌟 القسم السفلي: شريط السحب والأزرار الصريحة بتباين عالٍ
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'alarm.swipe_to_stop'.tr(),
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                          ExcludeSemantics(
                            child: Directionality(
                              textDirection: ui.TextDirection.ltr,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final trackWidth = constraints.maxWidth - 16;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.65,
                                      ),
                                      borderRadius: BorderRadius.circular(40),
                                      border: Border.all(
                                        color: Colors.white38,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                left: 24.0,
                                              ),
                                              child: Text(
                                                'alarm.snooze'.tr(),
                                                style: TextStyle(
                                                  color: canSnooze
                                                      ? Colors.white70
                                                      : Colors.transparent,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 24.0,
                                              ),
                                              child: Text(
                                                'alarm.stop'.tr(),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Inter',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          left:
                                              (trackWidth / 2) -
                                              35 +
                                              _dragPosition,
                                          child: GestureDetector(
                                            onHorizontalDragUpdate: (details) {
                                              if (_isProcessingAction) return;
                                              setState(() {
                                                _dragPosition =
                                                    (_dragPosition +
                                                            details.delta.dx)
                                                        .clamp(
                                                          canSnooze
                                                              ? -_maxDragThreshold -
                                                                    20
                                                              : 0.0,
                                                          _maxDragThreshold +
                                                              20,
                                                        );
                                              });
                                            },
                                            onHorizontalDragEnd: (details) {
                                              if (_isProcessingAction) return;
                                              if (_dragPosition >
                                                  _maxDragThreshold) {
                                                _triggerStop();
                                              } else if (_dragPosition <
                                                      -_maxDragThreshold &&
                                                  canSnooze) {
                                                _triggerSnooze();
                                              } else {
                                                setState(
                                                  () => _dragPosition = 0,
                                                );
                                              }
                                            },
                                            child: AnimatedContainer(
                                              duration: _dragPosition == 0
                                                  ? const Duration(
                                                      milliseconds: 300,
                                                    )
                                                  : Duration.zero,
                                              curve: Curves.elasticOut,
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                color: _dragPosition > 50
                                                    ? const Color(0xFFEF4444)
                                                    : (_dragPosition < -50
                                                          ? const Color(
                                                              0xFFF59E0B,
                                                            )
                                                          : highContrastAccent),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: highContrastAccent
                                                        .withValues(
                                                          alpha: 0.55,
                                                        ),
                                                    blurRadius: 16,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                _dragPosition > 50
                                                    ? LucideIcons.x
                                                    : (_dragPosition < -50
                                                          ? Icons.snooze
                                                          : _kindIcon()),
                                                color: const Color(0xFF070A12),
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (canSnooze) ...[
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.08,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: _isProcessingAction
                                      ? null
                                      : _triggerSnooze,
                                  icon: const Icon(Icons.snooze, size: 20),
                                  label: Text(
                                    'alarm.snooze'.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF8A80),
                                  backgroundColor: const Color(
                                    0xFFEF4444,
                                  ).withValues(alpha: 0.14),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: _isProcessingAction
                                    ? null
                                    : _triggerStop,
                                icon: const Icon(
                                  LucideIcons.power_off,
                                  size: 20,
                                ),
                                label: Text(
                                  'alarm.stop'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
