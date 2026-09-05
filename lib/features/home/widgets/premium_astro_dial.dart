import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../../core/astro_engine/astro_models.dart';
import '../../../core/astro_engine/astro_provider.dart';
import '../../settings/settings_provider.dart';
import '../../routines/routines_provider.dart'; 
import '../../tasks/tasks_provider.dart';
import '../../../models/task_model.dart'; 
import '../../../core/theme/dial_design_provider.dart';

const Color goldBase = Color(0xFFD4AF37);
const Color goldLight = Color(0xFFFFE58F);
const Color goldDark = Color(0xFFAA7900);
const Color carvedText = Color(0xFFFFD87A);

const double kInnerR = 0.35;   
const double kPeriodR = 0.50;  
const double kRailwayR = 0.82; 
const double kOuterR = 0.98;   

Color getNeonColorForCategory(TaskCategory category) {
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

double _timeToAngle(DateTime time, DateTime start, DateTime end) {
  final total = end.difference(start).inMicroseconds;
  if (total <= 0) return -pi / 2;
  return -pi / 2 + (time.difference(start).inMicroseconds / total) * 2 * pi;
}

class DialTask {
  final TaskModel taskModel; 
  final String shortName; 
  final DateTime time;
  final Color color;
  DialTask({required this.taskModel, required this.shortName, required this.time, required this.color});
}

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

class _PremiumAstroDialState extends ConsumerState<PremiumAstroDial> with TickerProviderStateMixin {
  late Ticker _ticker; 
  DateTime _lastSync = DateTime.now();
  late DateTime _baseWallTime;
  
  final ValueNotifier<DateTime> _smoothNow = ValueNotifier(DateTime.now());
  final ValueNotifier<double> _manualRotation = ValueNotifier(0.0);
  double _previousAngle = 0.0;
  
  late AnimationController _animController;
  Animation<double>? _anim;
  tz.Location? _cachedLocation;
  String? _cachedTzName;

  RenderBox? _cachedBox;
  Offset? _touchStart;
  Timer? _longPressTimer;
  bool _isTaskDragging = false;
  final List<DialTask> _currentDialTasks = []; 

  TaskModel? _draggedTask;
  double? _dragAngle;

  DateTime _getCityWallTime(dynamic settings) {
    final loc = settings.activeLocation;
    if (loc != null && loc.isAutoLocation == false && loc.timezone != null) {
      try {
        if (_cachedTzName != loc.timezone) {
          _cachedTzName = loc.timezone;
          _cachedLocation = tz.getLocation(loc.timezone!);
        }
        final nowInTarget = tz.TZDateTime.now(_cachedLocation!);
        return DateTime.utc(nowInTarget.year, nowInTarget.month, nowInTarget.day, nowInTarget.hour, nowInTarget.minute, nowInTarget.second, nowInTarget.millisecond);
      } catch (_) {}
    }
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day, now.hour, now.minute, now.second, now.millisecond);
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animController.addListener(() { 
      if (_anim != null) _manualRotation.value = _anim!.value; 
    });

    _baseWallTime = _getCityWallTime(ref.read(settingsProvider));
    _lastSync = DateTime.now();
    _smoothNow.value = _baseWallTime;

    _ticker = createTicker((elapsed) {
       final now = DateTime.now();
       if (now.difference(_lastSync).inSeconds > 60) {
         _baseWallTime = _getCityWallTime(ref.read(settingsProvider));
         _lastSync = now;
       }
       final diff = now.difference(_lastSync);
       _smoothNow.value = _baseWallTime.add(diff);
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _smoothNow.dispose();
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
      double actualDialAngle = (currentAngle - _getCurrentTotalRotation()) % (2 * pi);
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

    double actualDialAngle = (screenAngle - _getCurrentTotalRotation()) % (2 * pi);
    if (actualDialAngle < 0) actualDialAngle += 2 * pi;

    DialTask? closestTask;
    double minDiff = 0.15; 
    final astro = ref.read(astroProvider);
    final dayStart = astro.periods.first.startTime;
    final dayEnd = astro.periods.last.endTime;

    for (var dt in _currentDialTasks) {
      double tAngle = _timeToAngle(dt.time, dayStart, dayEnd) % (2 * pi);
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
      double startA = _timeToAngle(period.startTime, dayStart, dayEnd) % (2 * pi);
      double endA = _timeToAngle(period.endTime, dayStart, dayEnd) % (2 * pi);
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

    for (var period in state.periods) {
      double startA = _timeToAngle(period.startTime, dayStart, dayEnd) % (2 * pi);
      double endA = _timeToAngle(period.endTime, dayStart, dayEnd) % (2 * pi);
      if (startA < 0) startA += 2 * pi;
      if (endA < 0) endA += 2 * pi;
      
      bool inside = startA < endA ? (actualDialAngle >= startA && actualDialAngle <= endA) : (actualDialAngle >= startA || actualDialAngle <= endA);
      if (inside) {
        if (widget.onPeriodTapped != null) widget.onPeriodTapped!(period);
        break;
      }
    }
  }

  double _getCurrentTotalRotation() {
    final settings = ref.read(settingsProvider);
    final astro = ref.read(astroProvider);
    if (astro.periods.isEmpty) return 0.0;
    double autoRotationOffset = 0.0;
    final needleAngle = _timeToAngle(_smoothNow.value, astro.periods.first.startTime, astro.periods.last.endTime);
    if (settings.isDialAutoRotating) autoRotationOffset = -(needleAngle + pi / 2);
    return autoRotationOffset + _manualRotation.value;
  }

  @override
  Widget build(BuildContext context) {
    final astroState = ref.watch(astroProvider);
    final settings = ref.watch(settingsProvider);
    final selectedDesign = ref.watch(dialDesignProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = context.locale.languageCode; 

    if (astroState.periods.isEmpty) return SizedBox(width: widget.size, height: widget.size);

    final dayStart = astroState.periods.first.startTime;
    final dayEnd = astroState.periods.last.endTime;
    final pColor = astroState.currentPeriod.color.adapt(context);
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

    final staticLayersBase = RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          _buildLayer(BackgroundPainter(isDark: isDark, design: selectedDesign)),
          
          if (selectedDesign == DialDesign.classic) 
            _buildLayer(IslamicRetePainter(isDark: isDark)), 
          if (selectedDesign == DialDesign.geometric) 
            _buildLayer(GeometricRetePainter(isDark: isDark)),
            
          _buildLayer(RoutinesRingPainter(routineArcs: widget.routineArcs, isDark: isDark, design: selectedDesign)),
          _buildLayer(PeriodRingPainter(periods: astroState.periods, currentPeriod: astroState.currentPeriod, dayStart: dayStart, dayEnd: dayEnd, isDark: isDark, langCode: currentLang, design: selectedDesign)), 
          _buildLayer(OuterRingPainter(periods: astroState.periods, dayStart: dayStart, dayEnd: dayEnd, isDark: isDark, design: selectedDesign)), 
          
          if (selectedDesign == DialDesign.classic) 
            _buildLayer(CrownPainter(dayStart: dayStart, dayEnd: dayEnd)), 
        ],
      ),
    );

    final needleLayer = RepaintBoundary(
      child: _buildLayer(DynamicNeedlePainter(currentTime: _smoothNow.value, dayStart: dayStart, dayEnd: dayEnd, isDark: isDark, design: selectedDesign))
    );

    final prayersAndTasksLayer = RepaintBoundary(
      child: _buildLayer(RailwayRingPainter(
        ibadat: astroState.ibadatTimings, nightMarkers: activeNightMarkers, 
        tasks: _currentDialTasks, periods: astroState.periods, dayStart: dayStart, dayEnd: dayEnd, 
        isDark: isDark, draggedTask: _draggedTask, dragAngle: _dragAngle, langCode: currentLang, design: selectedDesign
      ))
    );

    final dividersLayer = RepaintBoundary(
      child: _buildLayer(DividerRingPainter(periods: astroState.periods, dayStart: dayStart, dayEnd: dayEnd, isDark: isDark, design: selectedDesign))
    );

    return SizedBox(
      width: widget.size, height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_smoothNow, _manualRotation]),
            builder: (context, child) {
              double autoRotationOffset = 0.0;
              final needleAngle = _timeToAngle(_smoothNow.value, dayStart, dayEnd);
              if (settings.isDialAutoRotating) autoRotationOffset = -(needleAngle + pi / 2);
              final totalRotation = autoRotationOffset + _manualRotation.value;

              return GestureDetector(
                onPanDown: _onPanDown,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                onPanCancel: _onPanCancel,
                onTapUp: (details) => _handleTap(details, astroState, dayStart, dayEnd, totalRotation),
                child: Transform.rotate(
                  angle: totalRotation,
                  child: RepaintBoundary(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        staticLayersBase, 
                        dividersLayer, 
                        prayersAndTasksLayer, 
                        needleLayer,      
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          _buildCenterGlow(isDark, selectedDesign),
          _buildCentralTime(astroState, textColor, pColor, isDark),
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

  Widget _buildCentralTime(AstroState state, Color textColor, Color pColor, bool isDark) {
    final virtualTime = state.currentFormattedVirtualTime;
    final String suwayaText = '${'common.suwaya'.tr()} ${state.currentSuwaya} ${'common.of'.tr()} ${state.currentPeriod.suwayasCount}';
    
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
        children: [
          // 🌟 التعديل هنا: الخط الفلكي (Playfair Display)
          Text(suwayaText, style: const TextStyle(color: goldLight, fontSize: 12, fontWeight: FontWeight.w900, fontFamily: 'Playfair Display', letterSpacing: 1.0, shadows: [Shadow(color: Colors.black87, blurRadius: 3)])),
          const SizedBox(height: 2),
          Text(currentPeriodName, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13, fontWeight: FontWeight.w900, shadows: const [Shadow(color: Colors.black54, blurRadius: 4)])),
          const SizedBox(height: 4),
          Stack(
            children: [
              // 🌟 التعديل هنا: الخط الفلكي (Playfair Display)
              Text(virtualTime, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, fontFamily: 'Playfair Display', letterSpacing: 2.0, foreground: Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = isDark ? Colors.black : Colors.white)),
              Text(virtualTime, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Playfair Display', letterSpacing: 2.0)),
            ],
          ),
          const SizedBox(height: 4),
          const TimeSpeedIndicator(), 
        ],
      ),
    );
  }
}

class TimeSpeedIndicator extends ConsumerWidget {
  const TimeSpeedIndicator({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final astroState = ref.watch(astroProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (astroState.periods.isEmpty) return const SizedBox.shrink();

    final speedMultiplier = astroState.timeSpeedMultiplier;
    final pColor = astroState.currentPeriod.color.adapt(context);
    final strokeColor = isDark ? Colors.black : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: pColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: pColor.withValues(alpha: 0.5), width: 1.0)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(speedMultiplier >= 1.0 ? LucideIcons.zap : LucideIcons.hourglass, color: pColor, size: 10),
          const SizedBox(width: 4),
          Stack(
            children: [
              // 🌟 التعديل هنا: الخط الفلكي (Playfair Display)
              Text('${speedMultiplier.toStringAsFixed(1)}x', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Playfair Display', foreground: Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=strokeColor)),
              Text('${speedMultiplier.toStringAsFixed(1)}x', style: TextStyle(color: pColor, fontSize: 11, fontWeight: FontWeight.w900, fontFamily: 'Playfair Display')),
            ],
          ),
        ],
      ),
    );
  }
}

class UnifiedDialItem {
  final String text;
  final DateTime time;
  final Color color;
  final TaskModel? taskModel; 
  final bool isPrayer; 
  UnifiedDialItem({required this.text, required this.time, required this.color, this.taskModel, this.isPrayer = false});
}

class RoutinesRingPainter extends CustomPainter {
  final List<RoutineArcData> routineArcs;
  final bool isDark;
  final DialDesign design;
  
  RoutinesRingPainter({required this.routineArcs, required this.isDark, required this.design});

  @override
  void paint(Canvas canvas, Size size) {
    if (routineArcs.isEmpty) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final innerRadius = R * kInnerR; 
    final outerRadius = R * kRailwayR; 
    
    for (var arc in routineArcs) {
      final rectOuter = Rect.fromCircle(center: center, radius: outerRadius);
      final rectInner = Rect.fromCircle(center: center, radius: innerRadius);

      final path = Path()
        ..arcTo(rectOuter, arc.startAngle, arc.sweepAngle, true)
        ..arcTo(rectInner, arc.startAngle + arc.sweepAngle, -arc.sweepAngle, false)
        ..close();

      final fillPaint = Paint()
        ..color = arc.color.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      if (design != DialDesign.minimal) {
        canvas.save();
        canvas.clipPath(path); 
        final hatchPaint = Paint()..color = arc.color.withValues(alpha: 0.4)..strokeWidth = 1.0..style = PaintingStyle.stroke;
        final bounds = path.getBounds();
        _drawLinearGrid(canvas, bounds, hatchPaint); 
        canvas.restore();
      }

      canvas.drawPath(path, Paint()..color = arc.color.withValues(alpha: 0.8)..strokeWidth = 1.5..style = PaintingStyle.stroke..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0));
    }
  }

  void _drawLinearGrid(Canvas canvas, Rect bounds, Paint paint) {
    const double step = 6.0; 
    for (double i = -bounds.height; i < bounds.width + bounds.height; i += step) {
      canvas.drawLine(Offset(bounds.left + i, bounds.top), Offset(bounds.left + i - bounds.height, bounds.bottom), paint);
    }
  }
  @override bool shouldRepaint(covariant RoutinesRingPainter old) => old.isDark != isDark || old.routineArcs.length != routineArcs.length || old.design != design;
}

