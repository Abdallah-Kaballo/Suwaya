import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:alarm/alarm.dart';
import 'package:isar_community/isar.dart';

import '../../core/astro_engine/astro_provider.dart';
import '../../core/database/local_db_service.dart';
import '../../models/task_model.dart';
import '../../models/daily_stats_model.dart';
import '../settings/settings_provider.dart';

class TasksState {
  final List<TaskModel> allTasks; 
  final List<TaskModel> nowTasks;  
  final List<TaskModel> todayTasks;
  final List<TaskModel> horizonTasks;
  final bool isLoading;

  const TasksState({
    this.allTasks = const [],
    this.nowTasks = const [],
    this.todayTasks = const [],
    this.horizonTasks = const [],
    this.isLoading = true,
  });
}

class TasksNotifier extends Notifier<TasksState> {
  @override
  TasksState build() {
    ref.listen(astroProvider, (prev, next) {
      if (prev?.currentPeriod.id != next.currentPeriod.id) loadTasks();
    });
    
    Future.microtask(() => loadTasks());
    return const TasksState();
  }

  Map<String, int>? _getDynamicAstro(TaskModel task, AstroState astroState, DateTime now) {
    if (task.isAstroTime && task.targetPeriodId != null) {
      return {'pId': task.targetPeriodId!, 'sNum': task.targetSuwayas.isNotEmpty ? task.targetSuwayas.first : 0};
    }
    if (!task.isAstroTime && task.targetCivilTimeMinutes != null && astroState.periods.isNotEmpty) {
      DateTime dt = DateTime(now.year, now.month, now.day, task.targetCivilTimeMinutes! ~/ 60, task.targetCivilTimeMinutes! % 60);
      final pStart = astroState.periods.first.startTime;
      DateTime pStartNoSecs = DateTime(pStart.year, pStart.month, pStart.day, pStart.hour, pStart.minute);
      
      if (dt.isBefore(pStartNoSecs)) dt = dt.add(const Duration(days: 1));
      if (dt.isAfter(astroState.periods.last.endTime)) dt = dt.subtract(const Duration(days: 1));
      if (dt.isBefore(pStartNoSecs)) dt = dt.add(const Duration(days: 1));

      for (var p in astroState.periods) {
        if ((dt.isAfter(p.startTime) || dt.isAtSameMomentAs(p.startTime)) && (dt.isBefore(p.endTime) || dt.isAtSameMomentAs(p.endTime))) {
          final suwayaDuration = p.endTime.difference(p.startTime).inMicroseconds / (p.suwayasCount > 0 ? p.suwayasCount : 1);
          final elapsed = dt.difference(p.startTime).inMicroseconds;
          int sIndex = (elapsed / suwayaDuration).floor().clamp(0, (p.suwayasCount > 0 ? p.suwayasCount : 1) - 1);
          return {'pId': p.id, 'sNum': sIndex + 1};
        }
      }
    }
    return null;
  }

  Future<List<String>> getUniqueTaskTitles() async {
    final all = await LocalDbService.getAllTasks();
    return all.map((t) => t.title).toSet().toList();
  }

