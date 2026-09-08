import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_provider.dart';
import '../../models/task_model.dart';
import '../../models/activity_log_model.dart';

// 🌟 المزود الذي سنستخدمه لاستدعاء المزامنة من أي مكان في التطبيق
final syncServiceProvider = Provider<SyncService>((ref) {
  final isar = ref.watch(isarProvider);
  final supabase = Supabase.instance.client;
  return SyncService(isar, supabase);
});

class SyncService {
  final Isar _isar;
  final SupabaseClient _supabase;
  bool _isSyncing = false;

  SyncService(this._isar, this._supabase);

  /// دالة المزامنة الشاملة (تستدعى عند فتح التطبيق، أو عند سحب الشاشة للتحديث)
  Future<void> syncAll() async {
    // نمنع المزامنة المتداخلة أو المزامنة إذا لم يكن المستخدم مسجلاً الدخول
    if (_isSyncing || _supabase.auth.currentUser == null) return;

    try {
      _isSyncing = true;
      debugPrint('🔄 بدء المزامنة السحابية...');

      // 1. دفع البيانات المحلية غير المتزامنة إلى السحابة (Push)
      await _pushTasks();
      await _pushActivityLogs();

      // 2. سحب البيانات الحديثة من السحابة (Pull)
      await _pullTasks();

      debugPrint('✅ اكتملت المزامنة بنجاح!');
    } catch (e) {
      debugPrint('❌ فشل في المزامنة: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ==========================================
  // ⬆️ منطق الرفع (PUSH)
  // ==========================================
  
  Future<void> _pushTasks() async {
    // جلب جميع المهام التي لم تتم مزامنتها
    final unsyncedTasks = await _isar.taskModels.filter().isSyncedEqualTo(false).findAll();
    if (unsyncedTasks.isEmpty) return;

    final String userId = _supabase.auth.currentUser!.id;

    // تحويل المهام إلى شكل (JSON) يقبله Supabase
    final payload = unsyncedTasks.map((t) => {
      'sync_id': t.syncId, // 🌟 المعرف الموحد بين الأجهزة
      'user_id': userId,
      'title': t.title,
      'type': t.type.name,
      'category': t.category.name,
      'is_completed': t.isCompleted,
      'is_deleted': t.isDeleted,
      'updated_at': t.updatedAt.toIso8601String(),
      // يمكنك إضافة باقي الحقول هنا (مثل targetPeriodId وغيرها)
    }).toList();

    // رفع البيانات (Upsert تقوم بالإضافة إذا كان جديداً، والتحديث إذا كان موجوداً مسبقاً)
    await _supabase.from('tasks').upsert(payload, onConflict: 'sync_id');

    // بمجرد نجاح الرفع، نحدث قاعدة البيانات المحلية لنخبر التطبيق أنها تزامنت
    await _isar.writeTxn(() async {
      for (var t in unsyncedTasks) {
        t.isSynced = true;
        await _isar.taskModels.put(t);
      }
    });
  }

  Future<void> _pushActivityLogs() async {
    final unsyncedLogs = await _isar.activityLogs.filter().isSyncedEqualTo(false).findAll();
    if (unsyncedLogs.isEmpty) return;

    final String userId = _supabase.auth.currentUser!.id;

    final payload = unsyncedLogs.map((log) => {
      'sync_id': log.syncId,
      'user_id': userId,
      'task_sync_id': log.taskSyncId,
      'category': log.category,
      'is_deleted': log.isDeleted,
      'completed_at_utc': log.completedAtUtc.toIso8601String(),
      'updated_at': log.updatedAt.toIso8601String(),
    }).toList();

    await _supabase.from('activity_logs').upsert(payload, onConflict: 'sync_id');

    await _isar.writeTxn(() async {
      for (var log in unsyncedLogs) {
        log.isSynced = true;
        await _isar.activityLogs.put(log);
      }
    });
  }

  // ==========================================
  // ⬇️ منطق السحب (PULL)
  // ==========================================

  Future<void> _pullTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String userId = _supabase.auth.currentUser!.id;
    
    // جلب وقت آخر مزامنة ناجحة (لنجلب فقط ما تغير بعدها لتوفير الباقة والسرعة)
    final lastSyncStr = prefs.getString('last_tasks_sync_$userId');
    DateTime lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : DateTime.fromMillisecondsSinceEpoch(0).toUtc();

    // جلب المهام من السحابة التي تم تحديثها بعد آخر مزامنة
    final response = await _supabase
        .from('tasks')
        .select()
        .eq('user_id', userId)
        .gt('updated_at', lastSync.toIso8601String());

    if (response.isEmpty) return;

    await _isar.writeTxn(() async {
      for (var row in response) {
        final syncId = row['sync_id'] as String;
        final remoteUpdatedAt = DateTime.parse(row['updated_at']);

        // البحث عن المهمة محلياً بواسطة الـ UUID
        var localTask = await _isar.taskModels.filter().syncIdEqualTo(syncId).findFirst();

        // 🌟 حل التعارض: إذا كانت نسختنا المحلية أحدث من السحابية، نتجاهل السحابية
        if (localTask != null) {
          if (localTask.updatedAt.isAfter(remoteUpdatedAt)) {
            continue; 
          }
        } else {
          localTask = TaskModel()..syncId = syncId;
        }

        // تحديث النسخة المحلية بالبيانات السحابية
        localTask.title = row['title'] ?? localTask.title;
        localTask.isCompleted = row['is_completed'] ?? localTask.isCompleted;
        localTask.isDeleted = row['is_deleted'] ?? localTask.isDeleted;
        localTask.updatedAt = remoteUpdatedAt;
        localTask.isSynced = true; // جاءت للتو من السحابة، فهي متزامنة

        // ملاحظة: قم بربط باقي الحقول السحابية بالحقول المحلية هنا (حسب الأعمدة في جدولك)
        
        await _isar.taskModels.put(localTask);
      }
    });

    // حفظ وقت إتمام هذه المزامنة لاستخدامه في المرة القادمة
    await prefs.setString('last_tasks_sync_$userId', DateTime.now().toUtc().toIso8601String());
  }
}