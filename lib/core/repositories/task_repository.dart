import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task_model.dart';
import '../database/database_provider.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return TaskRepository(isar);
});

class TaskRepository {
  final Isar _isar;

  TaskRepository(this._isar);

  Future<List<TaskModel>> getActiveTasks() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final todayStart = DateTime(now.year, now.month, now.day);

    return await _isar.taskModels
        .filter()
        .group((q) => q
            .typeEqualTo(TaskType.permanent)
            .or()
            .targetDateGreaterThan(todayStart)
            .or()
            .group((q2) => q2
                .isCompletedEqualTo(false)
                .and()
                .targetDateGreaterThan(thirtyDaysAgo)
            )
            .or()
            .completedAtGreaterThan(todayStart)
        )
        .findAll();
  }

  Future<void> saveTask(TaskModel task) async {
    await _isar.writeTxn(() async {
      await _isar.taskModels.put(task);
    });
  }

  Future<TaskModel?> getTaskById(int id) async {
    return await _isar.taskModels.get(id);
  }

  // 🌟 حذف المهمة فعلياً من قاعدة البيانات (بدلاً من isDeleted)
  Future<void> deleteTask(int id) async {
    await _isar.writeTxn(() async {
      await _isar.taskModels.delete(id);
    });
  }

  Future<List<TaskModel>> getRecentCompletedTasks(DateTime since) async {
    final completedTasks = await _isar.taskModels.filter()
        .isCompletedEqualTo(true)
        .and()
        .completedAtGreaterThan(since)
        .findAll();

    completedTasks.sort((a, b) {
      if (a.completedAt == null && b.completedAt == null) return 0;
      if (a.completedAt == null) return 1;
      if (b.completedAt == null) return -1;
      return b.completedAt!.compareTo(a.completedAt!);
    });

    return completedTasks;
  }
}