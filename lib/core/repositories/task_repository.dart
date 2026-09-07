import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task_model.dart';
import '../database/database_provider.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  // 🌟 حقن الاعتماديات: المستودع لا يعرف شيئاً عن LocalDbService، بل يأخذ Isar من المزود
  final isar = ref.watch(isarProvider);
  return TaskRepository(isar);
});

class TaskRepository {
  final Isar _isar;

  TaskRepository(this._isar);

  Future<List<TaskModel>> getAllTasks() async {
    // 🌟 تم نقل استبعاد المهام المحذوفة إلى هنا
    return await _isar.taskModels.filter().isDeletedEqualTo(false).findAll();
  }

  Future<void> saveTask(TaskModel task) async {
    await _isar.writeTxn(() async {
      await _isar.taskModels.put(task);
    });
  }

  Future<TaskModel?> getTaskById(int id) async {
    return await _isar.taskModels.get(id);
  }

  Future<void> deleteTask(int id) async {
    // 🌟 تم نقل منطق الحذف الآمن (Soft Delete) وعلامة المزامنة إلى المستودع
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
    // 🌟 تم نقل الفرز المنطقي للمهام المكتملة إلى هنا
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

  Future<List<TaskModel>> getRelevantTasksForToday(DateTime today) async {
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return await _isar.taskModels
        .filter()
        .targetDateEqualTo(startOfDay)
        .or()
        .targetDateIsNull() 
        .or()
        .typeEqualTo(TaskType.permanent)
        .findAll();
  }
}