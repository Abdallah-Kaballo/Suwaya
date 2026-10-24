import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suwaya_time/suwaya_time.dart';

import '../../models/routine_model.dart';
import '../../core/astro_engine/astro_provider.dart';
import '../../core/repositories/routine_repository.dart';

// مزود حالة لتتبع الروتين المتوهج حالياً
final highlightedRoutineProvider = StateProvider<int?>((ref) => null);

class RoutineArcData {
  final int id;
  final Color color;
  final double startAngle;
  final double sweepAngle;
  final DateTime startTime;
  final DateTime endTime;
  final String pattern;

  RoutineArcData({
    required this.id,
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
    required this.startTime,
    required this.endTime,
    this.pattern = 'linear',
  });
}

class RoutinesNotifier extends Notifier<List<RoutineModel>> {
  @override
  List<RoutineModel> build() {
    _loadRoutines();
    return [];
  }

  Future<void> _loadRoutines() async {
    final repository = ref.read(routineRepositoryProvider);
    final routines = await repository.getAllRoutines();
    state = List.from(routines);
  }

  Future<void> addRoutine(RoutineModel routine) async {
    final repository = ref.read(routineRepositoryProvider);
    await repository.saveRoutine(routine);

    state = [...state.where((r) => r.id != routine.id), routine];
  }

  Future<void> deleteRoutine(int id) async {
    state = state.where((r) => r.id != id).toList();

    final repository = ref.read(routineRepositoryProvider);
    await repository.deleteRoutine(id);
  }
}

final routinesProvider =
    NotifierProvider<RoutinesNotifier, List<RoutineModel>>(
  RoutinesNotifier.new,
);

final routineArcsProvider = Provider<List<RoutineArcData>>((ref) {
  final routines = ref.watch(routinesProvider);
  final astroState = ref.watch(astroProvider);
  final List<RoutineArcData> arcs = [];

  if (astroState.periods.isEmpty) return arcs;

  for (final r in routines) {
    if (!r.isActive) continue;

    if (r.recurrenceDays != null && r.recurrenceDays!.isNotEmpty) {
      final logicalDate = SuwayaScheduleEngine.resolveLogicalCivilDate(
        isAstroTime: r.isAstroTime,
        astroState: astroState,
        civilReference: virtualDateTimeNotifier.value,
      );
      if (!r.recurrenceDays!.contains(logicalDate.weekday)) {
        continue;
      }
    }

    final geometry = SuwayaScheduleEngine.computeRoutineDialArc(
      isAstroTime: r.isAstroTime,
      startPeriodId: r.startPeriodId,
      startSuwaya: r.startSuwaya,
      startVirtualMinute: r.startVirtualMinute,
      endPeriodId: r.endPeriodId,
      endSuwaya: r.endSuwaya,
      endVirtualMinute: r.endVirtualMinute,
      startCivilClock: r.startCivilClock,
      endCivilClock: r.endCivilClock,
      periods: astroState.periods,
    );

    if (geometry == null) continue;

    arcs.add(
      RoutineArcData(
        id: r.id,
        color: Color(r.colorValue),
        startAngle: geometry.startAngle,
        sweepAngle: geometry.sweepAngle,
        startTime: geometry.startTime,
        endTime: geometry.endTime,
        pattern: r.pattern,
      ),
    );
  }
  return arcs;
});