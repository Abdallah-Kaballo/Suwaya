import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suwaya_time/suwaya_time.dart';

import '../../core/astro_engine/astro_provider.dart';
import '../../core/repositories/task_repository.dart';
import '../../core/utils/time_formatters.dart';
import '../../models/task_model.dart';
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
  int _lastObservedCivilDay = -1;

  @override
  TasksState build() {
    // إعادة تحميل المهام عند تغير الفترة الفلكية أو بداية دورة مغرب جديدة
    ref.listen(astroProvider, (prev, next) {
      if (prev?.currentPeriod.id != next.currentPeriod.id ||
          prev?.cycleAnchors.cycleEndMaghrib !=
              next.cycleAnchors.cycleEndMaghrib) {
        loadTasks();
      }
    });

    // مراقبة عبور منتصف الليل المدني (00:00) لتحديث العادات والمهام المدنية فوراً
    void onCivilTimeTick() {
      final currentDay = virtualDateTimeNotifier.value.day;
      if (_lastObservedCivilDay != -1 && _lastObservedCivilDay != currentDay) {
        _lastObservedCivilDay = currentDay;
        if (state.allTasks.isNotEmpty) {
          _refreshFromMemory(state.allTasks);
        }
      } else {
        _lastObservedCivilDay = currentDay;
      }
    }

    virtualDateTimeNotifier.addListener(onCivilTimeTick);
    ref.onDispose(() {
      virtualDateTimeNotifier.removeListener(onCivilTimeTick);
    });

    Future.microtask(() => loadTasks());
    return const TasksState();
  }

  Map<String, int>? _getDynamicAstro(
    TaskModel task,
    AstroState astroState,
    DateTime now,
  ) {
    if (task.isAstroTime && task.targetPeriodId != null) {
      return {
        'pId': task.targetPeriodId!,
        'sNum': task.targetSuwayas.isNotEmpty ? task.targetSuwayas.first : 0,
      };
    }
    if (!task.isAstroTime &&
        task.targetCivilTimeMinutes != null &&
        astroState.periods.isNotEmpty) {
      final pStart = astroState.periods.first.startTime;
      final DateTime pStartNoSecs = DateTime.utc(
        pStart.year,
        pStart.month,
        pStart.day,
        pStart.hour,
        pStart.minute,
      );
      DateTime dt = DateTime.utc(
        pStart.year,
        pStart.month,
        pStart.day,
        task.targetCivilTimeMinutes! ~/ 60,
        task.targetCivilTimeMinutes! % 60,
      );

      if (dt.isBefore(pStartNoSecs)) dt = dt.add(const Duration(days: 1));
      if (dt.isAfter(astroState.periods.last.endTime)) {
        dt = dt.subtract(const Duration(days: 1));
      }
      if (dt.isBefore(pStartNoSecs)) dt = dt.add(const Duration(days: 1));

      for (var p in astroState.periods) {
        if ((dt.isAfter(p.startTime) || dt.isAtSameMomentAs(p.startTime)) &&
            (dt.isBefore(p.endTime) || dt.isAtSameMomentAs(p.endTime))) {
          final suwayaDuration =
              p.endTime.difference(p.startTime).inMicroseconds /
                  (p.suwayasCount > 0 ? p.suwayasCount : 1);
          final elapsed = dt.difference(p.startTime).inMicroseconds;
          int sIndex = (elapsed / suwayaDuration)
              .floor()
              .clamp(0, (p.suwayasCount > 0 ? p.suwayasCount : 1) - 1);
          return {'pId': p.id, 'sNum': sIndex + 1};
        }
      }
    }
    return null;
  }

  Future<List<String>> getUniqueTaskTitles() async {
    final activeTasks = await ref.read(taskRepositoryProvider).getActiveTasks();
    return activeTasks.map((t) => t.title).toSet().toList();
  }

  void _refreshFromMemory(List<TaskModel> allTasks) {
    final astroState = ref.read(astroProvider);
    final currentPeriodId =
        astroState.periods.isNotEmpty ? astroState.currentPeriod.id : null;
    final currentSuwaya = astroState.currentSuwayaTime.periodLocalSlotNumber;
    final cityNow = virtualDateTimeNotifier.value;

    final List<TaskModel> nowList = [];
    final List<TaskModel> todayList = [];
    final List<TaskModel> horizonList = [];

    final Map<int, Map<String, int>> astroCache = {};

    for (var task in allTasks) {
      // 🌟 تحديد اليوم المنطقي للمهمة:
      // - السويعية: تبدأ من مغرب اليوم السابق (تاريخ cycleEndMaghrib)
      // - المدنية: تبدأ من 12:00 منتصف الليل (تاريخ cityNow)
      final logicalToday = getLogicalDateForMode(
        isAstroTime: task.isAstroTime,
        astroState: astroState,
        civilReference: cityNow,
      );
      final logicalWeekday = logicalToday.weekday;

      if (task.type == TaskType.casual && task.isCompleted) continue;
      if (task.type == TaskType.permanent &&
          task.isCompletedOnDate(logicalToday)) {
        continue;
      }

      final effectiveDays = task.recurrenceDays;
      final dynamicAstro = _getDynamicAstro(task, astroState, cityNow);

      if (dynamicAstro != null) astroCache[task.id] = dynamicAstro;

      final pId = dynamicAstro?['pId'];
      final sNum = dynamicAstro?['sNum'];

      if (task.type == TaskType.permanent) {
        final bool isPermanentToday = effectiveDays == null ||
            effectiveDays.isEmpty ||
            effectiveDays.contains(logicalWeekday);
        if (isPermanentToday) {
          todayList.add(task);
          if (pId == currentPeriodId &&
              (sNum == 0 ||
                  sNum == currentSuwaya ||
                  task.targetSuwayas.contains(-1))) {
            nowList.add(task);
          }
        } else {
          horizonList.add(task);
        }
      } else {
        if (task.targetDate == null) {
          horizonList.add(task);
        } else if (task.targetDate!.year == logicalToday.year &&
            task.targetDate!.month == logicalToday.month &&
            task.targetDate!.day == logicalToday.day) {
          todayList.add(task);
          if (pId == currentPeriodId &&
              (sNum == 0 ||
                  sNum == currentSuwaya ||
                  task.targetSuwayas.contains(-1))) {
            nowList.add(task);
          }
        } else if (task.targetDate!.isAfter(logicalToday)) {
          horizonList.add(task);
        }
      }
    }

    todayList.sort((a, b) {
      final astroA = astroCache[a.id];
      final astroB = astroCache[b.id];
      int periodCompare = (astroA?['pId'] ?? 0).compareTo(astroB?['pId'] ?? 0);
      if (periodCompare != 0) return periodCompare;
      int aSuwaya = astroA?['sNum'] ?? 0;
      int bSuwaya = astroB?['sNum'] ?? 0;
      return aSuwaya.compareTo(bSuwaya);
    });

    nowList.sort((a, b) {
      final astroA = astroCache[a.id];
      final astroB = astroCache[b.id];
      int aSuwaya = astroA?['sNum'] ?? 0;
      int bSuwaya = astroB?['sNum'] ?? 0;
      return aSuwaya.compareTo(bSuwaya);
    });

    state = TasksState(
      allTasks: allTasks,
      nowTasks: nowList,
      todayTasks: todayList,
      horizonTasks: horizonList,
      isLoading: false,
    );
  }

  Future<void> loadTasks() async {
    final active = await ref.read(taskRepositoryProvider).getActiveTasks();
    _refreshFromMemory(active);
  }

  Future<void> toggleTaskNotification(TaskModel task) async {
    final hasAny = task.notifyMode || task.alarmMode || task.vibrateMode;
    if (hasAny) {
      task.notifyMode = false;
      task.alarmMode = false;
      task.vibrateMode = false;
    } else {
      task.notifyMode = true;
    }
    final updatedTasks =
        state.allTasks.map((t) => t.id == task.id ? task : t).toList();
    _refreshFromMemory(updatedTasks);
    await ref.read(taskRepositoryProvider).saveTask(task);
  }

  List<TaskModel> getTasksForDate(DateTime date) {
    final weekday = date.weekday;
    return state.allTasks.where((task) {
      if (task.type == TaskType.permanent) {
        final effectiveDays = task.recurrenceDays;
        return effectiveDays == null ||
            effectiveDays.isEmpty ||
            effectiveDays.contains(weekday);
      } else {
        return task.targetDate != null &&
            task.targetDate!.year == date.year &&
            task.targetDate!.month == date.month &&
            task.targetDate!.day == date.day;
      }
    }).toList();
  }

  Future<void> addTask(TaskModel task) async {
    await ref.read(taskRepositoryProvider).saveTask(task);
    final updatedList = [...state.allTasks.where((t) => t.id != task.id), task];
    _refreshFromMemory(updatedList);
  }

  Future<void> deleteTask(int id) async {
    final updatedList = state.allTasks.where((t) => t.id != id).toList();
    _refreshFromMemory(updatedList);
    await ref.read(taskRepositoryProvider).deleteTask(id);
  }

  Future<void> deleteMultipleTasks(List<int> ids) async {
    final updatedList =
        state.allTasks.where((t) => !ids.contains(t.id)).toList();
    _refreshFromMemory(updatedList);
    await ref.read(taskRepositoryProvider).deleteTasks(ids);
  }

  Future<void> toggleTaskStatus(TaskModel task) async {
    final astroState = ref.read(astroProvider);
    final logicalToday = getLogicalDateForMode(
      isAstroTime: task.isAstroTime,
      astroState: astroState,
      civilReference: virtualDateTimeNotifier.value,
    );
    bool isAchievedNow = false;

    if (task.type == TaskType.permanent) {
      final wasCompletedToday = task.isCompletedOnDate(logicalToday);
      if (!wasCompletedToday) {
        task.lastCompletedDate = logicalToday;
        task.completionHistory = [...task.completionHistory, logicalToday];
        task.currentStreak =
            task.completionHistory.length == 1 ? 1 : task.currentStreak + 1;
        if (task.currentStreak > task.longestStreak) {
          task.longestStreak = task.currentStreak;
        }
        isAchievedNow = true;
      } else {
        task.lastCompletedDate = null;
        task.completionHistory = task.completionHistory
            .where((d) => !(d.year == logicalToday.year &&
                d.month == logicalToday.month &&
                d.day == logicalToday.day))
            .toList();
        task.currentStreak = (task.currentStreak - 1).clamp(0, 9999);
        isAchievedNow = false;
      }
    } else {
      task.isCompleted = !task.isCompleted;
      task.completedAt = task.isCompleted ? DateTime.now() : null;
      isAchievedNow = task.isCompleted;
    }

    final updatedTasks =
        state.allTasks.map((t) => t.id == task.id ? task : t).toList();
    _refreshFromMemory(updatedTasks);

    await ref.read(taskRepositoryProvider).saveTask(task);

    try {
      if (isAchievedNow) {
        ref.read(settingsProvider.notifier).updateGlobalStreak();
      }
    } catch (_) {}
  }

  Future<void> rescheduleTask(
    TaskModel task,
    int periodId,
    int suwaya,
    int vMin,
  ) async {
    task.isAstroTime = true;
    task.targetPeriodId = periodId;
    task.targetSuwayas = [suwaya];
    task.targetVirtualMinute = vMin;
    task.targetCivilTimeMinutes = null;

    final updatedTasks =
        state.allTasks.map((t) => t.id == task.id ? task : t).toList();
    _refreshFromMemory(updatedTasks);

    await ref.read(taskRepositoryProvider).saveTask(task);
  }
}

final tasksProvider =
    NotifierProvider<TasksNotifier, TasksState>(TasksNotifier.new);
final currentTasksProvider = FutureProvider<List<TaskModel>>(
  (ref) async => ref.watch(tasksProvider).nowTasks,
);