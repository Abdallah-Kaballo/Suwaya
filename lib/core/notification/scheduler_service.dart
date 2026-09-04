import 'dart:async';
import 'dart:isolate'; // 🌟 1. استيراد مكتبة العزل (Isolates) للأداء الخارق
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:alarm/alarm.dart'; 
import 'package:timezone/timezone.dart' as tz;

import '../../models/routine_model.dart';
import '../../models/task_model.dart';
import '../../models/settings_model.dart';
import '../../features/tasks/tasks_provider.dart';
import '../../features/settings/settings_provider.dart';
import '../../features/routines/routines_provider.dart';
import '../astro_engine/astro_engine.dart';
import '../astro_engine/astro_models.dart'; 
import 'notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());

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
    String fingerprint = '${s.activeLocation?.latitude}_${s.activeLocation?.longitude}_'
        '${s.calculationMethod}_${s.madhab}_${s.highLatitudeRule}_'
        '${s.customFajrAngle}_${s.customIshaAngle}';
    for (var c in s.periodConfigs) {
      fingerprint += '_${c.periodId}:${c.isEnabled}:${c.alertLevel}:${c.soundPath}:${c.volume}:${c.manualOffsetMinutes}';
    }
    return fingerprint;
  }), (prev, nextFingerprint) {
    triggerSchedule();
  });

  return scheduler;
});

class NotificationScheduler {
  final NotificationService _service;
  bool _isScheduling = false; 

  NotificationScheduler(this._service);

  Duration _getUtcOffsetForLocation(SavedLocation? loc) {
    if (loc == null || loc.isAutoLocation == true || loc.timezone == null) return DateTime.now().timeZoneOffset;
    try {
      final location = tz.getLocation(loc.timezone!);
      final nowInTarget = tz.TZDateTime.now(location);
      return nowInTarget.timeZoneOffset;
    } catch (e) {
      return DateTime.now().timeZoneOffset;
    }
  }

  DateTime _getCityNow(SavedLocation? loc) {
    if (loc == null || loc.isAutoLocation == true || loc.timezone == null) return DateTime.now();
    try {
      final location = tz.getLocation(loc.timezone!);
      final nowInTarget = tz.TZDateTime.now(location);
      return DateTime.utc(nowInTarget.year, nowInTarget.month, nowInTarget.day, nowInTarget.hour, nowInTarget.minute, nowInTarget.second);
    } catch (e) {
      return DateTime.now();
    }
  }

  String _getAssetAudioPath(String? soundId) {
    if (soundId == null || soundId.isEmpty || soundId == 'default') return 'assets/audio/default.mp3';
    if (soundId.contains('assets/')) return soundId; 
    return 'assets/audio/$soundId.mp3';
  }

