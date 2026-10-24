import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/core/repositories/routine_repository.dart';
import 'package:suwaya/core/repositories/settings_repository.dart';
import 'package:suwaya/core/repositories/task_repository.dart';
import 'package:suwaya/core/services/migration_service.dart';
import 'package:suwaya/models/routine_model.dart';
import 'package:suwaya/models/settings_model.dart';
import 'package:suwaya/models/task_model.dart';

class _InMemoryTaskRepository implements TaskRepository {
  final List<TaskModel> tasks;
  _InMemoryTaskRepository(this.tasks);

  @override
  Future<List<TaskModel>> getAllTasks() async => List.from(tasks);

  @override
  Future<void> saveTask(TaskModel task) async {
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      tasks[idx] = task;
    } else {
      tasks.add(task);
    }
  }

  @override
  Future<void> deleteTask(int id) async => tasks.removeWhere((t) => t.id == id);

  @override
  Future<void> deleteTasks(List<int> ids) async =>
      tasks.removeWhere((t) => ids.contains(t.id));

  @override
  Future<List<TaskModel>> getActiveTasks() async => tasks;

  @override
  Future<List<TaskModel>> getRecentCompletedTasks(DateTime since) async => [];

  @override
  Future<TaskModel?> getTaskById(int id) async =>
      tasks.where((t) => t.id == id).firstOrNull;
}

class _InMemoryRoutineRepository implements RoutineRepository {
  final List<RoutineModel> routines;
  _InMemoryRoutineRepository(this.routines);

  @override
  Future<List<RoutineModel>> getAllRoutines() async => List.from(routines);

  @override
  Future<void> saveRoutine(RoutineModel routine) async {
    final idx = routines.indexWhere((r) => r.id == routine.id);
    if (idx >= 0) {
      routines[idx] = routine;
    } else {
      routines.add(routine);
    }
  }

  @override
  Future<void> deleteRoutine(int id) async =>
      routines.removeWhere((r) => r.id == id);
}

class _InMemorySettingsRepository implements SettingsRepository {
  SettingsModel settings;
  _InMemorySettingsRepository(this.settings);

  @override
  Future<SettingsModel> getSettings() async => settings;

  @override
  Future<void> saveSettings(SettingsModel s) async => settings = s;

  @override
  Future<void> updateActiveLocation(SavedLocation location) async {
    settings.activeLocation = location;
  }
}

