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

  /// دالة تعمل عند بدء تشغيل التطبيق للتحقق من وجود بيانات قديمة وترحيلها
  Future<void> runMigrationsIfNeeded() async {
    final taskRepo = _ref.read(taskRepositoryProvider);
    final routineRepo = _ref.read(routineRepositoryProvider);

    final allTasks = await taskRepo.getActiveTasks(); // افترض وجود هذه الدالة في الـ Repo أو استخدم getActiveTasks
    final allRoutines = await routineRepo.getAllRoutines();

    bool needsRestart = false;

    // 🌟 ترحيل المهام (Tasks)
    for (var task in allTasks) {
      if (task.scheduleModelVersion < 2) {
        debugPrint('Migration: Upgrading Task ID ${task.id} to V2');
        _migrateTaskToV2(task);
        await taskRepo.saveTask(task);
        needsRestart = true;
      }
    }

    // 🌟 ترحيل الروتينات (Routines)
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

  /// هجرة المهام: نقوم بتحويلها إلى النمط المدني (Civil) مؤقتاً كإجراء آمن 
  /// لضمان عدم ضياعها، ولأن حساب اللحظة الفلكية القديمة يتطلب المحرك القديم.
  void _migrateTaskToV2(TaskModel task) {
    task.scheduleModelVersion = 2;
    
    // إذا كانت المهمة مدنية بالأصل، نتركها كما هي.
    if (!task.isAstroTime) return;

    // تحويل المهام الفلكية القديمة إلى مهام مدنية عند الساعة 10:00 صباحاً كقيمة افتراضية (Fallback)
    // ليقوم المستخدم بإعادة جدولتها في السويعة الجديدة التي تناسبه.
    task.isAstroTime = false;
    task.targetCivilTimeMinutes = 10 * 60; // 10:00 AM
    task.targetPeriodId = null;
    task.targetSuwayas = [];
    task.targetVirtualMinute = 0;
  }

  void _migrateRoutineToV2(RoutineModel routine) {
    routine.scheduleModelVersion = 2;
    
    if (!routine.isAstroTime) return;

    // تحويل الروتين القديم إلى روتين مدني من 10:00 ص إلى 11:00 ص
    routine.isAstroTime = false;
    routine.startTimeMinutes = 10 * 60;
    routine.endTimeMinutes = 11 * 60;
    routine.startPeriodId = null;
    routine.startSuwaya = null;
    routine.startVirtualMinute = null;
    routine.endPeriodId = null;
    routine.endSuwaya = null;
    routine.endVirtualMinute = null;
  }
}