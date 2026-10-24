
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:hijri/hijri_calendar.dart';

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
import 'widgets/add_screen_dialogs.dart';

class UniversalAddScreen extends ConsumerStatefulWidget {
  final int currentPeriodId;
  final int currentSuwaya;
  final int initialTab;
  final TaskModel? existingTask;
  final RoutineModel? existingRoutine;
  final DateTime? initialDate; // 🌟 استقبال التاريخ المختار من شاشة التقويم

  const UniversalAddScreen({
    super.key,
    required this.currentPeriodId,
    required this.currentSuwaya,
    this.initialTab = 0,
    this.existingTask,
    this.existingRoutine,
    this.initialDate,
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
  int _timeMode = 0; // 0: سويعي (Astro), 1: مدني (Civil)

  int _targetGlobalSuwaya = 0;
  int _targetVirtualMinute = 0;

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

  bool _isCandidateTaskTimeInPast({
    required int mode,
    required int candidateGlobalSuwaya,
    required int candidateVirtualMin,
    required int candidateCivilHour,
    required int candidateCivilMin,
  }) {
    if (_tabController.index != 0) return false;

    final astroState = ref.read(astroProvider);
    final cityNow = virtualDateTimeNotifier.value;
    final isAstroMode = mode == 0;

    final logicalToday = SuwayaScheduleEngine.resolveLogicalCivilDate(
      isAstroTime: isAstroMode,
      astroState: astroState,
      civilReference: cityNow,
    );

    final targetCivilDate = _selectedDate != null
        ? CivilDate(
            _selectedDate!.year,
            _selectedDate!.month,
            _selectedDate!.day,
          )
        : logicalToday;

    return SuwayaScheduleEngine.isCandidateTaskTimeInPast(
      isAstroMode: isAstroMode,
      targetDate: targetCivilDate,
      candidateGlobalSuwaya: candidateGlobalSuwaya,
      candidateVirtualMinute: candidateVirtualMin,
      candidateCivilClock: CivilWallClock(
        hour: candidateCivilHour,
        minute: candidateCivilMin,
      ),
      astroState: astroState,
      cityNow: cityNow,
    );
  }

  String _pastTimeErrorMessage(BuildContext context) {
    final trMsg = 'add_screen.past_time_error'.tr();
    if (trMsg != 'add_screen.past_time_error') return trMsg;
    return context.locale.languageCode == 'ar'
        ? 'لا يمكن جدولة مهمة في وقت قد مضى من هذا اليوم'
        : 'Cannot schedule a task in a time that has already passed today';
  }

  int _mapLocalToGlobal(
    int? periodId,
    int? localSuwaya,
    List<AstroPeriod> periods,
  ) =>
      SuwayaCoordinateMapper.localToGlobal(periodId, localSuwaya, periods);

  int _uiToGlobal(int uiHour, bool isNight) =>
      SuwayaCoordinateMapper.uiPhaseToGlobal(uiHour, isNight);

  ({int uiHour, bool isNight}) _globalToUi(int globalIndex) {
    final res = SuwayaCoordinateMapper.globalToUiPhase(globalIndex);
    return (uiHour: res.uiHour, isNight: res.isNight);
  }

  Map<String, int> _mapGlobalToLocal(int global, List<AstroPeriod> periods) {
    final res = SuwayaCoordinateMapper.globalToLocal(global, periods);
    return {'pId': res.periodId, 'sNum': res.localSuwaya};
  }

  void _applyDefaultsForTab(int tabIndex) {
    if (widget.existingTask != null || widget.existingRoutine != null) return;
    final settings = ref.read(settingsProvider);
    if (tabIndex == 1) {
      _alertLevel = settings.defaultHabitAlertLevel;
      _alarmTone = settings.defaultHabitTone;
      _alarmVolume = settings.defaultHabitVolume;
    } else if (tabIndex == 0) {
      _alertLevel = settings.defaultTaskAlertLevel;
      _alarmTone = settings.defaultTaskTone;
      _alarmVolume = settings.defaultTaskVolume;
    }
  }

  @override
  void initState() {
    super.initState();
    final int startTab =
        widget.existingRoutine != null ? 2 : widget.initialTab;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: startTab,
    );
    final cityNow = virtualDateTimeNotifier.value;
    _selectedDate = widget.initialDate ??
        DateTime(cityNow.year, cityNow.month, cityNow.day);

    final periods = ref.read(astroProvider).periods;
    final defaultGlobal = _mapLocalToGlobal(
      widget.currentPeriodId,
      widget.currentSuwaya,
      periods,
    );

    _targetGlobalSuwaya = defaultGlobal;
    _routineStartGlobalSuwaya = defaultGlobal;
    _routineEndGlobalSuwaya = (defaultGlobal + 1) % 24;

    _applyDefaultsForTab(startTab);

    if (widget.existingTask != null) {
      final t = widget.existingTask!;
      _titleController.text = t.title;
      _selectedCategory = t.category;
      _selectedDate = t.targetDate ?? _selectedDate;
      _recurrenceDays = List.from(t.recurrenceDays ?? []);
      _showOnDial = t.showOnDial;
      _alertLevel = t.alarmMode ? 2 : (t.notifyMode ? 1 : 0);
      _alarmTone = t.alarmTone;
      _alarmVolume = t.alarmVolume;

      if (t.isAstroTime) {
        _hasTime = true;
        _timeMode = 0;
        _targetVirtualMinute = t.targetVirtualMinute;
        final localS = t.targetSuwayas.isNotEmpty ? t.targetSuwayas.first : 1;
        _targetGlobalSuwaya = _mapLocalToGlobal(
          t.targetPeriodId,
          localS,
          periods,
        );
      } else if (!t.isAstroTime && t.targetCivilClock != null) {
        _hasTime = true;
        _timeMode = 1;
        _targetCivilHour = t.targetCivilClock!.hour;
        _targetCivilMinute = t.targetCivilClock!.minute;
      }
    }

    if (widget.existingRoutine != null) {
      final r = widget.existingRoutine!;
      _titleController.text = r.title;
      _routineColor = Color(r.colorValue);
      _routinePattern = r.pattern;
      if (r.recurrenceDays != null) {
        _routineRecurrenceDays.addAll(r.recurrenceDays!);
      }
      _alertLevel = r.alertLevel;
      _alarmTone = r.alarmTone;
      _alarmVolume = r.alarmVolume;

      if (r.isAstroTime) {
        _routineTimeMode = 0;
        _routineStartGlobalSuwaya = _mapLocalToGlobal(
          r.startPeriodId,
          r.startSuwaya,
          periods,
        );
        _routineStartVirtualMinute = r.startVirtualMinute ?? 0;
        _routineEndGlobalSuwaya = _mapLocalToGlobal(
          r.endPeriodId,
          r.endSuwaya,
          periods,
        );
        _routineEndVirtualMinute = r.endVirtualMinute ?? 0;
      } else {
        _routineTimeMode = 1;
        if (r.startCivilClock != null) {
          _routineStartCivilHour = r.startCivilClock!.hour;
          _routineStartCivilMinute = r.startCivilClock!.minute;
        }
        if (r.endCivilClock != null) {
          _routineEndCivilHour = r.endCivilClock!.hour;
          _routineEndCivilMinute = r.endCivilClock!.minute;
        }
      }
    }

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _applyDefaultsForTab(_tabController.index);
      }
      setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _availableTones = {
      'assets/audio/default.mp3': 'alerts.default_ring'.tr(),
      'assets/audio/adhan.mp3': 'alerts.makkah_adhan'.tr(),
      'assets/audio/soft.mp3': 'alerts.soft_bell'.tr(),
    };
    if (!_availableTones.containsKey(_alarmTone)) {
      _alarmTone = 'assets/audio/default.mp3';
    }
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

  Future<void> _saveItem() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      HapticFeedback.heavyImpact();
      final isAr = context.locale.languageCode == 'ar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr
                ? 'يرجى كتابة عنوان أولاً قبل الحفظ!'
                : 'Please enter a title before saving!',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_tabController.index == 0 &&
        _isCandidateTaskTimeInPast(
          mode: _timeMode,
          candidateGlobalSuwaya: _targetGlobalSuwaya,
          candidateVirtualMin: _targetVirtualMinute,
          candidateCivilHour: _targetCivilHour,
          candidateCivilMin: _targetCivilMinute,
        )) {
      HapticFeedback.heavyImpact();
      setState(() => _timeError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_pastTimeErrorMessage(context)),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final periods = ref.read(astroProvider).periods;
    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    if (_tabController.index == 2) {
      // 🌟 فحص موحد لصلاحيات الإشعارات والمنبهات قبل حفظ الروتين أو المهمة
    if (_alertLevel >= 1) {
      final permsNotifier = ref.read(permissionsProvider.notifier);
      final hasNotif = await permsNotifier.ensureNotificationPermission();
      final hasExactAlarm = _alertLevel == 2
          ? await permsNotifier.ensureExactAlarmPermission()
          : true;
      if (!mounted) return;
      if (!hasNotif || !hasExactAlarm) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text('add_screen.permissions_required'.tr()),
            backgroundColor: Colors.redAccent,
          ),
        );
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

    // 🌟 فحص موحد لصلاحيات الإشعارات والمنبهات قبل حفظ الروتين أو المهمة
    if (_alertLevel >= 1) {
      final permsNotifier = ref.read(permissionsProvider.notifier);
      final hasNotif = await permsNotifier.ensureNotificationPermission();
      final hasExactAlarm = _alertLevel == 2
          ? await permsNotifier.ensureExactAlarmPermission()
          : true;
      if (!mounted) return;
      if (!hasNotif || !hasExactAlarm) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text('add_screen.permissions_required'.tr()),
            backgroundColor: Colors.redAccent,
          ),
        );
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

