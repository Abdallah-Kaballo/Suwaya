import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya/core/theme/astro_ui_extensions.dart';
import 'package:suwaya/core/utils/time_formatters.dart';
import 'package:suwaya/features/home/widgets/dial/dial_constants.dart';
import 'package:suwaya/features/home/widgets/dial/dial_models.dart';
import 'package:suwaya/features/home/widgets/dial/painters/background_painters.dart';
import 'package:suwaya/features/home/widgets/dial/painters/dynamic_elements_painters.dart';
import 'package:suwaya/features/home/widgets/dial/painters/rings_painters.dart';
import 'package:suwaya/features/home/widgets/dial/time_speed_indicator.dart';
import 'package:suwaya/features/routines/routines_provider.dart';
import 'package:suwaya/features/settings/settings_provider.dart';
import 'package:suwaya/features/tasks/tasks_provider.dart';
import 'package:suwaya/models/settings_model.dart';

import 'package:suwaya_time/suwaya_time.dart';

import '../../../../core/astro_engine/astro_provider.dart';
import '../../../../models/task_model.dart';
import '../../../../core/theme/dial_design_provider.dart';

class PremiumAstroDial extends ConsumerStatefulWidget {
  final double size;
  final List<RoutineArcData> routineArcs;
  final Function(AstroPeriod)? onPeriodTapped;
  final Future<void> Function(DialSelection)? onItemTapped;

  const PremiumAstroDial({
    super.key,
    required this.size,
    required this.routineArcs,
    this.onPeriodTapped,
    this.onItemTapped,
  });

  @override
  ConsumerState<PremiumAstroDial> createState() => _PremiumAstroDialState();
}

