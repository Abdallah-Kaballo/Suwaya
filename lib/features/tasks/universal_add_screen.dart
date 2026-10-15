import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'tasks_provider.dart';
import '../routines/routines_provider.dart';
import '../../models/task_model.dart';
import '../../models/routine_model.dart';
import '../../core/astro_engine/astro_provider.dart';
import 'package:suwaya_time/suwaya_time.dart';
import '../../core/location/permissions_provider.dart';
import '../../features/settings/settings_provider.dart';
import '../../shared/widgets/suwaya_time_text.dart';
import '../../core/utils/time_formatters.dart';

import 'widgets/add_screen_pickers.dart';
import 'widgets/pattern_preview_painter.dart';

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
  final int currentSuwaya; // هذه القيمة حالياً من 1 إلى 24 أو حسب الفترة
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

class _UniversalAddScreenState extends ConsumerState<UniversalAddScreen>
    with SingleTickerProviderStateMixin {
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
  // 🌟 0: سويعي (Astro), 1: مدني (Civil)
  int _timeMode = 0; 
  
  // المتغيرات السويعية (محولة من وإلى Global 0-23)
  int _targetGlobalSuwaya = 0;
  int _targetVirtualMinute = 0;
  
  // المتغيرات المدنية
  int _targetCivilHour = 8;
  int _targetCivilMinute = 0;

  int _routineTimeMode = 0;
  int _routineStartGlobalSuwaya = 0, _routineStartVirtualMinute = 0;
  int _routineStartCivilHour = 8, _routineStartCivilMinute = 0;
  
  int _routineEndGlobalSuwaya = 1, _routineEndVirtualMinute = 0;
  int _routineEndCivilHour = 10, _routineEndCivilMinute = 0;
  
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

    // افتراضيات (نجلبها من القرص)
    // بما أننا لا نعرف الفهرس العالمي من PeriodId مباشرة، سنفترض 0 مؤقتاً
    _targetGlobalSuwaya = 0; 
    _routineStartGlobalSuwaya = 0;
    _routineEndGlobalSuwaya = 1;

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

      if (t.isAstroTime) {
        _hasTime = true;
        _timeMode = 0;
        // لاستخراج Global Suwaya يجب أن نعلم الفترات
        _targetVirtualMinute = t.targetVirtualMinute;
        // سيتم حسابه لاحقاً داخل Build أو بتمريره
      } else if (!t.isAstroTime && t.targetCivilTimeMinutes != null) {
        _hasTime = true;
        _timeMode = 1; // 1 يعني مدني
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
        _routineTimeMode = 0;
        _routineStartVirtualMinute = r.startVirtualMinute ?? 0;
        _routineEndVirtualMinute = r.endVirtualMinute ?? 0;
      } else {
        _routineTimeMode = 1;
        if (r.startTimeMinutes != null) {
          _routineStartCivilHour = r.startTimeMinutes! ~/ 60;
          _routineStartCivilMinute = r.startTimeMinutes! % 60;
        }
        if (r.endTimeMinutes != null) {
          _routineEndCivilHour = r.endTimeMinutes! ~/ 60;
          _routineEndCivilMinute = r.endTimeMinutes! % 60;
        }
      }
    }

    _tabController.addListener(() => setState(() {}));
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

  @override
  void dispose() {
    _titleController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // 🌟 دوال التحويل بين واجهة المستخدم (1-12 ليل/نهار) والفهرس العالمي (0-23)
  int _uiToGlobal(int uiHour, bool isNight) {
    if (isNight) return uiHour - 1; // 1 ليل -> 0
    return uiHour + 11; // 1 نهار -> 12
  }

  ({int uiHour, bool isNight}) _globalToUi(int globalIndex) {
    globalIndex = globalIndex.clamp(0, 23);
    final isNight = globalIndex < 12;
    final uiHour = isNight ? globalIndex + 1 : globalIndex - 11;
    return (uiHour: uiHour, isNight: isNight);
  }

  Map<String, int> _mapGlobalToLocal(int global, List<AstroPeriod> periods) {
    int remaining = global.clamp(0, 23);
    for (var p in periods) {
      if (remaining < p.suwayasCount) {
        return {'pId': p.id, 'sNum': remaining + 1};
      }
      remaining -= p.suwayasCount;
    }
    if (periods.isEmpty) return {'pId': 1, 'sNum': 1};
    return {'pId': periods.last.id, 'sNum': periods.last.suwayasCount};
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

    final periods = ref.read(astroProvider).periods;
    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    if (_tabController.index == 2) {
      if (_alertLevel >= 1) {
        bool hasPermissions = await ref.read(permissionsProvider.notifier).ensureExactAlarmPermission();
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

      if (_routineTimeMode == 1) { // المدني
        routine.isAstroTime = false;
        routine.startTimeMinutes = (_routineStartCivilHour * 60) + _routineStartCivilMinute;
        routine.endTimeMinutes = (_routineEndCivilHour * 60) + _routineEndCivilMinute;
        routine.startPeriodId = null; routine.startSuwaya = null; routine.startVirtualMinute = null;
        routine.endPeriodId = null; routine.endSuwaya = null; routine.endVirtualMinute = null;
      } else { // السويعي
        routine.isAstroTime = true;
        routine.startTimeMinutes = null; routine.endTimeMinutes = null;

        final sm = _mapGlobalToLocal(_routineStartGlobalSuwaya, periods);
        routine.startPeriodId = sm['pId'];
        routine.startSuwaya = sm['sNum'];
        routine.startVirtualMinute = _routineStartVirtualMinute;
        final em = _mapGlobalToLocal(_routineEndGlobalSuwaya, periods);
        routine.endPeriodId = em['pId'];
        routine.endSuwaya = em['sNum'];
        routine.endVirtualMinute = _routineEndVirtualMinute;
      }

      await ref.read(routinesProvider.notifier).addRoutine(routine);
      if (!mounted) return;
      navigator.pop();
      return;
    }

    if (_alertLevel >= 1) {
      bool hasPermissions = await ref.read(permissionsProvider.notifier).ensureExactAlarmPermission();
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

    if (_hasTime) {
      if (_timeMode == 1) {
        task.isAstroTime = false;
        task.targetCivilTimeMinutes = (_targetCivilHour * 60) + _targetCivilMinute;
        task.targetPeriodId = null; task.targetSuwayas = []; task.targetVirtualMinute = 0;
      } else {
        task.isAstroTime = true;
        task.targetCivilTimeMinutes = null;
        task.targetVirtualMinute = _targetVirtualMinute;
        final mapped = _mapGlobalToLocal(_targetGlobalSuwaya, periods);
        task.targetPeriodId = mapped['pId'];
        task.targetSuwayas = [mapped['sNum']!];
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
    if (!mounted) return;
    navigator.pop();
  }

  Future<void> _showTimeDialog(Color pColor, Color surface, Color text, {bool isRoutine = false, bool isStart = false}) async {
    HapticFeedback.selectionClick();
    final settings = ref.read(settingsProvider);
    final iconMode = settings.suwayaIconMode;

    int tempMode = isRoutine ? _routineTimeMode : _timeMode;
    
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
                Text(
                  isRoutine ? (isStart ? 'add_screen.select_start_time'.tr() : 'add_screen.select_end_time'.tr()) : 'add_screen.pin_exact_time'.tr(),
                  style: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 16),
                if (!isRoutine) ...[
                  // 🌟 تبويبين فقط الآن!
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(value: 0, label: Text('ibadat.astro_time'.tr())),
                      ButtonSegment(value: 1, label: Text('add_screen.civil'.tr()))
                    ],
                    selected: {tempMode},
                    onSelectionChanged: (set) {
                      HapticFeedback.selectionClick();
                      setDialogState(() {
                        tempMode = set.first;
                        _timeMode = tempMode;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? pColor.withValues(alpha: 0.2) : Colors.transparent),
                      foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? pColor : text.withValues(alpha: 0.5))
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (tempMode == 0) // السويعي الجديد
                  Builder(builder: (context) {
                    final uiData = _globalToUi(tGlobalSuwaya);
                    return AstroTimePicker(
                      initialHour: uiData.uiHour,
                      initialMinute: tVirtualMinute,
                      initialIsNight: uiData.isNight,
                      textColor: text,
                      surfaceColor: surface,
                      accentColor: pColor,
                      iconMode: iconMode,
                      onChanged: (h, m, isNight) {
                        tGlobalSuwaya = _uiToGlobal(h, isNight);
                        tVirtualMinute = m;
                      }
                    );
                  })
                else // المدني 
                  DoubleWheelPicker(
                    label1: 'add_screen.civil_hour'.tr(), label2: 'add_screen.minute'.tr(),
                    initialVal1: tCivilHour, initialVal2: tCivilMinute,
                    min1: 0, max1: 23, max2: 59,
                    textColor: text, surfaceColor: surface,
                    onChanged: (h, m) { tCivilHour = h; tCivilMinute = m; }
                  ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)), onPressed: () => Navigator.pop(ctx), child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.redAccent)))),
                    const SizedBox(width: 8),
                    Expanded(flex: 2, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: pColor), onPressed: () {
                      setState(() {
                        if (isRoutine) {
                          if (isStart) {
                            _routineStartGlobalSuwaya = tGlobalSuwaya; _routineStartVirtualMinute = tVirtualMinute;
                            _routineStartCivilHour = tCivilHour; _routineStartCivilMinute = tCivilMinute;
                          } else {
                            _routineEndGlobalSuwaya = tGlobalSuwaya; _routineEndVirtualMinute = tVirtualMinute;
                            _routineEndCivilHour = tCivilHour; _routineEndCivilMinute = tCivilMinute;
                          }
                        } else {
                          _hasTime = true; _timeError = false;
                          _targetGlobalSuwaya = tGlobalSuwaya; _targetVirtualMinute = tVirtualMinute;
                          _targetCivilHour = tCivilHour; _targetCivilMinute = tCivilMinute;
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

  Future<void> _showRoutinePatternDialog(
      Color pColor, Color surface, Color text) async {
    HapticFeedback.selectionClick();
    await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
              builder: (context, setDialogState) => Dialog(
                backgroundColor: surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('add_screen.pattern_and_color'.tr(),
                          style: TextStyle(
                              color: text,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Color(0xFF00E5FF),
                            const Color(0xFF00E676),
                            const Color(0xFFFF3D00),
                            const Color(0xFFFFC400),
                            const Color(0xFFFF4081),
                            const Color(0xFFD500F9),
                          ].map((color) {
                            final isSelected = _routineColor == color;
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() => _routineColor = color);
                                setState(() {});
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white,
                                        width: isSelected ? 3 : 0)),
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
                          leading: CustomPaint(
                              size: const Size(30, 30),
                              painter: PatternPreviewPainter(
                                  entry.key, _routineColor)),
                          title: Text(entry.value,
                              style: TextStyle(
                                  color: isSelected ? pColor : text,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal)),
                          trailing: isSelected
                              ? Icon(LucideIcons.circle_check, color: pColor)
                              : null,
                          onTap: () {
                            setDialogState(() => _routinePattern = entry.key);
                            setState(() {});
                          },
                        );
                      }),
                      const SizedBox(height: 16),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: pColor),
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('common.done'.tr(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ),
              ),
            ));
  }

  Future<void> _showDateRecurrenceDialog(
      Color pColor, Color surface, Color text, bool isRoutine) async {
    HapticFeedback.selectionClick();
    final isHabit = _tabController.index == 1 || isRoutine;
    final activeList = isRoutine ? _routineRecurrenceDays : _recurrenceDays;

    final langCode = context.locale.languageCode;
    final safeIntl = (langCode == 'ff' || langCode == 'ug') ? 'en' : langCode;

    DateTime tempDate = _selectedDate ?? DateTime.now();

    await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
              builder: (context, setDialogState) => Dialog(
                backgroundColor: surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          isHabit
                              ? 'add_screen.recurrence_days'.tr()
                              : 'add_screen.target_date'.tr(),
                          style: TextStyle(
                              color: text,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (!isHabit)
                        CalendarDatePicker(
                          initialDate: tempDate.isBefore(DateTime(
                                  DateTime.now().year,
                                  DateTime.now().month,
                                  DateTime.now().day))
                              ? DateTime.now()
                              : tempDate, 
                          firstDate: DateTime.now(), 
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          onDateChanged: (d) {
                            setDialogState(() => tempDate = d);
                          },
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: Text('add_screen.every_day'.tr()),
                              selected: activeList.isEmpty,
                              selectedColor: pColor.withValues(alpha: 0.2),
                              onSelected: (val) {
                                setDialogState(() {
                                  if (val) activeList.clear();
                                });
                                setState(() {});
                              },
                            ),
                            ...List.generate(7, (index) {
                              final day = index + 1;
                              final isSelected = activeList.contains(day);
                              return FilterChip(
                                label: Text(DateFormat('EE', safeIntl)
                                    .format(DateTime(2024, 1, day))),
                                selected: isSelected,
                                selectedColor: pColor.withValues(alpha: 0.2),
                                onSelected: (val) {
                                  setDialogState(() {
                                    if (val) {
                                      activeList.add(day);
                                      if (activeList.length == 7) {
                                        activeList.clear();
                                      }
                                    } else {
                                      if (activeList.isEmpty) {
                                        activeList.addAll(
                                            [1, 2, 3, 4, 5, 6, 7]..remove(day));
                                      } else {
                                        activeList.remove(day);
                                      }
                                    }
                                  });
                                  setState(() {});
                                },
                              );
                            }),
                          ],
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: pColor),
                              onPressed: () {
                                if (!isHabit) {
                                  setState(() => _selectedDate = tempDate);
                                }
                                Navigator.pop(ctx);
                              },
                              child: Text('common.done'.tr(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ),
              ),
            ));
  }

  Future<void> _showAlertsDialog(
      Color pColor, Color surface, Color text) async {
    HapticFeedback.selectionClick();
    await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
              builder: (context, setDialogState) => Dialog(
                backgroundColor: surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('add_screen.alert_settings'.tr(),
                          style: TextStyle(
                              color: text,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _alertIcon(
                              0,
                              LucideIcons.volume_x,
                              'alerts.silent'.tr(),
                              pColor,
                              text,
                              setDialogState),
                          const SizedBox(width: 8),
                          _alertIcon(
                              1,
                              LucideIcons.bell,
                              'alerts.notification'.tr(),
                              pColor,
                              text,
                              setDialogState),
                          const SizedBox(width: 8),
                          _alertIcon(
                              2,
                              LucideIcons.alarm_clock,
                              'alerts.alarm'.tr(),
                              pColor,
                              text,
                              setDialogState),
                        ],
                      ),
                      if (_alertLevel == 2) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                              color: text.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _alarmTone,
                              dropdownColor: surface,
                              isExpanded: true,
                              items: _availableTones.entries
                                  .map((e) => DropdownMenuItem(
                                      value: e.key,
                                      child: Text(e.value,
                                          style: TextStyle(color: text))))
                                  .toList(),
                              onChanged: (val) {
                                setDialogState(() => _alarmTone = val!);
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Slider(
                            value: _alarmVolume,
                            activeColor: pColor,
                            onChanged: (v) {
                              setDialogState(() => _alarmVolume = v);
                              setState(() {});
                            }),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: pColor),
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('common.done'.tr(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ),
              ),
            ));
  }

  Future<void> _showCategoryDialDialog(
      Color pColor, Color surface, Color text) async {
    HapticFeedback.selectionClick();
    await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
              builder: (context, setDialogState) => Dialog(
                backgroundColor: surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('add_screen.category_and_dial'.tr(),
                          style: TextStyle(
                              color: text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: TaskCategory.values.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            final catColor = _getNeonColor(cat);
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() => _selectedCategory = cat);
                                setState(() {});
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                    color: isSelected
                                        ? catColor.withValues(alpha: 0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: isSelected
                                            ? catColor
                                            : text.withValues(alpha: 0.1))),
                                child: Row(children: [
                                  Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                          color: catColor,
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Text(cat.displayName,
                                      style: TextStyle(color: text))
                                ]),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('add_screen.show_on_dial'.tr(),
                            style: TextStyle(
                                color: text,
                                fontSize: 13,
                                fontWeight: FontWeight.bold)),
                        value: _showOnDial,
                        activeThumbColor: pColor,
                        onChanged: (val) {
                          setDialogState(() => _showOnDial = val);
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: pColor),
                              onPressed: () => Navigator.pop(ctx),
                              child: Text('common.done'.tr(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ),
              ),
            ));
  }

  Widget _alertIcon(int level, IconData icon, String title, Color accent,
      Color text, Function setDialogState) {
    final isActive = _alertLevel == level;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setDialogState(() => _alertLevel = level);
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: isActive
                  ? accent.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isActive ? accent : text.withValues(alpha: 0.1))),
          child: Column(children: [
            Icon(icon,
                color: isActive ? accent : text.withValues(alpha: 0.4),
                size: 20),
            const SizedBox(height: 4),
            Text(title,
                style: TextStyle(
                    color: isActive ? accent : text.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.bold))
          ]),
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
                  controller: _tabController, indicatorSize: TabBarIndicatorSize.tab,
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
                  controller: _titleController, autofocus: true,
                  style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900),
                  decoration: InputDecoration(border: InputBorder.none, hintText: 'add_screen.what_to_add'.tr(), hintStyle: TextStyle(color: textColor.withValues(alpha: 0.3))),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: TabBarView(
                  controller: _tabController, physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildDashboardGrid(textColor, surfaceColor, accentColor, false),
                    _buildDashboardGrid(textColor, surfaceColor, accentColor, true),
                    _buildRoutineDashboardGrid(textColor, surfaceColor, accentColor),
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
                    }, style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Icon(LucideIcons.trash, color: Colors.redAccent)))),
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

  Widget _buildDashboardGrid(Color textColor, Color surfaceColor, Color accentColor, bool isHabit) {
    String timeStr = 'add_screen.not_set_mandatory'.tr();
    Widget? timePreview;
    final settings = ref.watch(settingsProvider);
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    if (_hasTime) {
      if (_timeMode == 1) { // مدني
        timePreview = ClockTimeText.civil(
          civilTime: DateTime(2000, 1, 1, _targetCivilHour, _targetCivilMinute),
          civilTimeFormat: settings.civilTimeFormat,
          locale: context.locale.languageCode,
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        );
      } else { // سويعي 
        timePreview = Text(
          formatSuwayaTime(_targetGlobalSuwaya, _targetVirtualMinute, separator: '|', isRTL: isRTL, iconMode: settings.suwayaIconMode),
          style: const TextStyle(color: Color(0xFFF2C94C), fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
        );
      }
    }

    String dateStr = isHabit ? (_recurrenceDays.isEmpty ? 'add_screen.daily'.tr() : '${_recurrenceDays.length} ${'common.days'.tr()}') : DateFormat('MM/dd').format(_selectedDate!);
    String alertStr = _alertLevel == 0 ? 'alerts.silent'.tr() : (_alertLevel == 1 ? 'alerts.notification'.tr() : 'alerts.alarm'.tr());
    
    return Column(
      children: [
        Row(
          children: [
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.category_appearance'.tr(), _selectedCategory.displayName, LucideIcons.palette, _showOnDial, false, () => _showCategoryDialDialog(accentColor, surfaceColor, textColor)),
            const SizedBox(width: 12),
            _buildGridCard(surfaceColor, accentColor, textColor, isHabit ? 'add_screen.recurrence'.tr() : 'add_screen.date'.tr(), dateStr, LucideIcons.calendar, false, false, () => _showDateRecurrenceDialog(accentColor, surfaceColor, textColor, false)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.time'.tr(), timeStr, LucideIcons.clock, _hasTime, (_timeError && !_hasTime), () => _showTimeDialog(accentColor, surfaceColor, textColor), valueWidget: timePreview),
            const SizedBox(width: 12),
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.alert'.tr(), alertStr, _alertLevel == 2 ? LucideIcons.alarm_clock : LucideIcons.bell, _alertLevel > 0, false, () => _showAlertsDialog(accentColor, surfaceColor, textColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildRoutineDashboardGrid(Color textColor, Color surfaceColor, Color accentColor) {
    String recurrenceStr = _routineRecurrenceDays.isEmpty ? 'add_screen.daily'.tr() : '${_routineRecurrenceDays.length} ${'common.days'.tr()}';
    final settings = ref.watch(settingsProvider);
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    
    Widget startPreview; Widget endPreview;
    if (_routineTimeMode == 1) {
      startPreview = ClockTimeText.civil(civilTime: DateTime(2000, 1, 1, _routineStartCivilHour, _routineStartCivilMinute), civilTimeFormat: settings.civilTimeFormat, locale: context.locale.languageCode, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'));
      endPreview = ClockTimeText.civil(civilTime: DateTime(2000, 1, 1, _routineEndCivilHour, _routineEndCivilMinute), civilTimeFormat: settings.civilTimeFormat, locale: context.locale.languageCode, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'));
    } else {
      startPreview = Text(formatSuwayaTime(_routineStartGlobalSuwaya, _routineStartVirtualMinute, separator: '|', isRTL: isRTL, iconMode: settings.suwayaIconMode), style: const TextStyle(color: Color(0xFFF2C94C), fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'));
      endPreview = Text(formatSuwayaTime(_routineEndGlobalSuwaya, _routineEndVirtualMinute, separator: '|', isRTL: isRTL, iconMode: settings.suwayaIconMode), style: const TextStyle(color: Color(0xFFF2C94C), fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Inter'));
    }

    return Column(
      children: [
        Container(
          width: double.infinity, margin: const EdgeInsets.only(bottom: 16),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 0, label: Text('ibadat.astro_time'.tr())),
              ButtonSegment(value: 1, label: Text('add_screen.civil'.tr()))
            ],
            selected: {_routineTimeMode},
            onSelectionChanged: (set) { HapticFeedback.selectionClick(); setState(() => _routineTimeMode = set.first); },
            style: ButtonStyle(backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor.withValues(alpha: 0.2) : Colors.transparent), foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor : textColor.withValues(alpha: 0.5))),
          ),
        ),
        Row(
          children: [
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.start_time'.tr(), '', LucideIcons.sunset, true, false, () => _showTimeDialog(accentColor, surfaceColor, textColor, isRoutine: true, isStart: true), valueWidget: startPreview),
            const SizedBox(width: 12),
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.end_time'.tr(), '', LucideIcons.sunrise, true, false, () => _showTimeDialog(accentColor, surfaceColor, textColor, isRoutine: true, isStart: false), valueWidget: endPreview),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.pattern_color'.tr(), _availablePatterns[_routinePattern] ?? 'patterns.linear'.tr(), LucideIcons.paint_bucket, true, false, () => _showRoutinePatternDialog(accentColor, surfaceColor, textColor)),
            const SizedBox(width: 12),
            _buildGridCard(surfaceColor, accentColor, textColor, 'add_screen.recurrence'.tr(), recurrenceStr, LucideIcons.calendar_days, false, false, () => _showDateRecurrenceDialog(accentColor, surfaceColor, textColor, true)),
          ],
        ),
      ],
    );
  }

  Widget _buildGridCard(
      Color surfaceColor,
      Color accentColor,
      Color textColor,
      String title,
      String value,
      IconData icon,
      bool isHighlighted,
      bool isError,
      VoidCallback? onTap,
      {Widget? valueWidget}) {
    Color valColor = isError ? Colors.redAccent : textColor;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isError
                      ? Colors.redAccent
                      : (isHighlighted ? accentColor : Colors.transparent),
                  width: 2)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon,
                      color: isError
                          ? Colors.redAccent
                          : (isHighlighted
                              ? accentColor
                              : textColor.withValues(alpha: 0.5)),
                      size: 16),
                  const SizedBox(width: 6),
                  Text(title,
                      style: TextStyle(
                          color: isError
                              ? Colors.redAccent
                              : textColor.withValues(alpha: 0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              valueWidget ??
                  Text(value,
                      style: TextStyle(
                          color: valColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter')),
            ],
          ),
        ),
      ),
    );
  }
}