import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../../models/task_model.dart';
import '../../models/settings_model.dart';
import '../../models/geo_models.dart';
import '../../models/routine_model.dart';
import '../../models/activity_log_model.dart';

class DatabaseService {
  // 🌟 لم يعد هناك كائن static! الخدمة تقوم بالتهيئة وتعيد الكائن فقط.
  static Future<Isar> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Isar isar;

    try {
      isar = await Isar.open(
        [
          TaskModelSchema,
          SettingsModelSchema,
          GeoCountrySchema,
          RoutineModelSchema,
          ActivityLogSchema,
        ],
        directory: dir.path,
        inspector: !kReleaseMode,
      );
    } catch (e) {
      debugPrint('🚨 فشل فتح قاعدة البيانات: $e');
      try {
        // محاولة الفتح كخيار بديل (Fallback)
        isar = await Isar.open(
          [TaskModelSchema, SettingsModelSchema, GeoCountrySchema, RoutineModelSchema],
          directory: dir.path,
          inspector: !kReleaseMode,
        );
      } catch (_) {
        throw Exception('لا يمكن فتح قاعدة البيانات. يرجى إعادة تشغيل التطبيق.');
      }
    }

    await _ensureDefaultSettings(isar);
    return isar; 
  }

  static Future<void> _ensureDefaultSettings(Isar isar) async {
    final settingsCount = await isar.settingsModels.count();
    if (settingsCount == 0) {
      await isar.writeTxn(() async {
        await isar.settingsModels.put(SettingsModel()..id = 1);
      });
    }
  }
}