class BackgroundPainter extends CustomPainter {
  final bool isDark;
  final DialDesign design;
  BackgroundPainter({required this.isDark, required this.design});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    
    if (design == DialDesign.minimal) {
      canvas.drawCircle(center, R, Paint()..color = isDark ? const Color(0xFF13131A) : const Color(0xFFF8F9FA));
      return;
    }
    
    final bgPaint = Paint()..shader = RadialGradient(colors: isDark ? [const Color(0xFF13131A), const Color(0xFF030305)] : [const Color(0xFFF8F9FA), const Color(0xFFE2E8F0)]).createShader(Rect.fromCircle(center: center, radius: R));
    canvas.drawCircle(center, R, bgPaint);
    
    if (!isDark) return; 
    
    if (design == DialDesign.classic) {
      final rand = Random(42); 
      final paint = Paint();
      for (int i = 0; i < 90; i++) {
        final x = rand.nextDouble() * size.width;
        final y = rand.nextDouble() * size.height;
        final s = rand.nextDouble() * 2.0 + 1.0;
        paint.color = Colors.white.withValues(alpha: rand.nextDouble() * 0.5 + 0.1);
        Path starPath = Path()..moveTo(x, y - s)..quadraticBezierTo(x, y, x + s, y)..quadraticBezierTo(x, y, x, y + s)..quadraticBezierTo(x, y, x - s, y)..quadraticBezierTo(x, y, x, y - s);
        canvas.drawPath(starPath, paint);
      }
    }
  }
  @override bool shouldRepaint(covariant BackgroundPainter old) => old.isDark != isDark || old.design != design;
}

