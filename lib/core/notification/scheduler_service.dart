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
import '../utils/time_formatters.dart';
import '../../features/routines/routines_provider.dart';
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

  ref.listen(settingsProvider.select((s) {
    final sb = StringBuffer()
      ..write(
          'loc=${s.activeLocation?.latitude},${s.activeLocation?.longitude},${s.activeLocation?.timezone};')
      ..write(
          'astro=${s.calculationMethod},${s.madhab},${s.highLatitudeRule},${s.customFajrAngle},${s.customIshaAngle},${s.useAstroTimeForIbadat};');
    for (var c in s.periodConfigs) {
      sb.write(
          'p=${c.periodId}:${c.isEnabled}:${c.alertLevel}:${c.soundPath}:${c.volume}:${c.manualOffsetMinutes};');
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

  String _lastScheduleHash = '';
  Set<int> _previouslyScheduledNormalIds = {};

  NotificationScheduler(this._service);

  /// 🌟 حساب الـ UTC Offset لأي يوم مستهدف مع مراعاة التوقيت الصيفي والشتوي (DST)
  Duration _getUtcOffsetForDate(SavedLocation? loc, DateTime targetDate) {
    if (loc != null && loc.timezone != null && loc.timezone!.isNotEmpty) {
      try {
        final location = tz.getLocation(loc.timezone!);
        final targetInTz = tz.TZDateTime(
          location,
          targetDate.year,
          targetDate.month,
          targetDate.day,
          12,
        );
        return targetInTz.timeZoneOffset;
      } catch (_) {}
    }
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      12,
    ).timeZoneOffset;
  }

  /// 🌟 إصلاح حرج: إرجاع وقت المدينة دائماً بصيغة DateTime.utc الموحدة (Wall-Clock UTC)
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

  /// 🌟 تحويل وقت الحدث (Wall-Clock UTC في المدينة) إلى وقت الجهاز الفعلي مع تعويض أي تغير في التوقيت الصيفي/الشتوي
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

    // في حال الاعتماد على توقيت الجهاز المحليに直接
    final targetLocal = DateTime(
      targetCityWallTime.year,
      targetCityWallTime.month,
      targetCityWallTime.day,
      targetCityWallTime.hour,
      targetCityWallTime.minute,
      targetCityWallTime.second,
    );
    return targetLocal;
  }

  String _getAssetAudioPath(String? soundId) {
    if (soundId == null || soundId.isEmpty || soundId == 'default') {
      return 'assets/audio/default.mp3';
    }
    if (soundId.contains('assets/')) return soundId;
    return 'assets/audio/$soundId.mp3';
  }

  Future<void> scheduleAhead(
    SettingsModel settings,
    List<TaskModel> allTasks,
    List<RoutineModel> routines,
  ) async {
    if (_isScheduling) return;

    final loc = settings.activeLocation;
    final cityNow = _getCityNow(loc);
    final todayOffset = _getUtcOffsetForDate(loc, cityNow);

    final sb = StringBuffer()
      ..write(
          'loc=${loc?.latitude},${loc?.longitude},${loc?.timezone},offset=${todayOffset.inMinutes};')
      ..write(
          'astro=${settings.calculationMethod},${settings.madhab},${settings.highLatitudeRule},${settings.customFajrAngle},${settings.customIshaAngle},${settings.useAstroTimeForIbadat};');

    for (final c in settings.periodConfigs) {
      sb.write(
          'p=${c.periodId}:${c.isEnabled}:${c.alertLevel}:${c.soundPath}:${c.volume}:${c.manualOffsetMinutes};');
    }

    for (final t in allTasks) {
      // 🌟 بصمة شاملة لجميع خصائص المهمة لضمان إعادة الجدولة فور تعديل أي حقل
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

    if (currentHash == _lastScheduleHash) return;

    try {
      _isScheduling = true;

      if (loc == null) return;

      final activeAlarms = await Alarm.getAlarms();
      final activeAlarmMap = {for (var a in activeAlarms) a.id: a};

      final Set<int> requiredAlarmIds = {};
      final Set<int> requiredNormalIds = {};

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

      // 🌟 حساب فرق التوقيت لـ 9 أيام (-1 إلى 7) لتوفير إزاحة اليوم الحالي واليوم التالي لكل دورة
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
            (d) => (d['periods'] as List<AstroPeriod>).last.endTime.isAfter(cityNow),
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

      for (int index = 0; index < weekAstroData.length; index++) {
        final dayData = weekAstroData[index];
        final int dayOffset = dayData['dayOffset'] as int;
        final int safeOffsetIndex = dayOffset + 1; // 0..7 لتوليد معرفات إشعارات موجبة وفريدة
        final targetDate = dayData['targetDate'] as DateTime;
        final ibadat = dayData['ibadat'] as IbadatTimings;
        final periods = dayData['periods'] as List<AstroPeriod>;

        if (periods.isEmpty) continue;

        // 🌟 التاريخ المنطقي للدورة السويعية (من مغرب targetDate إلى مغرب اليوم التالي = تاريخ نهاية الدورة)
        final cycleEnd = periods.last.endTime;
        final astroCycleLogicalDate = DateTime.utc(
          cycleEnd.year,
          cycleEnd.month,
          cycleEnd.day,
        );
        final int astroWeekday = astroCycleLogicalDate.weekday;

        // 🌟 التاريخ المنطقي لليوم المدني (من 00:00 منتصف الليل إلى 23:59)
        final civilLogicalDate = DateTime.utc(
          targetDate.year,
          targetDate.month,
          targetDate.day,
        );
        final int civilWeekday = civilLogicalDate.weekday;

        // 1. الصلوات المفروضة وأجزاء الليل (تُجدول من dayOffset >= 0)
        if (dayOffset >= 0) {
          final mandatoryPrayers = [
            {'id': 'fajr', 'nameKey': 'periods.fajr', 'time': ibadat.fajr, 'numericId': 1},
            {'id': 'dhuhr', 'nameKey': 'periods.dhuhr', 'time': ibadat.dhuhr, 'numericId': 3},
            {'id': 'asr', 'nameKey': 'periods.asr', 'time': ibadat.asr, 'numericId': 4},
            {'id': 'maghrib', 'nameKey': 'periods.maghrib', 'time': ibadat.maghrib, 'numericId': 5},
            {'id': 'isha', 'nameKey': 'prayers.isha', 'time': ibadat.isha, 'numericId': 9},
          ];

          for (var prayer in mandatoryPrayers) {
            final String pId = prayer['id'] as String;
            final DateTime pTime = prayer['time'] as DateTime;
            final String nameKey = prayer['nameKey'] as String;
            final int numericId = prayer['numericId'] as int;

            if (pTime.isAfter(cityNow)) {
              // 🌟 الوضع الافتراضي للصلوات الخمس هو 1 (إشعار على الستارة بصوت الأذان)
              final int alertLevel = settings.getPeriodAlertLevel(pId, 1);

              if (alertLevel > 0) {
                final String soundId =
                    settings.getPeriodSound(pId, 'assets/audio/adhan.mp3');
                final String assetPath = _getAssetAudioPath(soundId);
                final int notificationId =
                    100000 + (safeOffsetIndex * 1000) + numericId;

                final realAlarmTime = _resolveRealDeviceAlarmTime(
                  targetCityWallTime: pTime,
                  cityNowWallTime: cityNow,
                  loc: loc,
                );

                if (realAlarmTime
                    .isBefore(DateTime.now().add(const Duration(seconds: 5)))) {
                  continue;
                }

                // المستوى 1 = إشعار على الستارة بصوت الأذان وزر إيقاف (بدون شاشة قفل كاملة)
                // المستوى 2 = منبه شاشة كاملة يوقظ الشاشة
                final bool isFullScreenAlarm = alertLevel == 2;
                final String modePrefix =
                    isFullScreenAlarm ? 'fullscreen' : 'curtain';
                final String prayerTitle =
                    '${'notifications.prayer_of'.tr()} ${nameKey.tr()}';

                requiredAlarmIds.add(notificationId);
                final existing = activeAlarmMap[notificationId];
                bool needsUpdate = true;
                if (existing != null) {
                  final timeDiff = existing.dateTime
                      .difference(realAlarmTime)
                      .inSeconds
                      .abs();
                  if (timeDiff < 60 &&
                      existing.assetAudioPath == assetPath &&
                      existing.androidFullScreenIntent == isFullScreenAlarm) {
                    needsUpdate = false;
                  }
                }

                if (needsUpdate) {
                  await Alarm.set(
                    alarmSettings: AlarmSettings(
                      id: notificationId,
                      dateTime: realAlarmTime,
                      assetAudioPath: assetPath,
                      loopAudio: isFullScreenAlarm,
                      vibrate: true,
                      androidFullScreenIntent: isFullScreenAlarm,
                      payload: '$modePrefix|$prayerTitle|0xFFD4AF37|0',
                      volumeSettings: VolumeSettings.fade(
                        volume: settings.getPeriodVolume(pId, 1.0),
                        fadeDuration: const Duration(seconds: 3),
                        volumeEnforced: isFullScreenAlarm,
                      ),
                      notificationSettings: NotificationSettings(
                        title: prayerTitle,
                        body: 'notifications.adhan_time_body'.tr(),
                        stopButton: 'alarm.stop'.tr(),
                      ),
                    ),
                  );
                }
              }
            }
          }

          // 2. قيام الليل
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
                final int nightIdSafe = nightPart.id.hashCode.abs() % 100;
                final int notificationId =
                    200000 + (safeOffsetIndex * 1000) + nightIdSafe;

                final realAlarmTime = _resolveRealDeviceAlarmTime(
                  targetCityWallTime: nightPart.startTime,
                  cityNowWallTime: cityNow,
                  loc: loc,
                );

                if (realAlarmTime
                    .isBefore(DateTime.now().add(const Duration(seconds: 5)))) {
                  continue;
                }

                final String qiyamTitle =
                    '${'notifications.time_for'.tr()} ${('night_parts.${nightPart.nameKey.replaceAll("np_", "")}').tr()}';

                if (alertLevel == 2) {
                  requiredAlarmIds.add(notificationId);
                  final existing = activeAlarmMap[notificationId];
                  bool needsUpdate = true;
                  if (existing != null) {
                    final timeDiff = existing.dateTime
                        .difference(realAlarmTime)
                        .inSeconds
                        .abs();
                    if (timeDiff < 60 && existing.assetAudioPath == assetPath) {
                      needsUpdate = false;
                    }
                  }

                  if (needsUpdate) {
                    await Alarm.set(
                      alarmSettings: AlarmSettings(
                        id: notificationId,
                        dateTime: realAlarmTime,
                        assetAudioPath: assetPath,
                        loopAudio: true,
                        vibrate: true,
                        androidFullScreenIntent: true,
                        payload: 'fullscreen|$qiyamTitle|0xFF8B5CF6|0',
                        volumeSettings: VolumeSettings.fade(
                          volume: settings.getPeriodVolume(nightPart.id, 0.5),
                          fadeDuration: const Duration(seconds: 3),
                          volumeEnforced: true,
                        ),
                        notificationSettings: NotificationSettings(
                          title: qiyamTitle,
                          body: 'notifications.qiyam_body'.tr(),
                          stopButton: 'alarm.stop'.tr(),
                        ),
                      ),
                    );
                  }
                } else if (alertLevel == 1) {
                  requiredNormalIds.add(notificationId);
                  await _service.scheduleNormalNotification(
                    id: notificationId,
                    title: qiyamTitle,
                    body: 'notifications.qiyam_short'.tr(),
                    scheduledTime: realAlarmTime,
                    playSound: true,
                    enableVibration: true,
                  );
                }
              }
            }
          }
        }

        // 🌟 3. قسم الروتين (فصل المنطق السويعي من المغرب عن المنطق المدني من منتصف الليل)
        for (var routine in routines) {
          if (!routine.isActive || routine.alertLevel == 0) continue;

          DateTime? routineAlarmTime;

          if (routine.isAstroTime && routine.startPeriodId != null) {
            // الروتين السُويعي: يتحقق من astroWeekday (حيث الأحد يبدأ من مغرب السبت)
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
            // الروتين المدني: يتحقق من civilWeekday (حيث الأحد يبدأ من 00:00 منتصف الليل)
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
                300000 + (safeOffsetIndex * 10000) + routine.id;
            final realAlarmTime = _resolveRealDeviceAlarmTime(
              targetCityWallTime: routineAlarmTime,
              cityNowWallTime: cityNow,
              loc: loc,
            );

            if (realAlarmTime
                .isBefore(DateTime.now().add(const Duration(seconds: 5)))) {
              continue;
            }

            if (routine.alertLevel == 2) {
              requiredAlarmIds.add(routineNotifId);
              final String rAsset = _getAssetAudioPath(routine.alarmTone);
              final existingTask = activeAlarmMap[routineNotifId];
              bool needsTaskUpdate = true;
              if (existingTask != null) {
                if (existingTask.dateTime
                            .difference(realAlarmTime)
                            .inSeconds
                            .abs() <
                        60 &&
                    existingTask.assetAudioPath == rAsset) {
                  needsTaskUpdate = false;
                }
              }

              if (needsTaskUpdate) {
                await Alarm.set(
                  alarmSettings: AlarmSettings(
                    id: routineNotifId,
                    dateTime: realAlarmTime,
                    assetAudioPath: rAsset,
                    loopAudio: true,
                    vibrate: true,
                    androidFullScreenIntent: true,
                    volumeSettings: VolumeSettings.fade(
                      volume: routine.alarmVolume,
                      fadeDuration: const Duration(seconds: 2),
                      volumeEnforced: true,
                    ),
                    notificationSettings: NotificationSettings(
                      title:
                          '${'notifications.period_start'.tr()}: ${routine.title}',
                      body: 'notifications.routine_body'.tr(),
                      stopButton: 'alarm.stop'.tr(),
                    ),
                  ),
                );
              }
            } else if (routine.alertLevel == 1) {
              requiredNormalIds.add(routineNotifId);
              await _service.scheduleNormalNotification(
                id: routineNotifId,
                title: '${'notifications.period_start'.tr()}: ${routine.title}',
                body: 'notifications.routine_body'.tr(),
                scheduledTime: realAlarmTime,
                playSound: true,
                enableVibration: true,
              );
            }
          }
        }

        // 🌟 4.أ. المهام والعادات السُويعية (تعتمد على astroCycleLogicalDate و astroWeekday)
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
                  String timeText =
                      "${'notifications.segment_time'.tr()} : \u2066$clockText\u2069";

                  final realTaskAlarmTime = _resolveRealDeviceAlarmTime(
                    targetCityWallTime: taskCityTime,
                    cityNowWallTime: cityNow,
                    loc: loc,
                  );

                  if (realTaskAlarmTime.isBefore(
                      DateTime.now().add(const Duration(seconds: 5)))) {
                    continue;
                  }

                  if (task.alarmMode) {
                    requiredAlarmIds.add(taskNotifId);
                    final String tAsset = _getAssetAudioPath(task.alarmTone);
                    final existingTask = activeAlarmMap[taskNotifId];
                    bool needsTaskUpdate = true;
                    if (existingTask != null) {
                      if (existingTask.dateTime
                                  .difference(realTaskAlarmTime)
                                  .inSeconds
                                  .abs() <
                              60 &&
                          existingTask.assetAudioPath == tAsset) {
                        needsTaskUpdate = false;
                      }
                    }

                    if (needsTaskUpdate) {
                      await Alarm.set(
                        alarmSettings: AlarmSettings(
                          id: taskNotifId,
                          dateTime: realTaskAlarmTime,
                          assetAudioPath: tAsset,
                          loopAudio: true,
                          vibrate: true,
                          androidFullScreenIntent: true,
                          volumeSettings: VolumeSettings.fade(
                            volume: task.alarmVolume,
                            fadeDuration: const Duration(seconds: 2),
                            volumeEnforced: true,
                          ),
                          notificationSettings: NotificationSettings(
                            title:
                                '${'notifications.time_for_task'.tr()}: ${task.title}',
                            body: timeText,
                            stopButton: 'alarm.stop'.tr(),
                          ),
                        ),
                      );
                    }
                  } else {
                    requiredNormalIds.add(taskNotifId);
                    await _service.scheduleNormalNotification(
                      id: taskNotifId,
                      title:
                          '${'notifications.time_for_task'.tr()}: ${task.title}',
                      body: timeText,
                      scheduledTime: realTaskAlarmTime,
                      playSound: task.notifyMode,
                      enableVibration: task.vibrateMode,
                    );
                  }
                }
              }
            }
          }
        }

        // 🌟 4.ب. المهام والعادات المدنية (تعتمد على civilLogicalDate و civilWeekday من 00:00 منتصف الليل)
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
                if (!(isTodayCivil && task.isCompletedOnDate(civilLogicalDate))) {
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
                final int taskNotifId = 500000 +
                    (safeOffsetIndex * 10000) +
                    (task.id % 10000);
                final civilStr =
                    '${(task.targetCivilTimeMinutes! ~/ 60).toString().padLeft(2, '0')}:${(task.targetCivilTimeMinutes! % 60).toString().padLeft(2, '0')}';

                final realTaskAlarmTime = _resolveRealDeviceAlarmTime(
                  targetCityWallTime: taskCityTime,
                  cityNowWallTime: cityNow,
                  loc: loc,
                );

                if (realTaskAlarmTime.isBefore(
                    DateTime.now().add(const Duration(seconds: 5)))) {
                  continue;
                }

                if (task.alarmMode) {
                  requiredAlarmIds.add(taskNotifId);
                  final String tAsset = _getAssetAudioPath(task.alarmTone);
                  final existingTask = activeAlarmMap[taskNotifId];
                  bool needsTaskUpdate = true;
                  if (existingTask != null) {
                    if (existingTask.dateTime
                                .difference(realTaskAlarmTime)
                                .inSeconds
                                .abs() <
                            60 &&
                        existingTask.assetAudioPath == tAsset) {
                      needsTaskUpdate = false;
                    }
                  }

                  if (needsTaskUpdate) {
                    await Alarm.set(
                      alarmSettings: AlarmSettings(
                        id: taskNotifId,
                        dateTime: realTaskAlarmTime,
                        assetAudioPath: tAsset,
                        loopAudio: true,
                        vibrate: true,
                        androidFullScreenIntent: true,
                        volumeSettings: VolumeSettings.fade(
                          volume: task.alarmVolume,
                          fadeDuration: const Duration(seconds: 2),
                          volumeEnforced: true,
                        ),
                        notificationSettings: NotificationSettings(
                          title:
                              '${'notifications.time_for_task'.tr()}: ${task.title}',
                          body: civilStr,
                          stopButton: 'alarm.stop'.tr(),
                        ),
                      ),
                    );
                  }
                } else {
                  requiredNormalIds.add(taskNotifId);
                  await _service.scheduleNormalNotification(
                    id: taskNotifId,
                    title:
                        '${'notifications.time_for_task'.tr()}: ${task.title}',
                    body: civilStr,
                    scheduledTime: realTaskAlarmTime,
                    playSound: task.notifyMode,
                    enableVibration: task.vibrateMode,
                  );
                }
              }
            }
          }
        }
      }

      for (var alarm in activeAlarms) {
        if (!requiredAlarmIds.contains(alarm.id)) {
          await Alarm.stop(alarm.id);
        }
      }

      final toCancelNormal =
          _previouslyScheduledNormalIds.difference(requiredNormalIds);
      for (var id in toCancelNormal) {
        try {
          await _service.cancel(id);
        } catch (_) {}
      }

      _previouslyScheduledNormalIds = requiredNormalIds;
      _lastScheduleHash = currentHash;
    } catch (e) {
      debugPrint(
          '🚨 خطأ استثنائي أثناء الجدولة. تم إلغاء تحديث الهاش لإعادة المحاولة لاحقاً: $e');
    } finally {
      _isScheduling = false;
    }
  }
}