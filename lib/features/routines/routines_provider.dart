import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart'; 

import '../../core/database/local_db_service.dart';
import '../../models/routine_model.dart';
import '../../core/astro_engine/astro_provider.dart';

class RoutineArcData {
  final Color color;
  final double startAngle;
  final double sweepAngle;
  final String pattern;

  RoutineArcData({
    required this.color,
    required this.startAngle,
    required this.sweepAngle,
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
    final db = LocalDbService.isar;
    final routines = await db.routineModels.where().findAll();
    state = List.from(routines);
  }

  Future<void> addRoutine(RoutineModel routine) async {
    final db = LocalDbService.isar;
    
    // 1. الكتابة السريعة للحصول على الـ ID المؤكد
    await db.writeTxn(() async {
      await db.routineModels.put(routine);
    });
    
    // 🌟 2. التحديث التدريجي: حقن العنصر في الذاكرة فوراً دون قراءة القاعدة من الصفر!
    state = [...state.where((r) => r.id != routine.id), routine];
  }

  Future<void> deleteRoutine(int id) async {
    // 🌟 1. التحديث الفوري للواجهة (Optimistic Update): حذف من الذاكرة فوراً لسرعة الاستجابة
    state = state.where((r) => r.id != id).toList();
    
    // 2. التنفيذ في الخلفية (Fire-and-Forget): الحذف من القاعدة بهدوء
    final db = LocalDbService.isar;
    db.writeTxn(() async {
      await db.routineModels.delete(id);
    });
  }
}

final routinesProvider = NotifierProvider<RoutinesNotifier, List<RoutineModel>>(RoutinesNotifier.new);

final routineArcsProvider = Provider<List<RoutineArcData>>((ref) {
  final routines = ref.watch(routinesProvider);
  final astroState = ref.watch(astroProvider);
  final List<RoutineArcData> arcs = [];

  if (astroState.periods.isEmpty) return arcs;

  final dayStart = astroState.periods.first.startTime; 
  final dayEnd = astroState.periods.last.endTime;      
  final totalDayMicro = dayEnd.difference(dayStart).inMicroseconds;

  if (totalDayMicro <= 0) return arcs;

  double getAngleForTime(DateTime t) {
    return -pi / 2 + (t.difference(dayStart).inMicroseconds / totalDayMicro) * 2 * pi;
  }

  double getAstroAngle(int globalSuwaya, int virtualMinute) {
    globalSuwaya %= 48; 
    
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

    if (r.isAstroTime) {
      int s = r.startSuwaya ?? 0;
      int sm = r.startVirtualMinute ?? 0;
      int e = r.endSuwaya ?? 0;
      int em = (r.endVirtualMinute ?? 0) + 1; 

      startAngle = getAstroAngle(s, sm);
      double endAngle = getAstroAngle(e, em);

      sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * pi;

    } else {
      if (r.startTimeMinutes == null || r.endTimeMinutes == null) continue;

      DateTime getMappedCivilTime(int totalMins) {
        DateTime dt = DateTime.utc(
          dayStart.year, dayStart.month, dayStart.day, 
          totalMins ~/ 60, totalMins % 60
        );
        
        if (dt.isBefore(dayStart)) dt = dt.add(const Duration(days: 1));
        if (dt.isAfter(dayEnd)) dt = dt.subtract(const Duration(days: 1));
        if (dt.isBefore(dayStart)) dt = dt.add(const Duration(days: 1));
        
        return dt;
      }

      DateTime startDt = getMappedCivilTime(r.startTimeMinutes!);
      DateTime endDt = getMappedCivilTime(r.endTimeMinutes!);

      if (endDt.isBefore(startDt) || endDt.isAtSameMomentAs(startDt)) {
        endDt = endDt.add(const Duration(days: 1));
      }

      startAngle = getAngleForTime(startDt);
      double endAngle = getAngleForTime(endDt);

      sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * pi;
    }

    arcs.add(RoutineArcData(
      color: Color(r.colorValue),
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      pattern: r.pattern, 
    ));
  }
  return arcs;
});