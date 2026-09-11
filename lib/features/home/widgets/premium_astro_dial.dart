import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya/features/home/widgets/dial/dial_constants.dart';
import 'package:suwaya/features/home/widgets/dial/dial_models.dart';
import 'package:suwaya/features/home/widgets/dial/painters/background_painters.dart';
import 'package:suwaya/features/home/widgets/dial/painters/dynamic_elements_painters.dart';
import 'package:suwaya/features/home/widgets/dial/painters/rings_painters.dart';
import 'package:suwaya/features/home/widgets/dial/time_speed_indicator.dart';
import 'package:suwaya/features/routines/routines_provider.dart';
import 'package:suwaya/features/settings/settings_provider.dart';
import 'package:suwaya/features/tasks/tasks_provider.dart';

import 'package:suwaya_time/suwaya_time.dart';

import '../../../../core/astro_engine/astro_provider.dart';
import '../../../../models/task_model.dart'; 
import '../../../../core/theme/dial_design_provider.dart';


class PremiumAstroDial extends ConsumerStatefulWidget {
  final double size;
  final List<RoutineArcData> routineArcs; 
  final Function(AstroPeriod)? onPeriodTapped;

  const PremiumAstroDial({
    super.key, 
    required this.size, 
    required this.routineArcs, 
    this.onPeriodTapped
  });

  @override
  ConsumerState<PremiumAstroDial> createState() => _PremiumAstroDialState();
}

