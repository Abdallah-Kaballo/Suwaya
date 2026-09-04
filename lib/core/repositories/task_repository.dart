import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task_model.dart';
import '../database/database_provider.dart';

// 🟢 توفير المستودع وحقن Isar بداخله (Dependency Injection)
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return TaskRepository(isar);
});

class TaskRepository {
  final Isar _isar;

  TaskRepository(this._isar);

  // ── 1. جلب كل المهام (للاستخدام العام) ──
  Future<List<TaskModel>> getAllTasks() async {
    return await _isar.taskModels.where().findAll();
  }

  // ── 2. حفظ أو تحديث مهمة ──
  Future<void> saveTask(TaskModel task) async {
    await _isar.writeTxn(() async {
      await _isar.taskModels.put(task);
    });
  }

  // ── 3. جلب مهمة محددة برقمها ──
  Future<TaskModel?> getTaskById(int id) async {
    return await _isar.taskModels.get(id);
  }

  // ── 4. 🚀 استعلام فائق السرعة عبر Isar (يحل مشكلة فلترة الذاكرة) ──
  // بدلاً من جلب 5000 مهمة للذاكرة، نجلب مهام اليوم والمهام المتكررة فقط
  Future<List<TaskModel>> getRelevantTasksForToday(DateTime today) async {
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    return await _isar.taskModels
        .filter()
        .targetDateEqualTo(startOfDay)
        .or()
        .targetDateIsNull() // لجلب مهام الأفق
        .or()
        .typeEqualTo(TaskType.permanent)
        .findAll();
  }
}