import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../../models/task_model.dart';
import 'package:suwaya/models/settings_model.dart';
import '../models/geo_models.dart';
import '../../models/routine_model.dart';
import '../../models/activity_log_model.dart'; 

class LocalDbService {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();

    try {
      isar = await Isar.open(
        [
          TaskModelSchema,
          SettingsModelSchema,
          GeoCountrySchema,
          RoutineModelSchema,
          ActivityLogSchema, // 🌟 التعديل هنا: استبدال المخطط القديم بالجديد
        ],
        directory: dir.path,
        inspector: true,
      );
    } catch (e) {
      debugPrint('🚨 فشل فتح قاعدة البيانات: $e');
      try {
        isar = await Isar.open(
          [
            TaskModelSchema,
            SettingsModelSchema,
            GeoCountrySchema,
            RoutineModelSchema,
          ],
          directory: dir.path,
          inspector: true,
        );
      } catch (_) {
        throw Exception('لا يمكن فتح قاعدة البيانات. يرجى إعادة تشغيل التطبيق أو استعادة نسخة احتياطية.');
      }
    }

    await _ensureDefaultSettings();
  }

  static Future<void> _ensureDefaultSettings() async {
    final settingsCount = await isar.settingsModels.count();
    if (settingsCount == 0) {
      await isar.writeTxn(() async {
        await isar.settingsModels.put(SettingsModel()..id = 1);
      });
    }
  }

  static Future<void> saveTask(TaskModel task) async {
    await isar.writeTxn(() async {
      await isar.taskModels.put(task);
    });
  }

  static Future<List<TaskModel>> getAllTasks() async {
    // 🟢 نعيد فقط المهام غير المحذوفة ناعمًا
    return await isar.taskModels.filter().isDeletedEqualTo(false).findAll();
  }

  static Future<void> deleteTask(int id) async {
    // 🟢 حذف ناعم
    await isar.writeTxn(() async {
      final task = await isar.taskModels.get(id);
      if (task != null) {
        task.isDeleted = true;
        task.updatedAt = DateTime.now().toUtc(); // 🌟 يفضل استخدام UTC هنا للمزامنة
        task.isSynced = false;
        await isar.taskModels.put(task);
      }
    });
  }

  static Future<List<TaskModel>> getRecentCompletedTasks(DateTime since) async {
    final completedTasks = await isar.taskModels.filter()
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