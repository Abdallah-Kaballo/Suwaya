import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/local_db_service.dart';
import '../../models/task_model.dart';
import '../../models/settings_model.dart';

class BackupService {
  final Isar _isar = LocalDbService.isar;

  // 🌟 استخراج البيانات وتصديرها كملف
  Future<bool> exportBackup() async {
    try {
      final settings = await _isar.settingsModels.where().findFirst();
      final tasks = await _isar.taskModels.where().findAll();

      // 1. تحضير المهام كقائمة JSON
      final List<Map<String, dynamic>> tasksList = tasks.map((t) {
        return {
          'title': t.title,
          'type': t.type.name,
          'category': t.category.name,
          'target_period_id': t.targetPeriodId,
          'target_suwayas': t.targetSuwayas,
          'is_completed': t.isCompleted,
          'current_streak': t.currentStreak,
          'longest_streak': t.longestStreak,
          'updated_at': t.updatedAt.toIso8601String(),
        };
      }).toList();

      // 2. تحضير ملف الـ Backup الشامل
      final Map<String, dynamic> backupData = {
        'app_name': 'Suwaya',
        'export_date': DateTime.now().toIso8601String(),
        'settings': {
          'theme_mode': settings?.themeMode,
          'calculation_method': settings?.calculationMethod,
          'harmony_streak': settings?.currentStreak,
        },
        'tasks': tasksList,
      };

      // 3. تحويل البيانات إلى نص وتنسيقها
      final String jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // 4. إنشاء ملف مؤقت في جهاز المستخدم
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'suwaya_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final File file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonString);

      // 5. فتح نافذة المشاركة باستخدام الكود المحدث لـ share_plus (الإصدار الحديث) 🌟
      final params = ShareParams(
        files: [XFile(file.path)],
        text: 'نسخة احتياطية لبياناتي من تطبيق سُويعَة ⏳',
      );
      await SharePlus.instance.share(params);

      return true;
    } catch (e) {
      debugPrint('❌ فشل النسخ الاحتياطي: $e');
      return false;
    }
  }
}

final backupServiceProvider = Provider((ref) => BackupService());