  // 🌟 هنا السر! يتم فلترة المهام المكتملة لكي تختفي من كل التطبيق
  void _refreshFromMemory(List<TaskModel> allTasks) {
    final astroState = ref.read(astroProvider);
    final currentPeriodId = astroState.periods.isNotEmpty ? astroState.currentPeriod.id : null;
    final currentSuwaya = astroState.currentSuwaya;
    final now = DateTime.now();
    final weekday = now.weekday;

    final List<TaskModel> nowList = [];
    final List<TaskModel> todayList = [];
    final List<TaskModel> horizonList = [];

    for (var task in allTasks) {
      // 🌟 الفلترة الجراحية: أي مهمة مكتملة يتم تجاهلها تماماً من القوائم
      if (task.type == TaskType.casual && task.isCompleted) continue;
      if (task.type == TaskType.permanent && task.isCompletedToday) continue;

      final effectiveDays = task.recurrenceDays;
      final dynamicAstro = _getDynamicAstro(task, astroState, now);
      final pId = dynamicAstro?['pId'];
      final sNum = dynamicAstro?['sNum'];
      
      if (task.type == TaskType.permanent) {
        final bool isPermanentToday = effectiveDays == null || effectiveDays.isEmpty || effectiveDays.contains(weekday);
        if (isPermanentToday) {
          todayList.add(task);
          if (pId == currentPeriodId && (sNum == 0 || sNum == currentSuwaya || task.targetSuwayas.contains(-1))) {
            nowList.add(task);
          }
        } else {
          horizonList.add(task);
        }
      } else {
        if (task.targetDate == null) {
          horizonList.add(task);
        } else if (task.targetDate!.year == now.year && task.targetDate!.month == now.month && task.targetDate!.day == now.day) {
          todayList.add(task);
          if (pId == currentPeriodId && (sNum == 0 || sNum == currentSuwaya || task.targetSuwayas.contains(-1))) {
            nowList.add(task);
          }
        } else if (task.targetDate!.isAfter(now)) {
          horizonList.add(task);
        }
      }
    }

    todayList.sort((a, b) {
      final astroA = _getDynamicAstro(a, astroState, now);
      final astroB = _getDynamicAstro(b, astroState, now);
      int periodCompare = (astroA?['pId'] ?? 0).compareTo(astroB?['pId'] ?? 0);
      if (periodCompare != 0) return periodCompare;
      int aSuwaya = astroA?['sNum'] ?? 0;
      int bSuwaya = astroB?['sNum'] ?? 0;
      return aSuwaya.compareTo(bSuwaya);
    });

    nowList.sort((a, b) {
      final astroA = _getDynamicAstro(a, astroState, now);
      final astroB = _getDynamicAstro(b, astroState, now);
      int aSuwaya = astroA?['sNum'] ?? 0;
      int bSuwaya = astroB?['sNum'] ?? 0;
      return aSuwaya.compareTo(bSuwaya);
    });

    state = TasksState(allTasks: allTasks, nowTasks: nowList, todayTasks: todayList, horizonTasks: horizonList, isLoading: false);
  }

  Future<void> loadTasks() async {
    final all = await LocalDbService.getAllTasks();
    _refreshFromMemory(all);
  }

  Future<void> toggleTaskNotification(TaskModel task) async {
    final hasAny = task.notifyMode || task.alarmMode || task.vibrateMode;
    if (hasAny) {
      task.notifyMode = false;
      task.alarmMode = false;
      task.vibrateMode = false;
      Alarm.stop(10000 + task.id); 
    } else {
      task.notifyMode = true; 
    }
    task.isSynced = false;
    final updatedTasks = state.allTasks.map((t) => t.id == task.id ? task : t).toList();
    _refreshFromMemory(updatedTasks);
    LocalDbService.saveTask(task);
  }

  List<TaskModel> getTasksForDate(DateTime date) {
    final weekday = date.weekday;
    return state.allTasks.where((task) {
      if (task.type == TaskType.permanent) {
        final effectiveDays = task.recurrenceDays;
        return effectiveDays == null || effectiveDays.isEmpty || effectiveDays.contains(weekday);
      } else {
        return task.targetDate != null && task.targetDate!.year == date.year && task.targetDate!.month == date.month && task.targetDate!.day == date.day;
      }
    }).toList();
  }

  Future<void> addTask(TaskModel task) async {
    task.isSynced = false;
    await LocalDbService.saveTask(task);
    final updatedList = [...state.allTasks.where((t) => t.id != task.id), task];
    _refreshFromMemory(updatedList);
  }

  Future<void> deleteTask(int id) async {
    final updatedList = state.allTasks.where((t) => t.id != id).toList();
    _refreshFromMemory(updatedList);
    LocalDbService.deleteTask(id);
    Alarm.stop(10000 + id); 
  }

