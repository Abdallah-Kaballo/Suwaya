import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:alarm/alarm.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:suwaya_time/suwaya_time.dart';

import 'routine_time_resolver.dart';
import '../../models/routine_model.dart';
import '../../models/task_model.dart';
import '../../models/settings_model.dart';
import '../../features/tasks/tasks_provider.dart';
import '../../features/settings/settings_provider.dart';
import '../../features/routines/routines_provider.dart';
import '../astro_engine/astro_provider.dart';
import '../services/alarm_service.dart';
import '../utils/time_formatters.dart';
import 'notification_service.dart';

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final notifService = ref.read(notificationServiceProvider);
  final scheduler = NotificationScheduler(notifService);

  Timer? debounceTimer;
  void triggerSchedule() {
    debounceTimer?.cancel();
    debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      final settings = ref.read(settingsProvider);
      final tasks = ref.read(tasksProvider).allTasks;
      final routines = ref.read(routinesProvider);
      scheduler.scheduleAhead(settings, tasks, routines);
    });
  }

  Future.microtask(() => triggerSchedule());

  ref.listen(tasksProvider, (prev, next) {
    if (prev?.allTasks != next.allTasks) triggerSchedule();
  });

  ref.listen(routinesProvider, (prev, next) {
    triggerSchedule();
  });

  // 🌟 إعادة تحريك نافذة الجدولة تلقائياً عند دخول دورة مغرب جديدة أو تغير الفترة الفلكية
  ref.listen(
    astroProvider.select((a) => a.cycleAnchors.cycleEndMaghrib),
    (prev, next) {
      if (prev != next) triggerSchedule();
    },
  );

  // 🌟 مراقبة شاملة لجميع حقول الإعدادات المؤثرة في الجدولة (شاملة visibleNightParts والغفوة)
  ref.listen(settingsProvider.select((s) {
    final sb = StringBuffer()
      ..write(
        'loc=${s.activeLocation?.latitude},${s.activeLocation?.longitude},${s.activeLocation?.timezone};',
      )
      ..write(
        'astro=${s.calculationMethod},${s.madhab},${s.highLatitudeRule},${s.customFajrAngle},${s.customIshaAngle},${s.useAstroTimeForIbadat};',
      )
      ..write(
        'night=${s.visibleNightParts.join(",")};snooze=${s.snoozeDurationMinutes},${s.maxSnoozeCount};',
      );
    for (var c in s.periodConfigs) {
      sb.write(
        'p=${c.periodId}:${c.isEnabled}:${c.alertLevel}:${c.soundPath}:${c.volume}:${c.manualOffsetMinutes};',
      );
    }
    return sb.toString();
  }), (prev, nextFingerprint) {
    triggerSchedule();
  });

  return scheduler;
});

class NotificationScheduler {
  final NotificationService _service;
  bool _isScheduling = false;

  // 🌟 حفظ أحدث طلب جدولة يصل أثناء انشغال المجدول لمنع إسقاط التعديلات
  bool _hasPendingSchedule = false;
  SettingsModel? _pendingSettings;
  List<TaskModel>? _pendingTasks;
  List<RoutineModel>? _pendingRoutines;
  bool _pendingForceRefresh = false;

  String _lastScheduleHash = '';
  Set<int> _previouslyScheduledNormalIds = {};
  int _retryCount = 0;
  Timer? _retryTimer;

  NotificationScheduler(this._service);

  /// 🌟 معرف رقمي ثابت وحتمي لأجزاء الليل الخمسة (بدلاً من String.hashCode غير المستقر)
  static int stableNightPartCode(String nightPartId) {
    switch (nightPartId.trim().toLowerCase()) {
      case 'half_1':
        return 11;
      case 'half_2':
        return 12;
      case 'third_1':
        return 21;
      case 'third_2':
        return 22;
      case 'third_3':
        return 23;
      case 'sixth_1':
        return 31;
      case 'sixth_2':
        return 32;
      case 'sixth_3':
        return 33;
      case 'sixth_4':
        return 34;
      case 'sixth_5':
        return 35;
      case 'sixth_6':
        return 36;
      default:
        int acc = 50;
        for (final unit in nightPartId.codeUnits) {
          acc = ((acc * 31) + unit) % 40 + 50;
        }
        return acc;
    }
  }

  /// 🌟 منع تصادم تنبيهين في نفس الثانية الفعلية:
  /// تعطى الأولوية المطلقة للأذان في الثانية +0s، وتُزاح التنبيهات المتزامنة معه بمقدار +2s تتابعياً
  static DateTime resolveCollisionSafeTime(
    DateTime desiredTime,
    Set<int> occupiedEpochSeconds,
  ) {
    final cleanTime = DateTime(
      desiredTime.year,
      desiredTime.month,
      desiredTime.day,
      desiredTime.hour,
      desiredTime.minute,
      desiredTime.second,
    );
    int candidateSec = cleanTime.millisecondsSinceEpoch ~/ 1000;
    int offsetSeconds = 0;

    while (occupiedEpochSeconds.contains(candidateSec) && offsetSeconds < 30) {
      offsetSeconds += 2;
      candidateSec += 2;
    }

    occupiedEpochSeconds.add(candidateSec);
    return cleanTime.add(Duration(seconds: offsetSeconds));
  }

