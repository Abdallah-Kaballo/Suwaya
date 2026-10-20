import 'package:alarm/alarm.dart';
import 'package:easy_localization/easy_localization.dart';

class ParsedAlarmData {
  final String title;
  final String body;
  final int colorValue;
  final int snoozeCount;

  const ParsedAlarmData({
    required this.title,
    required this.body,
    required this.colorValue,
    required this.snoozeCount,
  });
}

class AlarmService {
  static const int defaultMaxSnoozes = 3;
  static const int defaultSnoozeMinutes = 5;

  static Future<void> init() async {
    await Alarm.init();
  }

  /// 🌟 استخراج ذكي لبيانات المنبه يدعم كلاً من payload و notificationSettings
  static ParsedAlarmData parseAlarmSettings(AlarmSettings settings) {
    final notifTitle = settings.notificationSettings.title;
    final notifBody = settings.notificationSettings.body;

    final fallbackTitle = notifTitle.isNotEmpty
        ? notifTitle
        : 'alarm.default_title'.tr();
    final fallbackBody = notifBody.isNotEmpty
        ? notifBody
        : 'alarm.swipe_to_stop'.tr();

    final rawPayload = settings.payload;
    if (rawPayload == null || rawPayload.trim().isEmpty) {
      return ParsedAlarmData(
        title: fallbackTitle,
        body: fallbackBody,
        colorValue: 0xFFD4AF37,
        snoozeCount: 0,
      );
    }

    // 🌟 تنظيف البادئة (curtain| أو fullscreen|) بعد التحقق من وجود rawPayload
    final cleanPayload = rawPayload.replaceFirst(
      RegExp(r'^(curtain|fullscreen)\|'),
      '',
    );
    final parts = cleanPayload.split('|');

    final payloadTitle =
        (parts.isNotEmpty && parts[0].isNotEmpty && parts[0] != 'تنبيه')
            ? parts[0]
            : fallbackTitle;
    final colorVal = parts.length > 1
        ? (int.tryParse(parts[1]) ?? 0xFFD4AF37)
        : 0xFFD4AF37;
    final snoozes = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;

    return ParsedAlarmData(
      title: payloadTitle,
      body: fallbackBody,
      colorValue: colorVal,
      snoozeCount: snoozes,
    );
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
      payload: 'fullscreen|$title|$colorValue|0',
      volumeSettings: VolumeSettings.fade(
        volume: volume,
        fadeDuration: const Duration(seconds: 5),
        volumeEnforced: true,
      ),
      notificationSettings: NotificationSettings(
        title: '${'notifications.alert'.tr()}: $title',
        body: 'alarm.swipe_to_stop'.tr(),
        stopButton: 'alarm.stop'.tr(),
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  /// 🌟 غفوة ذكية تحترم إعدادات المستخدم وتحتفظ بعدد الغفوات حتى للمنبهات المجدولة عبر SchedulerService
  static Future<void> snooze(
    AlarmSettings currentSettings, {
    int snoozeMinutes = defaultSnoozeMinutes,
    int maxSnoozes = defaultMaxSnoozes,
  }) async {
    final parsed = parseAlarmSettings(currentSettings);

    if (parsed.snoozeCount >= maxSnoozes) return;

    final newPayload =
        'fullscreen|${parsed.title}|${parsed.colorValue}|${parsed.snoozeCount + 1}';

    final newSettings = currentSettings.copyWith(
      dateTime: DateTime.now().add(Duration(minutes: snoozeMinutes)),
      payload: () => newPayload,
    );

    await Alarm.stop(currentSettings.id);
    await Alarm.set(alarmSettings: newSettings);
  }
}