class IslamicRetePainter extends CustomPainter {
  final bool isDark;
  IslamicRetePainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final rRete = R * kInnerR; 

    canvas.save();
    canvas.translate(center.dx, center.dy);
    final paint = Paint()..color = goldBase.withValues(alpha: 0.15)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    
    final path1 = Path()..addPolygon([Offset(0, -rRete), Offset(rRete, 0), Offset(0, rRete), Offset(-rRete, 0)], true);
    canvas.drawPath(path1, paint);
    final d = rRete * 0.7071; 
    final path2 = Path()..addPolygon([Offset(d, -d), Offset(d, d), Offset(-d, d), Offset(-d, -d)], true);
    canvas.drawPath(path2, paint);
    canvas.drawCircle(Offset.zero, rRete * 0.8, paint);
    canvas.drawCircle(Offset.zero, rRete * 0.6, paint);
    canvas.restore();
  }
  @override bool shouldRepaint(covariant IslamicRetePainter old) => old.isDark != isDark;
}

class GeometricRetePainter extends CustomPainter {
  final bool isDark;
  GeometricRetePainter({required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final rRete = R * kInnerR; 

    canvas.save();
    canvas.translate(center.dx, center.dy);
    final paint = Paint()..color = goldBase.withValues(alpha: 0.2)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    
    final rectPath = Path()..addRect(Rect.fromCircle(center: Offset.zero, radius: rRete * 0.8));
    canvas.drawPath(rectPath, paint);
    canvas.rotate(pi / 4);
    canvas.drawPath(rectPath, paint);
    canvas.restore();
  }
  @override bool shouldRepaint(covariant GeometricRetePainter old) => old.isDark != isDark;
}

class PeriodRingPainter extends CustomPainter {
  final List<AstroPeriod> periods;
  final AstroPeriod currentPeriod;
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final String langCode; 
  final DialDesign design;

