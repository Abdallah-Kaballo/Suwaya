import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:alarm/alarm.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../../core/services/alarm_service.dart';

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
  
  // 🌟 متغيرات الشريط المزدوج
  double _dragPosition = 0.0;
  final double _maxDragThreshold = 120.0; // المسافة المطلوبة لتفعيل الإجراء
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // تحليل البيانات القادمة من المنبه (Isolate Payload)
    final payload = widget.alarmSettings.payload?.split('|') ?? ['تنبيه', '0xFFD4AF37', '0'];
    taskTitle = payload[0];
    accentColor = Color(int.tryParse(payload[1]) ?? 0xFFD4AF37);
    snoozeCount = int.tryParse(payload[2]) ?? 0;

    // نبض الإضاءة الهادئ
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeInOut));

    // 🌟 السحر: الاستماع لأزرار خفض ورفع الصوت للغفوة
    HardwareKeyboard.instance.addHandler(_handleHardwareKeys);
  }

  @override
  void dispose() {
    _glowController.dispose();
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeys);
    super.dispose();
  }

  bool _handleHardwareKeys(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp || event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
        _triggerSnooze();
        return true; // يمنع تغيير الصوت ويفعل الغفوة بدلاً من ذلك
      }
    }
    return false;
  }

  void _triggerSnooze() {
    if (snoozeCount >= AlarmService.maxSnoozes) return;
    HapticFeedback.heavyImpact();
    AlarmService.snooze(widget.alarmSettings);
    // 🌟 تطبيق طلبك: إغلاق الشاشة فوراً دون فتح التطبيق
    SystemNavigator.pop(); 
  }

  void _triggerStop() {
    HapticFeedback.heavyImpact();
    Alarm.stop(widget.alarmSettings.id);
    // 🌟 تطبيق طلبك: إغلاق الشاشة فوراً والعودة للصفحة الرئيسية للهاتف
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
          // خلفية نابضة باللون المميز للمهمة
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
                // 1. الوقت واسم المهمة
                Column(
                  children: [
                    Icon(LucideIcons.alarm_clock, color: accentColor, size: 40),
                    const SizedBox(height: 16),
                    Text(timeStr, style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                    const SizedBox(height: 8),
                    Text(taskTitle, style: TextStyle(color: accentColor, fontSize: 32, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    if (canSnooze)
                      Text('غفوة ${snoozeCount + 1} من ${AlarmService.maxSnoozes}', style: const TextStyle(color: Colors.white54, fontSize: 14))
                    else
                      const Text('بلغت الحد الأقصى للغفوات', style: TextStyle(color: Colors.redAccent, fontSize: 14)),
                  ],
                ),

                // 2. شريط السحب المزدوج (Double-sided Slider)
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
                        // نصوص الخلفية
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 24.0),
                              child: Text('غفوة', style: TextStyle(color: canSnooze ? Colors.white54 : Colors.transparent, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(right: 24.0),
                              child: Text('إيقاف', style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        // الزر القابل للسحب
                        Positioned(
                          left: (MediaQuery.of(context).size.width - 64) / 2 - 35 + _dragPosition,
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              setState(() {
                                _dragPosition += details.delta.dx;
                                // منع السحب للغفوة إذا انتهى رصيد الغفوات
                                if (!canSnooze && _dragPosition < 0) _dragPosition = 0;
                              });
                            },
                            onHorizontalDragEnd: (details) {
                              if (_dragPosition > _maxDragThreshold) {
                                _triggerStop();
                              } else if (_dragPosition < -_maxDragThreshold && canSnooze) {
                                _triggerSnooze();
                              } else {
                                // العودة للمنتصف بمرونة إذا لم يكمل السحب
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}