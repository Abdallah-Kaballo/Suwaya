import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌟

class AlarmService {
  static const int maxSnoozes = 3;
  static const int snoozeMinutes = 5;

  static Future<void> init() async {
    await Alarm.init();
  }

  static Future<bool> checkAndRequestPermissions() async {
    bool allGranted = true;
    
    if (await Permission.scheduleExactAlarm.isDenied) {
      final status = await Permission.scheduleExactAlarm.request();
      if (!status.isGranted) allGranted = false;
    }
    if (await Permission.systemAlertWindow.isDenied) {
      final status = await Permission.systemAlertWindow.request();
      if (!status.isGranted) allGranted = false;
    }
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (!status.isGranted) allGranted = false;
    }
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
    
    DateTime safeTime = dateTime;
    if (safeTime.isBefore(DateTime.now())) {
      safeTime = safeTime.add(const Duration(days: 1));
    }

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: safeTime, 
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
        // 🌟 تطبيق الترجمة
        title: '${'notifications.alert'.tr()}: $title',
        body: 'alarm.swipe_to_stop'.tr(),
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
      payload: () => newPayload, 
    );
    
    await Alarm.stop(currentSettings.id);
    await Alarm.set(alarmSettings: newSettings);
  }
}