  PeriodRingPainter({required this.periods, required this.currentPeriod, required this.dayStart, required this.dayEnd, required this.isDark, required this.langCode, required this.design});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final innerRadius = R * kInnerR;
    final outerRadius = R * kPeriodR;
    final width = design == DialDesign.minimal ? (outerRadius - innerRadius) * 0.4 : (outerRadius - innerRadius);
    final drawRadius = design == DialDesign.minimal ? innerRadius + (width / 2) + 10 : innerRadius + (width / 2);
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center);

    for (var period in periods) {
      final startAngle = _timeToAngle(period.startTime, dayStart, dayEnd);
      final endAngle = _timeToAngle(period.endTime, dayStart, dayEnd);
      double sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * pi;

      Color pColor = period.color;
      if (period.id == 6 || period.nameKey == 'period_second_third') pColor = const Color(0xFF3F51B5); 
      final isCurrent = period.id == currentPeriod.id;
      
      if (isCurrent && design != DialDesign.minimal) {
        final glowPaint = Paint()..color = pColor.withValues(alpha: 0.4)..style = PaintingStyle.stroke..strokeWidth = width + 6..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawArc(Rect.fromCircle(center: center, radius: drawRadius), startAngle, sweepAngle, false, glowPaint);
      }
      
      final gradient = SweepGradient(startAngle: startAngle, endAngle: startAngle + sweepAngle, colors: [pColor.withValues(alpha: isCurrent ? 0.9 : 0.4), pColor.withValues(alpha: isCurrent ? 0.6 : 0.2)]);
      final rect = Rect.fromCircle(center: center, radius: drawRadius);
      canvas.drawArc(rect, startAngle, sweepAngle, false, Paint()..style = PaintingStyle.stroke..strokeWidth = width..strokeCap = StrokeCap.butt..shader = gradient.createShader(rect));

      if (design == DialDesign.minimal) continue;

      final middleAngle = (startAngle + (sweepAngle / 2)) % (2 * pi);
      canvas.save();
      canvas.translate(center.dx + drawRadius * cos(middleAngle), center.dy + drawRadius * sin(middleAngle));
      canvas.rotate(middleAngle + pi / 2); 
      
      String pName = '';
      switch(period.id) {
        case 1: pName = 'periods.fajr'.tr(); break;
        case 2: pName = 'periods.duha'.tr(); break;
        case 3: pName = 'periods.dhuhr'.tr(); break;
        case 4: pName = 'periods.asr'.tr(); break;
        case 5: pName = 'periods.maghrib'.tr(); break;
        case 6: pName = 'periods.middle_third'.tr(); break;
        case 7: pName = 'periods.last_third'.tr(); break;
        default: pName = period.nameKey.tr();
      }

      textPainter.text = TextSpan(
        text: pName, 
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Tajawal', shadows: [Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)), Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 0))])
      );
      textPainter.layout();
      
      final double maxW = (sweepAngle * drawRadius) * 0.85; 
      final double maxH = width * 0.65;
      double scale = 1.0;
      if (textPainter.width > maxW && maxW > 0) scale = maxW / textPainter.width;
      if (textPainter.height > maxH && maxH > 0) scale = min(scale, maxH / textPainter.height);
      
      canvas.scale(scale, scale);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }
  }
  @override bool shouldRepaint(covariant PeriodRingPainter old) => old.currentPeriod.id != currentPeriod.id || old.isDark != isDark || old.dayStart != dayStart || old.langCode != langCode || old.design != design || old.periods.length != periods.length;
}

