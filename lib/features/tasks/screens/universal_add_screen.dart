import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection; // 🌟
import 'package:alarm/alarm.dart';

import '../tasks_provider.dart';
import '../../routines/routines_provider.dart';
import '../../../models/task_model.dart';
import '../../../models/routine_model.dart';
import '../../../core/astro_engine/astro_provider.dart';
import '../../../core/astro_engine/astro_models.dart';
import '../../../core/services/alarm_service.dart';

Color _getNeonColor(TaskCategory category) {
  final catStr = category.toString().toLowerCase();
  if (catStr.contains('work')) return const Color(0xFF00E5FF);
  if (catStr.contains('study')) return const Color(0xFF00E676);
  if (catStr.contains('sport')) return const Color(0xFFFF3D00);
  if (catStr.contains('worship')) return const Color(0xFFFFC400);
  if (catStr.contains('entertainment')) return const Color(0xFFFF4081);
  if (catStr.contains('personal')) return const Color(0xFFD500F9);
  if (catStr.contains('social')) return const Color(0xFF76FF03);
  return const Color(0xFF18FFFF);
}

class UniversalAddScreen extends ConsumerStatefulWidget {
  final int currentPeriodId;
  final int currentSuwaya;
  final int initialTab;
  final TaskModel? existingTask;
  final RoutineModel? existingRoutine;

  const UniversalAddScreen({
    super.key, 
    required this.currentPeriodId, 
    required this.currentSuwaya, 
    this.initialTab = 0,
    this.existingTask,
    this.existingRoutine,
  });

  @override
  ConsumerState<UniversalAddScreen> createState() => _UniversalAddScreenState();
}