  bool _isCivil12HourActive(BuildContext context, String civilTimeFormat) {
    if (civilTimeFormat == civilTimeFormat12Hour) return true;
    if (civilTimeFormat == civilTimeFormat24Hour) return false;
    return !(MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false);
  }

  Future<void> _showTimeDialog(
    Color pColor,
    Color surface,
    Color text, {
    bool isRoutine = false,
    bool isStart = false,
  }) async {
    HapticFeedback.selectionClick();
    final settings = ref.read(settingsProvider);
    final astroState = ref.read(astroProvider);
    final iconMode = settings.suwayaIconMode;
    final bool use12Hour = _isCivil12HourActive(
      context,
      settings.civilTimeFormat,
    );

    int tempMode = isRoutine ? _routineTimeMode : _timeMode;

    // إذا لم يكن المستخدم قد حدد وقتاً بعد، نبدأ العجلات من الوقت الحالي + 5 دقائق لتفادي الوقوع في الماضي
    int defaultGlobalSuwaya = _targetGlobalSuwaya;
    int defaultVirtualMin = _targetVirtualMinute;
    int defaultCivilHour = _targetCivilHour;
    int defaultCivilMin = _targetCivilMinute;

    if (!isRoutine && !_hasTime && astroState.periods.isNotEmpty) {
      final ct = astroState.currentSuwayaTime;
      final curG = ct.phase.isNight
          ? (ct.phaseSlotNumber - 1)
          : (12 + ct.phaseSlotNumber - 1);
      final nextTotalV = (curG * 60 + ct.virtualMinute + 5) % 1440;
      defaultGlobalSuwaya = nextTotalV ~/ 60;
      defaultVirtualMin = nextTotalV % 60;

      final cityNow = virtualDateTimeNotifier.value;
      final nextCivil = cityNow.add(const Duration(minutes: 5));
      defaultCivilHour = nextCivil.hour;
      defaultCivilMin = nextCivil.minute;
    }

    int tGlobalSuwaya = isRoutine
        ? (isStart ? _routineStartGlobalSuwaya : _routineEndGlobalSuwaya)
        : defaultGlobalSuwaya;
    int tVirtualMinute = isRoutine
        ? (isStart ? _routineStartVirtualMinute : _routineEndVirtualMinute)
        : defaultVirtualMin;
    int tCivilHour = isRoutine
        ? (isStart ? _routineStartCivilHour : _routineEndCivilHour)
        : defaultCivilHour;
    int tCivilMinute = isRoutine
        ? (isStart ? _routineStartCivilMinute : _routineEndCivilMinute)
        : defaultCivilMin;

    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isRoutine
                      ? (isStart
                          ? 'add_screen.select_start_time'.tr()
                          : 'add_screen.select_end_time'.tr())
                      : 'add_screen.pin_exact_time'.tr(),
                  style: TextStyle(
                    color: text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (!isRoutine) ...[
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(
                        value: 0,
                        label: Text('ibadat.astro_time'.tr()),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('add_screen.civil'.tr()),
                      ),
                    ],
                    selected: {tempMode},
                    onSelectionChanged: (set) {
                      HapticFeedback.selectionClick();
                      setDialogState(() {
                        tempMode = set.first;
                        dialogError = null;
                      });
                      setState(() {
                        _timeMode = tempMode;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? pColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? pColor
                            : text.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (tempMode == 0)
                  Builder(
                    builder: (context) {
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
                          if (dialogError != null) {
                            setDialogState(() => dialogError = null);
                          }
                        },
                      );
                    },
                  )
                else
                  DoubleWheelPicker(
                    label1: 'add_screen.civil_hour'.tr(),
                    label2: 'add_screen.minute'.tr(),
                    initialVal1: tCivilHour,
                    initialVal2: tCivilMinute,
                    min1: 0,
                    max1: 23,
                    max2: 59,
                    is12HourMode: use12Hour,
                    textColor: text,
                    surfaceColor: surface,
                    onChanged: (h, m) {
                      tCivilHour = h;
                      tCivilMinute = m;
                      if (dialogError != null) {
                        setDialogState(() => dialogError = null);
                      }
                    },
                  ),
                if (dialogError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    dialogError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'common.cancel'.tr(),
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: pColor,
                        ),
                        onPressed: () {
                          // 🌟 منع تأكيد وقت قد مضى في اليوم الحالي للمهام العابرة
                          if (!isRoutine &&
                              _isCandidateTaskTimeInPast(
                                mode: tempMode,
                                candidateGlobalSuwaya: tGlobalSuwaya,
                                candidateVirtualMin: tVirtualMinute,
                                candidateCivilHour: tCivilHour,
                                candidateCivilMin: tCivilMinute,
                              )) {
                            HapticFeedback.heavyImpact();
                            setDialogState(() {
                              dialogError = _pastTimeErrorMessage(context);
                            });
                            return;
                          }

                          setState(() {
                            if (isRoutine) {
                              if (isStart) {
                                _routineStartGlobalSuwaya = tGlobalSuwaya;
                                _routineStartVirtualMinute = tVirtualMinute;
                                _routineStartCivilHour = tCivilHour;
                                _routineStartCivilMinute = tCivilMinute;
                              } else {
                                _routineEndGlobalSuwaya = tGlobalSuwaya;
                                _routineEndVirtualMinute = tVirtualMinute;
                                _routineEndCivilHour = tCivilHour;
                                _routineEndCivilMinute = tCivilMinute;
                              }
                            } else {
                              _hasTime = true;
                              _timeError = false;
                              _timeMode = tempMode;
                              _targetGlobalSuwaya = tGlobalSuwaya;
                              _targetVirtualMinute = tVirtualMinute;
                              _targetCivilHour = tCivilHour;
                              _targetCivilMinute = tCivilMinute;
                            }
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'common.confirm'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDateRecurrenceDialog(
    Color pColor,
    Color surface,
    Color text,
    bool isRoutine,
  ) async {
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
            borderRadius: BorderRadius.circular(24),
          ),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (!isHabit)
                  // 🌟 عرض الرزنامة الهجرية الشبكية (مع تظليل الأيام السابقة بالرمادي) في الوضع السويعي، والرزنامة الميلادية في الوضع المدني
                  (_timeMode == 0
                      ? HijriCalendarDatePicker(
                          initialDate: tempDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          textColor: text,
                          accentColor: pColor,
                          hijriOffsetDays:
                              ref.read(settingsProvider).hijriOffsetDays,
                          onDateChanged: (d) {
                            setDialogState(() => tempDate = d);
                          },
                        )
                      : CalendarDatePicker(
                          initialDate: tempDate.isBefore(
                            DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              DateTime.now().day,
                            ),
                          )
                              ? DateTime.now()
                              : tempDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          onDateChanged: (d) {
                            setDialogState(() => tempDate = d);
                          },
                        ))
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
                          label: Text(
                            DateFormat('EE', safeIntl).format(
                              DateTime(2024, 1, day),
                            ),
                          ),
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
                                    [1, 2, 3, 4, 5, 6, 7]..remove(day),
                                  );
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
                    style: ElevatedButton.styleFrom(backgroundColor: pColor),
                    onPressed: () {
                      if (!isHabit) {
                        setState(() => _selectedDate = tempDate);
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'common.done'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
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

  Widget _buildDashboardGrid(
    Color textColor,
    Color surfaceColor,
    Color accentColor,
    bool isHabit,
  ) {
    String timeStr = 'add_screen.not_set_mandatory'.tr();
    Widget? timePreview;
    final settings = ref.watch(settingsProvider);

    if (_hasTime) {
      if (_timeMode == 1) {
        timePreview = ClockTimeText.civilClock(
          civilClock: CivilWallClock(
            hour: _targetCivilHour,
            minute: _targetCivilMinute,
          ),
          civilTimeFormat: settings.civilTimeFormat,
          locale: context.locale.languageCode,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        );
      } else {
        timePreview = ClockTimeText.suwaya(
          globalSuwayaIndex: _targetGlobalSuwaya,
          virtualMinute: _targetVirtualMinute,
          style: const TextStyle(
            color: Color(0xFFF2C94C),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        );
      }
    }

    String dateStr;
    if (isHabit) {
      dateStr = _recurrenceDays.isEmpty
          ? 'add_screen.daily'.tr()
          : '${_recurrenceDays.length} ${'common.days'.tr()}';
    } else {
      final targetDate = _selectedDate ?? DateTime.now();
      if (_timeMode == 0) {
        // 🌟 تطبيق تصحيح التاريخ الهجري
        final adjustedDate = targetDate.add(
          Duration(days: settings.hijriOffsetDays),
        );
        final hDate = HijriCalendar.fromDate(adjustedDate);
        dateStr =
            '${hDate.hDay} ${'hijri.m${hDate.hMonth}'.tr()} ${hDate.hYear}';
      } else {
        dateStr = DateFormat('yyyy/MM/dd').format(targetDate);
      }
    }

    final isAr = context.locale.languageCode == 'ar';
    String alertStr = _alertLevel == 0
        ? (isAr ? 'بدون إشعار' : 'No Notification')
        : (_alertLevel == 1
            ? (isAr ? 'إشعار على الستارة' : 'Curtain Notification')
            : (isAr ? 'تنبيه' : 'Alarm'));

    return Column(
      children: [
        Row(
          children: [
            _buildGridCard(
              surfaceColor,
              accentColor,
              textColor,
              'add_screen.category_appearance'.tr(),
              _selectedCategory.displayName,
              LucideIcons.palette,
              _showOnDial,
              false,
              () => _showCategoryDialDialog(accentColor, surfaceColor, textColor),
            ),
            const SizedBox(width: 12),
            _buildGridCard(
              surfaceColor,
              accentColor,
              textColor,
              isHabit ? 'add_screen.recurrence'.tr() : 'add_screen.date'.tr(),
              dateStr,
              LucideIcons.calendar,
              false,
              false,
              () => _showDateRecurrenceDialog(
                accentColor,
                surfaceColor,
                textColor,
                false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildGridCard(
              surfaceColor,
              accentColor,
              textColor,
              'add_screen.time'.tr(),
              timeStr,
              LucideIcons.clock,
              _hasTime,
              (_timeError && !_hasTime),
              () => _showTimeDialog(accentColor, surfaceColor, textColor),
              valueWidget: timePreview,
            ),
            const SizedBox(width: 12),
            _buildGridCard(
              surfaceColor,
              accentColor,
              textColor,
              'add_screen.alert'.tr(),
              alertStr,
              _alertLevel == 2 ? LucideIcons.alarm_clock : LucideIcons.bell,
              _alertLevel > 0,
              false,
              () => _showAlertsDialog(accentColor, surfaceColor, textColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoutineDashboardGrid(Color textColor, Color surfaceColor, Color accentColor) {
    String recurrenceStr = _routineRecurrenceDays.isEmpty ? 'add_screen.daily'.tr() : '${_routineRecurrenceDays.length} ${'common.days'.tr()}';
    final settings = ref.watch(settingsProvider);
    
    Widget startPreview; Widget endPreview;
    if (_routineTimeMode == 1) {
      startPreview = ClockTimeText.civilClock(
          civilClock: CivilWallClock(
            hour: _targetCivilHour,
            minute: _targetCivilMinute,
          ),
        civilTimeFormat: settings.civilTimeFormat,
        locale: context.locale.languageCode,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      );
      endPreview = ClockTimeText.civilClock(
          civilClock: CivilWallClock(
            hour: _targetCivilHour,
            minute: _targetCivilMinute,
          ),
        civilTimeFormat: settings.civilTimeFormat,
        locale: context.locale.languageCode,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      );
    } else {
      // 🌟 استخدام ClockTimeText.suwaya لمنع انعكاس السويعات والدقائق في الروتين
      startPreview = ClockTimeText.suwaya(
        globalSuwayaIndex: _routineStartGlobalSuwaya,
        virtualMinute: _routineStartVirtualMinute,
        style: const TextStyle(
          color: Color(0xFFF2C94C),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      );
      endPreview = ClockTimeText.suwaya(
        globalSuwayaIndex: _routineEndGlobalSuwaya,
        virtualMinute: _routineEndVirtualMinute,
        style: const TextStyle(
          color: Color(0xFFF2C94C),
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      );
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

  Future<void> _showRoutinePatternDialog(
    Color pColor,
    Color surface,
    Color text,
  ) =>
      showRoutinePatternModal(
        context: context,
        pColor: pColor,
        surface: surface,
        text: text,
        initialColor: _routineColor,
        initialPattern: _routinePattern,
        availablePatterns: _availablePatterns,
        onChanged: (color, pattern) => setState(() {
          _routineColor = color;
          _routinePattern = pattern;
        }),
      );

  Future<void> _showAlertsDialog(Color pColor, Color surface, Color text) =>
      showAlertsModal(
        context: context,
        pColor: pColor,
        surface: surface,
        text: text,
        initialAlertLevel: _alertLevel,
        initialTone: _alarmTone,
        initialVolume: _alarmVolume,
        availableTones: _availableTones,
        onChanged: (level, tone, vol) => setState(() {
          _alertLevel = level;
          _alarmTone = tone;
          _alarmVolume = vol;
        }),
      );

  Future<void> _showCategoryDialDialog(
    Color pColor,
    Color surface,
    Color text,
  ) =>
      showCategoryDialModal(
        context: context,
        pColor: pColor,
        surface: surface,
        text: text,
        initialCategory: _selectedCategory,
        initialShowOnDial: _showOnDial,
        onChanged: (cat, show) => setState(() {
          _selectedCategory = cat;
          _showOnDial = show;
        }),
      );
  Widget _buildGridCard(
    Color surfaceColor,
    Color accentColor,
    Color textColor,
    String title,
    String value,
    IconData icon,
    bool isHighlighted,
    bool isError,
    VoidCallback? onTap, {
    Widget? valueWidget,
  }) {
    return AddGridCard(
      surfaceColor: surfaceColor,
      accentColor: accentColor,
      textColor: textColor,
      title: title,
      value: value,
      icon: icon,
      isHighlighted: isHighlighted,
      isError: isError,
      onTap: onTap,
      valueWidget: valueWidget,
    );
  }
}