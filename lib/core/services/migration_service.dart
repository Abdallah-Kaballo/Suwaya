import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/task_repository.dart';
import '../repositories/routine_repository.dart';
import '../../models/task_model.dart';
import '../../models/routine_model.dart';

final migrationServiceProvider = Provider<MigrationService>((ref) {
  return MigrationService(ref);
});

class MigrationService {
  final Ref _ref;

  MigrationService(this._ref);

  Future<void> runMigrationsIfNeeded() async {
    final taskRepo = _ref.read(taskRepositoryProvider);
    final routineRepo = _ref.read(routineRepositoryProvider);

    final allTasks = await taskRepo.getActiveTasks();
    final allRoutines = await routineRepo.getAllRoutines();

    bool needsRestart = false;

    for (var task in allTasks) {
      if (task.scheduleModelVersion < 2) {
        debugPrint('Migration: Upgrading Task ID ${task.id} to V2');
        _migrateTaskToV2(task);
        await taskRepo.saveTask(task);
        needsRestart = true;
      }
    }

    for (var routine in allRoutines) {
      if (routine.scheduleModelVersion < 2) {
        debugPrint('Migration: Upgrading Routine ID ${routine.id} to V2');
        _migrateRoutineToV2(routine);
        await routineRepo.saveRoutine(routine);
        needsRestart = true;
      }
    }

    if (needsRestart) {
      debugPrint('Migration Completed Successfully.');
    }
  }

  /// 🌟 تحويل رقم الفترة من نظام V1 (حيث 1=الفجر.. 5=المغرب) إلى نظام V2 (حيث 1=المغرب.. 4=الفجر.. 7=العصر)
  int _mapV1PeriodIdToV2(int v1PeriodId) {
    switch (v1PeriodId) {
      case 1:
        return 4; // الفجر
      case 2:
        return 5; // الضحى
      case 3:
        return 6; // الظهر
      case 4:
        return 7; // العصر
      case 5:
        return 1; // المغرب / أول الليل
      case 6:
        return 2; // العشاء / وسط الليل
      case 7:
        return 3; // النصف الثاني من الليل / الثلث الأخير
      default:
        return v1PeriodId.clamp(1, 7);
    }
  }

  int _maxSuwayasForV2Period(int v2PeriodId) {
    switch (v2PeriodId) {
      case 1:
        return 1;
      case 2:
        return 4;
      case 3:
        return 6;
      case 4:
        return 1;
      case 5:
        return 6;
      case 6:
        return 3;
      case 7:
        return 3;
      default:
        return 1;
    }
  }

  /// 🌟 ترحيل ذكي يحافظ على الجدولة الفلكية للمهمة عبر تحويل نسبي من 48 سويعة (30 د) إلى 24 سويعة (60 د)
  void _migrateTaskToV2(TaskModel task) {
    task.scheduleModelVersion = 2;
    task.migrationCount += 1;

    if (!task.isAstroTime) return;

    if (task.targetPeriodId != null && task.targetSuwayas.isNotEmpty) {
      final v2PeriodId = _mapV1PeriodIdToV2(task.targetPeriodId!);
      final maxSuwayas = _maxSuwayasForV2Period(v2PeriodId);

      task.targetPeriodId = v2PeriodId;
      task.targetSuwayas = task.targetSuwayas
          .map((s) {
            if (s == -1) return -1;
            return ((s + 1) ~/ 2).clamp(1, maxSuwayas);
          })
          .toSet()
          .toList();
      // تحويل الدقيقة الافتراضية من مقياس (0..29) إلى مقياس (0..59)
      task.targetVirtualMinute = (task.targetVirtualMinute * 2).clamp(0, 59);
    } else {
      // في حال كانت الحقول الفلكية فارغة فقط نضع وقتاً مدنياً احتياطياً
      task.isAstroTime = false;
      task.targetCivilTimeMinutes ??= 10 * 60;
    }
  }

  /// 🌟 ترحيل ذكي يحافظ على الجدولة الفلكية للروتين في نظام الـ 24 سويعة الجديد
  void _migrateRoutineToV2(RoutineModel routine) {
    routine.scheduleModelVersion = 2;

    if (!routine.isAstroTime) return;

    if (routine.startPeriodId != null && routine.endPeriodId != null) {
      final newStartP = _mapV1PeriodIdToV2(routine.startPeriodId!);
      final newEndP = _mapV1PeriodIdToV2(routine.endPeriodId!);

      routine.startPeriodId = newStartP;
      routine.startSuwaya = (((routine.startSuwaya ?? 1) + 1) ~/ 2)
          .clamp(1, _maxSuwayasForV2Period(newStartP));
      routine.startVirtualMinute =
          ((routine.startVirtualMinute ?? 0) * 2).clamp(0, 59);

      routine.endPeriodId = newEndP;
      routine.endSuwaya = (((routine.endSuwaya ?? 1) + 1) ~/ 2)
          .clamp(1, _maxSuwayasForV2Period(newEndP));
      routine.endVirtualMinute =
          ((routine.endVirtualMinute ?? 0) * 2).clamp(0, 59);
    } else {
      routine.isAstroTime = false;
      routine.startTimeMinutes ??= 10 * 60;
      routine.endTimeMinutes ??= 11 * 60;
    }
  }
}