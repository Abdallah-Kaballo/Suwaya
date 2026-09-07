import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/activity_log_model.dart';
import '../database/database_provider.dart';

final activityLogRepositoryProvider = Provider<ActivityLogRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return ActivityLogRepository(isar);
});

class ActivityLogRepository {
  final Isar _isar;

  ActivityLogRepository(this._isar);

  Future<List<ActivityLog>> getRecentActiveLogs(DateTime since) async {
    return await _isar.activityLogs
        .filter()
        .isDeletedEqualTo(false)
        .completedAtUtcGreaterThan(since)
        .findAll();
  }

  Future<void> saveLog(ActivityLog log) async {
    await _isar.writeTxn(() async {
      await _isar.activityLogs.put(log);
    });
  }
}