class RailwayRingPainter extends CustomPainter {
  final dynamic ibadat;
  final List<Map<String, dynamic>> nightMarkers;
  final List<DialTask> tasks; 
  final List<AstroPeriod> periods; 
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final TaskModel? draggedTask; 
  final double? dragAngle;      
  final String langCode;
  final DialDesign design;
  
  RailwayRingPainter({
    required this.ibadat, required this.nightMarkers, required this.tasks, required this.periods,
    required this.dayStart, required this.dayEnd, required this.isDark,
    this.draggedTask, this.dragAngle, required this.langCode, required this.design,
  });

  void _drawEquilateralArrow(Canvas canvas, Offset center, double radius, double baseWidth, double angle, Color color, {bool isDragged = false, bool isPrayer = false}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle + pi / 2);
    canvas.translate(0, -radius);
    
    if (isDragged) canvas.scale(1.4); 

    if (design == DialDesign.minimal) {
      canvas.drawCircle(Offset.zero, 4.0, Paint()..color = color);
      canvas.restore();
      return;
    }

    final double height = baseWidth * 0.866; 

    final path = Path();
    path.moveTo(0, -height); 
    path.lineTo(-baseWidth / 2, 0); 
    path.lineTo(baseWidth / 2, 0); 
    path.close();

    canvas.drawPath(path, Paint()..color = color..maskFilter = MaskFilter.blur(BlurStyle.normal, isDragged ? 8 : 3));
    canvas.drawPath(path, Paint()..color = color);
    