void main() {
  group('MigrationService V1 (48 Suwayas) to V2 (24 Suwayas) Tests', () {
    test(
        '1 & 2. Converts V1 period/suwaya/virtualMinute to V2 while preserving IDs, titles, and streak history',
        () async {
      final historyDate = DateTime(2026, 10, 10);
      final v1Task = TaskModel()
        ..id = 101
        ..title = 'ورد الفجر'
        ..scheduleModelVersion = 1
        ..isAstroTime = true
        ..targetPeriodId = 1 // في V1: الفجر كان الفترة 1
        ..targetSuwayas = [2]
        ..targetVirtualMinute = 15 // في V1: 15 من 30 (منتصف السويعة)
        ..currentStreak = 7
        ..longestStreak = 14
        ..completionHistory = [historyDate];

      final taskRepo = _InMemoryTaskRepository([v1Task]);
      final routineRepo = _InMemoryRoutineRepository([]);
      final settingsRepo =
          _InMemorySettingsRepository(SettingsModel()..madhab = 'shafi');

      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(taskRepo),
          routineRepositoryProvider.overrideWithValue(routineRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(migrationServiceProvider).runMigrationsIfNeeded();

      final migrated = taskRepo.tasks.first;
      expect(migrated.scheduleModelVersion, 2);
      expect(migrated.id, 101);
      expect(migrated.title, 'ورد الفجر');
      expect(migrated.currentStreak, 7);
      expect(migrated.longestStreak, 14);
      expect(migrated.completionHistory, equals([historyDate]));
      // في V2: الفجر أصبح الفترة 4، وعدد سويعاته 1، والدقيقة 15*2 = 30
      expect(migrated.targetPeriodId, V2AstroPeriod.fajr.id);
      expect(migrated.targetSuwayas, equals([1]));
      expect(migrated.targetVirtualMinute, 30);
    });

    test(
        '3. Converts incomplete astro routines and tasks safely to civil fallback (10:00 - 11:00)',
        () async {
      final incompleteTask = TaskModel()
        ..id = 202
        ..title = 'مهمة ناقصة'
        ..scheduleModelVersion = 1
        ..isAstroTime = true
        ..targetPeriodId = null
        ..targetSuwayas = [];

      final incompleteRoutine = RoutineModel()
        ..id = 303
        ..title = 'روتين ناقص'
        ..scheduleModelVersion = 1
        ..isAstroTime = true
        ..startPeriodId = null
        ..endPeriodId = null;

      final taskRepo = _InMemoryTaskRepository([incompleteTask]);
      final routineRepo = _InMemoryRoutineRepository([incompleteRoutine]);
      final settingsRepo = _InMemorySettingsRepository(SettingsModel());

      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(taskRepo),
          routineRepositoryProvider.overrideWithValue(routineRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
        ],
      );
      addTearDown(container.dispose);

      await container.read(migrationServiceProvider).runMigrationsIfNeeded();

      expect(incompleteTask.scheduleModelVersion, 2);
      expect(incompleteTask.isAstroTime, isFalse);
      expect(incompleteTask.targetCivilTimeMinutes, 10 * 60);

      expect(incompleteRoutine.scheduleModelVersion, 2);
      expect(incompleteRoutine.isAstroTime, isFalse);
      expect(incompleteRoutine.startTimeMinutes, 10 * 60);
      expect(incompleteRoutine.endTimeMinutes, 11 * 60);
    });

    test(
        '4 & 5. Idempotency & interrupted restart: does not re-migrate records already at version 2',
        () async {
      final v1Task = TaskModel()
        ..id = 1
        ..scheduleModelVersion = 1
        ..isAstroTime = true
        ..targetPeriodId = 7 // قيام V1 -> الفترة 3 في V2
        ..targetSuwayas = [4] // تتحول إلى 2 في المرة الأولى
        ..targetVirtualMinute = 10; // تتحول إلى 20 في المرة الأولى

      final taskRepo = _InMemoryTaskRepository([v1Task]);
      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(taskRepo),
          routineRepositoryProvider
              .overrideWithValue(_InMemoryRoutineRepository([])),
          settingsRepositoryProvider
              .overrideWithValue(_InMemorySettingsRepository(SettingsModel())),
        ],
      );
      addTearDown(container.dispose);

      // التشغيل الأول
      await container.read(migrationServiceProvider).runMigrationsIfNeeded();
      expect(v1Task.scheduleModelVersion, 2);
      expect(v1Task.migrationCount, 1);
      expect(v1Task.targetSuwayas, equals([2]));
      expect(v1Task.targetVirtualMinute, 20);

      // التشغيل الثاني (يجب ألا يغير شيئاً إطلاقاً)
      await container.read(migrationServiceProvider).runMigrationsIfNeeded();
      expect(v1Task.migrationCount, 1);
      expect(v1Task.targetSuwayas, equals([2]));
      expect(v1Task.targetVirtualMinute, 20);
    });

    test('6. Respects Hanafi vs Shafi max Suwayas clamping for Dhuhr and Asr',
        () async {
      // في المذهب الحنفي: الظهر 4 سويعات والعصر 2 سويعتان
      // في مذهب الجمهور: الظهر 3 سويعات والعصر 3 سويعات
      final asrTaskHanafi = TaskModel()
        ..id = 10
        ..scheduleModelVersion = 1
        ..isAstroTime = true
        ..targetPeriodId = 4 // العصر في V1
        ..targetSuwayas = [6]; // (6+1)~/2 = 3 -> تُقيد بـ 2 في الحنفي

      final taskRepo = _InMemoryTaskRepository([asrTaskHanafi]);
      final container = ProviderContainer(
        overrides: [
          taskRepositoryProvider.overrideWithValue(taskRepo),
          routineRepositoryProvider
              .overrideWithValue(_InMemoryRoutineRepository([])),
          settingsRepositoryProvider.overrideWithValue(
            _InMemorySettingsRepository(SettingsModel()..madhab = 'hanafi'),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(migrationServiceProvider).runMigrationsIfNeeded();
      expect(asrTaskHanafi.targetPeriodId, V2AstroPeriod.asr.id);
      expect(asrTaskHanafi.targetSuwayas, equals([2]));
    });
  });
}