  // 🌟 دالة الحذف الجماعي للمهام المحددة
  Future<void> deleteMultipleTasks(List<int> ids) async {
    final updatedList = state.allTasks.where((t) => !ids.contains(t.id)).toList();
    _refreshFromMemory(updatedList);
    for (var id in ids) {
      LocalDbService.deleteTask(id);
      Alarm.stop(10000 + id);
    }
  }

  Future<void> toggleTaskStatus(TaskModel task) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool isAchievedNow = false;

    if (task.type == TaskType.permanent) {
      final wasCompletedToday = task.isCompletedToday;
      if (!wasCompletedToday) {
        task.lastCompletedDate = today;
        task.completionHistory = [...task.completionHistory, today];
        task.currentStreak = task.completionHistory.length == 1 ? 1 : task.currentStreak + 1;
        if (task.currentStreak > task.longestStreak) task.longestStreak = task.currentStreak;
        isAchievedNow = true;
      } else {
        task.lastCompletedDate = null;
        task.completionHistory = task.completionHistory.where((d) => !(d.year == today.year && d.month == today.month && d.day == today.day)).toList();
        task.currentStreak = (task.currentStreak - 1).clamp(0, 9999);
        isAchievedNow = false;
      }
    } else {
      task.isCompleted = !task.isCompleted;
      task.completedAt = task.isCompleted ? DateTime.now() : null;
      isAchievedNow = task.isCompleted;
    }
    
    task.isSynced = false;
    
    final updatedTasks = state.allTasks.map((t) => t.id == task.id ? task : t).toList();
    _refreshFromMemory(updatedTasks);

    LocalDbService.saveTask(task).then((_) {
      if (isAchievedNow) ref.read(settingsProvider.notifier).updateGlobalStreak();
      _updateDailyStats(task, isAchievedNow);
    });
  }

  Future<void> _updateDailyStats(TaskModel task, bool isCompleted) async {
    final db = LocalDbService.isar;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await db.writeTxn(() async {
      var stats = await db.dailyCosmicStats.where().dateStringEqualTo(todayStr).findFirst();
      stats ??= DailyCosmicStats()..dateString = todayStr;
      final increment = isCompleted ? 1 : -1;
      stats.totalCompleted = (stats.totalCompleted + increment).clamp(0, 99999);
      switch (task.targetPeriodId) {
        case 1: stats.fajrCount = (stats.fajrCount + increment).clamp(0, 9999); break;
        case 2: stats.duhaCount = (stats.duhaCount + increment).clamp(0, 9999); break;
        case 3: stats.dhuhrCount = (stats.dhuhrCount + increment).clamp(0, 9999); break;
        case 4: stats.asrCount = (stats.asrCount + increment).clamp(0, 9999); break;
        case 5: stats.maghribCount = (stats.maghribCount + increment).clamp(0, 9999); break;
        case 6: stats.ishaCount = (stats.ishaCount + increment).clamp(0, 9999); break;
        case 7: stats.qiyamCount = (stats.qiyamCount + increment).clamp(0, 9999); break;
      }
      await db.dailyCosmicStats.put(stats);
    });
  }

  Future<void> rescheduleTask(TaskModel task, int periodId, int suwaya, int vMin) async {
    task.isAstroTime = true;
    task.targetPeriodId = periodId;
    task.targetSuwayas = [suwaya];
    task.targetVirtualMinute = vMin;
    task.targetCivilTimeMinutes = null; 
    task.isSynced = false;

    final updatedTasks = state.allTasks.map((t) => t.id == task.id ? task : t).toList();
    _refreshFromMemory(updatedTasks);
    LocalDbService.saveTask(task);
  }
}

final tasksProvider = NotifierProvider<TasksNotifier, TasksState>(TasksNotifier.new);
final currentTasksProvider = FutureProvider<List<TaskModel>>((ref) async => ref.watch(tasksProvider).nowTasks);