class _PremiumAstroDialState extends ConsumerState<PremiumAstroDial>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> _manualRotation = ValueNotifier(0.0);
  double _previousAngle = 0.0;

  late AnimationController _animController;
  Animation<double>? _anim;

  RenderBox? _cachedBox;
  Offset? _touchStart;
  Timer? _longPressTimer;
  bool _isTaskDragging = false;
  final List<DialTask> _currentDialTasks = [];

  TaskModel? _draggedTask;
  double? _dragAngle;
  String? _highlightedMarkerId;
  int? _highlightedPeriodId;
  Timer? _selectionTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animController.addListener(() {
      if (_anim != null) _manualRotation.value = _anim!.value;
    });
  }

  @override
  void dispose() {
    _manualRotation.dispose();
    _animController.dispose();
    _longPressTimer?.cancel();
    _selectionTimer?.cancel();
    super.dispose();
  }

  void _onPanDown(DragDownDetails details) {
    _animController.stop();
    _cachedBox = context.findRenderObject() as RenderBox?;
    _touchStart = details.globalPosition;
    _isTaskDragging = false;

    _longPressTimer?.cancel();
    _longPressTimer = Timer(const Duration(milliseconds: 400), () {
      _isTaskDragging = true;
      _startTaskDrag(details.globalPosition);
    });

    if (_cachedBox != null) {
      final center = _cachedBox!.size.center(Offset.zero);
      final touch = _cachedBox!.globalToLocal(details.globalPosition);
      _previousAngle = atan2(touch.dy - center.dy, touch.dx - center.dx);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_touchStart != null && !_isTaskDragging) {
      if ((details.globalPosition - _touchStart!).distance > 10.0) {
        _longPressTimer?.cancel();
      }
    }

    if (_cachedBox == null) return;
    final center = _cachedBox!.size.center(Offset.zero);
    final touch = _cachedBox!.globalToLocal(details.globalPosition);
    final currentAngle = atan2(touch.dy - center.dy, touch.dx - center.dx);

    if (_isTaskDragging) {
      final currentTime = ref.read(astroProvider).virtualTime;
      double actualDialAngle =
          (currentAngle - _getCurrentTotalRotation(currentTime)) % (2 * pi);
      if (actualDialAngle < 0) actualDialAngle += 2 * pi;
      setState(() => _dragAngle = actualDialAngle);
    } else {
      double delta = currentAngle - _previousAngle;
      if (delta > pi) delta -= 2 * pi;
      if (delta < -pi) delta += 2 * pi;
      _manualRotation.value += delta;
      _previousAngle = currentAngle;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _longPressTimer?.cancel();
    if (_isTaskDragging) {
      _handleTaskDrop();
    } else {
      _snapBack();
    }
    _isTaskDragging = false;
    _touchStart = null;
  }

  void _onPanCancel() {
    _longPressTimer?.cancel();
    _snapBack();
    setState(() {
      _draggedTask = null;
      _dragAngle = null;
    });
    _isTaskDragging = false;
    _touchStart = null;
  }

  void _snapBack() {
    if (_manualRotation.value != 0.0) {
      _anim = Tween<double>(begin: _manualRotation.value, end: 0.0).animate(
        CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
      );
      _animController.forward(from: 0.0);
    }
  }

  void _startTaskDrag(Offset globalPosition) {
    if (_cachedBox == null) {
      _isTaskDragging = false;
      return;
    }
    final center = _cachedBox!.size.center(Offset.zero);
    final touch = _cachedBox!.globalToLocal(globalPosition);
    final dx = touch.dx - center.dx;
    final dy = touch.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    final R = widget.size / 2;
    if (distance < R * kPeriodR || distance > R * kRailwayR) {
      _isTaskDragging = false;
      return;
    }

    double screenAngle = atan2(dy, dx);
    if (screenAngle < 0) screenAngle += 2 * pi;

    final currentTime = ref.read(astroProvider).virtualTime;
    double actualDialAngle =
        (screenAngle - _getCurrentTotalRotation(currentTime)) % (2 * pi);
    if (actualDialAngle < 0) actualDialAngle += 2 * pi;

    DialTask? closestTask;
    double minDiff = 0.15;
    final astro = ref.read(astroProvider);
    final dayStart = astro.periods.first.startTime;
    final dayEnd = astro.periods.last.endTime;

    for (var dt in _currentDialTasks) {
      double tAngle = timeToAngle(dt.time, dayStart, dayEnd) % (2 * pi);
      if (tAngle < 0) tAngle += 2 * pi;
      double diff = (actualDialAngle - tAngle).abs();
      if (diff > pi) diff = 2 * pi - diff;

      if (diff < minDiff) {
        minDiff = diff;
        closestTask = dt;
      }
    }

    if (closestTask != null) {
      HapticFeedback.heavyImpact();
      setState(() {
        _draggedTask = closestTask!.taskModel;
        _dragAngle = actualDialAngle;
      });
    } else {
      _isTaskDragging = false;
    }
  }

  void _handleTaskDrop() {
    if (_draggedTask == null || _dragAngle == null) return;

    final state = ref.read(astroProvider);
    final dayStart = state.periods.first.startTime;
    final dayEnd = state.periods.last.endTime;

    AstroPeriod? targetPeriod;
    int targetSuwaya = 1;
    int targetVMin = 0;

    for (var period in state.periods) {
      double startA =
          timeToAngle(period.startTime, dayStart, dayEnd) % (2 * pi);
      double endA = timeToAngle(period.endTime, dayStart, dayEnd) % (2 * pi);
      if (startA < 0) startA += 2 * pi;
      if (endA < 0) endA += 2 * pi;

      bool inside = startA < endA
          ? (_dragAngle! >= startA && _dragAngle! <= endA)
          : (_dragAngle! >= startA || _dragAngle! <= endA);

      if (inside) {
        targetPeriod = period;
        double sweep = endA - startA;
        if (sweep < 0) sweep += 2 * pi;
        double relativeAngle = _dragAngle! - startA;
        if (relativeAngle < 0) relativeAngle += 2 * pi;

        double progress = relativeAngle / sweep;
        int sIndex = (progress * period.suwayasCount).round();
        if (sIndex >= period.suwayasCount) {
          sIndex = period.suwayasCount - 1;
        }

        targetSuwaya = sIndex + 1;
        targetVMin = 0;
        break;
      }
    }

    if (targetPeriod != null) {
      HapticFeedback.lightImpact();
      ref.read(tasksProvider.notifier).rescheduleTask(
            _draggedTask!,
            targetPeriod.id,
            targetSuwaya,
            targetVMin,
          );
    }
    setState(() {
      _draggedTask = null;
      _dragAngle = null;
    });
  }

  bool _angleInSweep(double angle, double start, double sweep) {
    var relative = (angle - start) % (2 * pi);
    if (relative < 0) relative += 2 * pi;
    return relative < sweep || (sweep >= 2 * pi && relative <= sweep);
  }

  Future<void> _selectDialItem(DialSelection selection) async {
    _selectionTimer?.cancel();
    setState(() {
      _highlightedMarkerId = selection.type == DialSelectionType.prayer ||
              selection.type == DialSelectionType.task
          ? selection.id
          : null;
      _highlightedPeriodId = selection.type == DialSelectionType.period
          ? int.tryParse(selection.id)
          : null;
    });
    ref.read(highlightedTaskProvider.notifier).state =
        selection.type == DialSelectionType.task
            ? int.tryParse(selection.id)
            : null;
    ref.read(highlightedRoutineProvider.notifier).state =
        selection.type == DialSelectionType.routine
            ? int.tryParse(selection.id)
            : null;

    await widget.onItemTapped?.call(selection);
    if (!mounted) return;
    _selectionTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _highlightedMarkerId = null;
        _highlightedPeriodId = null;
      });
      ref.read(highlightedTaskProvider.notifier).state = null;
      ref.read(highlightedRoutineProvider.notifier).state = null;
    });
  }

  void _handleTap(
    TapUpDetails details,
    AstroState state,
    DateTime dayStart,
    DateTime dayEnd,
    double totalRotation,
    DialDesign design,
  ) {
    if (_cachedBox == null) return;
    final center = _cachedBox!.size.center(Offset.zero);
    final touch = _cachedBox!.globalToLocal(details.globalPosition);
    final dx = touch.dx - center.dx;
    final dy = touch.dy - center.dy;

    double screenAngle = atan2(dy, dx);
    if (screenAngle < 0) screenAngle += 2 * pi;

    double actualDialAngle = (screenAngle - totalRotation) % (2 * pi);
    if (actualDialAngle < 0) actualDialAngle += 2 * pi;

    final distance = sqrt(dx * dx + dy * dy);
    final R = widget.size / 2;

    final periodOuterRadius = R * kPeriodR;
    final periodInnerRadius = R * kInnerR;
    final periodBandWidth = design == DialDesign.minimal
        ? (periodOuterRadius - periodInnerRadius) * 0.4
        : periodOuterRadius - periodInnerRadius;
    final periodDrawRadius = design == DialDesign.minimal
        ? periodInnerRadius + periodBandWidth / 2 + 10
        : periodInnerRadius + periodBandWidth / 2;
    final isOnPeriodRing = design == DialDesign.minimal
        ? (distance - periodDrawRadius).abs() <= periodBandWidth / 2 + 7
        : distance >= periodInnerRadius && distance <= periodOuterRadius;

    if (isOnPeriodRing) {
      for (var period in state.periods) {
        final startAngle =
            timeToAngle(period.startTime, dayStart, dayEnd) % (2 * pi);
        final endAngle =
            timeToAngle(period.endTime, dayStart, dayEnd) % (2 * pi);
        var sweep = endAngle - startAngle;
        if (sweep <= 0) sweep += 2 * pi;
        if (_angleInSweep(actualDialAngle, startAngle, sweep)) {
          HapticFeedback.lightImpact();
          _selectDialItem(
            DialSelection(
              id: period.id.toString(),
              type: DialSelectionType.period,
              title: _periodTitle(period),
              startTime: period.startTime,
              endTime: period.endTime,
              color: period.uiColor,
            ),
          );
          if (widget.onItemTapped == null) {
            widget.onPeriodTapped?.call(period);
          }
          return;
        }
      }
    }

    final markerLayouts = layoutDialMarkers(
      size: Size(widget.size, widget.size),
      ibadat: state.ibadatTimings,
      nightMarkers: _activeNightMarkers(state),
      tasks: _currentDialTasks,
      design: design,
      dayStart: dayStart,
      dayEnd: dayEnd,
    );
    final tappedMarker = hitTestDialMarker(
      position: touch,
      size: Size(widget.size, widget.size),
      totalRotation: totalRotation,
      layouts: markerLayouts,
    );

    if (tappedMarker != null) {
      final item = tappedMarker.item;
      final isTask = item.taskModel != null;
      HapticFeedback.lightImpact();

      DateTime? markerEndTime;
      if (!isTask) {
        for (final np in state.ibadatTimings.nightParts) {
          if (np.id == item.id) {
            markerEndTime = np.endTime;
            break;
          }
        }
      }

      _selectDialItem(
        DialSelection(
          id: isTask ? item.taskModel!.id.toString() : item.id,
          type: isTask ? DialSelectionType.task : DialSelectionType.prayer,
          title: isTask ? item.taskModel!.title : item.text,
          startTime: item.time,
          endTime: markerEndTime,
          color: item.color,
        ),
      );
      return;
    }

    if (distance > periodOuterRadius && distance < R * kRailwayR) {
      final routines = ref.read(routinesProvider);
      for (final arc in widget.routineArcs) {
        if (_angleInSweep(actualDialAngle, arc.startAngle, arc.sweepAngle)) {
          final routine =
              routines.where((item) => item.id == arc.id).firstOrNull;
          if (routine == null) return;
          HapticFeedback.lightImpact();
          _selectDialItem(
            DialSelection(
              id: routine.id.toString(),
              type: DialSelectionType.routine,
              title: routine.title,
              startTime: arc.startTime,
              endTime: arc.endTime,
              color: arc.color,
            ),
          );
          return;
        }
      }
    }
  }

  List<Map<String, dynamic>> _activeNightMarkers(AstroState state) {
    final settings = ref.read(settingsProvider);
    final markers = <Map<String, dynamic>>[];
    for (final part in state.ibadatTimings.nightParts) {
      if (settings.visibleNightParts.contains(part.id)) {
        markers.add({
          'id': part.id,
          'n': ('night_parts.${part.nameKey.replaceAll('np_', '')}').tr(),
          't': part.startTime,
        });
      }
    }
    if (settings.showSunrise) {
      markers.add({
        'id': 'sunrise',
        'n': 'ibadat.sunrise'.tr(),
        't': state.ibadatTimings.sunrise,
      });
    }
    return markers;
  }

  String _periodTitle(AstroPeriod period) {
    switch (period.id) {
      case 1:
        return 'periods.maghrib'.tr();
      case 2:
        return 'periods.isha'.tr();
      case 3:
        return 'periods.qiyam'.tr();
      case 4:
        return 'periods.fajr'.tr();
      case 5:
        return 'periods.duha'.tr();
      case 6:
        return 'periods.dhuhr'.tr();
      case 7:
        return 'periods.asr'.tr();
      default:
        return period.nameKey.tr();
    }
  }

  double _getCurrentTotalRotation(DateTime currentTime) {
    final settings = ref.read(settingsProvider);
    final astro = ref.read(astroProvider);
    if (astro.periods.isEmpty) return 0.0;
    double autoRotationOffset = 0.0;
    final needleAngle = timeToAngle(
      currentTime,
      astro.periods.first.startTime,
      astro.periods.last.endTime,
    );
    if (settings.isDialAutoRotating) {
      autoRotationOffset = -(needleAngle + pi / 2);
    }
    return autoRotationOffset + _manualRotation.value;
  }

  @override
  Widget build(BuildContext context) {
    final astroState = ref.watch(astroProvider);
    final settings = ref.watch(settingsProvider);
    final selectedDesign = ref.watch(dialDesignProvider);
    final highlightedTaskId = ref.watch(highlightedTaskProvider);
    final highlightedRoutineId = ref.watch(highlightedRoutineProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (astroState.periods.isEmpty) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    final dayStart = astroState.periods.first.startTime;
    final dayEnd = astroState.periods.last.endTime;
    final textColor = isDark ? Colors.white : const Color(0xFF0B0F19);

    final activeNightMarkers = _activeNightMarkers(astroState);

    final todayTasks = ref.watch(tasksProvider).todayTasks;
    _currentDialTasks.clear();

    for (var task in todayTasks) {
      if (task.showOnDial) {
        try {
          DateTime? taskTime;
          if (task.isAstroTime && task.targetPeriodId != null) {
            final p = astroState.periods
                .firstWhere((per) => per.id == task.targetPeriodId);
            final suwayaCount = p.suwayasCount > 0 ? p.suwayasCount : 1;
            final int localSuwaya = task.targetSuwayas.isNotEmpty
                ? (task.targetSuwayas.first == -1
                    ? (suwayaCount ~/ 2) + 1
                    : task.targetSuwayas.first)
                : (suwayaCount ~/ 2) + 1;

            taskTime = p.resolveSlotWallTime(
              localSuwaya,
              task.targetVirtualMinute,
            );
          } else if (!task.isAstroTime && task.targetCivilTimeMinutes != null) {
            DateTime pStartNoSecs = DateTime.utc(
              dayStart.year,
              dayStart.month,
              dayStart.day,
              dayStart.hour,
              dayStart.minute,
            );
            DateTime dt = DateTime.utc(
              dayStart.year,
              dayStart.month,
              dayStart.day,
              task.targetCivilTimeMinutes! ~/ 60,
              task.targetCivilTimeMinutes! % 60,
            );
            if (dt.isBefore(pStartNoSecs)) dt = dt.add(const Duration(days: 1));
            if (dt.isAfter(dayEnd)) dt = dt.subtract(const Duration(days: 1));
            if (dt.isBefore(pStartNoSecs)) dt = dt.add(const Duration(days: 1));
            taskTime = dt;
          }
          if (taskTime != null) {
            Color tColor =
                getNeonColorForCategory(task.category, isDark: isDark);
            String formattedName = task.dialShortName ?? task.title;
            _currentDialTasks.add(
              DialTask(
                taskModel: task,
                shortName: formattedName.replaceAll('\n', ' '),
                time: taskTime,
                color: tColor,
              ),
            );
          }
        } catch (_) {}
      }
    }

    // 🌟 الطبقات الهندسية الصامتة (لا تحتوي على نصوص، لذا تُحفظ في RepaintBoundary مستقل)
    final staticGeometryStack = RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildLayer(
            BackgroundPainter(isDark: isDark, design: selectedDesign),
          ),
          if (selectedDesign == DialDesign.classic)
            _buildLayer(IslamicRetePainter(isDark: isDark)),
          if (selectedDesign == DialDesign.geometric)
            _buildLayer(GeometricRetePainter(isDark: isDark)),
          _buildLayer(
            RoutinesRingPainter(
              routineArcs: widget.routineArcs,
              isDark: isDark,
              design: selectedDesign,
              highlightedRoutineId: highlightedRoutineId,
            ),
          ),
        ],
      ),
    );

    final precomputedMarkerLayouts = layoutDialMarkers(
      size: Size(widget.size, widget.size),
      ibadat: astroState.ibadatTimings,
      nightMarkers: activeNightMarkers,
      tasks: List.of(_currentDialTasks),
      design: selectedDesign,
      dayStart: dayStart,
      dayEnd: dayEnd,
    );

    final bool isDayPhase = astroState.currentSuwayaTime.phase.isDay;
    final String effectivePinMode =
        settings.useAstroTimeForIbadat ? settings.dialPinMode : 'civil24';
    final String currentLangCode = context.locale.languageCode;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ValueListenableBuilder<DateTime>(
            valueListenable: virtualDateTimeNotifier,
            builder: (context, liveTime, _) {
              final needleAngle = timeToAngle(liveTime, dayStart, dayEnd);
              final autoRotationOffset =
                  settings.isDialAutoRotating ? -(needleAngle + pi / 2) : 0.0;

              return GestureDetector(
                onPanDown: _onPanDown,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onPanCancel: _onPanCancel,
                onTapUp: (details) => _handleTap(
                  details,
                  astroState,
                  dayStart,
                  dayEnd,
                  autoRotationOffset + _manualRotation.value,
                  selectedDesign,
                ),
                child: AnimatedBuilder(
                  animation: _manualRotation,
                  builder: (context, _) {
                    final totalRotation =
                        autoRotationOffset + _manualRotation.value;

                    return Transform.rotate(
                      angle: totalRotation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          staticGeometryStack,
                          _buildLayer(
                            PeriodRingPainter(
                              periods: astroState.periods,
                              currentPeriod: astroState.currentPeriod,
                              dayStart: dayStart,
                              dayEnd: dayEnd,
                              isDark: isDark,
                              langCode: currentLangCode,
                              design: selectedDesign,
                              highlightedPeriodId: _highlightedPeriodId,
                              totalRotation: totalRotation,
                            ),
                          ),
                          _buildLayer(
                            OuterRingPainter(
                              periods: astroState.periods,
                              dayStart: dayStart,
                              dayEnd: dayEnd,
                              isDark: isDark,
                              design: selectedDesign,
                              pinMode: effectivePinMode,
                              totalRotation: totalRotation,
                            ),
                          ),
                          _buildLayer(
                            DividerRingPainter(
                              periods: astroState.periods,
                              dayStart: dayStart,
                              dayEnd: dayEnd,
                              isDark: isDark,
                              design: selectedDesign,
                            ),
                          ),
                          _buildLayer(
                            RailwayRingPainter(
                              ibadat: astroState.ibadatTimings,
                              nightMarkers: activeNightMarkers,
                              tasks: List.of(_currentDialTasks),
                              periods: astroState.periods,
                              dayStart: dayStart,
                              dayEnd: dayEnd,
                              isDark: isDark,
                              draggedTask: _draggedTask,
                              dragAngle: _dragAngle,
                              langCode: currentLangCode,
                              design: selectedDesign,
                              highlightedTaskId: highlightedTaskId,
                              highlightedMarkerId: _highlightedMarkerId,
                              dialPinMode: effectivePinMode,
                              precomputedLayouts: precomputedMarkerLayouts,
                              totalRotation: totalRotation,
                            ),
                          ),
                          if (selectedDesign == DialDesign.classic)
                            _buildMaghribCrownImage(dayStart, dayEnd),
                          // 🌟 استخدام صورة العقرب المرفقة Hours Hand.png (أو الرسم المبسط في الوضع Minimal)
                          if (selectedDesign == DialDesign.minimal)
                            _buildLayer(
                              DynamicNeedlePainter(
                                currentTime: liveTime,
                                dayStart: dayStart,
                                dayEnd: dayEnd,
                                isDark: isDark,
                                design: selectedDesign,
                              ),
                            )
                          else
                            _buildHoursHandImage(needleAngle),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          _buildCenterGlow(isDark, selectedDesign, isDayPhase),
          _buildCentralTime(astroState, textColor, isDark, settings),
        ],
      ),
    );
  }

  Widget _buildLayer(CustomPainter painter) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: CustomPaint(painter: painter),
      );

  /// 🌟 رسم عقرب الساعة باستخدام الصورة المرفقة (assets/icons/Hours Hand.png)
  /// يمتد العقرب من تحت القرص المركزي (الشمس/القمر) حتى حافة مسار السكة (kRailwayR)
  Widget _buildHoursHandImage(double needleAngle) {
    final double r = widget.size / 2;
    final double startRadius = r * 0.20; // يبدأ من تحت القرص المركزي (0.34 * r)
    final double tipRadius = r * kRailwayR - 4.0; // ينتهي عند حافة مسار السكة
    final double handLength = tipRadius - startRadius;
    final double handWidth = handLength * 0.36;
    final double centerOffsetY = -(startRadius + (handLength / 2));

    return IgnorePointer(
      child: Transform.rotate(
        angle: needleAngle + pi / 2,
        child: Transform.translate(
          offset: Offset(0, centerOffsetY),
          child: Image.asset(
            'assets/icons/Hours Hand.png',
            width: handWidth,
            height: handLength,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  /// 🌟 وضع صورة التاج الإسطرلابي (Astrolabe Crown.png)
  Widget _buildMaghribCrownImage(DateTime dayStart, DateTime dayEnd) {
    final double r = widget.size / 2;
    final double edgeR = r * kRailwayR;
    final double maghribAngle = timeToAngle(dayStart, dayStart, dayEnd);
    const double crownWidth = 22.0;
    const double crownHeight = 20.0;

    return IgnorePointer(
      child: Transform.rotate(
        angle: maghribAngle + pi / 2,
        child: Transform.translate(
          offset: Offset(0, -(edgeR + (crownHeight / 2) - 1.5)),
          child: Image.asset(
            'assets/icons/Astrolabe Crown.png',
            width: crownWidth,
            height: crownHeight,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  Widget _buildCenterGlow(bool isDark, DialDesign design, bool isDayPhase) {
    final double centerDiameter = widget.size * (kInnerR - 0.02);
    final String imagePath = isDayPhase
        ? 'assets/icons/sun.png'
        : 'assets/icons/moon.png';

    return IgnorePointer(
      child: Container(
        width: centerDiameter,
        height: centerDiameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: design == DialDesign.minimal
              ? []
              : [
                  BoxShadow(
                    color: isDark ? Colors.black87 : Colors.black26,
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                  BoxShadow(
                    color: goldBase.withValues(alpha: 0.15),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
        ),
        child: ClipOval(
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              Image.asset(
                imagePath,
                width: centerDiameter,
                height: centerDiameter,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.black.withValues(alpha: isDayPhase ? 0.56 : 0.44),
                      Colors.black.withValues(alpha: isDayPhase ? 0.30 : 0.22),
                    ],
                  ),
                  border: Border.all(
                    color: design == DialDesign.minimal
                        ? (isDark ? Colors.white12 : Colors.black12)
                        : goldBase.withValues(alpha: 0.85),
                    width: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCentralTime(
    AstroState state,
    Color textColor,
    bool isDark,
    SettingsModel settings,
  ) {
    final double centerDiameter = widget.size * (kInnerR - 0.02);
    const Color centerClockColor = Color(0xFFFFF3C4);

    if (!settings.useAstroTimeForIbadat) {
      return IgnorePointer(
        child: SizedBox(
          width: centerDiameter,
          height: centerDiameter,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ValueListenableBuilder<DateTime>(
                valueListenable: virtualDateTimeNotifier,
                builder: (context, liveTime, child) {
                  final String civilTimeString = formatCivilTime(
                    liveTime,
                    format: settings.civilTimeFormat,
                    locale: context.locale.languageCode,
                    context: context,
                  );

                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      civilTimeString,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: centerClockColor,
                        fontFamily: 'Inter',
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                          Shadow(
                            color: Colors.black,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    return IgnorePointer(
      child: SizedBox(
        width: centerDiameter,
        height: centerDiameter,
        child: Directionality(
          textDirection: ui.TextDirection.ltr,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ValueListenableBuilder<String>(
                    valueListenable: virtualTimeNotifier,
                    builder: (context, virtualTime, child) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          virtualTime,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: centerClockColor,
                            fontFamily: 'Inter',
                            letterSpacing: 1.4,
                            fontFeatures: [ui.FontFeature.tabularFigures()],
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 10,
                                offset: Offset(0, 2),
                              ),
                              Shadow(
                                color: Colors.black,
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Align(
                alignment: Alignment(0.0, 0.58),
                child: TimeSpeedIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}