    if (!isPrayer) {
      final inner = Path()..moveTo(0, -height + 2)..lineTo(-baseWidth / 2 + 2, -1)..lineTo(baseWidth / 2 - 2, -1)..close();
      canvas.drawPath(inner, Paint()..color = Colors.white.withValues(alpha: 0.8));
    }
    canvas.restore();
  }

  void _drawTextBadge(Canvas canvas, Offset center, double radius, double angle, String text, Color color) {
    if (design == DialDesign.minimal) return; 

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle + pi / 2);
    canvas.translate(0, -radius);

    final textPainter = TextPainter(
      text: TextSpan(
        text: text, 
        style: TextStyle(
          color: color, 
          fontSize: 13, 
          fontWeight: FontWeight.w900, 
          fontFamily: 'Tajawal',
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 4, offset: const Offset(0, 1)),
            Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 0)),
          ]
        )
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (ibadat == null || ibadat.maghrib == null) return;
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    
    final innerRadius = R * kPeriodR;
    final outerRadius = R * kRailwayR;
    final width = outerRadius - innerRadius;

    canvas.drawCircle(center, innerRadius + (width / 2), Paint()..color = isDark ? Colors.black.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = width);
    canvas.drawCircle(center, outerRadius, Paint()..color = goldBase.withValues(alpha: 0.6)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    
    const int numTracks = 3;
    final double trackStep = width / numTracks;
    
    final double outerTrackTip = outerRadius - 8.0; 
    final double midTrackTip = outerTrackTip - trackStep;
    final double innerTrackTip = midTrackTip - trackStep;
    final trackRadii = [outerTrackTip, midTrackTip, innerTrackTip];

    if (design != DialDesign.minimal) {
      for (var r in trackRadii) {
         canvas.drawCircle(center, r, Paint()..color = Colors.white.withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = 0.5);
      }
    }

    final stationPaint = Paint()..color = goldLight.withValues(alpha: 0.2)..style = PaintingStyle.fill;
    for (var period in periods) {
      final startAngle = _timeToAngle(period.startTime, dayStart, dayEnd);
      final endAngle = _timeToAngle(period.endTime, dayStart, dayEnd);
      double sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * pi;
      final suwayaAngle = sweepAngle / period.suwayasCount;

      for (int i = 0; i < period.suwayasCount; i++) {
        final angle = startAngle + (i * suwayaAngle);
        for (int t = 0; t < numTracks; t++) {
          final r = trackRadii[t] - (trackStep * 0.433);
          canvas.drawCircle(Offset(center.dx + r * cos(angle), center.dy + r * sin(angle)), design == DialDesign.minimal ? 0.5 : 1.2, stationPaint);
        }
      }
    }

    List<UnifiedDialItem> prayersList = [];
    prayersList.add(UnifiedDialItem(text: 'prayers.fajr'.tr(), time: ibadat.fajr, color: goldLight, isPrayer: true));
    prayersList.add(UnifiedDialItem(text: 'prayers.dhuhr'.tr(), time: ibadat.dhuhr, color: goldLight, isPrayer: true));
    prayersList.add(UnifiedDialItem(text: 'prayers.asr'.tr(), time: ibadat.asr, color: goldLight, isPrayer: true));
    prayersList.add(UnifiedDialItem(text: 'prayers.maghrib'.tr(), time: ibadat.maghrib, color: goldLight, isPrayer: true));
    prayersList.add(UnifiedDialItem(text: 'prayers.isha'.tr(), time: ibadat.isha, color: goldLight, isPrayer: true));
    for(var nm in nightMarkers) { prayersList.add(UnifiedDialItem(text: nm['n'] as String, time: nm['t'] as DateTime, color: goldBase, isPrayer: true)); }

    List<List<Map<String, double>>> occupied = [[], [], []];

    for (var p in prayersList) {
      double angle = _timeToAngle(p.time, dayStart, dayEnd);
      
      _drawEquilateralArrow(canvas, center, trackRadii[0], 12.0, angle, p.color, isPrayer: true);
      occupied[0].add({'angle': angle, 'margin': 0.04});
      
      double midBadgeCenter = trackRadii[0] - (trackStep * 0.4); 
      _drawTextBadge(canvas, center, midBadgeCenter, angle, p.text, p.color);
      occupied[1].add({'angle': angle, 'margin': 0.10}); 
    }

    List<UnifiedDialItem> taskItems = tasks.map((t) => UnifiedDialItem(taskModel: t.taskModel, text: t.shortName, time: t.time, color: t.color, isPrayer: false)).toList();
    taskItems.sort((a, b) => a.time.compareTo(b.time));

    for (var item in taskItems) {
      bool isDragged = draggedTask != null && item.taskModel!.id == draggedTask!.id;
      double angle = (isDragged && dragAngle != null) ? dragAngle! : _timeToAngle(item.time, dayStart, dayEnd);
      
      int targetTrack = 2; 
      double taskMargin = 0.04;

      for (int t = 0; t < numTracks; t++) {
        bool isFree = true;
        for (var occ in occupied[t]) {
          double diff = (angle - occ['angle']!).abs();
          if (diff > pi) diff = 2 * pi - diff;
          if (diff < (taskMargin + occ['margin']!)) {
            isFree = false;
            break;
          }
        }
        if (isFree) {
          targetTrack = t;
          break;
        }
      }
      
      occupied[targetTrack].add({'angle': angle, 'margin': taskMargin});
      _drawEquilateralArrow(canvas, center, trackRadii[targetTrack], 10.0, angle, item.color, isDragged: isDragged, isPrayer: false);
    }
  }

  @override 
  bool shouldRepaint(covariant RailwayRingPainter old) {
    return old.isDark != isDark || old.langCode != langCode || old.design != design ||
           old.dayStart != dayStart || old.tasks.length != tasks.length || old.nightMarkers.length != nightMarkers.length || 
           old.draggedTask?.id != draggedTask?.id || old.dragAngle != dragAngle; 
  }
}

