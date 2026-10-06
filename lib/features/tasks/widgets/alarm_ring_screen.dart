import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:alarm/alarm.dart';

class AlarmRingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  // دالة الإيقاف
  void _stopAlarm(BuildContext context) async {
    HapticFeedback.heavyImpact();
    await Alarm.stop(alarmSettings.id);
    if (context.mounted) Navigator.pop(context);
  }

  // دالة الغفوة (10 دقائق افتراضياً)
  void _snoozeAlarm(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final now = DateTime.now();
    
    // إنشاء إعدادات جديدة للغفوة بعد 10 دقائق
    final snoozeSettings = alarmSettings.copyWith(
      dateTime: DateTime(
        now.year, now.month, now.day, now.hour, now.minute, 0, 0,
      ).add(const Duration(minutes: 10)),
    );
    
    await Alarm.set(alarmSettings: snoozeSettings);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 التحديث الجديد: قراءة البيانات مع مفاتيح الـ Fallback
    final title = alarmSettings.notificationSettings.title.isNotEmpty 
        ? alarmSettings.notificationSettings.title 
        : 'alarm_screen.default_title'.tr();
    final body = alarmSettings.notificationSettings.body.isNotEmpty 
        ? alarmSettings.notificationSettings.body 
        : 'alarm_screen.default_body'.tr();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19), // لون ليلي عميق
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // الأيقونة العلوية
            const Center(
              child: Icon(LucideIcons.bell_ring, color: Color(0xFFD4AF37), size: 60),
            ),
            
            // عنوان التنبيه
            Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),

            // أزرار التفاعل (إيقاف / غفوة)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    RawMaterialButton(
                      onPressed: () => _snoozeAlarm(context),
                      shape: const CircleBorder(),
                      fillColor: Colors.white12,
                      padding: const EdgeInsets.all(24),
                      child: const Icon(LucideIcons.moon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text('alarm_screen.snooze'.tr(), style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  ],
                ),
                
                Column(
                  children: [
                    RawMaterialButton(
                      onPressed: () => _stopAlarm(context),
                      shape: const CircleBorder(),
                      fillColor: const Color(0xFFD4AF37), 
                      padding: const EdgeInsets.all(32),
                      child: const Icon(LucideIcons.power, color: Colors.black, size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text('alarm_screen.stop'.tr(), style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}