  Future<void> scheduleAhead(SettingsModel settings, List<TaskModel> allTasks, List<RoutineModel> routines) async {
    if (_isScheduling) return;
    _isScheduling = true;

    try {
      final loc = settings.activeLocation;
      if (loc == null) return; 

      final activeAlarms = await Alarm.getAlarms();
      final activeAlarmMap = {for (var a in activeAlarms) a.id: a};
      final Set<int> requiredAlarmIds = {}; 

      final cityOffset = _getUtcOffsetForLocation(loc);
      final cityNow = _getCityNow(loc);

      final manualOffsetsMap = {
        for (var c in settings.periodConfigs)
          if (c.periodId != null) c.periodId!: c.manualOffsetMinutes
      };

      // ==============================================================
      // 🌟 2. استخراج المتغيرات الأساسية لتمريرها بسلام إلى الـ Isolate
      // ==============================================================
      final double lat = loc.latitude;
      final double lng = loc.longitude;
      final String calcMethod = settings.calculationMethod;
      final String madhab = settings.madhab;
      final String hlRule = settings.highLatitudeRule;
      final double fajrAngle = settings.customFajrAngle;
      final double ishaAngle = settings.customIshaAngle;
      final Map<String, int> isolatedManualOffsets = Map<String, int>.from(manualOffsetsMap);
      final Duration isolatedCityOffset = cityOffset;
      final DateTime isolatedCityNow = cityNow;

      // ==============================================================
      // 🌟 3. السحر الحقيقي (Isolate.run): تشغيل العمليات الفلكية الثقيلة 
      // لـ 7 أيام في الخلفية لمنع تجمّد الواجهة الرسومية (Zero Jank)
      // ==============================================================
      final List<Map<String, dynamic>> weekAstroData = await Isolate.run(() {
        final distribution = AstroEngine.calculateAnnualSuwayaDistribution(
          lat, lng, calcMethod, madhab, hlRule, fajrAngle, ishaAngle, 
          isolatedCityOffset, manualOffsets: isolatedManualOffsets,
        );

        final List<Map<String, dynamic>> daysData = [];
        
        for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
          final targetDate = isolatedCityNow.add(Duration(days: dayOffset));
          
          final ibadat = AstroEngine.getIbadatTimings(
            lat, lng, targetDate, calcMethod, madhab, hlRule, 
            fajrAngle, ishaAngle, isolatedCityOffset, manualOffsets: isolatedManualOffsets,
          );
          
          final periods = AstroEngine.generatePeriodsForDay(
            lat, lng, targetDate, calcMethod, madhab, hlRule, 
            fajrAngle, ishaAngle, distribution, isolatedCityOffset, manualOffsets: isolatedManualOffsets,
          );
          
          daysData.add({
            'targetDate': targetDate,
            'ibadat': ibadat,
            'periods': periods,
          });
        }
        return daysData;
      });

      // ==============================================================
      // 🌟 4. العودة للمسار الرئيسي وتوزيع الإشعارات بناءً على البيانات الجاهزة
      // ==============================================================
      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final dayData = weekAstroData[dayOffset];
        final targetDate = dayData['targetDate'] as DateTime;
        final ibadat = dayData['ibadat'] as IbadatTimings;
        final periods = dayData['periods'] as List<AstroPeriod>;

        // 🟢 1. جدولة الصلوات الخمس المفروضة
        final mandatoryPrayers = [
          {'id': '1', 'nameKey': 'period_fajr', 'time': ibadat.fajr, 'numericId': 1},
          {'id': '3', 'nameKey': 'period_dhuhr', 'time': ibadat.dhuhr, 'numericId': 3},
          {'id': '4', 'nameKey': 'period_asr', 'time': ibadat.asr, 'numericId': 4},
          {'id': '5', 'nameKey': 'period_maghrib', 'time': ibadat.maghrib, 'numericId': 5},
          {'id': 'isha', 'nameKey': 'isha', 'time': ibadat.isha, 'numericId': 9},
        ];

        for (var prayer in mandatoryPrayers) {
          final String pId = prayer['id'] as String;
          final DateTime pTime = prayer['time'] as DateTime;
          final String nameKey = prayer['nameKey'] as String;
          final int numericId = prayer['numericId'] as int;

          if (pTime.isAfter(cityNow)) {
            final int alertLevel = settings.getPeriodAlertLevel(pId, 0);

            if (alertLevel > 0) {
              final String soundId = settings.getPeriodSound(pId, 'assets/audio/adhan.mp3');
              final String assetPath = _getAssetAudioPath(soundId);
              final int notificationId = (dayOffset * 100) + numericId;

              final durationUntilAlarm = pTime.difference(cityNow);
              final realAlarmTime = DateTime.now().add(durationUntilAlarm);

              if (realAlarmTime.isBefore(DateTime.now().add(const Duration(seconds: 5)))) continue;

              if (alertLevel == 2) {
                requiredAlarmIds.add(notificationId);

                final existing = activeAlarmMap[notificationId];
                bool needsUpdate = true;
                if (existing != null) {
                  final timeDiff = existing.dateTime.difference(realAlarmTime).inSeconds.abs();
                  if (timeDiff < 60 && existing.assetAudioPath == assetPath) {
                    needsUpdate = false; 
                  }
                }

                if (needsUpdate) {
                  await Alarm.set(alarmSettings: AlarmSettings(
                    id: notificationId,
                    dateTime: realAlarmTime, 
                    assetAudioPath: assetPath,
                    loopAudio: true,
                    vibrate: true,
                    volumeSettings: VolumeSettings.fade(
                      volume: 1.0, fadeDuration: const Duration(seconds: 3), volumeEnforced: true,
                    ),
                    notificationSettings: NotificationSettings(
                      title: 'صلاة ${nameKey.tr()}',
                      body: 'حان الآن موعد الأذان، استعد للصلاة.',
                      stopButton: 'إيقاف التنبيه',
                    ),
                  ));
                }
              } else if (alertLevel == 1) {
                await _service.scheduleNormalNotification(
                  id: notificationId,
                  title: 'صلاة ${nameKey.tr()}',
                  body: 'حان الآن موعد الأذان.',
                  scheduledTime: realAlarmTime, 
                  playSound: true,
                  enableVibration: true,
                );
              }
            }
          }
        }

        // 🟢 2. جدولة أجزاء الليل (قيام الليل)
        for (var nightPart in ibadat.nightParts) {
          if (settings.visibleNightParts.contains(nightPart.id) && nightPart.startTime.isAfter(cityNow)) {
            final int alertLevel = settings.getPeriodAlertLevel(nightPart.id, 0);
            if (alertLevel > 0) {
              final String soundId = settings.getPeriodSound(nightPart.id, 'assets/audio/soft.mp3');
              final String assetPath = _getAssetAudioPath(soundId);
              final int nightIdSafe = nightPart.id.hashCode.abs() % 100;
              final int notificationId = 1000 + (dayOffset * 100) + nightIdSafe;

              final durationUntilAlarm = nightPart.startTime.difference(cityNow);
              final realAlarmTime = DateTime.now().add(durationUntilAlarm);

              if (realAlarmTime.isBefore(DateTime.now().add(const Duration(seconds: 5)))) continue;

              if (alertLevel == 2) {
                requiredAlarmIds.add(notificationId);

                final existing = activeAlarmMap[notificationId];
                bool needsUpdate = true;
                if (existing != null) {
                  final timeDiff = existing.dateTime.difference(realAlarmTime).inSeconds.abs();
                  if (timeDiff < 60 && existing.assetAudioPath == assetPath) {
                    needsUpdate = false; 
                  }
                }

                if (needsUpdate) {
                  await Alarm.set(alarmSettings: AlarmSettings(
                    id: notificationId,
                    dateTime: realAlarmTime, 
                    assetAudioPath: assetPath,
                    loopAudio: true,
                    vibrate: true,
                    volumeSettings: VolumeSettings.fade(
                      volume: 1.0, fadeDuration: const Duration(seconds: 3), volumeEnforced: true,
                    ),
                    notificationSettings: NotificationSettings(
                      title: 'وقت ${nightPart.nameKey.tr()}',
                      body: 'وقت التنزل الإلهي، قم وناجِ ربك.',
                      stopButton: 'إيقاف التنبيه',
                    ),
                  ));
                }
              } else if (alertLevel == 1) {
                await _service.scheduleNormalNotification(
                  id: notificationId,
                  title: 'وقت ${nightPart.nameKey.tr()}',
                  body: 'وقت التنزل الإلهي قد بدأ.',
                  scheduledTime: realAlarmTime, 
                  playSound: true,
                  enableVibration: true,
                );
              }
            }
          }
        }

        // 🟢 3. جدولة الفترات الروتينية (Routines) 
        for (var routine in routines) {
          if (!routine.isActive || routine.alertLevel == 0) continue;
          if (routine.recurrenceDays != null && routine.recurrenceDays!.isNotEmpty && !routine.recurrenceDays!.contains(targetDate.weekday)) continue;

          DateTime? routineAlarmTime;

          if (!routine.isAstroTime && routine.startTimeMinutes != null) {
              routineAlarmTime = DateTime(targetDate.year, targetDate.month, targetDate.day, routine.startTimeMinutes! ~/ 60, routine.startTimeMinutes! % 60);
              if (routineAlarmTime.isBefore(cityNow)) routineAlarmTime = routineAlarmTime.add(const Duration(days: 1));
          } else if (routine.isAstroTime && routine.startPeriodId != null) {
              try {
                  final p = periods.firstWhere((p) => p.id == routine.startPeriodId);
                  final suwayaCount = p.suwayasCount > 0 ? p.suwayasCount : 1;
                  final microPerSuwaya = p.endTime.difference(p.startTime).inMicroseconds ~/ suwayaCount;
                  final microPerVirtualMin = microPerSuwaya ~/ 30;

                  int sIndex = (routine.startSuwaya ?? 1) - 1;
                  if (sIndex < 0) sIndex = 0;
                  int vMin = routine.startVirtualMinute ?? 0;

                  routineAlarmTime = p.startTime.add(Duration(microseconds: (microPerSuwaya * sIndex) + (microPerVirtualMin * vMin)));
              } catch (_) {}
          }

          if (routineAlarmTime != null && routineAlarmTime.isAfter(cityNow)) {
              final int routineNotifId = 20000 + (dayOffset * 10000) + routine.id;
              final durationUntilAlarm = routineAlarmTime.difference(cityNow);
              final realAlarmTime = DateTime.now().add(durationUntilAlarm);

              if (realAlarmTime.isBefore(DateTime.now().add(const Duration(seconds: 5)))) continue;

              if (routine.alertLevel == 2) {
                  requiredAlarmIds.add(routineNotifId);
                  final String rAsset = _getAssetAudioPath(routine.alarmTone);

                  final existingTask = activeAlarmMap[routineNotifId];
                  bool needsTaskUpdate = true;
                  if (existingTask != null) {
                    final timeDiff = existingTask.dateTime.difference(realAlarmTime).inSeconds.abs();
                    if (timeDiff < 60 && existingTask.assetAudioPath == rAsset) {
                      needsTaskUpdate = false; 
                    }
                  }

                  if (needsTaskUpdate) {
                    await Alarm.set(alarmSettings: AlarmSettings(
                      id: routineNotifId,
                      dateTime: realAlarmTime, 
                      assetAudioPath: rAsset,
                      loopAudio: true, vibrate: true,
                      volumeSettings: VolumeSettings.fade(volume: routine.alarmVolume, fadeDuration: const Duration(seconds: 2), volumeEnforced: true),
                      notificationSettings: NotificationSettings(
                        title: 'بداية فترة: ${routine.title}', body: 'حان وقت بدء الفترة المحددة.', stopButton: 'إيقاف التنبيه',
                      ),
                    ));
                  }
              } else if (routine.alertLevel == 1) {
                  await _service.scheduleNormalNotification(
                    id: routineNotifId, 
                    title: 'بداية فترة: ${routine.title}',
                    body: 'حان وقت بدء الفترة المحددة.',
                    scheduledTime: realAlarmTime, 
                    playSound: true, enableVibration: true,
                  );
              }
          }
        }

        // 🟢 4. معالجة المهام (Tasks)
        for (var period in periods) {
          int globalSuwayaBase = 0;
          for (var p in periods) {
            if (p.id == period.id) break;
            globalSuwayaBase += p.suwayasCount;
          }

          for (var task in allTasks) {
            if (!(task.notifyMode || task.alarmMode || task.vibrateMode)) continue;
            if (task.targetPeriodId != period.id || task.targetSuwayas.isEmpty) continue;

            bool isForThisDay = false;
            if (task.type == TaskType.casual) {
              if (task.targetDate != null && 
                  task.targetDate!.year == targetDate.year && 
                  task.targetDate!.month == targetDate.month && 
                  task.targetDate!.day == targetDate.day) {
                if (!task.isCompleted) isForThisDay = true;
              }
            } else if (task.type == TaskType.permanent) {
              if (task.recurrenceDays == null || task.recurrenceDays!.isEmpty || task.recurrenceDays!.contains(targetDate.weekday)) {
                if (!(dayOffset == 0 && task.isCompletedToday)) isForThisDay = true;
              }
            }

            if (isForThisDay) {
              final suwayaCount = period.suwayasCount > 0 ? period.suwayasCount : 1;
              final microPerSuwaya = period.endTime.difference(period.startTime).inMicroseconds ~/ suwayaCount;
              final microPerVirtualMin = microPerSuwaya ~/ 30;
              
              for (var suwayaNum in task.targetSuwayas) {
                // 🌟 معالجة المهام العائمة (-1) بتعيينها تلقائياً في منتصف الفترة في المجدول
                int effectiveSuwayaNum = suwayaNum;
                if (effectiveSuwayaNum == -1) {
                    effectiveSuwayaNum = (suwayaCount ~/ 2) + 1;
                }

                final sIndex = effectiveSuwayaNum - 1;
                final vMin = task.targetVirtualMinute; 
                
                final taskCityTime = period.startTime.add(Duration(
                  microseconds: (microPerSuwaya * sIndex) + (microPerVirtualMin * vMin)
                ));
                
                if (taskCityTime.isAfter(cityNow)) {
                  final int taskIdSafe = task.id % 1000;
                  final int taskNotifId = 10000 + (dayOffset * 10000) + (taskIdSafe * 10) + effectiveSuwayaNum;
                  int currentGlobalSuwaya = globalSuwayaBase + sIndex;
                  String timeText = 'الزمن المقطعي : ${currentGlobalSuwaya.toString().padLeft(2, '0')}:${vMin.toString().padLeft(2, '0')}';
                  
                  final taskDurationUntilAlarm = taskCityTime.difference(cityNow);
                  final realTaskAlarmTime = DateTime.now().add(taskDurationUntilAlarm);
                  
                  if (realTaskAlarmTime.isBefore(DateTime.now().add(const Duration(seconds: 5)))) continue;
                  
                  if (task.alarmMode) {
                    requiredAlarmIds.add(taskNotifId);
                    final String tAsset = _getAssetAudioPath(task.alarmTone);

                    final existingTask = activeAlarmMap[taskNotifId];
                    bool needsTaskUpdate = true;
                    if (existingTask != null) {
                      final timeDiff = existingTask.dateTime.difference(realTaskAlarmTime).inSeconds.abs();
                      if (timeDiff < 60 && existingTask.assetAudioPath == tAsset) {
                        needsTaskUpdate = false; 
                      }
                    }

                    if (needsTaskUpdate) {
                      await Alarm.set(alarmSettings: AlarmSettings(
                        id: taskNotifId,
                        dateTime: realTaskAlarmTime, 
                        assetAudioPath: tAsset,
                        loopAudio: true, vibrate: true,
                        volumeSettings: VolumeSettings.fade(volume: task.alarmVolume, fadeDuration: const Duration(seconds: 2), volumeEnforced: true),
                        notificationSettings: NotificationSettings(
                          title: 'حان وقت: ${task.title}', body: timeText, stopButton: 'إيقاف التنبيه',
                        ),
                      ));
                    }
                  } else {
                    await _service.scheduleNormalNotification(
                      id: taskNotifId, 
                      title: 'حان وقت: ${task.title}',
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
      }

      // 🟢 5. التنظيف الذكي
      for (var alarm in activeAlarms) {
         if (!requiredAlarmIds.contains(alarm.id) && alarm.id < 100000) {
            await Alarm.stop(alarm.id);
         }
      }
    } finally {
      _isScheduling = false;
    }
  }
}