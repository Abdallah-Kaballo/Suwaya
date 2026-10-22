import '../../models/routine_model.dart';
import '../../models/settings_model.dart';
import '../../models/task_model.dart';
import 'routine_time_resolver.dart';

class ScheduleFingerprint {
  /// معرف رقمي ثابت وحتمي لأجزاء الليل الخمسة (بدلاً من String.hashCode غير المستقر)
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

  /// منع تصادم تنبيهين في نفس الثانية الفعلية:
  /// الأولوية المطلقة للأذان في الثانية +0s، وتُزاح التنبيهات المتزامنة معه بمقدار +2s تتابعياً
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

  /// بناء بصمة التغييرات الشاملة للموقع والإعدادات والمهام والروتينات
  static String compute({
    required DateTime cityNow,
    required Duration todayOffset,
    required SettingsModel settings,
    required List<TaskModel> allTasks,
    required List<RoutineModel> routines,
  }) {
    final loc = settings.activeLocation;
    final sb = StringBuffer()
      ..write('date=${cityNow.year}-${cityNow.month}-${cityNow.day};')
      ..write(
        'loc=${loc?.latitude},${loc?.longitude},${loc?.timezone},offset=${todayOffset.inMinutes};',
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
    return sb.toString();
  }
}