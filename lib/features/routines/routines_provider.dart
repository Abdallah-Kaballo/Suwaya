import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/routine_model.dart';
import '../../core/astro_engine/astro_provider.dart';
import '../../core/repositories/routine_repository.dart';

// 🌟 مزود حالة لتتبع الروتين المتوهج حالياً
final highlightedRoutineProvider = StateProvider<int?>((ref) => null);

class RoutineArcData {
  final int id; // 🌟 إضافة الـ ID للتعرف عليه عند اللمس
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

final routinesProvider = NotifierProvider<RoutinesNotifier, List<RoutineModel>>(
    RoutinesNotifier.new);

final routineArcsProvider = Provider<List<RoutineArcData>>((ref) {
  final routines = ref.watch(routinesProvider);
  final astroState = ref.watch(astroProvider);
  final List<RoutineArcData> arcs = [];

  if (astroState.periods.isEmpty) return arcs;

  final dayStart = astroState.periods.first.startTime;
  final dayEnd = astroState.periods.last.endTime;
  final totalDayMicro = dayEnd.difference(dayStart).inMicroseconds;

  if (totalDayMicro <= 0) return arcs;

  final totalSuwayas =
      astroState.periods.fold(0, (sum, p) => sum + p.suwayasCount);
  final effectiveTotalSuwayas = totalSuwayas > 0 ? totalSuwayas : 48;

  double getAngleForTime(DateTime t) {
    return -pi / 2 +
        (t.difference(dayStart).inMicroseconds / totalDayMicro) * 2 * pi;
  }

  double getAstroAngle(int globalSuwaya, int virtualMinute) {
    globalSuwaya %= effectiveTotalSuwayas;

    int accumulatedSuwayas = 0;
    for (var p in astroState.periods) {
      if (globalSuwaya < accumulatedSuwayas + p.suwayasCount) {
        int localSuwaya = globalSuwaya - accumulatedSuwayas;

        double pStartAngle = getAngleForTime(p.startTime);
        double pEndAngle = getAngleForTime(p.endTime);
        double sweep = pEndAngle - pStartAngle;
        if (sweep <= 0) sweep += 2 * pi;

        double anglePerSuwaya = sweep / p.suwayasCount;
        double exactLocal = localSuwaya + (virtualMinute / 30.0);

        return pStartAngle + (exactLocal * anglePerSuwaya);
      }
      accumulatedSuwayas += p.suwayasCount;
    }
    return getAngleForTime(dayEnd);
  }

  for (final r in routines) {
    if (!r.isActive) continue;

    double startAngle = 0;
    double sweepAngle = 0;
    late DateTime startTime;
    late DateTime endTime;

    if (r.isAstroTime) {
      int sPId = r.startPeriodId ?? astroState.periods.first.id;
      int sLocal = r.startSuwaya ?? 1;
      int sm = r.startVirtualMinute ?? 0;

      int ePId = r.endPeriodId ?? astroState.periods.last.id;
      int eLocal = r.endSuwaya ?? 1;
      int em = r.endVirtualMinute ?? 0;

      int getGlobal(int pId, int sNum) {
        int g = 0;
        for (var p in astroState.periods) {
          if (p.id == pId) return g + sNum - 1;
          g += p.suwayasCount;
        }
        return 0;
      }

      int startGlobal = getGlobal(sPId, sLocal);
      int endGlobal = getGlobal(ePId, eLocal);

      DateTime getAstroTime(int periodId, int localSuwaya, int minute) {
        final period = astroState.periods.firstWhere(
          (candidate) => candidate.id == periodId,
          orElse: () => astroState.periods.first,
        );
        final count = period.suwayasCount > 0 ? period.suwayasCount : 1;
        final localIndex = (localSuwaya - 1).clamp(0, count - 1);
        final microsPerSuwaya =
            period.endTime.difference(period.startTime).inMicroseconds ~/ count;
        return period.startTime.add(Duration(
          microseconds: microsPerSuwaya * localIndex +
              (microsPerSuwaya * minute / 30).round(),
        ));
      }

      startTime = getAstroTime(sPId, sLocal, sm);
      endTime = getAstroTime(ePId, eLocal, em);
      if (!endTime.isAfter(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }

      startAngle = getAstroAngle(startGlobal, sm);
      double endAngle = getAstroAngle(endGlobal, em);

      sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * pi;
    } else {
      if (r.startTimeMinutes == null || r.endTimeMinutes == null) continue;

      DateTime getMappedCivilTime(int totalMins) {
        DateTime dt = DateTime.utc(dayStart.year, dayStart.month, dayStart.day,
            totalMins ~/ 60, totalMins % 60);

        if (dt.isBefore(dayStart)) dt = dt.add(const Duration(days: 1));
        if (dt.isAfter(dayEnd)) dt = dt.subtract(const Duration(days: 1));
        if (dt.isBefore(dayStart)) dt = dt.add(const Duration(days: 1));

        return dt;
      }

      startTime = getMappedCivilTime(r.startTimeMinutes!);
      endTime = getMappedCivilTime(r.endTimeMinutes!);

      if (!endTime.isAfter(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }

      startAngle = getAngleForTime(startTime);
      double endAngle = getAngleForTime(endTime);

      sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * pi;
    }

    arcs.add(RoutineArcData(
      id: r.id, // 🌟 تمرير الـ ID للتعرف عليه
      color: Color(r.colorValue),
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      startTime: startTime,
      endTime: endTime,
      pattern: r.pattern,
    ));
  }
  return arcs;
});
