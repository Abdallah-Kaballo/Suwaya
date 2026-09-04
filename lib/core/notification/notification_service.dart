import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const String _standardChannelId = 'suwaya_system_standard_v2';
  static const String _insistentChannelId = 'suwaya_system_alarm_v2';
  static const String _vibrateChannelId = 'suwaya_system_vibrate_v2';

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);
    await _createChannels();
  }

  Future<void> _createChannels() async {
    if (!Platform.isAndroid) return;
    final androidImplementation = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    const systemAlarmSound = UriAndroidNotificationSound('content://settings/system/alarm_alert');
    const systemNotifSound = UriAndroidNotificationSound('content://settings/system/notification_sound');

    await androidImplementation?.createNotificationChannel(const AndroidNotificationChannel(
      _standardChannelId, 'إشعارات النظام',
      description: 'إشعارات المهام العادية',
      importance: Importance.high, playSound: true, sound: systemNotifSound, enableVibration: true,
    ));
    
    await androidImplementation?.createNotificationChannel(const AndroidNotificationChannel(
      _insistentChannelId, 'تنبيهات الصلوات القوية',
      description: 'منبه يستخدم نغمة جهازك الرسمية ويخترق الوضع الصامت',
      importance: Importance.max, playSound: true, sound: systemAlarmSound, enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ));
    
    await androidImplementation?.createNotificationChannel(const AndroidNotificationChannel(
      _vibrateChannelId, 'الاهتزاز الصامت',
      description: 'تنبيه بالاهتزاز فقط',
      importance: Importance.high, playSound: false, enableVibration: true,
    ));
  }

  // 🌟 دالة مساعدة لضبط الوقت بأمان (لتفادي المنبهات المفقودة أو الوهمية)
  DateTime _getSafeScheduledTime(DateTime scheduledTime, {bool isDailyRoutine = true}) {
    if (scheduledTime.isBefore(DateTime.now())) {
      // إذا كان روتيناً يومياً (صلاة)، نرحله للغد. أما إذا كانت مهمة عابرة نتركها لتتجاهل (return لاحقاً)
      if (isDailyRoutine) return scheduledTime.add(const Duration(days: 1));
    }
    return scheduledTime;
  }

  Future<void> scheduleNormalNotification({
    required int id, required String title, required String body, required DateTime scheduledTime,
    bool playSound = true, bool enableVibration = true,
  }) async {
    final safeTime = _getSafeScheduledTime(scheduledTime);
    if (safeTime.isBefore(DateTime.now())) return; // حماية أخيرة

    final androidDetails = AndroidNotificationDetails(
      _standardChannelId, 'إشعارات النظام',
      importance: Importance.high, priority: Priority.high,
      playSound: playSound, enableVibration: enableVibration,
      sound: const UriAndroidNotificationSound('content://settings/system/notification_sound'),
    );

    _safeZonedSchedule(id, title, body, safeTime, androidDetails, InterruptionLevel.active);
  }

  Future<void> scheduleInsistentAlarm({
    required int id, required String title, required String body, required DateTime scheduledTime,
  }) async {
    final safeTime = _getSafeScheduledTime(scheduledTime);
    if (safeTime.isBefore(DateTime.now())) return;

    final androidDetails = AndroidNotificationDetails(
      _insistentChannelId, 'تنبيهات الصلوات القوية',
      importance: Importance.max, priority: Priority.max,
      playSound: true, enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
      fullScreenIntent: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: const UriAndroidNotificationSound('content://settings/system/alarm_alert'),
    );

    _safeZonedSchedule(id, title, body, safeTime, androidDetails, InterruptionLevel.critical);
  }

  Future<void> scheduleTaskNotification({
    required int id, required String title, required String body,
    required DateTime scheduledTime,
    required bool alarmMode, required bool notifyMode, required bool vibrateMode,
  }) async {
    // المهام العابرة لا نرحلها للغد، إذا مضت نلغيها
    if (scheduledTime.isBefore(DateTime.now())) return;

    String channelId = _standardChannelId;
    Importance importance = Importance.high;
    bool playSound = true;
    bool isInsistent = false;
    AndroidNotificationSound? targetSound = const UriAndroidNotificationSound('content://settings/system/notification_sound');

    if (alarmMode) {
      channelId = _insistentChannelId;
      importance = Importance.max;
      isInsistent = true;
      targetSound = const UriAndroidNotificationSound('content://settings/system/alarm_alert');
    } else if (!notifyMode && vibrateMode) {
      channelId = _vibrateChannelId;
      playSound = false;
      targetSound = null;
    } else if (!notifyMode && !vibrateMode && !alarmMode) {
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      alarmMode ? 'تنبيهات قوية' : 'إشعارات',
      importance: importance,
      priority: Priority.max,
      playSound: playSound,
      sound: targetSound,
      enableVibration: true,
      category: isInsistent ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
      additionalFlags: isInsistent ? Int32List.fromList(<int>[4]) : null,
      fullScreenIntent: isInsistent,
      audioAttributesUsage: isInsistent ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
    );

    _safeZonedSchedule(id, title, body, scheduledTime, androidDetails, isInsistent ? InterruptionLevel.critical : InterruptionLevel.active);
  }

  // 🌟 حارس أمان ضد الانهيارات في Android 14+ بسبب صلاحية Exact Alarm
  Future<void> _safeZonedSchedule(int id, String title, String body, DateTime time, AndroidNotificationDetails androidDetails, InterruptionLevel iosLevel) async {
    try {
      final iosDetails = DarwinNotificationDetails(interruptionLevel: iosLevel, presentSound: androidDetails.playSound);
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id, title, body,
        tz.TZDateTime.from(time, tz.local),
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('🚨 فشل جدولة الإشعار بسبب نقص الصلاحيات: $e');
    }
  }

  Future<void> cancelAll() async => await flutterLocalNotificationsPlugin.cancelAll();
  Future<void> cancelNotification(int id) async => await flutterLocalNotificationsPlugin.cancel(id);
}

// مزود الخدمة
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});