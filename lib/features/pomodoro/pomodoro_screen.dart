import 'dart:async';
import 'dart:math' show pi, cos, sin;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../core/astro_engine/astro_provider.dart';
import '../tasks/tasks_provider.dart';
import '../../shared/widgets/task_card.dart'; 

final pomodoroModeProvider = StateProvider<int>((ref) => 1);

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  Timer? _dynamicTimer;
  int _visualElapsedSecs = 0;
  double _currentSpeed = 0.0;
  int _lastEngineSecs = -1;

  @override
  void dispose() {
    _dynamicTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final astroState = ref.watch(astroProvider);
    final mode = ref.watch(pomodoroModeProvider);
    final tasksState = ref.watch(tasksProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (astroState.periods.isEmpty) {
      return Scaffold(backgroundColor: scaffoldBgColor, body: const Center(child: CircularProgressIndicator()));
    }

    final engineElapsed = astroState.elapsedVirtualTime.inSeconds;
    final speed = astroState.timeSpeedMultiplier;

    if (_dynamicTimer == null || _currentSpeed != speed) {
      _currentSpeed = speed;
      _visualElapsedSecs = engineElapsed;
      _lastEngineSecs = engineElapsed;
      
      _dynamicTimer?.cancel();
      if (speed > 0) {
        final ms = (1000 / speed).round().clamp(10, 10000);
        _dynamicTimer = Timer.periodic(Duration(milliseconds: ms), (t) {
          if (mounted) setState(() { _visualElapsedSecs++; });
        });
      }
    } else {
       if (engineElapsed != _lastEngineSecs) {
         _lastEngineSecs = engineElapsed;
         if ((_visualElapsedSecs - engineElapsed).abs() > 2) {
            _visualElapsedSecs = engineElapsed;
         }
       }
    }

    final currentPeriod = astroState.currentPeriod;
    const totalSuwayaSecs = 1800; 
    final elapsedSecs = _visualElapsedSecs % totalSuwayaSecs;
    
    int focusDuration = 1500; 
    if (mode == 0) focusDuration = 1800; 
    if (mode == 2) focusDuration = 1200; 

    final isBreak = elapsedSecs >= focusDuration;
    final remainingSecs = isBreak ? (totalSuwayaSecs - elapsedSecs) : (focusDuration - elapsedSecs);
    
    final double globalProgress = elapsedSecs / totalSuwayaSecs;
    final double focusRatio = focusDuration / totalSuwayaSecs;

    final m = (remainingSecs ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSecs % 60).toString().padLeft(2, '0');

    final activeColor = isBreak ? const Color(0xFF00E5FF) : const Color(0xFFFF3D00);

    final currentSuwayaTasks = tasksState.todayTasks.where((t) => 
      !t.isCompletedToday && 
      t.targetPeriodId == currentPeriod.id && 
      (t.targetSuwayas.isEmpty || t.targetSuwayas.contains(astroState.currentSuwaya))
    ).toList();

    // 🌟 ترجمة دقيقة لاسم الفترة الحالية
    String currentPeriodName = '';
    switch(currentPeriod.id) {
      case 1: currentPeriodName = 'periods.fajr'.tr(); break;
      case 2: currentPeriodName = 'periods.duha'.tr(); break;
      case 3: currentPeriodName = 'periods.dhuhr'.tr(); break;
      case 4: currentPeriodName = 'periods.asr'.tr(); break;
      case 5: currentPeriodName = 'periods.maghrib'.tr(); break;
      case 6: currentPeriodName = 'periods.middle_third'.tr(); break;
      case 7: currentPeriodName = 'periods.last_third'.tr(); break;
      default: currentPeriodName = currentPeriod.nameKey.tr();
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: activeColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: activeColor, blurRadius: 8)])),
              const SizedBox(width: 8),
              // 🌟 استخدام الاسم المُترجم بدلاً من nameKey
              Text('$currentPeriodName • ${'common.suwaya'.tr()} ${astroState.currentSuwaya}/${currentPeriod.suwayasCount} • ×${speed.toStringAsFixed(1)}', 
                 style: TextStyle(color: activeColor, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          if (isDark)
            Positioned(
              top: 50, left: -50, right: -50,
              child: Container(
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [activeColor.withValues(alpha: 0.20), Colors.transparent],
                    stops: const [0.1, 1.0],
                  ),
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 320, height: 320,
                      child: CustomPaint(
                        painter: _AstrolabePainter(
                          progress: globalProgress,
                          focusRatio: focusRatio,
                          activeColor: activeColor,
                          isBreak: isBreak,
                        ),
                      ),
                    ),
                    
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isBreak ? 'pomodoro.break_remaining'.tr() : 'pomodoro.focus_remaining'.tr(),
                          style: TextStyle(color: activeColor.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$m:$s',
                          style: TextStyle(fontSize: 76, fontWeight: FontWeight.w200, color: textColor, fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: activeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: activeColor.withValues(alpha: 0.5))
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isBreak ? LucideIcons.coffee : LucideIcons.brain, color: activeColor, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                isBreak ? 'pomodoro.deep_relaxation'.tr() : 'pomodoro.in_flow'.tr(),
                                style: TextStyle(color: activeColor, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const Spacer(flex: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), 
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.black12)
                    ),
                    child: Row(
                      children: [
                        _buildModeTab('pomodoro.absolute_focus'.tr(), 0, mode, activeColor, isDark),
                        _buildModeTab('pomodoro.balanced'.tr(), 1, mode, activeColor, isDark),
                        _buildModeTab('pomodoro.relaxed'.tr(), 2, mode, activeColor, isDark),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: currentSuwayaTasks.isEmpty 
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: Text('pomodoro.no_tasks'.tr(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, right: 8),
                            child: Text('pomodoro.focus_now_on'.tr(), style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)),
                          ),
                          ...currentSuwayaTasks.map((task) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: TaskCard(task: task),
                          )),
                        ],
                      ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: currentPeriod.suwayasCount,
                    itemBuilder: (context, index) {
                      final sNum = index + 1;
                      final isCurrent = sNum == astroState.currentSuwaya;
                      final isPast = sNum < astroState.currentSuwaya;
                      
                      return Container(
                        width: 75,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: isCurrent ? activeColor.withValues(alpha: isDark ? 0.15 : 0.08) : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isCurrent ? activeColor.withValues(alpha: 0.5) : (isDark ? Colors.white12 : Colors.black12)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${'common.suwaya'.tr()} $sNum', style: TextStyle(color: isPast ? (isDark ? Colors.white38 : Colors.black38) : (isCurrent ? activeColor : (isDark ? Colors.white70 : Colors.black87)), fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (isPast)
                              Icon(LucideIcons.circle_check, color: isDark ? Colors.white24 : Colors.black26, size: 24)
                            else if (isCurrent)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: activeColor, blurRadius: 4)]),
                                child: Icon(isBreak ? LucideIcons.coffee : LucideIcons.flame, color: Colors.white, size: 16), 
                              )
                            else
                              Icon(LucideIcons.lock_keyhole, color: isDark ? Colors.white12 : Colors.black12, size: 18)
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String title, int value, int currentValue, Color activeColor, bool isDark) {
    final isSelected = value == currentValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(pomodoroModeProvider.notifier).state = value;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected ? [BoxShadow(color: activeColor.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)] : [],
          ),
          child: Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white54 : Colors.black54), 
                fontSize: 12, 
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AstrolabePainter extends CustomPainter {
  final double progress;
  final double focusRatio;
  final Color activeColor;
  final bool isBreak;

  _AstrolabePainter({required this.progress, required this.focusRatio, required this.activeColor, required this.isBreak});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final trackRadius = radius * 0.90; 
    final mapRadius = radius * 0.78;   

    const startAngle = -pi / 2;
    const totalSweep = 2 * pi;

    final mapRect = Rect.fromCircle(center: center, radius: mapRadius);
    final focusSweep = totalSweep * focusRatio;
    final breakSweep = totalSweep * (1 - focusRatio);

    canvas.drawCircle(center, mapRadius, Paint()..color = Colors.white.withValues(alpha: 0.03)..style = PaintingStyle.stroke..strokeWidth = 10);
    canvas.drawArc(mapRect, startAngle, focusSweep - 0.05, false, Paint()..color = const Color(0xFFFF3D00).withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round);
    
    if (breakSweep > 0) {
      canvas.drawArc(mapRect, startAngle + focusSweep + 0.05, breakSweep - 0.05, false, Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.3)..style = PaintingStyle.stroke..strokeWidth = 10..strokeCap = StrokeCap.round);
    }

    canvas.drawCircle(center, trackRadius, Paint()..color = Colors.white.withValues(alpha: 0.02)..style = PaintingStyle.stroke..strokeWidth = 2);
    for (int i = 0; i < 60; i++) {
      final angle = startAngle + (i / 60) * totalSweep;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 6.0 : 3.0;
      final innerP = Offset(center.dx + cos(angle) * (trackRadius - tickLength), center.dy + sin(angle) * (trackRadius - tickLength));
      final outerP = Offset(center.dx + cos(angle) * (trackRadius + tickLength), center.dy + sin(angle) * (trackRadius + tickLength));
      canvas.drawLine(innerP, outerP, Paint()..color = activeColor.withValues(alpha: isMajor ? 0.4 : 0.1)..strokeWidth = isMajor ? 1.5 : 1.0);
    }

    final currentSweep = progress * totalSweep;
    final progressRect = Rect.fromCircle(center: center, radius: trackRadius);

    canvas.drawArc(progressRect, startAngle, currentSweep, false, Paint()..color = activeColor.withValues(alpha: 0.5)..style = PaintingStyle.stroke..strokeWidth = 8..maskFilter = const MaskFilter.blur(BlurStyle.solid, 8));
    canvas.drawArc(progressRect, startAngle, currentSweep, false, Paint()..color = activeColor..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round);

    final orbAngle = startAngle + currentSweep;
    final orbCenter = Offset(center.dx + cos(orbAngle) * trackRadius, center.dy + sin(orbAngle) * trackRadius);
    canvas.drawCircle(orbCenter, 14, Paint()..color = activeColor.withValues(alpha: 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(orbCenter, 6, Paint()..color = Colors.white);
    canvas.drawCircle(orbCenter, 6, Paint()..color = activeColor..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _AstrolabePainter old) => old.progress != progress || old.isBreak != isBreak || old.activeColor != activeColor;
}