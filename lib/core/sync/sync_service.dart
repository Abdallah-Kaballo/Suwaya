import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/task_model.dart';
import '../../models/activity_log_model.dart';
import '../database/local_db_service.dart';
import 'auth_service.dart';

class SyncService {
  final _supabase = Supabase.instance.client;
  final _isar = LocalDbService.isar;
  final AuthService _authService;

  SyncService(this._authService);

  // 🌟 الدالة الرئيسية التي يتم استدعاؤها للمزامنة
  Future<void> syncAll() async {
    if (_authService.currentUser == null) return; 

    // 1. سحب التعديلات من السحابة وتطبيقها محلياً
    await _pullRemoteChanges();
    // 2. رفع التعديلات المحلية (التي لم تُزامن) للسحابة
    await _pushLocalChanges();
  }

  Future<void> migrateGuestData() async {
    await _isar.writeTxn(() async {
      // 1. جعل كل المهام المحلية غير متزامنة لفرض رفعها
      final tasks = await _isar.taskModels.where().findAll();
      for (var t in tasks) {
        t.isSynced = false;
        await _isar.taskModels.put(t);
      }

      // 2. جعل كل سجلات النشاط غير متزامنة لفرض رفعها
      final logs = await _isar.activityLogs.where().findAll();
      for (var log in logs) {
        log.isSynced = false;
        await _isar.activityLogs.put(log);
      }
    });

    // 3. حذف توقيت المزامنة لفرض سحب كل بيانات السحابة (إن وجدت)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_sync_time');
    
    debugPrint('🔄 تم تجهيز بيانات الضيف للدمج مع الحساب السحابي');
  }

  Future<void> _pushLocalChanges() async {
    final userId = _authService.currentUser!.id;
    
    // 🌟 استخراج المهام غير المتزامنة (بما فيها المحذوفة ناعماً)
    final unsyncedTasks = await _isar.taskModels.filter().isSyncedEqualTo(false).findAll();
    
    if (unsyncedTasks.isNotEmpty) {
      final taskPayload = unsyncedTasks.map((t) => {
        'sync_id': t.syncId,
        'user_id': userId,
        'title': t.title,
        'type': t.type.name,
        'category': t.category.name,
        'target_period_id': t.targetPeriodId,
        'target_suwayas': t.targetSuwayas,
        'is_completed': t.isCompleted,
        'current_streak': t.currentStreak,
        'is_deleted': t.isDeleted,
        'updated_at': t.updatedAt.toIso8601String(),
      }).toList();

      try {
        await _supabase.from('tasks').upsert(taskPayload);
        // تحديث الحالة محلياً إلى "تمت المزامنة"
        await _isar.writeTxn(() async {
          for (var t in unsyncedTasks) {
            t.isSynced = true;
            await _isar.taskModels.put(t);
          }
        });
      } catch (e) {
        debugPrint('❌ فشل رفع المهام: $e');
      }
    }

    // 🌟 استخراج سجلات النشاط غير المتزامنة
    final unsyncedLogs = await _isar.activityLogs.filter().isSyncedEqualTo(false).findAll();
    if (unsyncedLogs.isNotEmpty) {
      final logPayload = unsyncedLogs.map((log) => {
        'sync_id': log.syncId,
        'user_id': userId,
        'task_sync_id': log.taskSyncId,
        'category': log.category,
        'period_id': log.periodId,
        'suwayas_count': log.suwayasCount,
        'active_day_date': log.activeDayDate,
        'completed_at_utc': log.completedAtUtc.toIso8601String(),
        'is_deleted': log.isDeleted,
        'updated_at': log.updatedAt.toIso8601String(),
      }).toList();

      try {
        await _supabase.from('activity_logs').upsert(logPayload);
        await _isar.writeTxn(() async {
          for (var log in unsyncedLogs) {
            log.isSynced = true;
            await _isar.activityLogs.put(log);
          }
        });
      } catch (e) {
        debugPrint('❌ فشل رفع السجلات: $e');
      }
    }
  }

  Future<void> _pullRemoteChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('last_sync_time');
    DateTime? lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

    try {
      // 🌟 سحب المهام
      var taskQuery = _supabase.from('tasks').select();
      if (lastSync != null) {
        taskQuery = taskQuery.gt('updated_at', lastSync.toIso8601String());
      }
      final List<dynamic> remoteTasks = await taskQuery;

      if (remoteTasks.isNotEmpty) {
        await _isar.writeTxn(() async {
          for (var json in remoteTasks) {
            final syncId = json['sync_id'] as String;
            final remoteUpdatedAt = DateTime.parse(json['updated_at']);

            var localTask = await _isar.taskModels.filter().syncIdEqualTo(syncId).findFirst();

            // تطبيق التعديل السحابي فقط إذا كان أحدث من المحلي (Conflict Resolution)
            if (localTask == null || remoteUpdatedAt.isAfter(localTask.updatedAt)) {
              localTask ??= TaskModel()..syncId = syncId;
              
              localTask.title = json['title'];
              localTask.type = TaskType.values.firstWhere((e) => e.name == json['type'], orElse: () => TaskType.casual);
              localTask.category = TaskCategory.values.firstWhere((e) => e.name == json['category'], orElse: () => TaskCategory.unspecified);
              localTask.targetPeriodId = json['target_period_id'];
              localTask.targetSuwayas = List<int>.from(json['target_suwayas'] ?? []);
              localTask.isCompleted = json['is_completed'] ?? false;
              localTask.currentStreak = json['current_streak'] ?? 0;
              localTask.isDeleted = json['is_deleted'] ?? false;
              
              localTask.updatedAt = remoteUpdatedAt;
              localTask.isSynced = true; 

              await _isar.taskModels.put(localTask);
            }
          }
        });
      }
      
      // حفظ وقت المزامنة لتجنب سحب نفس البيانات مستقبلاً
      await prefs.setString('last_sync_time', DateTime.now().toUtc().toIso8601String());
    } catch (e) {
      debugPrint('❌ فشل سحب البيانات: $e');
    }
  }
}

final syncServiceProvider = Provider((ref) {
  final auth = ref.watch(authServiceProvider);
  return SyncService(auth);
});