class OuterRingPainter extends CustomPainter {
  final List<AstroPeriod> periods;
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final DialDesign design;

  OuterRingPainter({required this.periods, required this.dayStart, required this.dayEnd, required this.isDark, required this.design});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    
    final pinStart = R * kRailwayR; 
    final pinEnd = pinStart + (R * 0.04); 
    final textR = pinEnd + (R * 0.07);    

    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr, textAlign: TextAlign.center);
    int globalLineIndex = 0;

    for (var period in periods) {
      final startAngle = _timeToAngle(period.startTime, dayStart, dayEnd);
      final endAngle = _timeToAngle(period.endTime, dayStart, dayEnd);
      double sweepAngle = endAngle - startAngle;
      if (sweepAngle <= 0) sweepAngle += 2 * pi;
      final suwayaAngle = sweepAngle / period.suwayasCount;

      for (int i = 0; i < period.suwayasCount; i++) {
        final lineAngle = startAngle + (i * suwayaAngle);
        
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(lineAngle + pi/2); 
        
        if (design != DialDesign.minimal) {
          canvas.drawLine(Offset(0, -pinStart), Offset(0, -pinEnd), Paint()..color = goldBase..strokeWidth = 2.0..strokeCap = StrokeCap.round);
        }
        canvas.drawCircle(Offset(0, -pinEnd), design == DialDesign.minimal ? 1.0 : 1.5, Paint()..color = goldLight);

        if (design != DialDesign.minimal || globalLineIndex % 5 == 0) {
          // 🌟 التعديل هنا: الخط الفلكي (Playfair Display)
          textPainter.text = TextSpan(
            text: globalLineIndex.toString().padLeft(2, '0'), 
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'Playfair Display', shadows: const [Shadow(color: Colors.black, blurRadius: 4)])
          );
          textPainter.layout();
          canvas.translate(0, -textR);
          textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
        }
        
        canvas.restore();
        globalLineIndex++;
      }
    }
  }
  @override bool shouldRepaint(covariant OuterRingPainter old) => old.isDark != isDark || old.dayStart != dayStart || old.design != design || old.periods.length != periods.length; 
}

class CrownPainter extends CustomPainter {
  final DateTime dayStart;
  final DateTime dayEnd;
  CrownPainter({required this.dayStart, required this.dayEnd});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final angle = _timeToAngle(dayStart, dayStart, dayEnd); 
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle + pi / 2); 
    canvas.translate(0, -R * kRailwayR); 
    
    final scale = R / 185.0; 
    canvas.scale(scale, scale);

    final Path base = Path()..moveTo(-14, 0)..lineTo(-8, -6)..quadraticBezierTo(0, -8, 8, -6)..lineTo(14, 0)..close();
    final shader = const LinearGradient(colors: [goldLight, goldBase, goldDark]).createShader(const Rect.fromLTRB(-15, -30, 15, 0));
    final metalPaint = Paint()..shader = shader;
    
    canvas.drawPath(base, Paint()..color = Colors.black..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawPath(base, metalPaint);
    canvas.drawPath(base, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 1.0);
    
    final Rect hoopRect = Rect.fromCircle(center: const Offset(0, -16), radius: 14);
    canvas.drawArc(hoopRect, 0, 2*pi, false, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 5.0..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawArc(hoopRect, 0, 2*pi, false, Paint()..shader = shader..style = PaintingStyle.stroke..strokeWidth = 4.0);
    canvas.drawArc(hoopRect, 0, 2*pi, false, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 1.0);
    
    canvas.drawCircle(const Offset(0, -32), 4.0, metalPaint);
    canvas.drawCircle(const Offset(0, -32), 4.0, Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 1.0);
    
    canvas.drawLine(const Offset(-6, -2), const Offset(-6, -5), Paint()..color = Colors.black54..strokeWidth = 1.5);
    canvas.drawLine(const Offset(6, -2), const Offset(6, -5), Paint()..color = Colors.black54..strokeWidth = 1.5);
    canvas.drawCircle(const Offset(0, -4), 2.5, Paint()..color = Colors.white); 

    canvas.restore();
  }
  @override bool shouldRepaint(covariant CrownPainter old) => false;
}

