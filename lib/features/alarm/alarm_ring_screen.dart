import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:alarm/alarm.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../core/services/alarm_service.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> with SingleTickerProviderStateMixin {
  late String taskTitle;
  late Color accentColor;
  late int snoozeCount;
  
  static const platform = MethodChannel('com.suwaya.app/lockscreen');
  
  double _dragPosition = 0.0;
  final double _maxDragThreshold = 120.0; 
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _enableLockScreenVisibility();

    // 🌟 الترجمة للنصوص الافتراضية
    final payload = widget.alarmSettings.payload?.split('|') ?? ['alarm.default_title'.tr(), '0xFFD4AF37', '0'];
    taskTitle = payload[0] == 'تنبيه' ? 'alarm.default_title'.tr() : payload[0];
    accentColor = Color(int.tryParse(payload[1]) ?? 0xFFD4AF37);
    snoozeCount = int.tryParse(payload[2]) ?? 0;

    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

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
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp || event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
        _triggerSnooze();
        return true; 
      }
    }
    return false;
  }

  void _triggerSnooze() {
    if (snoozeCount >= AlarmService.maxSnoozes) return;
    HapticFeedback.heavyImpact();
    AlarmService.snooze(widget.alarmSettings);
    SystemNavigator.pop(); 
  }

  void _triggerStop() {
    HapticFeedback.heavyImpact();
    Alarm.stop(widget.alarmSettings.id);
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final bool canSnooze = snoozeCount < AlarmService.maxSnoozes;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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
                    radius: 1.5,
                    colors: [accentColor.withValues(alpha: _glowAnimation.value), const Color(0xFF0F172A)],
                  ),
                ),
              );
            },
          ),
          
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(LucideIcons.alarm_clock, color: accentColor, size: 40),
                    const SizedBox(height: 16),
                    Text(timeStr, style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                    const SizedBox(height: 8),
                    Text(taskTitle, style: TextStyle(color: accentColor, fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    if (canSnooze)
                      // 🌟 ترجمة الغفوات
                      Text('${'alarm.snooze'.tr()} ${snoozeCount + 1} ${'common.of'.tr()} ${AlarmService.maxSnoozes}', style: const TextStyle(color: Colors.white54, fontSize: 14))
                    else
                      Text('alarm.max_snoozes_reached'.tr(), style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                  ],
                ),

                // 🌟 نظام السحب + أزرار النقر البديلة لحل مشكلة الإمكانية (Accessibility)
                Column(
                  children: [
                    Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 24.0),
                                  child: Text('alarm.snooze'.tr(), style: TextStyle(color: canSnooze ? Colors.white54 : Colors.transparent, fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 24.0),
                                  child: Text('alarm.stop'.tr(), style: const TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            Positioned(
                              left: (MediaQuery.of(context).size.width - 64) / 2 - 35 + _dragPosition,
                              child: GestureDetector(
                                onHorizontalDragUpdate: (details) {
                                  setState(() {
                                    _dragPosition += details.delta.dx;
                                    if (!canSnooze && _dragPosition < 0) _dragPosition = 0;
                                  });
                                },
                                onHorizontalDragEnd: (details) {
                                  if (_dragPosition > _maxDragThreshold) {
                                    _triggerStop();
                                  } else if (_dragPosition < -_maxDragThreshold && canSnooze) {
                                    _triggerSnooze();
                                  } else {
                                    setState(() => _dragPosition = 0);
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: _dragPosition == 0 ? const Duration(milliseconds: 300) : Duration.zero,
                                  curve: Curves.elasticOut,
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: _dragPosition > 50 ? Colors.redAccent : (_dragPosition < -50 ? Colors.amber : accentColor),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)],
                                  ),
                                  child: Icon(
                                    _dragPosition > 50 ? LucideIcons.x : (_dragPosition < -50 ? Icons.snooze : LucideIcons.bell_ring),
                                    color: Colors.white, size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 🌟 أزرار ضخمة بديلة في حال لم يفهم المستخدم نظام السحب
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (canSnooze) ...[
                          TextButton.icon(
                            style: TextButton.styleFrom(foregroundColor: Colors.white70, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                            onPressed: _triggerSnooze,
                            icon: const Icon(Icons.snooze),
                            label: Text('alarm.snooze'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 16),
                        ],
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                          onPressed: _triggerStop,
                          icon: const Icon(LucideIcons.power_off),
                          label: Text('alarm.stop'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}