class _UniversalAddScreenState extends ConsumerState<UniversalAddScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();

  TaskCategory _selectedCategory = TaskCategory.work;
  DateTime? _selectedDate;
  List<int> _recurrenceDays = [];
  bool _showOnDial = true;
  bool _timeError = false; 

  int _alertLevel = 1; 
  String _alarmTone = 'assets/audio/default.mp3';
  double _alarmVolume = 1.0;

  bool _hasTime = false;
  int _timeMode = 0; 
  late int _targetPeriodId;
  late int _targetLocalSuwaya;
  int _targetGlobalSuwaya = 0; 
  int _targetVirtualMinute = 0;
  int _targetCivilHour = 8;
  int _targetCivilMinute = 0;

  int _routineTimeMode = 0; 
  late int _routineStartPeriodId;
  late int _routineStartLocalSuwaya;
  int _routineStartGlobalSuwaya = 0, _routineStartVirtualMinute = 0, _routineStartCivilHour = 8, _routineStartCivilMinute = 0;
  late int _routineEndPeriodId;
  late int _routineEndLocalSuwaya;
  int _routineEndGlobalSuwaya = 1, _routineEndVirtualMinute = 0, _routineEndCivilHour = 10, _routineEndCivilMinute = 0;
  String _routinePattern = 'linear';
  Color _routineColor = const Color(0xFF00E5FF);
  final List<int> _routineRecurrenceDays = [];

  late final Map<String, String> _availableTones;
  late final Map<String, String> _availablePatterns;

  @override
  void initState() {
    super.initState();
    int startTab = widget.existingRoutine != null ? 2 : widget.initialTab;
    _tabController = TabController(length: 3, vsync: this, initialIndex: startTab);
    _selectedDate = DateTime.now();

    final periods = ref.read(astroProvider).periods;
    _targetPeriodId = widget.currentPeriodId;
    _targetLocalSuwaya = widget.currentSuwaya;
    _targetGlobalSuwaya = _mapLocalToGlobal(_targetPeriodId, _targetLocalSuwaya, periods);

    _routineStartPeriodId = widget.currentPeriodId;
    _routineStartLocalSuwaya = widget.currentSuwaya;
    _routineStartGlobalSuwaya = _targetGlobalSuwaya;
    _routineEndPeriodId = widget.currentPeriodId;
    _routineEndLocalSuwaya = widget.currentSuwaya < 3 ? widget.currentSuwaya + 1 : widget.currentSuwaya; 
    _routineEndGlobalSuwaya = _targetGlobalSuwaya + 1;

    if (widget.existingTask != null) {
      final t = widget.existingTask!;
      _titleController.text = t.title;
      _selectedCategory = t.category;
      _selectedDate = t.targetDate ?? DateTime.now();
      _recurrenceDays = List.from(t.recurrenceDays ?? []);
      _showOnDial = t.showOnDial;
      _alertLevel = t.alarmMode ? 2 : (t.notifyMode ? 1 : 0);
      _alarmTone = t.alarmTone;
      _alarmVolume = t.alarmVolume;

      if (t.isAstroTime && t.targetPeriodId != null && t.targetSuwayas.isNotEmpty) {
        _hasTime = true; 
        _timeMode = 0;
        _targetPeriodId = t.targetPeriodId!;
        _targetLocalSuwaya = t.targetSuwayas.first;
        _targetVirtualMinute = t.targetVirtualMinute;
        _targetGlobalSuwaya = _mapLocalToGlobal(_targetPeriodId, _targetLocalSuwaya, periods);
      } else if (!t.isAstroTime && t.targetCivilTimeMinutes != null) {
        _hasTime = true; 
        _timeMode = 2;
        _targetCivilHour = t.targetCivilTimeMinutes! ~/ 60;
        _targetCivilMinute = t.targetCivilTimeMinutes! % 60;
      }
    }

    if (widget.existingRoutine != null) {
      final r = widget.existingRoutine!;
      _titleController.text = r.title;
      _routineColor = Color(r.colorValue);
      _routinePattern = r.pattern;
      if (r.recurrenceDays != null) _routineRecurrenceDays.addAll(r.recurrenceDays!);
      _alertLevel = r.alertLevel;
      _alarmTone = r.alarmTone;
      _alarmVolume = r.alarmVolume;

      if (r.isAstroTime) {
        if (r.startPeriodId != null && r.endPeriodId != null) {
          _routineTimeMode = 0;
          _routineStartPeriodId = r.startPeriodId!; _routineStartLocalSuwaya = r.startSuwaya ?? 1; _routineStartVirtualMinute = r.startVirtualMinute ?? 0;
          _routineEndPeriodId = r.endPeriodId!; _routineEndLocalSuwaya = r.endSuwaya ?? 1; _routineEndVirtualMinute = r.endVirtualMinute ?? 0;
          _routineStartGlobalSuwaya = _mapLocalToGlobal(_routineStartPeriodId, _routineStartLocalSuwaya, periods);
          _routineEndGlobalSuwaya = _mapLocalToGlobal(_routineEndPeriodId, _routineEndLocalSuwaya, periods);
        } else {
          _routineTimeMode = 1;
          _routineStartGlobalSuwaya = r.startSuwaya ?? 1; _routineStartVirtualMinute = r.startVirtualMinute ?? 0;
          _routineEndGlobalSuwaya = r.endSuwaya ?? 2; _routineEndVirtualMinute = r.endVirtualMinute ?? 0;
          final sMap = _mapGlobalToLocal(_routineStartGlobalSuwaya, periods);
          _routineStartPeriodId = sMap['pId']!; _routineStartLocalSuwaya = sMap['sNum']!;
          final eMap = _mapGlobalToLocal(_routineEndGlobalSuwaya, periods);
          _routineEndPeriodId = eMap['pId']!; _routineEndLocalSuwaya = eMap['sNum']!;
        }
      } else {
        _routineTimeMode = 2;
        if (r.startTimeMinutes != null) { _routineStartCivilHour = r.startTimeMinutes! ~/ 60; _routineStartCivilMinute = r.startTimeMinutes! % 60; }
        if (r.endTimeMinutes != null) { _routineEndCivilHour = r.endTimeMinutes! ~/ 60; _routineEndCivilMinute = r.endTimeMinutes! % 60; }
      }
    }
    
    _tabController.addListener(() { setState(() {}); });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _availableTones = {
      'assets/audio/default.mp3': 'alerts.default_ring'.tr(),
      'assets/audio/adhan.mp3': 'alerts.makkah_adhan'.tr(),
      'assets/audio/soft.mp3': 'alerts.soft_bell'.tr(),
      'assets/audio/birds.mp3': 'alerts.birds'.tr(),
    };
    _availablePatterns = {
      'linear': 'patterns.linear'.tr(),
      'hexagon': 'patterns.hexagon'.tr(),
      'stone': 'patterns.stone'.tr(),
      'trihex': 'patterns.trihex'.tr(),
    };
  }

  int _mapLocalToGlobal(int pId, int sNum, List<AstroPeriod> periods) {
    int global = 0;
    for (var p in periods) {
      if (p.id == pId) return global + sNum - 1; 
      global += p.suwayasCount;
    }
    return 0;
  }

  Map<String, int> _mapGlobalToLocal(int global, List<AstroPeriod> periods) {
    int remaining = global; 
    for (var p in periods) {
      if (remaining < p.suwayasCount) return {'pId': p.id, 'sNum': remaining + 1};
      remaining -= p.suwayasCount;
    }
    if (periods.isEmpty) return {'pId': 1, 'sNum': 1};
    return {'pId': periods.last.id, 'sNum': periods.last.suwayasCount}; 
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    
    if (_tabController.index != 2 && !_hasTime) {
      HapticFeedback.heavyImpact();
      setState(() => _timeError = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('add_screen.time_required'.tr()), backgroundColor: Colors.redAccent));
      return;
    }

    HapticFeedback.heavyImpact();

    final int themeColorValue = Theme.of(context).primaryColor.toARGB32();
    final periods = ref.read(astroProvider).periods;
    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    if (_tabController.index == 2) {
      if (_alertLevel == 2) {
        bool hasPermissions = await AlarmService.checkAndRequestPermissions();
        if (!mounted) return;
        if (!hasPermissions) {
          scaffold.showSnackBar(SnackBar(content: Text('add_screen.permissions_required'.tr()), backgroundColor: Colors.redAccent));
          return;
        }
      }

      final routine = widget.existingRoutine ?? RoutineModel();
      routine.title = title;
      routine.colorValue = _routineColor.toARGB32();
      routine.pattern = _routinePattern;
      routine.isActive = true;
      routine.recurrenceDays = _routineRecurrenceDays.isEmpty ? null : _routineRecurrenceDays;
      routine.alertLevel = _alertLevel;
      routine.alarmTone = _alarmTone;
      routine.alarmVolume = _alarmVolume;

      if (_routineTimeMode == 2) {
        routine.isAstroTime = false;
        routine.startTimeMinutes = (_routineStartCivilHour * 60) + _routineStartCivilMinute;
        routine.endTimeMinutes = (_routineEndCivilHour * 60) + _routineEndCivilMinute;
        routine.startPeriodId = null; routine.startSuwaya = null; routine.startVirtualMinute = null;
        routine.endPeriodId = null; routine.endSuwaya = null; routine.endVirtualMinute = null;
      } else {
        routine.isAstroTime = true;
        routine.startTimeMinutes = null;
        routine.endTimeMinutes = null;

        if (_routineTimeMode == 1) {
          final sm = _mapGlobalToLocal(_routineStartGlobalSuwaya, periods);
          routine.startPeriodId = sm['pId']; routine.startSuwaya = sm['sNum']; routine.startVirtualMinute = _routineStartVirtualMinute;
          final em = _mapGlobalToLocal(_routineEndGlobalSuwaya, periods);
          routine.endPeriodId = em['pId']; routine.endSuwaya = em['sNum']; routine.endVirtualMinute = _routineEndVirtualMinute;
        } else {
          routine.startPeriodId = _routineStartPeriodId; routine.startSuwaya = _routineStartLocalSuwaya; routine.startVirtualMinute = _routineStartVirtualMinute;
          routine.endPeriodId = _routineEndPeriodId; routine.endSuwaya = _routineEndLocalSuwaya; routine.endVirtualMinute = _routineEndVirtualMinute;
        }
      }

      await ref.read(routinesProvider.notifier).addRoutine(routine);
      if (!mounted) return;
      navigator.pop();
      return;
    }

    if (_alertLevel == 2) {
      bool hasPermissions = await AlarmService.checkAndRequestPermissions();
      if (!mounted) return; 
      if (!hasPermissions) {
        scaffold.showSnackBar(SnackBar(content: Text('add_screen.permissions_required'.tr()), backgroundColor: Colors.redAccent));
        return; 
      }
    }

    final task = widget.existingTask ?? TaskModel();
    task.title = title;
    task.type = _tabController.index == 1 ? TaskType.permanent : TaskType.casual;
    task.category = _selectedCategory;
    task.showOnDial = _showOnDial;
    task.dialShortName = _showOnDial ? (title.length > 6 ? title.substring(0, 6) : title) : '';
    
    task.alarmMode = _alertLevel == 2;
    task.notifyMode = _alertLevel >= 1;
    task.vibrateMode = _alertLevel == 2; 
    task.alarmTone = _alarmTone;
    task.alarmVolume = _alarmVolume;

    DateTime? exactAlarmTime;
    
    if (_hasTime) {
      DateTime baseDate = _selectedDate ?? DateTime.now();

      if (_timeMode == 2) {
        task.isAstroTime = false;
        task.targetCivilTimeMinutes = (_targetCivilHour * 60) + _targetCivilMinute;
        task.targetPeriodId = null;
        task.targetSuwayas = [];
        task.targetVirtualMinute = 0;

        exactAlarmTime = DateTime(baseDate.year, baseDate.month, baseDate.day, _targetCivilHour, _targetCivilMinute);
        if (exactAlarmTime.isBefore(DateTime.now())) exactAlarmTime = exactAlarmTime.add(const Duration(days: 1));
      } else {
        task.isAstroTime = true;
        task.targetCivilTimeMinutes = null;
        task.targetVirtualMinute = _targetVirtualMinute;

        if (_timeMode == 1) {
          final mapped = _mapGlobalToLocal(_targetGlobalSuwaya, periods);
          task.targetPeriodId = mapped['pId'];
          task.targetSuwayas = [mapped['sNum']!];
        } else {
          task.targetPeriodId = _targetPeriodId;
          task.targetSuwayas = [_targetLocalSuwaya];
        }

        if (periods.isNotEmpty && task.targetPeriodId != null) {
          try {
            final p = periods.firstWhere((per) => per.id == task.targetPeriodId);
            final microPerSuwaya = p.endTime.difference(p.startTime).inMicroseconds ~/ (p.suwayasCount > 0 ? p.suwayasCount : 1);
            final microPerVirtualMin = microPerSuwaya ~/ 30;
            int sIndex = task.targetSuwayas.first - 1;
            
            DateTime calculatedTime = p.startTime.add(Duration(microseconds: (microPerSuwaya * sIndex) + (microPerVirtualMin * _targetVirtualMinute)));
            exactAlarmTime = DateTime(baseDate.year, baseDate.month, baseDate.day, calculatedTime.hour, calculatedTime.minute);
            
            if (calculatedTime.day != p.startTime.day) exactAlarmTime = exactAlarmTime.add(const Duration(days: 1));
            if (exactAlarmTime.isBefore(DateTime.now())) exactAlarmTime = exactAlarmTime.add(const Duration(days: 1));
          } catch (_) {}
        }
      }
    }

    if (task.type == TaskType.casual) {
      task.targetDate = _selectedDate;
      task.recurrenceDays = null;
    } else {
      task.targetDate = null;
      task.recurrenceDays = _recurrenceDays.isEmpty ? null : _recurrenceDays;
    }

    await ref.read(tasksProvider.notifier).addTask(task);

    final int targetAlarmId = 10000 + task.id;
    if ((task.alarmMode || task.notifyMode) && exactAlarmTime != null) {
      await AlarmService.scheduleAlarm(
        id: targetAlarmId, dateTime: exactAlarmTime, title: task.title,
        colorValue: themeColorValue, 
        tonePath: task.alarmTone, volume: task.alarmVolume,
        fullScreenIntent: task.alarmMode, vibrate: task.vibrateMode,        
      );
    } else {
      await Alarm.stop(targetAlarmId); 
    }

    if (!mounted) return; 
    navigator.pop();
  }

  Future<void> _showTimeDialog(Color pColor, Color surface, Color text, List<AstroPeriod> periods, {bool isRoutine = false, bool isStart = false}) async {
    HapticFeedback.selectionClick();
    
    int tempMode = isRoutine ? _routineTimeMode : _timeMode;
    int tPeriodId = isRoutine ? (isStart ? _routineStartPeriodId : _routineEndPeriodId) : _targetPeriodId;
    int tLocalSuwaya = isRoutine ? (isStart ? _routineStartLocalSuwaya : _routineEndLocalSuwaya) : _targetLocalSuwaya;
    int tGlobalSuwaya = isRoutine ? (isStart ? _routineStartGlobalSuwaya : _routineEndGlobalSuwaya) : _targetGlobalSuwaya;
    int tVirtualMinute = isRoutine ? (isStart ? _routineStartVirtualMinute : _routineEndVirtualMinute) : _targetVirtualMinute;
    int tCivilHour = isRoutine ? (isStart ? _routineStartCivilHour : _routineEndCivilHour) : _targetCivilHour;
    int tCivilMinute = isRoutine ? (isStart ? _routineStartCivilMinute : _routineEndCivilMinute) : _targetCivilMinute;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isRoutine ? (isStart ? 'add_screen.select_start_time'.tr() : 'add_screen.select_end_time'.tr()) : 'add_screen.pin_exact_time'.tr(), style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                if (!isRoutine) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<int>(
                      segments: [ButtonSegment(value: 0, label: Text('add_screen.by_periods'.tr())), ButtonSegment(value: 1, label: Text('add_screen.cumulative'.tr())), ButtonSegment(value: 2, label: Text('add_screen.civil'.tr()))],
                      selected: {tempMode},
                      onSelectionChanged: (set) { 
                        HapticFeedback.selectionClick(); 
                        setDialogState(() { 
                          tempMode = set.first; 
                          _timeMode = tempMode;
                        }); 
                      },
                      style: ButtonStyle(backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? pColor.withValues(alpha: 0.2) : Colors.transparent), foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? pColor : text.withValues(alpha: 0.5))),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (tempMode == 0)
                  _TripleWheelPicker(periods: periods, initialPeriodId: tPeriodId, initialSuwaya: tLocalSuwaya, initialMinute: tVirtualMinute, textColor: text, surfaceColor: surface, onChanged: (pId, sNum, vMin) { tPeriodId = pId; tLocalSuwaya = sNum; tVirtualMinute = vMin; })
                else if (tempMode == 1)
                  _DoubleWheelPicker(label1: 'add_screen.cumulative_suwaya'.tr(), label2: 'add_screen.minute'.tr(), initialVal1: tGlobalSuwaya, initialVal2: tVirtualMinute, min1: 0, max1: 47, max2: 30, textColor: text, surfaceColor: surface, onChanged: (s, m) { tGlobalSuwaya = s; tVirtualMinute = m; })
                else
                  _DoubleWheelPicker(label1: 'add_screen.civil_hour'.tr(), label2: 'add_screen.minute'.tr(), initialVal1: tCivilHour, initialVal2: tCivilMinute, min1: 0, max1: 23, max2: 59, textColor: text, surfaceColor: surface, onChanged: (h, m) { tCivilHour = h; tCivilMinute = m; }),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)), onPressed: () { Navigator.pop(ctx); }, child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.redAccent)))),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: pColor), onPressed: () { 
                      setState(() {
                        if (isRoutine) {
                          if (isStart) { _routineStartPeriodId = tPeriodId; _routineStartLocalSuwaya = tLocalSuwaya; _routineStartGlobalSuwaya = tGlobalSuwaya; _routineStartVirtualMinute = tVirtualMinute; _routineStartCivilHour = tCivilHour; _routineStartCivilMinute = tCivilMinute; }
                          else { _routineEndPeriodId = tPeriodId; _routineEndLocalSuwaya = tLocalSuwaya; _routineEndGlobalSuwaya = tGlobalSuwaya; _routineEndVirtualMinute = tVirtualMinute; _routineEndCivilHour = tCivilHour; _routineEndCivilMinute = tCivilMinute; }
                        } else {
                          _hasTime = true; _timeError = false; 
                          _targetPeriodId = tPeriodId; _targetLocalSuwaya = tLocalSuwaya; _targetGlobalSuwaya = tGlobalSuwaya; _targetVirtualMinute = tVirtualMinute; _targetCivilHour = tCivilHour; _targetCivilMinute = tCivilMinute;
                        }
                      });
                      Navigator.pop(ctx); 
                    }, child: Text('common.confirm'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                  ],
                )
              ],
            ),
          ),
        ),
      )
    );
  }

  Future<void> _showRoutinePatternDialog(Color pColor, Color surface, Color text) async {
    HapticFeedback.selectionClick();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('add_screen.pattern_and_color'.tr(), style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Color(0xFF00E5FF), const Color(0xFF00E676), const Color(0xFFFF3D00),
                      const Color(0xFFFFC400), const Color(0xFFFF4081), const Color(0xFFD500F9),
                    ].map((color) {
                      final isSelected = _routineColor == color;
                      return GestureDetector(
                        onTap: () { setDialogState(() => _routineColor = color); setState((){}); },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12), width: 36, height: 36,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: isSelected ? 3 : 0)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                ..._availablePatterns.entries.map((entry) {
                  final isSelected = _routinePattern == entry.key;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CustomPaint(size: const Size(30, 30), painter: _PatternPreviewPainter(entry.key, _routineColor)),
                    title: Text(entry.value, style: TextStyle(color: isSelected ? pColor : text, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    trailing: isSelected ? Icon(LucideIcons.circle_check, color: pColor) : null,
                    onTap: () { setDialogState(() => _routinePattern = entry.key); setState((){}); },
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: pColor), onPressed: () => Navigator.pop(ctx), child: Text('common.done'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ),
      )
    );
  }

  Future<void> _showDateRecurrenceDialog(Color pColor, Color surface, Color text, bool isRoutine) async {
    HapticFeedback.selectionClick();
    final isHabit = _tabController.index == 1 || isRoutine;
    final activeList = isRoutine ? _routineRecurrenceDays : _recurrenceDays;
    
    final langCode = context.locale.languageCode;
    final safeIntl = (langCode == 'ff' || langCode == 'ug') ? 'en' : langCode;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isHabit ? 'add_screen.recurrence_days'.tr() : 'add_screen.target_date'.tr(), style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                if (!isHabit)
                  CalendarDatePicker(
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    onDateChanged: (d) { setDialogState(() => _selectedDate = d); setState(() {}); },
                  )
                else
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text('add_screen.every_day'.tr()), selected: activeList.isEmpty, selectedColor: pColor.withValues(alpha: 0.2),
                        onSelected: (val) { setDialogState(() { if (val) activeList.clear(); }); setState(() {}); },
                      ),
                      ...List.generate(7, (index) {
                        final day = index + 1; final isSelected = activeList.contains(day);
                        return FilterChip(
                          label: Text(DateFormat('EE', safeIntl).format(DateTime(2024, 1, day))), selected: isSelected, selectedColor: pColor.withValues(alpha: 0.2),
                          onSelected: (val) {
                            setDialogState(() { 
                              if (val) { activeList.add(day); if (activeList.length == 7) activeList.clear(); } 
                              else { if (activeList.isEmpty) { activeList.addAll([1, 2, 3, 4, 5, 6, 7]..remove(day)); } else { activeList.remove(day); } } 
                            });
                            setState(() {});
                          },
                        );
                      }),
                    ],
                  ),
                
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: pColor), onPressed: () => Navigator.pop(ctx), child: Text('common.done'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ),
      )
    );
  }

  Future<void> _showAlertsDialog(Color pColor, Color surface, Color text) async {
    HapticFeedback.selectionClick();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('add_screen.alert_settings'.tr(), style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    _alertIcon(0, LucideIcons.volume_x, 'alerts.silent'.tr(), pColor, text, setDialogState),
                    const SizedBox(width: 8),
                    _alertIcon(1, LucideIcons.bell, 'alerts.notification'.tr(), pColor, text, setDialogState),
                    const SizedBox(width: 8),
                    _alertIcon(2, LucideIcons.alarm_clock, 'alerts.alarm'.tr(), pColor, text, setDialogState),
                  ],
                ),
                
                if (_alertLevel == 2) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(color: text.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _alarmTone, dropdownColor: surface, isExpanded: true,
                        items: _availableTones.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: TextStyle(color: text)))).toList(),
                        onChanged: (val) { setDialogState(() => _alarmTone = val!); setState((){}); },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Slider(value: _alarmVolume, activeColor: pColor, onChanged: (v) { setDialogState(() => _alarmVolume = v); setState((){}); }),
                ],
                
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: pColor), onPressed: () => Navigator.pop(ctx), child: Text('common.done'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ),
      )
    );
  }

  Future<void> _showCategoryDialDialog(Color pColor, Color surface, Color text) async {
    HapticFeedback.selectionClick();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('add_screen.category_and_dial'.tr(), style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: TaskCategory.values.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      final catColor = _getNeonColor(cat);
                      return GestureDetector(
                        onTap: () { setDialogState(() => _selectedCategory = cat); setState((){}); },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: isSelected ? catColor.withValues(alpha: 0.2) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? catColor : text.withValues(alpha: 0.1))),
                          child: Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)), const SizedBox(width: 6), Text(cat.displayName, style: TextStyle(color: text))]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('add_screen.show_on_dial'.tr(), style: TextStyle(color: text, fontSize: 13, fontWeight: FontWeight.bold)),
                  value: _showOnDial, 
                  activeThumbColor: pColor, 
                  onChanged: (val) { setDialogState(() => _showOnDial = val); setState((){}); },
                ),
                
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: pColor), onPressed: () => Navigator.pop(ctx), child: Text('common.done'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
        ),
      )
    );
  }

  Widget _alertIcon(int level, IconData icon, String title, Color accent, Color text, Function setDialogState) {
    final isActive = _alertLevel == level;
    return Expanded(
      child: GestureDetector(
        onTap: () { setDialogState(() => _alertLevel = level); setState((){}); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isActive ? accent.withValues(alpha: 0.15) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? accent : text.withValues(alpha: 0.1))),
          child: Column(children: [Icon(icon, color: isActive ? accent : text.withValues(alpha: 0.4), size: 20), const SizedBox(height: 4), Text(title, style: TextStyle(color: isActive ? accent : text.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.bold))]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : const Color(0xFFF5F7FA);
    final surfaceColor = isDark ? const Color(0xFF13131A) : Colors.white;
    final accentColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final periods = ref.watch(astroProvider).periods;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.x, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text('add_screen.new_addition'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: accentColor.withValues(alpha: 0.1))),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14), border: Border.all(color: accentColor, width: 2)),
                  labelColor: accentColor, unselectedLabelColor: textColor.withValues(alpha: 0.4),
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: [Tab(text: 'tasks.casual_task'.tr()), Tab(text: 'tasks.continuous_habit'.tr()), Tab(text: 'tasks.routine_period'.tr())],
                ),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: accentColor.withValues(alpha: 0.2))),
                child: TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900),
                  decoration: InputDecoration(border: InputBorder.none, hintText: 'add_screen.what_to_add'.tr(), hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3))),
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(), 
                  children: [
                    _buildDashboardGrid(textColor, surfaceColor, accentColor, periods, false), 
                    _buildDashboardGrid(textColor, surfaceColor, accentColor, periods, true),  
                    _buildRoutineDashboardGrid(textColor, surfaceColor, accentColor, periods),  
                  ],
                ),
              ),

              Row(
                children: [
                  if (widget.existingTask != null || widget.existingRoutine != null) ...[
                    Expanded(flex: 1, child: SizedBox(height: 60, child: OutlinedButton(onPressed: () { 
                      if (widget.existingTask != null) {
                        ref.read(tasksProvider.notifier).deleteTask(widget.existingTask!.id); 
                      } else if (widget.existingRoutine != null) {
                        ref.read(routinesProvider.notifier).deleteRoutine(widget.existingRoutine!.id);
                      }
                      Navigator.pop(context); 
                    }, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Icon(LucideIcons.trash_2, color: Colors.redAccent)))),
                    const SizedBox(width: 12),
                  ],
                  Expanded(flex: 3, child: SizedBox(height: 60, child: ElevatedButton(onPressed: _saveItem, style: ElevatedButton.styleFrom(backgroundColor: accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: Text('add_screen.save_and_add'.tr(), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardGrid(Color textColor, Color surfaceColor, Color accentColor, List<AstroPeriod> periods, bool isHabit) {
    String timeStr = 'add_screen.not_set_mandatory'.tr();
    if (_hasTime) {
      if (_timeMode == 2) {
        timeStr = '${_targetCivilHour.toString().padLeft(2, '0')}:${_targetCivilMinute.toString().padLeft(2, '0')}';
      } else if (_timeMode == 1) {
        timeStr = '${_targetGlobalSuwaya.toString().padLeft(2, '0')}:${_targetVirtualMinute.toString().padLeft(2, '0')}';
      } else {
        int pIndex = periods.indexWhere((p) => p.id == _targetPeriodId);
        if (pIndex == -1) pIndex = 0;
        timeStr = '${pIndex.toString().padLeft(2, '0')}:${_targetLocalSuwaya.toString().padLeft(2, '0')}:${_targetVirtualMinute.toString().padLeft(2, '0')}';
      }
    }

    String dateStr = isHabit ? (_recurrenceDays.isEmpty ? 'add_screen.daily'.tr() : '${_recurrenceDays.length} ${'common.days'.tr()}') : DateFormat('MM/dd').format(_selectedDate!);
    String alertStr = _alertLevel == 0 ? 'alerts.silent'.tr() : (_alertLevel == 1 ? 'alerts.notification'.tr() : 'alerts.alarm'.tr());
    String catStr = _selectedCategory.displayName;

    return Column(
      children: [
        Row(
          children: [
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.category_appearance'.tr(), catStr, LucideIcons.palette, _showOnDial, false, () => _showCategoryDialDialog(accentColor, surfaceColor, textColor)),
            const SizedBox(width: 12),
            _buildGridCard(surfaceColor, accentColor, textColor, isHabit ? 'add_screen.recurrence'.tr() : 'add_screen.date'.tr(), dateStr, LucideIcons.calendar, false, false, () => _showDateRecurrenceDialog(accentColor, surfaceColor, textColor, false)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.time'.tr(), timeStr, LucideIcons.clock, _hasTime, (_timeError && !_hasTime), () => _showTimeDialog(accentColor, surfaceColor, textColor, periods)),
            const SizedBox(width: 12),
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.alert'.tr(), alertStr, _alertLevel == 2 ? LucideIcons.alarm_clock : LucideIcons.bell, _alertLevel > 0, false, () => _showAlertsDialog(accentColor, surfaceColor, textColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildRoutineDashboardGrid(Color textColor, Color surfaceColor, Color accentColor, List<AstroPeriod> periods) {
    String recurrenceStr = _routineRecurrenceDays.isEmpty ? 'add_screen.daily'.tr() : '${_routineRecurrenceDays.length} ${'common.days'.tr()}';
    
    String startStr = '', endStr = '';
    
    if (_routineTimeMode == 2) {
      startStr = '${_routineStartCivilHour.toString().padLeft(2, '0')}:${_routineStartCivilMinute.toString().padLeft(2, '0')}';
      endStr = '${_routineEndCivilHour.toString().padLeft(2, '0')}:${_routineEndCivilMinute.toString().padLeft(2, '0')}';
    } else if (_routineTimeMode == 1) {
      startStr = '${_routineStartGlobalSuwaya.toString().padLeft(2, '0')}:${_routineStartVirtualMinute.toString().padLeft(2, '0')}';
      endStr = '${_routineEndGlobalSuwaya.toString().padLeft(2, '0')}:${_routineEndVirtualMinute.toString().padLeft(2, '0')}';
    } else {
      int sIndexStart = periods.indexWhere((p) => p.id == _routineStartPeriodId);
      if (sIndexStart == -1) sIndexStart = 0;
      startStr = '${sIndexStart.toString().padLeft(2, '0')}:${_routineStartLocalSuwaya.toString().padLeft(2, '0')}:${_routineStartVirtualMinute.toString().padLeft(2, '0')}';
      
      int sIndexEnd = periods.indexWhere((p) => p.id == _routineEndPeriodId);
      if (sIndexEnd == -1) sIndexEnd = 0;
      endStr = '${sIndexEnd.toString().padLeft(2, '0')}:${_routineEndLocalSuwaya.toString().padLeft(2, '0')}:${_routineEndVirtualMinute.toString().padLeft(2, '0')}';
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text('add_screen.by_periods'.tr())), 
              ButtonSegment(value: 1, label: Text('add_screen.cumulative_suwaya'.tr())), 
              ButtonSegment(value: 2, label: Text('add_screen.civil'.tr()))
            ],
            selected: {_routineTimeMode},
            onSelectionChanged: (set) { 
              HapticFeedback.selectionClick(); 
              setState(() => _routineTimeMode = set.first); 
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor.withValues(alpha: 0.2) : Colors.transparent), 
              foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor : textColor.withValues(alpha: 0.5))
            ),
          ),
        ),
        Row(
          children: [
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.start_time'.tr(), startStr, LucideIcons.sunset, true, false, () => _showTimeDialog(accentColor, surfaceColor, textColor, periods, isRoutine: true, isStart: true)),
            const SizedBox(width: 12),
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.end_time'.tr(), endStr, LucideIcons.sunrise, true, false, () => _showTimeDialog(accentColor, surfaceColor, textColor, periods, isRoutine: true, isStart: false)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.pattern_color'.tr(), _availablePatterns[_routinePattern] ?? 'خطوط', LucideIcons.paint_bucket, true, false, () => _showRoutinePatternDialog(accentColor, surfaceColor, textColor)),
            const SizedBox(width: 12),
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.recurrence'.tr(), recurrenceStr, LucideIcons.calendar_days, false, false, () => _showDateRecurrenceDialog(accentColor, surfaceColor, textColor, true)),
          ],
        ),
      ],
    );
  }

  Widget _buildGridCard(Color surfaceColor, Color accentColor, Color textColor, String title, String value, IconData icon, bool isHighlighted, bool isError, VoidCallback? onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor, 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(
              color: isError ? Colors.redAccent : (isHighlighted ? accentColor : Colors.transparent), 
              width: 2
            )
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: isError ? Colors.redAccent : (isHighlighted ? accentColor : textColor.withValues(alpha: 0.5)), size: 16),
                  const SizedBox(width: 6),
                  Text(title, style: TextStyle(color: isError ? Colors.redAccent : textColor.withValues(alpha: 0.5), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              Text(value, style: TextStyle(color: isError ? Colors.redAccent : textColor, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatternPreviewPainter extends CustomPainter {
  final String pattern;
  final Color color;
  _PatternPreviewPainter(this.pattern, this.color);
  
  @override 
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rRect = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(rRect, Paint()..color = color.withValues(alpha: 0.2)..style = PaintingStyle.fill);
    canvas.drawRRect(rRect, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
    
    final p = Paint()..color = color..strokeWidth = 2;
    if (pattern == 'linear') {
      canvas.drawLine(const Offset(0, 10), const Offset(30, 10), p);
      canvas.drawLine(const Offset(0, 20), const Offset(30, 20), p);
    } else if (pattern == 'hexagon') {
      canvas.drawLine(const Offset(0, 0), const Offset(30, 30), p);
      canvas.drawLine(const Offset(30, 0), const Offset(0, 30), p);
    } else if (pattern == 'stone') {
      canvas.drawCircle(const Offset(10, 10), 3, p);
      canvas.drawCircle(const Offset(20, 20), 3, p);
    } else {
      canvas.drawLine(const Offset(15, 0), const Offset(15, 30), p);
      canvas.drawLine(const Offset(0, 15), const Offset(30, 15), p);
    }
  }
  @override bool shouldRepaint(covariant CustomPainter old) => true;
}

class _TripleWheelPicker extends StatefulWidget {
  final List<AstroPeriod> periods; 
  final int initialPeriodId; 
  final int initialSuwaya; 
  final int initialMinute;
  final Function(int pId, int sNum, int min) onChanged; 
  final Color textColor; 
  final Color surfaceColor;
  
  const _TripleWheelPicker({
    required this.periods, required this.initialPeriodId, required this.initialSuwaya, 
    required this.initialMinute, required this.onChanged, required this.textColor, 
    required this.surfaceColor
  });
  
  @override 
  State<_TripleWheelPicker> createState() => _TripleWheelPickerState();
}

class _TripleWheelPickerState extends State<_TripleWheelPicker> {
  late int selectedPeriodIndex, selectedSuwaya, selectedMinute;
  late FixedExtentScrollController _periodController, _suwayaController, _minuteController;
  
  @override 
  void initState() {
    super.initState();
    selectedPeriodIndex = widget.periods.indexWhere((p) => p.id == widget.initialPeriodId);
    if (selectedPeriodIndex == -1) { selectedPeriodIndex = 0; }
    selectedSuwaya = widget.initialSuwaya; 
    selectedMinute = widget.initialMinute;
    _periodController = FixedExtentScrollController(initialItem: selectedPeriodIndex);
    _suwayaController = FixedExtentScrollController(initialItem: selectedSuwaya);
    _minuteController = FixedExtentScrollController(initialItem: 10000 * 30 + selectedMinute);
  }
  
  @override 
  void dispose() { 
    _periodController.dispose(); 
    _suwayaController.dispose(); 
    _minuteController.dispose(); 
    super.dispose(); 
  }

  String _getCustomPeriodName(int idx) {
    switch (idx) {
      case 0: return 'periods.fajr'.tr();
      case 1: return 'periods.duha'.tr();
      case 2: return 'periods.dhuhr'.tr();
      case 3: return 'periods.asr'.tr();
      case 4: return 'periods.maghrib'.tr();
      case 5: return 'periods.middle_third'.tr();
      case 6: return 'periods.last_third'.tr();
      default: return '${'common.period'.tr()} ${idx + 1}';
    }
  }

  @override 
  Widget build(BuildContext context) {
    if (widget.periods.isEmpty) return const SizedBox.shrink();
    AstroPeriod currentPeriod = widget.periods[selectedPeriodIndex];
    int maxSuwayas = currentPeriod.suwayasCount > 0 ? currentPeriod.suwayasCount : 1;
    
    final headerStyle = TextStyle(color: widget.textColor.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Expanded(flex: 3, child: Center(child: Text('common.period'.tr(), style: headerStyle))),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: Center(child: Text('common.suwaya'.tr(), style: headerStyle))),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: Center(child: Text('add_screen.minute'.tr(), style: headerStyle))),
          ]
        ),
      ),
      const SizedBox(height: 8),
      Directionality(
        textDirection: TextDirection.ltr, 
        child: SizedBox(height: 140, child: Row(children: [
          Expanded(
            flex: 3, 
            child: CupertinoPicker.builder(
              scrollController: _periodController, 
              itemExtent: 40, 
              onSelectedItemChanged: (i) { 
                HapticFeedback.selectionClick(); 
                setState(() { 
                  selectedPeriodIndex = i; 
                  if (selectedSuwaya > widget.periods[i].suwayasCount - 1) { 
                    selectedSuwaya = widget.periods[i].suwayasCount - 1; 
                    _suwayaController.jumpToItem(selectedSuwaya); 
                  } 
                }); 
                widget.onChanged(widget.periods[i].id, selectedSuwaya, selectedMinute); 
              }, 
              childCount: widget.periods.length, 
              itemBuilder: (ctx, idx) => Center(
                child: Text(
                  '${idx.toString().padLeft(2, '0')}(${_getCustomPeriodName(idx)})', 
                  style: TextStyle(color: widget.textColor, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')
                )
              )
            )
          ),
          Text(':', style: TextStyle(color: widget.textColor.withValues(alpha: 0.3), fontSize: 24, fontWeight: FontWeight.bold)),
          
          Expanded(
            flex: 2, 
            child: CupertinoPicker.builder(
              scrollController: _suwayaController, 
              itemExtent: 40, 
              onSelectedItemChanged: (i) { 
                HapticFeedback.selectionClick(); 
                selectedSuwaya = i; 
                widget.onChanged(widget.periods[selectedPeriodIndex].id, selectedSuwaya, selectedMinute); 
              }, 
              childCount: maxSuwayas, 
              itemBuilder: (ctx, idx) => Center(
                child: Text(
                  idx.toString().padLeft(2, '0'), 
                  style: TextStyle(color: widget.textColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace')
                )
              )
            )
          ),
          Text(':', style: TextStyle(color: widget.textColor.withValues(alpha: 0.3), fontSize: 24, fontWeight: FontWeight.bold)),
          
          Expanded(
            flex: 2, 
            child: CupertinoPicker.builder(
              scrollController: _minuteController, 
              itemExtent: 40, 
              onSelectedItemChanged: (i) { 
                HapticFeedback.selectionClick(); 
                selectedMinute = i % 30; 
                widget.onChanged(widget.periods[selectedPeriodIndex].id, selectedSuwaya, selectedMinute); 
              }, 
              itemBuilder: (ctx, idx) => Center(
                child: Text(
                  (idx % 30).toString().padLeft(2, '0'), 
                  style: TextStyle(color: widget.textColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace')
                )
              )
            )
          ),
        ]))
      )
    ]);
  }
}

class _DoubleWheelPicker extends StatefulWidget {
  final String label1, label2; final int initialVal1, initialVal2, min1, max1, max2;
  final Function(int, int) onChanged; final Color textColor, surfaceColor;
  const _DoubleWheelPicker({required this.label1, required this.label2, required this.initialVal1, required this.initialVal2, required this.min1, required this.max1, required this.max2, required this.onChanged, required this.textColor, required this.surfaceColor});
  @override State<_DoubleWheelPicker> createState() => _DoubleWheelPickerState();
}
class _DoubleWheelPickerState extends State<_DoubleWheelPicker> {
  late int val1, val2; late FixedExtentScrollController _controller1, _controller2;
  @override void initState() {
    super.initState();
    val1 = widget.initialVal1; val2 = widget.initialVal2;
    int range1 = widget.max1 - widget.min1 + 1;
    _controller1 = FixedExtentScrollController(initialItem: 10000 * range1 + (val1 - widget.min1));
    _controller2 = FixedExtentScrollController(initialItem: 10000 * widget.max2 + val2);
  }
  @override void dispose() { 
    _controller1.dispose(); 
    _controller2.dispose(); 
    super.dispose(); 
  }
  @override Widget build(BuildContext context) {
    int range1 = widget.max1 - widget.min1 + 1;
    final headerStyle = TextStyle(color: widget.textColor.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Expanded(child: Center(child: Text(widget.label1, style: headerStyle))),
            const SizedBox(width: 24),
            Expanded(child: Center(child: Text(widget.label2, style: headerStyle))),
          ]
        ),
      ),
      const SizedBox(height: 8),
      Directionality(
        textDirection: TextDirection.ltr, 
        child: SizedBox(height: 140, child: Row(children: [
          Expanded(child: CupertinoPicker.builder(scrollController: _controller1, itemExtent: 40, onSelectedItemChanged: (i) { HapticFeedback.selectionClick(); val1 = (i % range1) + widget.min1; widget.onChanged(val1, val2); }, itemBuilder: (ctx, idx) => Center(child: Text(((idx % range1) + widget.min1).toString().padLeft(2, '0'), style: TextStyle(color: widget.textColor, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace'))))),
          Text(':', style: TextStyle(color: widget.textColor.withValues(alpha: 0.3), fontSize: 24, fontWeight: FontWeight.bold)),
          Expanded(child: CupertinoPicker.builder(scrollController: _controller2, itemExtent: 40, onSelectedItemChanged: (i) { HapticFeedback.selectionClick(); val2 = i % widget.max2; widget.onChanged(val1, val2); }, itemBuilder: (ctx, idx) => Center(child: Text((idx % widget.max2).toString().padLeft(2, '0'), style: TextStyle(color: widget.textColor, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'monospace'))))),
        ]))
      )
    ]);
  }
}