class DynamicNeedlePainter extends CustomPainter {
  final DateTime currentTime;
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final DialDesign design;

  DynamicNeedlePainter({required this.currentTime, required this.dayStart, required this.dayEnd, required this.isDark, required this.design});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final angle = _timeToAngle(currentTime, dayStart, dayEnd);
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle + pi/2); 

    final needleLength = R * kRailwayR - 8.0; 
    final needleStart = R * 0.25; 

    if (design == DialDesign.minimal) {
      canvas.drawLine(Offset(0, -needleStart), Offset(0, -needleLength), Paint()..color = const Color(0xFF007BFF)..strokeWidth = 2.0..strokeCap = StrokeCap.round);
      canvas.drawCircle(Offset(0, -needleLength), 4.0, Paint()..color = const Color(0xFF007BFF));
      canvas.restore();
      return;
    }

    final stripedPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(8, 8), 
        [const Color(0xFF007BFF), const Color(0xFF007BFF), const Color(0xFFFFD700), const Color(0xFFFFD700)],
        [0.0, 0.5, 0.5, 1.0],
        TileMode.repeated,
      );

    canvas.drawLine(Offset(0, -needleStart), Offset(0, -needleLength), Paint()..color = const Color(0xFF007BFF).withValues(alpha: 0.3)..strokeWidth = 6.0..strokeCap = StrokeCap.round..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawLine(Offset(0, -needleStart), Offset(0, -needleLength), stripedPaint..strokeWidth = 3.5..strokeCap = StrokeCap.round..style = PaintingStyle.stroke);
    
    final Path compassArrow = Path()
      ..moveTo(0, -needleLength - 8) 
      ..lineTo(-5, -needleLength + 4)
      ..lineTo(5, -needleLength + 4)
      ..close();

    canvas.drawPath(compassArrow, stripedPaint..style = PaintingStyle.fill);
    canvas.drawPath(compassArrow, Paint()..color = isDark ? Colors.black87 : Colors.white..style = PaintingStyle.stroke..strokeWidth = 0.8);

    canvas.restore();
  }
  @override bool shouldRepaint(covariant DynamicNeedlePainter old) => old.currentTime != currentTime || old.design != design;
}

class DividerRingPainter extends CustomPainter {
  final List<AstroPeriod> periods;
  final DateTime dayStart;
  final DateTime dayEnd;
  final bool isDark;
  final DialDesign design;
  
  DividerRingPainter({required this.periods, required this.dayStart, required this.dayEnd, required this.isDark, required this.design});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final R = size.width / 2;
    final innerR = R * kInnerR;
    final outerR = R * kRailwayR; 

    for (var period in periods) {
      final angle = _timeToAngle(period.startTime, dayStart, dayEnd);
      final p1 = Offset(center.dx + innerR * cos(angle), center.dy + innerR * sin(angle));
      final p2 = Offset(center.dx + outerR * cos(angle), center.dy + outerR * sin(angle));
      
      if (design == DialDesign.minimal) {
        canvas.drawLine(p1, p2, Paint()..color = isDark ? Colors.white24 : Colors.black26..strokeWidth = 1.5..strokeCap = StrokeCap.round);
        continue;
      }

      canvas.drawLine(p1, p2, Paint()..color = isDark ? Colors.black : Colors.white..strokeWidth = 6.0..strokeCap = StrokeCap.round);
      canvas.drawLine(p1, p2, Paint()..color = goldBase..strokeWidth = 2.5..strokeCap = StrokeCap.round);
      
      canvas.drawCircle(p2, 4.0, Paint()..color = goldBase);
      canvas.drawCircle(p2, 2.0, Paint()..color = isDark ? Colors.black : Colors.white);
    }
  }
  
  @override bool shouldRepaint(covariant DividerRingPainter old) => old.isDark != isDark || old.dayStart != dayStart || old.design != design || old.periods.length != periods.length;
}