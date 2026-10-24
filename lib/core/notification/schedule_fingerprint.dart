import 'package:suwaya_time/suwaya_time.dart';
import '../../models/routine_model.dart';
import '../../models/settings_model.dart';
import '../../models/task_model.dart';
import 'routine_time_resolver.dart';

class ScheduleFingerprint {
  /// معرف رقمي ثابت وحتمي لأجزاء الليل الخمسة عبر النواة
  static int stableNightPartCode(String nightPartId) =>
      SuwayaRecurrenceEngine.stableNightPartCode(nightPartId);

  /// منع تصادم تنبيهين في نفس الثانية الفعلية عبر النواة
  static DateTime resolveCollisionSafeTime(
    DateTime desiredTime,
    Set<int> occupiedEpochSeconds,
  ) =>
      SuwayaRecurrenceEngine.resolveCollisionSafeTime(
        desiredTime,
        occupiedEpochSeconds,
      );

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