  Duration _getUtcOffsetForDate(
    SavedLocation? loc,
    DateTime targetDate, {
    int hour = 12,
  }) {
    if (loc != null && loc.timezone != null && loc.timezone!.isNotEmpty) {
      try {
        final location = tz.getLocation(loc.timezone!);
        final targetInTz = tz.TZDateTime(
          location,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          hour,
        );
        return targetInTz.timeZoneOffset;
      } catch (_) {}
    }
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
    ).timeZoneOffset;
  }

  DateTime _getCityNow(SavedLocation? loc) {
    if (loc != null && loc.timezone != null && loc.timezone!.isNotEmpty) {
      try {
        final location = tz.getLocation(loc.timezone!);
        final nowInTarget = tz.TZDateTime.now(location);
        return DateTime.utc(
          nowInTarget.year,
          nowInTarget.month,
          nowInTarget.day,
          nowInTarget.hour,
          nowInTarget.minute,
          nowInTarget.second,
        );
      } catch (_) {}
    }
    final now = DateTime.now();
    return DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
    );
  }

  DateTime _resolveRealDeviceAlarmTime({
    required DateTime targetCityWallTime,
    required DateTime cityNowWallTime,
    required SavedLocation? loc,
  }) {
    if (loc != null && loc.timezone != null && loc.timezone!.isNotEmpty) {
      try {
        final location = tz.getLocation(loc.timezone!);
        final nowTz = tz.TZDateTime.now(location);
        final targetTz = tz.TZDateTime(
          location,
          targetCityWallTime.year,
          targetCityWallTime.month,
          targetCityWallTime.day,
          targetCityWallTime.hour,
          targetCityWallTime.minute,
          targetCityWallTime.second,
        );
        final realDuration = targetTz.difference(nowTz);
        return DateTime.now().add(realDuration);
      } catch (_) {}
    }

    return DateTime(
      targetCityWallTime.year,
      targetCityWallTime.month,
      targetCityWallTime.day,
      targetCityWallTime.hour,
      targetCityWallTime.minute,
      targetCityWallTime.second,
    );
  }

  String _getAssetAudioPath(String? soundId) {
    if (soundId == null || soundId.isEmpty || soundId == 'default') {
      return 'assets/audio/default.mp3';
    }
    if (soundId == 'assets/audio/birds.mp3' || soundId == 'birds') {
      return 'assets/audio/soft.mp3';
    }
    if (soundId.contains('assets/')) return soundId;
    return 'assets/audio/$soundId.mp3';
  }

  Future<void> scheduleAhead(
    SettingsModel settings,
    List<TaskModel> allTasks,
    List<RoutineModel> routines, {
    bool forceRefresh = false,
  }) async {
    if (_isScheduling) {
      _hasPendingSchedule = true;
      _pendingSettings = settings.clone();
      _pendingTasks = List<TaskModel>.from(allTasks);
      _pendingRoutines = List<RoutineModel>.from(routines);
      _pendingForceRefresh = _pendingForceRefresh || forceRefresh;
      return;
    }

    final loc = settings.activeLocation;
    if (loc == null) {
      // مقصود: لا نحدث _lastScheduleHash حتى تعاد المحاولة فور اختيار المستخدم لموقعه
      return;
    }

    final cityNow = _getCityNow(loc);
    final todayOffset = _getUtcOffsetForDate(loc, cityNow);

    // 🌟 تضمين تاريخ اليوم الحالي في البصمة لضمان تحرك نافذة الـ 7 أيام تلقائياً كل يوم جديد
    final sb = StringBuffer()
      ..write(
        'date=${cityNow.year}-${cityNow.month}-${cityNow.day};',
      )
      ..write(
        'loc=${loc.latitude},${loc.longitude},${loc.timezone},offset=${todayOffset.inMinutes};',
      )
      ..write(
        'astro=${settings.calculationMethod},${settings.madhab},${settings.highLatitudeRule},${settings.customFajrAngle},${settings.customIshaAngle},${settings.useAstroTimeForIbadat};',
      )
      ..write(
        'nightParts=${settings.visibleNightParts.join(",")};snooze=${settings.snoozeDurationMinutes}:${settings.maxSnoozeCount};',
      );

    for (final c in settings.periodConfigs) {
      sb.write(
        'p=${c.periodId}:${c.isEnabled}:${c.alertLevel}:${c.soundPath}:${c.volume}:${c.manualOffsetMinutes};',
      );
    }

    for (final t in allTasks) {
      sb.write(
        't=${t.id}:${t.title}:${t.type.index}:${t.isCompleted}:'
        '${t.lastCompletedDate?.millisecondsSinceEpoch}:'
        '${t.targetDate?.millisecondsSinceEpoch}:'
        '${t.isAstroTime}:${t.targetPeriodId}:'
        '${t.targetSuwayas.join(",")}:${t.targetVirtualMinute}:'
        '${t.targetCivilTimeMinutes}:'
        '${t.recurrenceDays?.join(",")}:'
        '${t.notifyMode}:${t.alarmMode}:${t.vibrateMode}:'
        '${t.alarmTone}:${t.alarmVolume}:${t.scheduleModelVersion};',
      );
    }

    sb.write(buildRoutineScheduleFingerprint(routines));
    final currentHash = sb.toString();

    if (!forceRefresh && currentHash == _lastScheduleHash) return;

    bool hadSchedulingFailures = false;

    try {
      _isScheduling = true;

      final activeAlarms = await Alarm.getAlarms();
      final activeAlarmMap = {for (var a in activeAlarms) a.id: a};

      final Set<int> requiredAlarmIds = {};
      final Set<int> requiredNormalIds = {};
      final Set<int> occupiedAlarmSeconds = {};

      final manualOffsetsMap = {
        for (var c in settings.periodConfigs)
          if (c.periodId != null) c.periodId!: c.manualOffsetMinutes
      };

      final double lat = loc.latitude;
      final double lng = loc.longitude;
      final CalculationMethodType calcMethod =
          settings.calculationMethod.toCalculationMethod();
      final MadhabType madhab = settings.madhab.toMadhab();
      final HighLatitudeRuleType hlRule =
          settings.highLatitudeRule.toHighLatRule();
      final Map<PrayerKey, int> isolatedManualOffsets =
          manualOffsetsMap.toPrayerKeyMap();
      final double fajrAngle = settings.customFajrAngle;
      final double ishaAngle = settings.customIshaAngle;
      final DateTime isolatedCityNow = cityNow;

      final List<Duration> weekCityOffsets = List.generate(
        9,
        (index) => _getUtcOffsetForDate(
          loc,
          isolatedCityNow.add(Duration(days: index - 1)),
        ),
      );

      final List<Map<String, dynamic>> weekAstroData = await Isolate.run(() {
        final List<Map<String, dynamic>> daysData = [];

        for (int index = 0; index < 8; index++) {
          final int dayOffset = index - 1;
          final targetDate = isolatedCityNow.add(Duration(days: dayOffset));
          final dayCityOffset = weekCityOffsets[index];
          final nextDayOffset = weekCityOffsets[index + 1];

          final ibadat = PrayerCalculator.getIbadatTimings(
            lat,
            lng,
            targetDate,
            calcMethod,
            madhab,
            hlRule,
            fajrAngle,
            ishaAngle,
            dayCityOffset,
            nextDayCityOffset: nextDayOffset,
            manualOffsets: isolatedManualOffsets,
          );

          final periods = SuwayaTimeEngine.generateDay(
            lat,
            lng,
            targetDate,
            calcMethod,
            madhab,
            hlRule,
            fajrAngle,
            ishaAngle,
            dayCityOffset,
            nextDayCityOffset: nextDayOffset,
            manualOffsets: isolatedManualOffsets,
          ).periods;

          daysData.add({
            'dayOffset': dayOffset,
            'targetDate': targetDate,
            'ibadat': ibadat,
            'periods': periods,
          });
        }
        return daysData;
      });

      final currentAstroEnd = weekAstroData
          .firstWhere(
            (d) =>
                (d['periods'] as List<AstroPeriod>).last.endTime.isAfter(cityNow),
            orElse: () => weekAstroData.first,
          )['periods'] as List<AstroPeriod>;
      final currentActiveAstroDate = DateTime.utc(
        currentAstroEnd.last.endTime.year,
        currentAstroEnd.last.endTime.month,
        currentAstroEnd.last.endTime.day,
      );
      final currentCivilDate = DateTime.utc(
        cityNow.year,
        cityNow.month,
        cityNow.day,
      );

      final int userSnoozeMins = settings.snoozeDurationMinutes > 0
          ? settings.snoozeDurationMinutes
          : AlarmService.defaultSnoozeMinutes;
      final int userMaxSnoozes = settings.maxSnoozeCount > 0
          ? settings.maxSnoozeCount
          : AlarmService.defaultMaxSnoozes;

      for (int index = 0; index < weekAstroData.length; index++) {
        final dayData = weekAstroData[index];
        final int dayOffset = dayData['dayOffset'] as int;
        final int safeOffsetIndex = dayOffset + 1;
        final targetDate = dayData['targetDate'] as DateTime;
        final ibadat = dayData['ibadat'] as IbadatTimings;
        final periods = dayData['periods'] as List<AstroPeriod>;

        if (periods.isEmpty) continue;

        final cycleEnd = periods.last.endTime;
        final astroCycleLogicalDate = DateTime.utc(
          cycleEnd.year,
          cycleEnd.month,
          cycleEnd.day,
        );
        final int astroWeekday = astroCycleLogicalDate.weekday;

        final civilLogicalDate = DateTime.utc(
          targetDate.year,
          targetDate.month,
          targetDate.day,
        );
        final int civilWeekday = civilLogicalDate.weekday;

        // ====================================================
        // 1. الصلوات المفروضة (الأولوية القصوى في الثانية +0s)
        // ====================================================
        if (dayOffset >= 0) {
          final mandatoryPrayers = [
            {
              'id': 'fajr',
              'nameKey': 'periods.fajr',
              'time': ibadat.fajr,
              'numericId': 1,
            },
            {
              'id': 'dhuhr',
              'nameKey': 'periods.dhuhr',
              'time': ibadat.dhuhr,
              'numericId': 3,
            },
            {
              'id': 'asr',
              'nameKey': 'periods.asr',
              'time': ibadat.asr,
              'numericId': 4,
            },
            {
              'id': 'maghrib',
              'nameKey': 'periods.maghrib',
              'time': ibadat.maghrib,
              'numericId': 5,
            },
            {
              'id': 'isha',
              'nameKey': 'prayers.isha',
              'time': ibadat.isha,
              'numericId': 9,
            },
          ];

          for (var prayer in mandatoryPrayers) {
            final String pId = prayer['id'] as String;
            final DateTime pTime = prayer['time'] as DateTime;
            final String nameKey = prayer['nameKey'] as String;
            final int numericId = prayer['numericId'] as int;

            if (pTime.isAfter(cityNow)) {
              final int alertLevel = settings.getPeriodAlertLevel(pId, 1);

              if (alertLevel > 0) {
                final String soundId =
                    settings.getPeriodSound(pId, 'assets/audio/adhan.mp3');
                final String assetPath = _getAssetAudioPath(soundId);
                final int notificationId =
                    100000 + (safeOffsetIndex * 1000) + numericId;

                final rawDeviceTime = _resolveRealDeviceAlarmTime(
                  targetCityWallTime: pTime,
                  cityNowWallTime: cityNow,
                  loc: loc,
                );

                if (rawDeviceTime
                    .isBefore(DateTime.now().add(const Duration(seconds: 5)))) {
                  continue;
                }

                final realAlarmTime = resolveCollisionSafeTime(
                  rawDeviceTime,
                  occupiedAlarmSeconds,
                );

                final bool isFullScreenAlarm = alertLevel == 2;
                final deliveryMode = isFullScreenAlarm
                    ? AlarmDeliveryMode.fullscreenAlarm
                    : AlarmDeliveryMode.curtainAudio;
                final String prayerTitle =
                    '${'notifications.prayer_of'.tr()} ${nameKey.tr()}';
                final String prayerBody = 'notifications.adhan_time_body'.tr();
                final policy = AlarmPolicyTable.forEvent(
                  kind: AlarmEventKind.prayer,
                  sourceId: pId,
                );

                final payloadStr = ParsedAlarmData(
                  eventId: notificationId,
                  kind: AlarmEventKind.prayer,
                  deliveryMode: deliveryMode,
                  sourceId: pId,
                  title: prayerTitle,
                  body: prayerBody,
                  colorValue: 0xFFD4AF37,
                  snoozeAllowed: false, // الأذان لا يقبل الغفوة افتراضياً
                  snoozeDurationMinutes: userSnoozeMins,
                  snoozeCount: 0,
                  maxSnoozes: 0,
                  loopAudio: false, // الأذان يعمل مرة واحدة كاملاً دون تكرار مزعج
                  volumePolicy: AlarmVolumePolicy.userAdjustable,
                ).toPayloadString();

                requiredAlarmIds.add(notificationId);
                final existing = activeAlarmMap[notificationId];
                bool needsUpdate = true;
                if (existing != null) {
                  final timeDiff = existing.dateTime
                      .difference(realAlarmTime)
                      .inSeconds
                      .abs();
                  if (timeDiff < 5 &&
                      existing.assetAudioPath == assetPath &&
                      existing.androidFullScreenIntent == isFullScreenAlarm &&
                      existing.loopAudio == false &&
                      existing.payload == payloadStr) {
                    needsUpdate = false;
                  }
                }

                if (needsUpdate) {
                  final ok = await Alarm.set(
                    alarmSettings: AlarmSettings(
                      id: notificationId,
                      dateTime: realAlarmTime,
                      assetAudioPath: assetPath,
                      loopAudio: false,
                      vibrate: true,
                      androidFullScreenIntent: isFullScreenAlarm,
                      payload: payloadStr,
                      volumeSettings: VolumeSettings.fade(
                        volume: settings.getPeriodVolume(pId, 1.0),
                        fadeDuration: policy.fadeDuration,
                        volumeEnforced: false,
                      ),
                      notificationSettings: NotificationSettings(
                        title: prayerTitle,
                        body: prayerBody,
                        stopButton: 'alarm.stop'.tr(),
                      ),
                    ),
                  );
                  if (!ok) hadSchedulingFailures = true;
                }
              }
            }
          }

          // ====================================================
          // 2. أجزاء الليل (قيام الليل) بمعرفات ثابتة بدون hashCode
          // ====================================================
          for (var nightPart in ibadat.nightParts) {
            if (settings.visibleNightParts.contains(nightPart.id) &&
                nightPart.startTime.isAfter(cityNow)) {
              final int alertLevel =
                  settings.getPeriodAlertLevel(nightPart.id, 0);
              if (alertLevel > 0) {
                final String soundId = settings.getPeriodSound(
                  nightPart.id,
                  'assets/audio/soft.mp3',
                );
                final String assetPath = _getAssetAudioPath(soundId);
                final int nightIdSafe = stableNightPartCode(nightPart.id);
                final int notificationId =
                    200000 + (safeOffsetIndex * 1000) + nightIdSafe;

                final rawDeviceTime = _resolveRealDeviceAlarmTime(
                  targetCityWallTime: nightPart.startTime,
                  cityNowWallTime: cityNow,
                  loc: loc,
                );

                if (rawDeviceTime
                    .isBefore(DateTime.now().add(const Duration(seconds: 5)))) {
                  continue;
                }

                final String qiyamTitle =
                    '${'notifications.time_for'.tr()} ${('night_parts.${nightPart.nameKey.replaceAll("np_", "")}').tr()}';
                final String qiyamBody = 'notifications.qiyam_body'.tr();

                if (alertLevel == 2) {
                  final realAlarmTime = resolveCollisionSafeTime(
                    rawDeviceTime,
                    occupiedAlarmSeconds,
                  );
                  final policy = AlarmPolicyTable.forEvent(
                    kind: AlarmEventKind.qiyam,
                    sourceId: nightPart.id,
                  );
                  final payloadStr = ParsedAlarmData(
                    eventId: notificationId,
                    kind: AlarmEventKind.qiyam,
                    deliveryMode: AlarmDeliveryMode.fullscreenAlarm,
                    sourceId: nightPart.id,
                    title: qiyamTitle,
                    body: qiyamBody,
                    colorValue: 0xFF8B5CF6,
                    snoozeAllowed: policy.snoozeAllowedDefault,
                    snoozeDurationMinutes: userSnoozeMins,
                    snoozeCount: 0,
                    maxSnoozes: userMaxSnoozes,
                    loopAudio: policy.loopAudioDefault,
                    volumePolicy: policy.volumePolicyDefault,
                  ).toPayloadString();

                  requiredAlarmIds.add(notificationId);
                  final existing = activeAlarmMap[notificationId];
                  bool needsUpdate = true;
                  if (existing != null) {
                    final timeDiff = existing.dateTime
                        .difference(realAlarmTime)
                        .inSeconds
                        .abs();
                    if (timeDiff < 5 &&
                        existing.assetAudioPath == assetPath &&
                        existing.payload == payloadStr) {
                      needsUpdate = false;
                    }
                  }

                  if (needsUpdate) {
                    final ok = await Alarm.set(
                      alarmSettings: AlarmSettings(
                        id: notificationId,
                        dateTime: realAlarmTime,
                        assetAudioPath: assetPath,
                        loopAudio: policy.loopAudioDefault,
                        vibrate: true,
                        androidFullScreenIntent: true,
                        payload: payloadStr,
                        volumeSettings: VolumeSettings.fade(
                          volume: settings.getPeriodVolume(nightPart.id, 0.5),
                          fadeDuration: policy.fadeDuration,
                          volumeEnforced: false,
                        ),
                        notificationSettings: NotificationSettings(
                          title: qiyamTitle,
                          body: qiyamBody,
                          stopButton: 'alarm.stop'.tr(),
                        ),
                      ),
                    );
                    if (!ok) hadSchedulingFailures = true;
                  }
                } else if (alertLevel == 1) {
                  requiredNormalIds.add(notificationId);
                  await _service.scheduleNormalNotification(
                    id: notificationId,
                    title: qiyamTitle,
                    body: 'notifications.qiyam_short'.tr(),
                    scheduledTime: rawDeviceTime,
                    playSound: true,
                    enableVibration: true,
                  );
                }
              }
            }
          }
        }

        // ====================================================
        // 3. قسم الروتين (سويعي ومدني) مع Payload V2 صريح
        // ====================================================
        for (var routine in routines) {
          if (!routine.isActive || routine.alertLevel == 0) continue;

          DateTime? routineAlarmTime;

          if (routine.isAstroTime && routine.startPeriodId != null) {
            if (routine.recurrenceDays != null &&
                routine.recurrenceDays!.isNotEmpty &&
                !routine.recurrenceDays!.contains(astroWeekday)) {
              continue;
            }
            try {
              final p =
                  periods.firstWhere((p) => p.id == routine.startPeriodId);
              routineAlarmTime = resolveAstroRoutineTime(
                period: p,
                localSuwaya: routine.startSuwaya ?? 1,
                virtualMinute: routine.startVirtualMinute ?? 0,
              );
            } catch (_) {}
          } else if (!routine.isAstroTime &&
              routine.startTimeMinutes != null &&
              dayOffset >= 0) {
            if (routine.recurrenceDays != null &&
                routine.recurrenceDays!.isNotEmpty &&
                !routine.recurrenceDays!.contains(civilWeekday)) {
              continue;
            }
            routineAlarmTime = DateTime.utc(
              civilLogicalDate.year,
              civilLogicalDate.month,
              civilLogicalDate.day,
              routine.startTimeMinutes! ~/ 60,
              routine.startTimeMinutes! % 60,
            );
          }

          if (routineAlarmTime != null && routineAlarmTime.isAfter(cityNow)) {
            final int routineNotifId =
                300000 + (safeOffsetIndex * 10000) + (routine.id % 10000);
            final rawDeviceTime = _resolveRealDeviceAlarmTime(
              targetCityWallTime: routineAlarmTime,
              cityNowWallTime: cityNow,
              loc: loc,
            );

            if (rawDeviceTime
                .isBefore(DateTime.now().add(const Duration(seconds: 5)))) {
              continue;
            }

            final String rTitle =
                '${'notifications.period_start'.tr()}: ${routine.title}';
            final String rBody = 'notifications.routine_body'.tr();

            if (routine.alertLevel == 2) {
              final realAlarmTime = resolveCollisionSafeTime(
                rawDeviceTime,
                occupiedAlarmSeconds,
              );
              final String rAsset = _getAssetAudioPath(routine.alarmTone);
              final policy = AlarmPolicyTable.forEvent(
                kind: AlarmEventKind.routine,
                sourceId: routine.id.toString(),
              );
              final payloadStr = ParsedAlarmData(
                eventId: routineNotifId,
                kind: AlarmEventKind.routine,
                deliveryMode: AlarmDeliveryMode.fullscreenAlarm,
                sourceId: routine.id.toString(),
                title: routine.title,
                body: rBody,
                colorValue: routine.colorValue,
                snoozeAllowed: policy.snoozeAllowedDefault,
                snoozeDurationMinutes: userSnoozeMins,
                snoozeCount: 0,
                maxSnoozes: userMaxSnoozes,
                loopAudio: true,
                volumePolicy: AlarmVolumePolicy.userAdjustable,
              ).toPayloadString();

              requiredAlarmIds.add(routineNotifId);
              final existingTask = activeAlarmMap[routineNotifId];
              bool needsTaskUpdate = true;
              if (existingTask != null) {
                if (existingTask.dateTime
                            .difference(realAlarmTime)
                            .inSeconds
                            .abs() <
                        5 &&
                    existingTask.assetAudioPath == rAsset &&
                    existingTask.payload == payloadStr) {
                  needsTaskUpdate = false;
                }
              }

              if (needsTaskUpdate) {
                final ok = await Alarm.set(
                  alarmSettings: AlarmSettings(
                    id: routineNotifId,
                    dateTime: realAlarmTime,
                    assetAudioPath: rAsset,
                    loopAudio: true,
                    vibrate: true,
                    androidFullScreenIntent: true,
                    payload: payloadStr,
                    volumeSettings: VolumeSettings.fade(
                      volume: routine.alarmVolume,
                      fadeDuration: policy.fadeDuration,
                      volumeEnforced: false,
                    ),
                    notificationSettings: NotificationSettings(
                      title: rTitle,
                      body: rBody,
                      stopButton: 'alarm.stop'.tr(),
                    ),
                  ),
                );
                if (!ok) hadSchedulingFailures = true;
              }
            } else if (routine.alertLevel == 1) {
              requiredNormalIds.add(routineNotifId);
              await _service.scheduleNormalNotification(
                id: routineNotifId,
                title: rTitle,
                body: rBody,
                scheduledTime: rawDeviceTime,
                playSound: true,
                enableVibration: true,
              );
            }
          }
        }

        // ====================================================
        // 4.أ. المهام والعادات السُويعية مع Payload V2 صريح
        // ====================================================
        for (var period in periods) {
          int globalSuwayaBase = 0;
          for (var p in periods) {
            if (p.id == period.id) break;
            globalSuwayaBase += p.suwayasCount;
          }

          for (var task in allTasks) {
            if (!task.isAstroTime) continue;
            if (!(task.notifyMode || task.alarmMode || task.vibrateMode)) {
              continue;
            }
            if (task.targetPeriodId != period.id ||
                task.targetSuwayas.isEmpty) {
              continue;
            }

            bool isForThisCycle = false;
            if (task.type == TaskType.casual) {
              if (task.targetDate != null &&
                  task.targetDate!.year == astroCycleLogicalDate.year &&
                  task.targetDate!.month == astroCycleLogicalDate.month &&
                  task.targetDate!.day == astroCycleLogicalDate.day) {
                if (!task.isCompleted) isForThisCycle = true;
              }
            } else if (task.type == TaskType.permanent) {
              if (task.recurrenceDays == null ||
                  task.recurrenceDays!.isEmpty ||
                  task.recurrenceDays!.contains(astroWeekday)) {
                final isCurrentActiveCycle =
                    astroCycleLogicalDate.year == currentActiveAstroDate.year &&
                        astroCycleLogicalDate.month ==
                            currentActiveAstroDate.month &&
                        astroCycleLogicalDate.day == currentActiveAstroDate.day;
                if (!(isCurrentActiveCycle &&
                    task.isCompletedOnDate(astroCycleLogicalDate))) {
                  isForThisCycle = true;
                }
              }
            }

            if (isForThisCycle) {
              final suwayaCount =
                  period.suwayasCount > 0 ? period.suwayasCount : 1;
              final microPerSuwaya = period.endTime
                      .difference(period.startTime)
                      .inMicroseconds ~/
                  suwayaCount;
              final microPerVirtualMin = microPerSuwaya ~/ 60;

              for (var suwayaNum in task.targetSuwayas) {
                int effectiveSuwayaNum =
                    suwayaNum == -1 ? (suwayaCount ~/ 2) + 1 : suwayaNum;
                final taskCityTime = period.startTime.add(
                  Duration(
                    microseconds:
                        (microPerSuwaya * (effectiveSuwayaNum - 1)) +
                            (microPerVirtualMin * task.targetVirtualMinute),
                  ),
                );

                if (taskCityTime.isAfter(cityNow)) {
                  final int taskNotifId = 400000 +
                      (safeOffsetIndex * 10000) +
                      ((task.id % 1000) * 10) +
                      effectiveSuwayaNum;
                  final clockText = formatSuwayaTime(
                    globalSuwayaBase + (effectiveSuwayaNum - 1),
                    task.targetVirtualMinute,
                    separator: '|',
                  );
                  final String timeText =
                      "${'notifications.segment_time'.tr()} : \u2066$clockText\u2069";

                  final rawDeviceTime = _resolveRealDeviceAlarmTime(
                    targetCityWallTime: taskCityTime,
                    cityNowWallTime: cityNow,
                    loc: loc,
                  );

                  if (rawDeviceTime.isBefore(
                      DateTime.now().add(const Duration(seconds: 5)))) {
                    continue;
                  }

                  final taskKind = task.type == TaskType.permanent
                      ? AlarmEventKind.habit
                      : AlarmEventKind.task;
                  final String notifTitle =
                      '${'notifications.time_for_task'.tr()}: ${task.title}';

                  if (task.alarmMode) {
                    final realTaskAlarmTime = resolveCollisionSafeTime(
                      rawDeviceTime,
                      occupiedAlarmSeconds,
                    );
                    final String tAsset = _getAssetAudioPath(task.alarmTone);
                    final policy = AlarmPolicyTable.forEvent(
                      kind: taskKind,
                      sourceId: task.id.toString(),
                    );
                    final payloadStr = ParsedAlarmData(
                      eventId: taskNotifId,
                      kind: taskKind,
                      deliveryMode: AlarmDeliveryMode.fullscreenAlarm,
                      sourceId: task.id.toString(),
                      title: task.title,
                      body: timeText,
                      colorValue: task.category.dialColor.toARGB32(),
                      snoozeAllowed: true,
                      snoozeDurationMinutes: userSnoozeMins,
                      snoozeCount: 0,
                      maxSnoozes: userMaxSnoozes,
                      loopAudio: true,
                      volumePolicy: AlarmVolumePolicy.userAdjustable,
                    ).toPayloadString();

                    requiredAlarmIds.add(taskNotifId);
                    final existingTask = activeAlarmMap[taskNotifId];
                    bool needsTaskUpdate = true;
                    if (existingTask != null) {
                      if (existingTask.dateTime
                                  .difference(realTaskAlarmTime)
                                  .inSeconds
                                  .abs() <
                              5 &&
                          existingTask.assetAudioPath == tAsset &&
                          existingTask.payload == payloadStr) {
                        needsTaskUpdate = false;
                      }
                    }

                    if (needsTaskUpdate) {
                      final ok = await Alarm.set(
                        alarmSettings: AlarmSettings(
                          id: taskNotifId,
                          dateTime: realTaskAlarmTime,
                          assetAudioPath: tAsset,
                          loopAudio: true,
                          vibrate: true,
                          androidFullScreenIntent: true,
                          payload: payloadStr,
                          volumeSettings: VolumeSettings.fade(
                            volume: task.alarmVolume,
                            fadeDuration: policy.fadeDuration,
                            volumeEnforced: false,
                          ),
                          notificationSettings: NotificationSettings(
                            title: notifTitle,
                            body: timeText,
                            stopButton: 'alarm.stop'.tr(),
                          ),
                        ),
                      );
                      if (!ok) hadSchedulingFailures = true;
                    }
                  } else {
                    requiredNormalIds.add(taskNotifId);
                    await _service.scheduleNormalNotification(
                      id: taskNotifId,
                      title: notifTitle,
                      body: timeText,
                      scheduledTime: rawDeviceTime,
                      playSound: task.notifyMode,
                      enableVibration: task.vibrateMode,
                    );
                  }
                }
              }
            }
          }
        }

        // ====================================================
        // 4.ب. المهام والعادات المدنية مع Payload V2 صريح
        // ====================================================
        if (dayOffset >= 0) {
          for (var task in allTasks) {
            if (task.isAstroTime || task.targetCivilTimeMinutes == null) {
              continue;
            }
            if (!(task.notifyMode || task.alarmMode || task.vibrateMode)) {
              continue;
            }

            bool isForThisCivilDay = false;
            if (task.type == TaskType.casual) {
              if (task.targetDate != null &&
                  task.targetDate!.year == civilLogicalDate.year &&
                  task.targetDate!.month == civilLogicalDate.month &&
                  task.targetDate!.day == civilLogicalDate.day) {
                if (!task.isCompleted) isForThisCivilDay = true;
              }
            } else if (task.type == TaskType.permanent) {
              if (task.recurrenceDays == null ||
                  task.recurrenceDays!.isEmpty ||
                  task.recurrenceDays!.contains(civilWeekday)) {
                final isTodayCivil =
                    civilLogicalDate.year == currentCivilDate.year &&
                        civilLogicalDate.month == currentCivilDate.month &&
                        civilLogicalDate.day == currentCivilDate.day;
                if (!(isTodayCivil &&
                    task.isCompletedOnDate(civilLogicalDate))) {
                  isForThisCivilDay = true;
                }
              }
            }

            if (isForThisCivilDay) {
              final taskCityTime = DateTime.utc(
                civilLogicalDate.year,
                civilLogicalDate.month,
                civilLogicalDate.day,
                task.targetCivilTimeMinutes! ~/ 60,
                task.targetCivilTimeMinutes! % 60,
              );

              if (taskCityTime.isAfter(cityNow)) {
                final int taskNotifId =
                    500000 + (safeOffsetIndex * 10000) + (task.id % 10000);
                final civilStr =
                    '${(task.targetCivilTimeMinutes! ~/ 60).toString().padLeft(2, '0')}:${(task.targetCivilTimeMinutes! % 60).toString().padLeft(2, '0')}';

                final rawDeviceTime = _resolveRealDeviceAlarmTime(
                  targetCityWallTime: taskCityTime,
                  cityNowWallTime: cityNow,
                  loc: loc,
                );

                if (rawDeviceTime.isBefore(
                    DateTime.now().add(const Duration(seconds: 5)))) {
                  continue;
                }

                final taskKind = task.type == TaskType.permanent
                    ? AlarmEventKind.habit
                    : AlarmEventKind.task;
                final String notifTitle =
                    '${'notifications.time_for_task'.tr()}: ${task.title}';

                if (task.alarmMode) {
                  final realTaskAlarmTime = resolveCollisionSafeTime(
                    rawDeviceTime,
                    occupiedAlarmSeconds,
                  );
                  final String tAsset = _getAssetAudioPath(task.alarmTone);
                  final policy = AlarmPolicyTable.forEvent(
                    kind: taskKind,
                    sourceId: task.id.toString(),
                  );
                  final payloadStr = ParsedAlarmData(
                    eventId: taskNotifId,
                    kind: taskKind,
                    deliveryMode: AlarmDeliveryMode.fullscreenAlarm,
                    sourceId: task.id.toString(),
                    title: task.title,
                    body: civilStr,
                    colorValue: task.category.dialColor.toARGB32(),
                    snoozeAllowed: true,
                    snoozeDurationMinutes: userSnoozeMins,
                    snoozeCount: 0,
                    maxSnoozes: userMaxSnoozes,
                    loopAudio: true,
                    volumePolicy: AlarmVolumePolicy.userAdjustable,
                  ).toPayloadString();

                  requiredAlarmIds.add(taskNotifId);
                  final existingTask = activeAlarmMap[taskNotifId];
                  bool needsTaskUpdate = true;
                  if (existingTask != null) {
                    if (existingTask.dateTime
                                .difference(realTaskAlarmTime)
                                .inSeconds
                                .abs() <
                            5 &&
                        existingTask.assetAudioPath == tAsset &&
                        existingTask.payload == payloadStr) {
                      needsTaskUpdate = false;
                    }
                  }

                  if (needsTaskUpdate) {
                    final ok = await Alarm.set(
                      alarmSettings: AlarmSettings(
                        id: taskNotifId,
                        dateTime: realTaskAlarmTime,
                        assetAudioPath: tAsset,
                        loopAudio: true,
                        vibrate: true,
                        androidFullScreenIntent: true,
                        payload: payloadStr,
                        volumeSettings: VolumeSettings.fade(
                          volume: task.alarmVolume,
                          fadeDuration: policy.fadeDuration,
                          volumeEnforced: false,
                        ),
                        notificationSettings: NotificationSettings(
                          title: notifTitle,
                          body: civilStr,
                          stopButton: 'alarm.stop'.tr(),
                        ),
                      ),
                    );
                    if (!ok) hadSchedulingFailures = true;
                  }
                } else {
                  requiredNormalIds.add(taskNotifId);
                  await _service.scheduleNormalNotification(
                    id: taskNotifId,
                    title: notifTitle,
                    body: civilStr,
                    scheduledTime: rawDeviceTime,
                    playSound: task.notifyMode,
                    enableVibration: task.vibrateMode,
                  );
                }
              }
            }
          }
        }
      }

      // تنظيف المنبهات القديمة
      for (var alarm in activeAlarms) {
        if (!requiredAlarmIds.contains(alarm.id)) {
          await Alarm.stop(alarm.id);
        }
      }

      // 🌟 دمج الإشعارات المعلقة فعلياً في النظام مع الذاكرة لضمان حذف الإشعارات القديمة حتى بعد إعادة تشغيل التطبيق
      final osPendingNormalIds = await _service.getPendingNormalNotificationIds();
      final knownNormalIds = {
        ..._previouslyScheduledNormalIds,
        ...osPendingNormalIds,
      };
      final toCancelNormal = knownNormalIds.difference(requiredNormalIds);
      for (var id in toCancelNormal) {
        try {
          await _service.cancel(id);
        } catch (_) {}
      }

      _previouslyScheduledNormalIds = requiredNormalIds;

      if (!hadSchedulingFailures) {
        _lastScheduleHash = currentHash;
        _retryCount = 0;
        _retryTimer?.cancel();
      } else if (_retryCount < 3) {
        _retryCount++;
        _retryTimer?.cancel();
        _retryTimer = Timer(Duration(seconds: 5 * _retryCount), () {
          scheduleAhead(settings, allTasks, routines, forceRefresh: true);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('🚨 NotificationScheduler exception: $e\n$stackTrace');
      // 🌟 إعادة المحاولة تلقائياً عند فشل الحساب أو استدعاء خدمات النظام
      if (_retryCount < 3) {
        _retryCount++;
        _retryTimer?.cancel();
        _retryTimer = Timer(Duration(seconds: 5 * _retryCount), () {
          scheduleAhead(settings, allTasks, routines, forceRefresh: true);
        });
      }
    } finally {
      _isScheduling = false;
      // 🌟 تنفيذ أحدث طلب جدولة معلق فور انتهاء العملية الجارية
      if (_hasPendingSchedule &&
          _pendingSettings != null &&
          _pendingTasks != null &&
          _pendingRoutines != null) {
        final nextSettings = _pendingSettings!;
        final nextTasks = _pendingTasks!;
        final nextRoutines = _pendingRoutines!;
        final nextForce = _pendingForceRefresh;

        _hasPendingSchedule = false;
        _pendingSettings = null;
        _pendingTasks = null;
        _pendingRoutines = null;
        _pendingForceRefresh = false;

        Future.microtask(() => scheduleAhead(
              nextSettings,
              nextTasks,
              nextRoutines,
              forceRefresh: nextForce,
            ));
      }
    }
  }
}