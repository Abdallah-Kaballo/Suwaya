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
    _enableLockScreenVisibility();

    // 🌟 قراءة موحدة وذكية لبيانات المنبه (سواء من payload أو NotificationSettings)
    final parsed = AlarmService.parseAlarmSettings(widget.alarmSettings);
    taskTitle = parsed.title;
    taskBody = parsed.body;
    accentColor = Color(parsed.colorValue);
    snoozeCount = parsed.snoozeCount;

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.18, end: 0.55).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    HardwareKeyboard.instance.addHandler(_handleHardwareKeys);
  }

  Future<void> _enableLockScreenVisibility() async {
    try {
      await platform.invokeMethod('showOnLockScreen');
    } catch (e) {
      debugPrint('Failed to show on lock screen: $e');
    }
  }

  Future<void> _disableLockScreenVisibility() async {
    try {
      await platform.invokeMethod('hideFromLockScreen');
    } catch (e) {
      debugPrint('Failed to hide from lock screen: $e');
    }
  }

  @override
  void dispose() {
    _disableLockScreenVisibility();
    _glowController.dispose();
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeys);
    super.dispose();
  }

  bool _handleHardwareKeys(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp ||
          event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
        _triggerSnooze();
        return true;
      }
    }
    return false;
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

  Future<void> _triggerSnooze() async {
    if (_isProcessingAction) return;
    final settings = ref.read(settingsProvider);
    final maxSnoozes = settings.maxSnoozeCount > 0
        ? settings.maxSnoozeCount
        : AlarmService.defaultMaxSnoozes;
    final snoozeMins = settings.snoozeDurationMinutes > 0
        ? settings.snoozeDurationMinutes
        : AlarmService.defaultSnoozeMinutes;

    if (snoozeCount >= maxSnoozes) return;

    _isProcessingAction = true;
    HapticFeedback.heavyImpact();
    await AlarmService.snooze(
      widget.alarmSettings,
      snoozeMinutes: snoozeMins,
      maxSnoozes: maxSnoozes,
    );
    _closeRingScreen();
  }

  Future<void> _triggerStop() async {
    if (_isProcessingAction) return;
    _isProcessingAction = true;
    HapticFeedback.heavyImpact();
    await Alarm.stop(widget.alarmSettings.id);
    _closeRingScreen();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final settings = ref.watch(settingsProvider);
    final maxSnoozes = settings.maxSnoozeCount > 0
        ? settings.maxSnoozeCount
        : AlarmService.defaultMaxSnoozes;
    final bool canSnooze = snoozeCount < maxSnoozes;

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
                    // 🌟 القسم العلوي: الأيقونة، الوقت السويعي والمدني، العنوان والوصف
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.alarm_clock,
                            color: accentColor,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ClockTimeText.civil(
                          civilTime: now,
                          civilTimeFormat: settings.civilTimeFormat,
                          locale: context.locale.languageCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
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
                            '${'alarm.snooze'.tr()} (${snoozeCount + 1}/$maxSnoozes)',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 13,
                            ),
                          )
                        else
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

                    // 🌟 القسم السفلي: شريط السحب والأزرار السريعة
                    Column(
                      children: [
                        Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final trackWidth = constraints.maxWidth - 16;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
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
                                          padding:
                                              const EdgeInsets.only(left: 24.0),
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
                                          padding:
                                              const EdgeInsets.only(right: 24.0),
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
                                      left: (trackWidth / 2) - 35 + _dragPosition,
                                      child: GestureDetector(
                                        onHorizontalDragUpdate: (details) {
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
                                                    alpha: 0.5),
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
                                                    : LucideIcons.bell_ring),
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
                                onPressed: _triggerSnooze,
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
                              onPressed: _triggerStop,
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