import 'package:isar_community/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/routine_model.dart';
import '../database/database_provider.dart';

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return RoutineRepository(isar);
});

class RoutineRepository {
  final Isar _isar;

  RoutineRepository(this._isar);

  Future<List<RoutineModel>> getAllRoutines() async {
    return await _isar.routineModels.where().findAll();
  }

  Future<void> saveRoutine(RoutineModel routine) async {
    await _isar.writeTxn(() async {
      await _isar.routineModels.put(routine);
    });
  }

  Future<void> deleteRoutine(int id) async {
    await _isar.writeTxn(() async {
      await _isar.routineModels.delete(id);
    });
  }
}