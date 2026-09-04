import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';

class AlarmService {
  static const int maxSnoozes = 3;
  static const int snoozeMinutes = 5;

  static Future<void> init() async {
    await Alarm.init();
  }

  static Future<bool> checkAndRequestPermissions() async {
    bool allGranted = true;
    
    // صلاحية المنبهات الدقيقة (حرجة جداً لأندرويد 12 و 13 و 14)
    if (await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      if (!status.isGranted) allGranted = false;
    }
    // صلاحية الظهور فوق التطبيقات
    if (await Permission.systemAlertWindow.isDenied) {
      final status = await Permission.systemAlertWindow.request();
      if (!status.isGranted) allGranted = false;
    }
    // صلاحية تجاهل تحسين البطارية
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (!status.isGranted) allGranted = false;
    }
    // 🌟 إضافة صلاحية الإشعارات العادية (مهمة لأندرويد 13+)
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (!status.isGranted) allGranted = false;
    }

    return allGranted;
  }

  static Future<void> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required int colorValue,
    required String tonePath,
    required double volume,
    bool fullScreenIntent = true,
    bool vibrate = true,
  }) async {
    
    // 🌟 الحارس الزمني الذكي: إذا مضى الوقت، اجعله للغد (يمنع المنبه الشبح)
    DateTime safeTime = dateTime;
    if (safeTime.isBefore(DateTime.now())) {
      safeTime = safeTime.add(const Duration(days: 1));
    }

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: safeTime, // نستخدم الوقت الآمن هنا
      assetAudioPath: tonePath,
      loopAudio: true,
      vibrate: vibrate,
      androidFullScreenIntent: fullScreenIntent,
      payload: '$title|$colorValue|0',
      volumeSettings: VolumeSettings.fade(
        volume: volume,
        fadeDuration: const Duration(seconds: 10),
      ),
      notificationSettings: NotificationSettings(
        title: 'تنبيه: $title',
        body: 'اسحب للإيقاف أو الغفوة',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  static Future<void> snooze(AlarmSettings currentSettings) async {
    final payloadParts = currentSettings.payload?.split('|') ?? [];
    int currentSnoozes = payloadParts.length > 2 ? int.tryParse(payloadParts[2]) ?? 0 : 0;

    if (currentSnoozes >= maxSnoozes) return;
    final newPayload = '${payloadParts[0]}|${payloadParts[1]}|${currentSnoozes + 1}';

    final newSettings = currentSettings.copyWith(
      dateTime: DateTime.now().add(const Duration(minutes: snoozeMinutes)),
      payload: () => newPayload, // 🌟 تم إرجاع الأقواس لكي تتوافق مع دالة copyWith
    );
    
    await Alarm.stop(currentSettings.id);
    await Alarm.set(alarmSettings: newSettings);
  }
}