import 'dart:async';
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
import 'schedule_fingerprint.dart';
import 'schedule_plan_builder.dart';

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

  static int stableNightPartCode(String nightPartId) =>
      ScheduleFingerprint.stableNightPartCode(nightPartId);

  static DateTime resolveCollisionSafeTime(
    DateTime desiredTime,
    Set<int> occupiedEpochSeconds,
  ) =>
      ScheduleFingerprint.resolveCollisionSafeTime(
        desiredTime,
        occupiedEpochSeconds,
      );

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

    final currentHash = ScheduleFingerprint.compute(
      cityNow: cityNow,
      todayOffset: todayOffset,
      settings: settings,
      allTasks: allTasks,
      routines: routines,
    );

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

      final List<Duration> weekCityOffsets = List.generate(
        9,
        (index) => _getUtcOffsetForDate(
          loc,
          cityNow.add(Duration(days: index - 1)),
        ),
      );

      final List<ScheduledDayAstroWindow> weekAstroWindows =
          await SchedulePlanBuilder.computeWeekAstroWindows(
        latitude: loc.latitude,
        longitude: loc.longitude,
        timezoneId: loc.timezone,
        isolatedCityNow: cityNow,
        fallbackDayOffsets: weekCityOffsets,
        calcMethod: settings.calculationMethod.toCalculationMethod(),
        madhab: settings.madhab.toMadhab(),
        hlRule: settings.highLatitudeRule.toHighLatRule(),
        fajrAngle: settings.customFajrAngle,
        ishaAngle: settings.customIshaAngle,
        manualOffsets: manualOffsetsMap.toPrayerKeyMap(),
      );

      final currentAstroEnd = weekAstroWindows
          .firstWhere(
            (d) => d.periods.last.endTime.isAfter(cityNow),
            orElse: () => weekAstroWindows.first,
          )
          .periods;
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

      for (int index = 0; index < weekAstroWindows.length; index++) {
        final dayWindow = weekAstroWindows[index];
        final int dayOffset = dayWindow.dayOffset;
        final int safeOffsetIndex = dayOffset + 1;
        final targetDate = dayWindow.targetDate;
        final ibadat = dayWindow.ibadat;
        final periods = dayWindow.periods;

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
                  loopAudio:
                      false, // الأذان يعمل مرة واحدة كاملاً دون تكرار مزعج
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
                  final ok = await _service.scheduleNormalNotification(
                    id: notificationId,
                    title: qiyamTitle,
                    body: 'notifications.qiyam_short'.tr(),
                    scheduledTime: rawDeviceTime,
                    playSound: true,
                    enableVibration: true,
                  );
                  if (!ok) hadSchedulingFailures = true;
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
                toWallClock: (utc) => TimezoneResolver.toWallClock(
                  utc,
                  timezoneId: loc.timezone,
                  fallbackOffset: weekCityOffsets[index],
                ),
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
              final ok = await _service.scheduleNormalNotification(
                id: routineNotifId,
                title: rTitle,
                body: rBody,
                scheduledTime: rawDeviceTime,
                playSound: true,
                enableVibration: true,
              );
              if (!ok) hadSchedulingFailures = true;
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

              for (var suwayaNum in task.targetSuwayas) {
                final int effectiveSuwayaNum =
                    suwayaNum == -1 ? (suwayaCount ~/ 2) + 1 : suwayaNum;
                final DateTime taskCityTime = period.resolveSlotWallTime(
                  effectiveSuwayaNum,
                  task.targetVirtualMinute,
                  toWallClock: (utc) => TimezoneResolver.toWallClock(
                    utc,
                    timezoneId: loc.timezone,
                    fallbackOffset: weekCityOffsets[index],
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
                    final ok = await _service.scheduleNormalNotification(
                      id: taskNotifId,
                      title: notifTitle,
                      body: timeText, // (أو civilStr في القسم 4.ب)
                      scheduledTime: rawDeviceTime,
                      playSound: task.notifyMode,
                      enableVibration: task.vibrateMode,
                    );
                    if (!ok) hadSchedulingFailures = true;
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

                if (rawDeviceTime
                    .isBefore(DateTime.now().add(const Duration(seconds: 5)))) {
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
      final osPendingNormalIds =
          await _service.getPendingNormalNotificationIds();
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
