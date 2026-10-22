import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

import '../../models/task_model.dart';
import '../../models/settings_model.dart';
import '../../models/geo_models.dart';
import '../../models/routine_model.dart';


class DatabaseService {
  static Future<Isar> init() async {
    final existingInstance = Isar.getInstance();
    if (existingInstance != null && existingInstance.isOpen) {
      await _ensureDefaultSettings(existingInstance);
      return existingInstance;
    }

    final dir = await getApplicationDocumentsDirectory();
    late final Isar isar;

    try {
      isar = await Isar.open(
        [
          TaskModelSchema,
          SettingsModelSchema,
          GeoCountrySchema,
          RoutineModelSchema,
        ],
        directory: dir.path,
        inspector: !kReleaseMode,
      );
    } catch (e, stackTrace) {
      debugPrint('🚨 فشل فتح قاعدة بيانات Isar في المسار (${dir.path}): $e\n$stackTrace');
      throw StateError(
        'تعذر فتح قاعدة البيانات المحلية (قد تكون مقفلة بواسطة عملية أخرى أو لا توجد مساحة كافية): $e',
      );
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