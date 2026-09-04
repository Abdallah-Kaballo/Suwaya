import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/task_model.dart';
import '../../models/settings_model.dart';
import '../database/local_db_service.dart';
import 'auth_service.dart';

class SyncService {
  final _supabase = Supabase.instance.client;
  final _isar = LocalDbService.isar;
  final AuthService _authService;

  SyncService(this._authService);

  Future<void> syncAll() async {
    await _isar.settingsModels.where().findFirst();

    if (_authService.currentUser == null) {
      await _authService.signInAnonymously();
    }
    if (_authService.currentUser == null) return; 

    await _pullRemoteChanges();
    await _pushLocalChanges();
  }

  Future<void> _pushLocalChanges() async {
    final userId = _authService.currentUser!;
    
    // 🌟 الإصلاح: سحب المهام غير المتزامنة (حتى لو كانت محذوفة ناعماً) لرفع حالتها للسحابة
    final unsyncedTasks = await _isar.taskModels.filter().isSyncedEqualTo(false).findAll();
    if (unsyncedTasks.isEmpty) return;

    final List<Map<String, dynamic>> payload = unsyncedTasks.map((t) {
      return {
        'sync_id': t.syncId,
        'user_id': userId,
        'title': t.title,
        'type': t.type.name,
        'category': t.category.name,
        'target_period_id': t.targetPeriodId,
        'target_suwayas': t.targetSuwayas,
        'target_date': t.targetDate?.toIso8601String(),
        'recurrence_days': t.recurrenceDays,
        'is_completed': t.isCompleted,
        'completion_history': jsonEncode(t.completionHistory.map((d) => d.toIso8601String()).toList()),
        'current_streak': t.currentStreak,
        'longest_streak': t.longestStreak,
        'notify_mode': t.notifyMode,
        'alarm_mode': t.alarmMode,
        'vibrate_mode': t.vibrateMode,
        'is_deleted': t.isDeleted, // 🌟 يضمن رفع حالة الحذف للسحابة
        'updated_at': t.updatedAt.toIso8601String(),
      };
    }).toList();

    try {
      await _supabase.from('tasks').upsert(payload);

      await _isar.writeTxn(() async {
        for (var t in unsyncedTasks) {
          t.isSynced = true;
          await _isar.taskModels.put(t);
        }
      });
      debugPrint('☁️ تم رفع ${unsyncedTasks.length} مهام بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في الرفع: $e');
    }
  }

  Future<void> _pullRemoteChanges() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString('last_sync_time');
    DateTime? lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

    try {
      var query = _supabase.from('tasks').select();
      if (lastSync != null) {
        query = query.gt('updated_at', lastSync.toIso8601String());
      }

      final List<dynamic> remoteData = await query;
      if (remoteData.isEmpty) return;

      await _isar.writeTxn(() async {
        for (var json in remoteData) {
          final syncId = json['sync_id'] as String;
          final remoteUpdatedAt = DateTime.parse(json['updated_at']);

          var localTask = await _isar.taskModels.filter().syncIdEqualTo(syncId).findFirst();

          if (localTask == null || remoteUpdatedAt.isAfter(localTask.updatedAt)) {
            localTask ??= TaskModel()..syncId = syncId;
            
            localTask.title = json['title'];
            localTask.type = TaskType.values.firstWhere((e) => e.name == json['type'], orElse: () => TaskType.casual);
            localTask.category = TaskCategory.values.firstWhere((e) => e.name == json['category'], orElse: () => TaskCategory.unspecified);
            localTask.targetPeriodId = json['target_period_id'];
            localTask.targetSuwayas = List<int>.from(json['target_suwayas'] ?? []);
            localTask.targetDate = json['target_date'] != null ? DateTime.parse(json['target_date']) : null;
            localTask.recurrenceDays = json['recurrence_days'] != null ? List<int>.from(json['recurrence_days']) : null;
            localTask.isCompleted = json['is_completed'] ?? false;
            
            if (json['completion_history'] != null) {
              List<dynamic> history = jsonDecode(json['completion_history']);
              localTask.completionHistory = history.map((e) => DateTime.parse(e.toString())).toList();
            }
            
            localTask.currentStreak = json['current_streak'] ?? 0;
            localTask.longestStreak = json['longest_streak'] ?? 0;
            localTask.notifyMode = json['notify_mode'] ?? true;
            localTask.alarmMode = json['alarm_mode'] ?? false;
            localTask.vibrateMode = json['vibrate_mode'] ?? false;
            localTask.isDeleted = json['is_deleted'] ?? false; // 🌟 تحديث حالة الحذف محلياً
            
            localTask.updatedAt = remoteUpdatedAt;
            localTask.isSynced = true; 

            await _isar.taskModels.put(localTask);
          }
        }
      });
      
      await prefs.setString('last_sync_time', DateTime.now().toUtc().toIso8601String());
      debugPrint('☁️ تم سحب وتحديث ${remoteData.length} مهام محلياً');
    } catch (e) {
      debugPrint('❌ خطأ في السحب: $e');
    }
  }
}

final syncServiceProvider = Provider((ref) {
  final auth = ref.watch(authServiceProvider);
  return SyncService(auth);
});