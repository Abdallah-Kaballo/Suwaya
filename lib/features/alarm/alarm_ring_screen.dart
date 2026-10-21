import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:alarm/alarm.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../core/astro_engine/astro_provider.dart';
import '../../core/services/alarm_service.dart';
import '../../features/settings/settings_provider.dart';
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
  late final Color accentColor;
  late final int snoozeCount;

  static const platform = MethodChannel('com.suwaya.app/lockscreen');

  double _dragPosition = 0.0;
  final double _maxDragThreshold = 110.0;
  bool _isProcessingAction = false;

  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _enableLockScreenAndAlarmStream();

    parsedData = AlarmService.parseAlarmSettings(widget.alarmSettings);
    taskTitle = parsedData.title;
    taskBody = parsedData.body;
    accentColor = Color(parsedData.colorValue);
    snoozeCount = parsedData.snoozeCount;

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.18, end: 0.55).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  /// 🌟 تفعيل الظهور فوق شاشة القفل + ربط أزرار الصوت الفيزيائية بمسار صوت المنبه (STREAM_ALARM)
  Future<void> _enableLockScreenAndAlarmStream() async {
    try {
      await platform.invokeMethod('showOnLockScreen');
      await platform.invokeMethod('setAlarmVolumeControl', {'enabled': true});
    } catch (e) {
      debugPrint('Lockscreen/Volume channel note: $e');
    }
  }

  Future<void> _disableLockScreenAndRestoreStream() async {
    try {
      await platform.invokeMethod('setAlarmVolumeControl', {'enabled': false});
      await platform.invokeMethod('hideFromLockScreen');
    } catch (e) {
      debugPrint('Lockscreen/Volume restore note: $e');
    }
  }

  @override
  void dispose() {
    _disableLockScreenAndRestoreStream();
    _glowController.dispose();
    super.dispose();
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
        content: Text(message),
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

    // محاولة ثانية احتياطية لضمان عدم بقاء المستخدم عالقاً
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final settings = ref.watch(settingsProvider);
    final maxSnoozes = settings.maxSnoozeCount > 0
        ? settings.maxSnoozeCount
        : parsedData.maxSnoozes;
    final snoozeMins = settings.snoozeDurationMinutes > 0
        ? settings.snoozeDurationMinutes
        : parsedData.snoozeDurationMinutes;

    final bool isPrayer = parsedData.kind == AlarmEventKind.prayer;
    final bool canSnooze =
        !isPrayer && parsedData.snoozeAllowed && snoozeCount < maxSnoozes;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        body: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.4,
                      colors: [
                        accentColor.withValues(alpha: _glowAnimation.value),
                        const Color(0xFF0B0F19),
                      ],
                    ),
                  ),
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 🌟 القسم العلوي: شارة نوع الحدث، الأيقونة، الساعة المدنية والسويعية، العنوان
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_kindIcon(), color: accentColor, size: 15),
                              const SizedBox(width: 6),
                              Text(
                                _kindBadgeLabel(context),
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        ClockTimeText.civil(
                          civilTime: now,
                          civilTimeFormat: settings.civilTimeFormat,
                          locale: context.locale.languageCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 62,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 6),
                        ValueListenableBuilder<String>(
                          valueListenable: virtualTimeNotifier,
                          builder: (context, virtualTime, _) {
                            return Directionality(
                              textDirection: ui.TextDirection.ltr,
                              child: Text(
                                virtualTime,
                                style: const TextStyle(
                                  color: Color(0xFFF2C94C),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                  letterSpacing: 1.2,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Text(
                          taskTitle,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (taskBody.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            taskBody,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (canSnooze)
                          Text(
                            '${'alarm.snooze'.tr()} +$snoozeMins ${'details.minute'.tr()} (${snoozeCount + 1}/$maxSnoozes)',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          )
                        else if (!isPrayer &&
                            parsedData.snoozeAllowed &&
                            snoozeCount >= maxSnoozes)
                          Text(
                            'alarm.max_snoozes_reached'.tr(),
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),

                    // 🌟 القسم السفلي: شريط السحب والأزرار الصريحة
                    Column(
                      children: [
                        Directionality(
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
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(
                                    color: Colors.white24,
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
                                                  ? Colors.white54
                                                  : Colors.transparent,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
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
                                              color: Colors.white54,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      left:
                                          (trackWidth / 2) - 35 + _dragPosition,
                                      child: GestureDetector(
                                        onHorizontalDragUpdate: (details) {
                                          if (_isProcessingAction) return;
                                          setState(() {
                                            _dragPosition = (_dragPosition +
                                                    details.delta.dx)
                                                .clamp(
                                              canSnooze
                                                  ? -_maxDragThreshold - 20
                                                  : 0.0,
                                              _maxDragThreshold + 20,
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
                                            setState(() => _dragPosition = 0);
                                          }
                                        },
                                        child: AnimatedContainer(
                                          duration: _dragPosition == 0
                                              ? const Duration(milliseconds: 300)
                                              : Duration.zero,
                                          curve: Curves.elasticOut,
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: _dragPosition > 50
                                                ? Colors.redAccent
                                                : (_dragPosition < -50
                                                    ? Colors.amber
                                                    : accentColor),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: accentColor.withValues(
                                                  alpha: 0.5,
                                                ),
                                                blurRadius: 15,
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
                                            color: Colors.white,
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
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (canSnooze) ...[
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                ),
                                onPressed:
                                    _isProcessingAction ? null : _triggerSnooze,
                                icon: const Icon(Icons.snooze),
                                label: Text(
                                  'alarm.snooze'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                              ),
                              onPressed:
                                  _isProcessingAction ? null : _triggerStop,
                              icon: const Icon(LucideIcons.power_off),
                              label: Text(
                                'alarm.stop'.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }
}