class _PremiumAstroDialState extends ConsumerState<PremiumAstroDial> with SingleTickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animController.addListener(() { 
      if (_anim != null) _manualRotation.value = _anim!.value; 
    });
    // 🌟 تم حذف المؤقت الداخلي الثقيل، نحن الآن نعتمد على المحرك مباشرة!
  }

  @override
  void dispose() {
    _manualRotation.dispose();
    _animController.dispose();
    _longPressTimer?.cancel();
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
      double actualDialAngle = (currentAngle - _getCurrentTotalRotation(currentTime)) % (2 * pi);
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
    setState(() { _draggedTask = null; _dragAngle = null; });
    _isTaskDragging = false;
    _touchStart = null;
  }

  void _snapBack() {
    if (_manualRotation.value != 0.0) {
      _anim = Tween<double>(begin: _manualRotation.value, end: 0.0).animate(CurvedAnimation(parent: _animController, curve: Curves.elasticOut));
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
    double actualDialAngle = (screenAngle - _getCurrentTotalRotation(currentTime)) % (2 * pi);
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
      double startA = timeToAngle(period.startTime, dayStart, dayEnd) % (2 * pi);
      double endA = timeToAngle(period.endTime, dayStart, dayEnd) % (2 * pi);
      if (startA < 0) startA += 2 * pi;
      if (endA < 0) endA += 2 * pi;

      bool inside = startA < endA ? (_dragAngle! >= startA && _dragAngle! <= endA) : (_dragAngle! >= startA || _dragAngle! <= endA);

      if (inside) {
        targetPeriod = period;
        double sweep = endA - startA;
        if (sweep < 0) sweep += 2 * pi;
        double relativeAngle = _dragAngle! - startA;
        if (relativeAngle < 0) relativeAngle += 2 * pi;
        
        double progress = relativeAngle / sweep;
        double suwayaFloat = progress * period.suwayasCount;
        
        int sIndex = suwayaFloat.floor();
        targetSuwaya = sIndex + 1;
        targetVMin = ((suwayaFloat - sIndex) * 30).round().clamp(0, 29);
        break;
      }
    }

    if (targetPeriod != null) {
      HapticFeedback.lightImpact(); 
      ref.read(tasksProvider.notifier).rescheduleTask(_draggedTask!, targetPeriod.id, targetSuwaya, targetVMin);
    }
    setState(() { _draggedTask = null; _dragAngle = null; });
  }

  void _handleTap(TapUpDetails details, AstroState state, DateTime dayStart, DateTime dayEnd, double totalRotation) {
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

    if (distance >= R * kPeriodR && distance <= R * kOuterR) {
      DialTask? tappedTask;
      double minDiff = 0.08; 
      for (var dt in _currentDialTasks) {
        double tAngle = timeToAngle(dt.time, dayStart, dayEnd) % (2 * pi);
        if (tAngle < 0) tAngle += 2 * pi;
        double diff = (actualDialAngle - tAngle).abs();
        if (diff > pi) diff = 2 * pi - diff;
        if (diff < minDiff) {
          minDiff = diff;
          tappedTask = dt;
        }
      }
      
      if (tappedTask != null) {
        HapticFeedback.lightImpact();
        ref.read(highlightedTaskProvider.notifier).state = tappedTask.taskModel.id;
        Future.delayed(const Duration(seconds: 3), () {
          if (ref.read(highlightedTaskProvider) == tappedTask!.taskModel.id) {
            ref.read(highlightedTaskProvider.notifier).state = null;
          }
        });
        return; 
      }
    }

    for (var period in state.periods) {
      double startA = timeToAngle(period.startTime, dayStart, dayEnd) % (2 * pi);
      double endA = timeToAngle(period.endTime, dayStart, dayEnd) % (2 * pi);
      if (startA < 0) startA += 2 * pi;
      if (endA < 0) endA += 2 * pi;
      
      bool inside = startA < endA ? (actualDialAngle >= startA && actualDialAngle <= endA) : (actualDialAngle >= startA || actualDialAngle <= endA);
      if (inside) {
        if (widget.onPeriodTapped != null) widget.onPeriodTapped!(period);
        break;
      }
    }
  }

  double _getCurrentTotalRotation(DateTime currentTime) {
    final settings = ref.read(settingsProvider);
    final astro = ref.read(astroProvider);
    if (astro.periods.isEmpty) return 0.0;
    double autoRotationOffset = 0.0;
    final needleAngle = timeToAngle(currentTime, astro.periods.first.startTime, astro.periods.last.endTime);
    if (settings.isDialAutoRotating) autoRotationOffset = -(needleAngle + pi / 2);
    return autoRotationOffset + _manualRotation.value;
  }

  @override
  Widget build(BuildContext context) {
    final astroState = ref.watch(astroProvider);
    final settings = ref.watch(settingsProvider);
    final selectedDesign = ref.watch(dialDesignProvider);
    final highlightedTaskId = ref.watch(highlightedTaskProvider);
    
    // 🌟 المتغير الذهبي لحل مشكلة تزامن العقرب! يقرأ الوقت مباشرة من المحرك.
    final currentTime = astroState.virtualTime; 
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = context.locale.languageCode; 

    if (astroState.periods.isEmpty) return SizedBox(width: widget.size, height: widget.size);

    final dayStart = astroState.periods.first.startTime;
    final dayEnd = astroState.periods.last.endTime;
    final textColor = isDark ? Colors.white : const Color(0xFF0B0F19);
    
    List<Map<String, dynamic>> activeNightMarkers = [];
    for (var part in astroState.ibadatTimings.nightParts) {
      if (settings.activeNightMarkers.contains(part.nameKey)) {
        activeNightMarkers.add({'n': ('night_parts.${part.nameKey.replaceAll("np_", "")}').tr(), 't': part.startTime});
      }
    }

    if (settings.showSunrise) {
      activeNightMarkers.add({
        'n': 'ibadat.sunrise'.tr(), 
        't': astroState.ibadatTimings.sunrise
      });
    }

    final todayTasks = ref.watch(tasksProvider).todayTasks;
    _currentDialTasks.clear(); 

    for (var task in todayTasks) {
      if (task.showOnDial) {
        try {
          DateTime? taskTime;
          if (task.isAstroTime && task.targetPeriodId != null) {
            final p = astroState.periods.firstWhere((per) => per.id == task.targetPeriodId);
            final suwayaCount = p.suwayasCount > 0 ? p.suwayasCount : 1;
            final microPerSuwaya = p.endTime.difference(p.startTime).inMicroseconds ~/ suwayaCount;
            int sIndex = task.targetSuwayas.isNotEmpty ? (task.targetSuwayas.first == -1 ? suwayaCount ~/ 2 : task.targetSuwayas.first - 1) : suwayaCount ~/ 2;
            sIndex = sIndex.clamp(0, suwayaCount - 1);
            final microPerVirtualMinute = microPerSuwaya / 30.0;
            taskTime = p.startTime.add(Duration(microseconds: (microPerSuwaya * sIndex) + (microPerVirtualMinute * task.targetVirtualMinute).toInt()));
          } else if (!task.isAstroTime && task.targetCivilTimeMinutes != null) {
            DateTime pStartNoSecs = DateTime.utc(dayStart.year, dayStart.month, dayStart.day, dayStart.hour, dayStart.minute);
            DateTime dt = DateTime.utc(dayStart.year, dayStart.month, dayStart.day, task.targetCivilTimeMinutes! ~/ 60, task.targetCivilTimeMinutes! % 60);
            if (dt.isBefore(pStartNoSecs)) dt = dt.add(const Duration(days: 1));
            if (dt.isAfter(dayEnd)) dt = dt.subtract(const Duration(days: 1));
            if (dt.isBefore(pStartNoSecs)) dt = dt.add(const Duration(days: 1));
            taskTime = dt; 
          }
          if (taskTime != null) {
            Color tColor = getNeonColorForCategory(task.category); 
            String formattedName = task.dialShortName ?? task.title;
            _currentDialTasks.add(DialTask(taskModel: task, shortName: formattedName.replaceAll('\n', ' '), time: taskTime, color: tColor));
          }
        } catch (_) {}
      }
    }

    // 🌟 طبقات الرسم تم تجميعها كمتغير واحد (Stack) لتمريرها كـ child
    final heavyDialStack = RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. الخلفيات
          _buildLayer(BackgroundPainter(isDark: isDark, design: selectedDesign)),
          if (selectedDesign == DialDesign.classic) _buildLayer(IslamicRetePainter(isDark: isDark)), 
          if (selectedDesign == DialDesign.geometric) _buildLayer(GeometricRetePainter(isDark: isDark)),
          
          // 2. الحلقات والفواصل
          _buildLayer(RoutinesRingPainter(routineArcs: widget.routineArcs, isDark: isDark, design: selectedDesign)),
          _buildLayer(PeriodRingPainter(periods: astroState.periods, currentPeriod: astroState.currentPeriod, dayStart: dayStart, dayEnd: dayEnd, isDark: isDark, langCode: currentLang, design: selectedDesign)), 
          _buildLayer(OuterRingPainter(periods: astroState.periods, dayStart: dayStart, dayEnd: dayEnd, isDark: isDark, design: selectedDesign)), 
          if (selectedDesign == DialDesign.classic) _buildLayer(CrownPainter(dayStart: dayStart, dayEnd: dayEnd)), 
          _buildLayer(DividerRingPainter(periods: astroState.periods, dayStart: dayStart, dayEnd: dayEnd, isDark: isDark, design: selectedDesign)),

          // 3. المهام والعقرب (الذي يستخدم currentTime)
          _buildLayer(RailwayRingPainter(
            ibadat: astroState.ibadatTimings, nightMarkers: activeNightMarkers, 
            tasks: List.of(_currentDialTasks), 
            periods: astroState.periods, dayStart: dayStart, dayEnd: dayEnd, 
            isDark: isDark, draggedTask: _draggedTask, dragAngle: _dragAngle, langCode: currentLang, design: selectedDesign,
            highlightedTaskId: highlightedTaskId 
          )),
          _buildLayer(DynamicNeedlePainter(currentTime: currentTime, dayStart: dayStart, dayEnd: dayEnd, isDark: isDark, design: selectedDesign)),
        ],
      ),
    );

    return SizedBox(
      width: widget.size, height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onPanDown: _onPanDown,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            onPanCancel: _onPanCancel,
            onTapUp: (details) => _handleTap(details, astroState, dayStart, dayEnd, _getCurrentTotalRotation(currentTime)),
            
            // 🌟 السحر الحقيقي للأداء: استخدام child داخل AnimatedBuilder
            child: AnimatedBuilder(
              animation: _manualRotation, // ينصت فقط لحركة السحب اليدوية!
              child: heavyDialStack, // يمرر الطبقات المعقدة مرة واحدة ولا يعيد بناءها!
              builder: (context, child) {
                double autoRotationOffset = 0.0;
                final needleAngle = timeToAngle(currentTime, dayStart, dayEnd);
                if (settings.isDialAutoRotating) autoRotationOffset = -(needleAngle + pi / 2);
                final totalRotation = autoRotationOffset + _manualRotation.value;

                return Transform.rotate(
                  angle: totalRotation,
                  child: child, // كرت الشاشة يقوم بتدوير الصورة الجاهزة، أداء خرافي!
                );
              },
            ),
          ),
          _buildCenterGlow(isDark, selectedDesign),
          _buildCentralTime(astroState, textColor, isDark),
        ],
      ),
    );
  }

  Widget _buildLayer(CustomPainter painter) => SizedBox(width: widget.size, height: widget.size, child: CustomPaint(painter: painter));

  Widget _buildCenterGlow(bool isDark, DialDesign design) {
    if (design == DialDesign.minimal) {
      return Container(
        width: widget.size * (kInnerR - 0.02), height: widget.size * (kInnerR - 0.02),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF13131A) : const Color(0xFFF8F9FA),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 1.5),
        ),
      );
    }
    
    return Container(
      width: widget.size * (kInnerR - 0.02), height: widget.size * (kInnerR - 0.02),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF0D0D14).withValues(alpha: 0.85) : const Color(0xFFF0F4F8).withValues(alpha: 0.9),
        border: Border.all(color: goldBase.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(color: isDark ? Colors.black87 : Colors.white, blurRadius: 20, spreadRadius: 4),
          BoxShadow(color: goldBase.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 1),
        ],
      ),
    );
  }

  Widget _buildCentralTime(AstroState state, Color textColor, bool isDark) {
    final int displaySuwaya = state.currentSuwaya; 
    final String suwayaText = '${'common.suwaya'.tr()} $displaySuwaya ${'common.of'.tr()} ${state.currentPeriod.suwayasCount}';
    
    String currentPeriodName = '';
    switch(state.currentPeriod.id) {
      case 1: currentPeriodName = 'periods.fajr'.tr(); break;
      case 2: currentPeriodName = 'periods.duha'.tr(); break;
      case 3: currentPeriodName = 'periods.dhuhr'.tr(); break;
      case 4: currentPeriodName = 'periods.asr'.tr(); break;
      case 5: currentPeriodName = 'periods.maghrib'.tr(); break;
      case 6: currentPeriodName = 'periods.middle_third'.tr(); break;
      case 7: currentPeriodName = 'periods.last_third'.tr(); break;
      default: currentPeriodName = state.currentPeriod.nameKey.tr();
    }

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              Text(suwayaText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal', foreground: Paint()..style=PaintingStyle.stroke..strokeWidth=0.8..color=Colors.white)),
              Text(suwayaText, style: const TextStyle(color: astroGold, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
            ],
          ),
          const SizedBox(height: 1),
          Text(currentPeriodName, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w900, shadows: const [Shadow(color: Colors.black54, blurRadius: 4)])),
          const SizedBox(height: 2),
          
          ValueListenableBuilder<String>(
            valueListenable: virtualTimeNotifier,
            builder: (context, virtualTime, child) {
              return Stack(
                children: [
                  Text(virtualTime, style: TextStyle(fontSize: 32, fontWeight: FontWeight.normal, fontFamily: 'Playfair Display', letterSpacing: 2.0, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = Colors.white)),
                  Text(virtualTime, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.normal, color: astroGold, fontFamily: 'Playfair Display', letterSpacing: 2.0)),
                ],
              );
            }
          ),
          
          const SizedBox(height: 2),
          const TimeSpeedIndicator(), 
        ],
      ),
    );
  }
}