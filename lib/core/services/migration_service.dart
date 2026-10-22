import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suwaya/models/settings_model.dart';
import '../repositories/task_repository.dart';
import '../repositories/routine_repository.dart';
import '../../models/task_model.dart';
import '../../models/routine_model.dart';
import '../repositories/settings_repository.dart';

final migrationServiceProvider = Provider<MigrationService>((ref) {
  return MigrationService(ref);
});

/// 🌟 تعريف فترات النظام القديم (V1 - يبدأ من الفجر) لمنع الأرقام السحرية
enum V1LegacyPeriod {
  fajr(1),
  duha(2),
  dhuhr(3),
  asr(4),
  maghrib(5),
  isha(6),
  qiyam(7);

  final int id;
  const V1LegacyPeriod(this.id);

  static V1LegacyPeriod? fromId(int id) {
    for (final p in V1LegacyPeriod.values) {
      if (p.id == id) return p;
    }
    return null;
  }
}

enum V2AstroPeriod {
  maghrib(1, 1),
  isha(2, 4),
  qiyam(3, 6),
  fajr(4, 1),
  duha(5, 6),
  dhuhr(6, 3),
  asr(7, 3);

  final int id;
  final int defaultMaxSuwayas;
  const V2AstroPeriod(this.id, this.defaultMaxSuwayas);

  // 🌟 حساب الحد الأقصى للسويعات بناءً على المذهب الفقهي المختار
  int maxSuwayasForMadhab({required bool isHanafi}) {
    if (this == V2AstroPeriod.dhuhr) return isHanafi ? 4 : 3;
    if (this == V2AstroPeriod.asr) return isHanafi ? 2 : 3;
    return defaultMaxSuwayas;
  }

  static V2AstroPeriod fromId(int id) {
    for (final p in V2AstroPeriod.values) {
      if (p.id == id) return p;
    }
    return V2AstroPeriod.maghrib;
  }
}

class MigrationService {
  final Ref _ref;

  MigrationService(this._ref);

  Future<void> runMigrationsIfNeeded() async {
    final taskRepo = _ref.read(taskRepositoryProvider);
    final routineRepo = _ref.read(routineRepositoryProvider);
    final settingsRepo = _ref.read(settingsRepositoryProvider);

    final settings = await settingsRepo.getSettings();
    final bool isHanafi = settings.madhab.toLowerCase() == 'hanafi';

    // 🌟 توحيد معرفات الصلوات في periodConfigs إلى المعرفات النصية الصريحة ومنع التكرار
    if (_normalizeSettingsPeriodConfigs(settings)) {
      await settingsRepo.saveSettings(settings);
    }

    final allTasks = await taskRepo.getAllTasks();
    final allRoutines = await routineRepo.getAllRoutines();

    bool needsRestart = false;

    for (var task in allTasks) {
      if (task.scheduleModelVersion < 2) {
        debugPrint('Migration: Upgrading Task ID ${task.id} to V2');
        _migrateTaskToV2(task, isHanafi: isHanafi);
        await taskRepo.saveTask(task);
        needsRestart = true;
      }
    }

    for (var routine in allRoutines) {
      if (routine.scheduleModelVersion < 2) {
        debugPrint('Migration: Upgrading Routine ID ${routine.id} to V2');
        _migrateRoutineToV2(routine, isHanafi: isHanafi);
        await routineRepo.saveRoutine(routine);
        needsRestart = true;
      }
    }

    if (needsRestart) {
      debugPrint('Migration Completed Successfully.');
    }
  }

  bool _normalizeSettingsPeriodConfigs(SettingsModel settings) {
    bool changed = false;
    final Map<String, PeriodConfig> deduplicated = {};

    for (final config in settings.periodConfigs) {
      final rawId = config.periodId;
      if (rawId == null || rawId.isEmpty) continue;
      final normalizedId = SettingsModel.normalizePeriodId(rawId);
      if (normalizedId != rawId) {
        config.periodId = normalizedId;
        changed = true;
      }
      if (deduplicated.containsKey(normalizedId)) {
        changed = true;
      }
      deduplicated[normalizedId] = config;
    }

    if (changed) {
      settings.periodConfigs = deduplicated.values.toList();
    }
    return changed;
  }

  V2AstroPeriod _mapV1PeriodToV2(int v1PeriodId) {
    return switch (V1LegacyPeriod.fromId(v1PeriodId)) {
      V1LegacyPeriod.fajr => V2AstroPeriod.fajr,
      V1LegacyPeriod.duha => V2AstroPeriod.duha,
      V1LegacyPeriod.dhuhr => V2AstroPeriod.dhuhr,
      V1LegacyPeriod.asr => V2AstroPeriod.asr,
      V1LegacyPeriod.maghrib => V2AstroPeriod.maghrib,
      V1LegacyPeriod.isha => V2AstroPeriod.isha,
      V1LegacyPeriod.qiyam => V2AstroPeriod.qiyam,
      null => V2AstroPeriod.fromId(v1PeriodId.clamp(1, 7)),
    };
  }

  void _migrateTaskToV2(TaskModel task, {required bool isHanafi}) {
    task.scheduleModelVersion = 2;
    task.migrationCount += 1;

    if (!task.isAstroTime) return;

    if (task.targetPeriodId != null && task.targetSuwayas.isNotEmpty) {
      final targetV2 = _mapV1PeriodToV2(task.targetPeriodId!);
      final maxSuwayas = targetV2.maxSuwayasForMadhab(isHanafi: isHanafi);

      task.targetPeriodId = targetV2.id;
      task.targetSuwayas = task.targetSuwayas
          .map((s) {
            if (s == -1) return -1;
            return ((s + 1) ~/ 2).clamp(1, maxSuwayas);
          })
          .toSet()
          .toList();
      task.targetVirtualMinute = (task.targetVirtualMinute * 2).clamp(0, 59);
    } else {
      task.isAstroTime = false;
      task.targetCivilTimeMinutes ??= 10 * 60;
    }
  }

  void _migrateRoutineToV2(RoutineModel routine, {required bool isHanafi}) {
    routine.scheduleModelVersion = 2;

    if (!routine.isAstroTime) return;

    if (routine.startPeriodId != null && routine.endPeriodId != null) {
      final newStartP = _mapV1PeriodToV2(routine.startPeriodId!);
      final newEndP = _mapV1PeriodToV2(routine.endPeriodId!);

      final maxStart = newStartP.maxSuwayasForMadhab(isHanafi: isHanafi);
      final maxEnd = newEndP.maxSuwayasForMadhab(isHanafi: isHanafi);

      routine.startPeriodId = newStartP.id;
      routine.startSuwaya =
          (((routine.startSuwaya ?? 1) + 1) ~/ 2).clamp(1, maxStart);
      routine.startVirtualMinute =
          ((routine.startVirtualMinute ?? 0) * 2).clamp(0, 59);

      routine.endPeriodId = newEndP.id;
      routine.endSuwaya =
          (((routine.endSuwaya ?? 1) + 1) ~/ 2).clamp(1, maxEnd);
      routine.endVirtualMinute =
          ((routine.endVirtualMinute ?? 0) * 2).clamp(0, 59);
    } else {
      routine.isAstroTime = false;
      routine.startTimeMinutes ??= 10 * 60;
      routine.endTimeMinutes ??= 11 * 60;
    }
  }
}