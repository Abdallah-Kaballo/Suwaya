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

  // 🌟 تعديل الأداء (النقطة 8): جلب المهام النشطة فقط (دائمة + عابرة مستقبلية أو لم تكتمل بعد)
  Future<List<TaskModel>> getActiveTasks() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final todayStart = DateTime(now.year, now.month, now.day);

    return await _isar.taskModels
        .filter()
        .isDeletedEqualTo(false) // غير محذوفة
        .and()
        .group((q) => q
            // إما دائمة
            .typeEqualTo(TaskType.permanent)
            .or()
            // أو عابرة وتاريخها بعد اليوم (مستقبلية)
            .targetDateGreaterThan(todayStart)
            .or()
            // أو عابرة ولم تكتمل بعد وتاريخها ليس أقدم من 30 يوماً
            .group((q2) => q2
                .isCompletedEqualTo(false)
                .and()
                .targetDateGreaterThan(thirtyDaysAgo)
            )
            .or()
            // أو عابرة اكتملت اليوم تحديداً (لكي تظهر في الواجهة قبل أن تختفي غداً)
            .completedAtGreaterThan(todayStart)
        )
        .findAll();
  }

  // نحتفظ بهذه الدالة للمزامنة السحابية فقط (لأن المزامنة تحتاج كل شيء)
  Future<List<TaskModel>> getAllTasksForSync() async {
    return await _isar.taskModels.where().findAll();
  }

  Future<void> saveTask(TaskModel task) async {
    task.updatedAt = DateTime.now().toUtc();
    await _isar.writeTxn(() async {
      await _isar.taskModels.put(task);
    });
  }

  Future<TaskModel?> getTaskById(int id) async {
    return await _isar.taskModels.get(id);
  }

  Future<void> deleteTask(int id) async {
    await _isar.writeTxn(() async {
      final task = await _isar.taskModels.get(id);
      if (task != null) {
        task.isDeleted = true;
        task.updatedAt = DateTime.now().toUtc(); 
        task.isSynced = false;
        await _isar.taskModels.put(task);
      }
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