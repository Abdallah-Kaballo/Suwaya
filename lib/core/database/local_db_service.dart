import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../../models/task_model.dart';
import 'package:suwaya/models/settings_model.dart';
import '../models/geo_models.dart';
import '../../models/routine_model.dart';
import '../../models/daily_stats_model.dart'; // 🟢 استيراد نموذج الإحصائيات

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
          DailyCosmicStatsSchema, // 🟢 تمت الإضافة
        ],
        directory: dir.path,
        inspector: true,
      );
    } catch (e) {
      debugPrint('🚨 فشل فتح قاعدة البيانات: $e');
      // 🛡️ لا نحذف البيانات تلقائيًا. نعطي المستخدم فرصة لاستعادة نسخة أو إعادة التثبيت.
      // بدلاً من deleteFromDisk، نحاول الفتح بدون أي مخططات جديدة قد تكون السبب.
      // إذا فشل أيضًا، نرمي استثناءً واضحًا ليتعامل معه main.dart.
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
        // إذا استمر الفشل، نرمي استثناءً يمنع التطبيق من الاستمرار بصمت.
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
        task.updatedAt = DateTime.now();
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