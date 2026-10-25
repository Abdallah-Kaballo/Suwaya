import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_localization/easy_localization.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _standardChannelId = 'suwaya_system_standard_v3';
  static const String _insistentChannelId = 'suwaya_system_alarm_v3';
  static const String _vibrateChannelId = 'suwaya_system_vibrate_v3';

  Future<void> init() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initSettings);
    await _createAndSweepChannels();
  }

  Future<void> refreshLocalizedChannels() async {
    await _createAndSweepChannels();
  }

  Future<void> _createAndSweepChannels() async {
    if (!Platform.isAndroid) return;
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    try {
      await androidImplementation
          ?.deleteNotificationChannel('suwaya_system_standard_v2');
      await androidImplementation
          ?.deleteNotificationChannel('suwaya_system_alarm_v2');
      await androidImplementation
          ?.deleteNotificationChannel('suwaya_system_vibrate_v2');
    } catch (_) {}

    const systemAlarmSound =
        UriAndroidNotificationSound('content://settings/system/alarm_alert');
    const systemNotifSound = UriAndroidNotificationSound(
        'content://settings/system/notification_sound');

    await androidImplementation?.createNotificationChannel(
      AndroidNotificationChannel(
        _standardChannelId,
        'notifications.system_alerts'.tr(),
        description: 'notifications.normal_tasks_desc'.tr(),
        importance: Importance.max,
        playSound: true,
        sound: systemNotifSound,
        enableVibration: true,
      ),
    );

    await androidImplementation?.createNotificationChannel(
      AndroidNotificationChannel(
        _insistentChannelId,
        'notifications.prayers_alerts'.tr(),
        description: 'notifications.prayers_alerts_desc'.tr(),
        importance: Importance.max,
        playSound: true,
        sound: systemAlarmSound,
        enableVibration: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    await androidImplementation?.createNotificationChannel(
      AndroidNotificationChannel(
        _vibrateChannelId,
        'notifications.silent_vibration'.tr(),
        description: 'notifications.silent_vibration_desc'.tr(),
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
      ),
    );
  }

  DateTime _getSafeScheduledTime(
    DateTime scheduledTime, {
    bool isDailyRoutine = true,
  }) {
    if (scheduledTime.isBefore(DateTime.now())) {
      if (isDailyRoutine) return scheduledTime.add(const Duration(days: 1));
    }
    return scheduledTime;
  }

  Future<bool> scheduleNormalNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool playSound = true,
    bool enableVibration = true,
  }) async {
    final safeTime =
        _getSafeScheduledTime(scheduledTime, isDailyRoutine: false);
    if (safeTime.isBefore(DateTime.now())) return true;

    final stopText =
        'alarm.stop'.tr() != 'alarm.stop' ? 'alarm.stop'.tr() : 'إيقاف';

    final androidDetails = AndroidNotificationDetails(
      playSound ? _standardChannelId : _vibrateChannelId,
      'notifications.system_alerts'.tr(),
      importance: Importance.max,
      priority: Priority.max,
      playSound: playSound,
      enableVibration: enableVibration,
      sound: playSound
          ? const UriAndroidNotificationSound(
              'content://settings/system/notification_sound',
            )
          : null,
      actions: playSound
          ? <AndroidNotificationAction>[
              AndroidNotificationAction(
                'stop_action',
                stopText,
                cancelNotification: true,
                showsUserInterface: false,
              ),
            ]
          : null,
    );

    return await _safeZonedSchedule(
      id,
      title,
      body,
      safeTime,
      androidDetails,
      InterruptionLevel.timeSensitive,
    );
  }

  Future<void> cancel(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<Set<int>> getPendingNormalNotificationIds() async {
    try {
      final pending =
          await flutterLocalNotificationsPlugin.pendingNotificationRequests();
      return pending
          .map((req) => req.id)
          .where((id) =>
              id != _pomodoroLiveNotificationId &&
              id != _pomodoroChimeNotificationId)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<bool> _safeZonedSchedule(
    int id,
    String title,
    String body,
    DateTime time,
    AndroidNotificationDetails androidDetails,
    InterruptionLevel iosLevel,
  ) async {
    final iosDetails = DarwinNotificationDetails(
      interruptionLevel: iosLevel,
      presentSound: androidDetails.playSound,
    );
    final tzTime = tz.TZDateTime.from(time, tz.local);
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (e) {
      debugPrint('⚠️ السقوط الآمن لجدولة الإشعار على الستارة: $e');
      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        return true;
      } catch (innerError) {
        debugPrint('🚨 فشل جدولة الإشعار نهائياً: $innerError');
        return false;
      }
    }
  }

  Future<void> cancelAll() async =>
      await flutterLocalNotificationsPlugin.cancelAll();
  static const int _pomodoroLiveNotificationId = 888888;
  static const int _pomodoroChimeNotificationId = 888889;

  /// 🌟 إظهار البومودورو الحية على الستارة مع عداد تنازلي حي (Chronometer Countdown)
  Future<void> showLivePomodoroNotification({
    required String title,
    required String body,
    required DateTime phaseEndTime,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _vibrateChannelId,
        'notifications.system_alerts'.tr(),
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
        showWhen: true,
        when: phaseEndTime.millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: true,
        category: AndroidNotificationCategory.progress,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: false,
        presentBadge: false,
        presentSound: false,
      );

      await flutterLocalNotificationsPlugin.show(
        _pomodoroLiveNotificationId,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (_) {}
  }

  /// 🌟 إلغاء إشعار البومودورو الحي من الستارة عند الإيقاف أو الانتهاء
  Future<void> cancelLivePomodoroNotification() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(_pomodoroLiveNotificationId);
    } catch (_) {}
  }

  /// 🌟 إصدار جرس تنبيه فوري عند انتهاء أو بدء جلسات البومودورو والراحة
  Future<void> playPomodoroTransitionAlert({
    required String title,
    required String body,
    required bool isMuted,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        isMuted ? _vibrateChannelId : _standardChannelId,
        'notifications.system_alerts'.tr(),
        importance: Importance.high,
        priority: Priority.high,
        playSound: !isMuted,
        enableVibration: true,
        autoCancel: true,
        timeoutAfter: 6000,
        sound: isMuted
            ? null
            : const UriAndroidNotificationSound(
                'content://settings/system/notification_sound',
              ),
      );

      final iosDetails = DarwinNotificationDetails(
        interruptionLevel: InterruptionLevel.active,
        presentSound: !isMuted,
      );

      await flutterLocalNotificationsPlugin.show(
        _pomodoroChimeNotificationId,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
      );
    } catch (_) {}
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
