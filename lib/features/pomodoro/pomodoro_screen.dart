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
    
    final m = (remainingSecs ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSecs % 60).toString().padLeft(2, '0');

    // 🌟 ألوان ثابتة: أزرق (الفجر) للراحة، وأحمر (المغرب) للتركيز
    final activeColor = isBreak ? const Color(0xFF64B5F6) : const Color(0xFFE53935);

    final currentSuwayaTasks = tasksState.todayTasks.where((t) => 
      !t.isCompletedToday && 
      t.targetPeriodId == currentPeriod.id && 
      (t.targetSuwayas.isEmpty || t.targetSuwayas.contains(astroState.currentSuwaya))
    ).toList();

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('$currentPeriodName • ${'common.suwaya'.tr()} ${astroState.currentSuwaya}/${currentPeriod.suwayasCount}', 
           style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Playfair Display')),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            
            // 🌟 المؤقت الهادئ (Zen Timer)
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 300, height: 300,
                  child: CustomPaint(
                    painter: _ZenTimerPainter(
                      progress: globalProgress,
                      activeColor: activeColor,
                      isDark: isDark,
                    ),
                  ),
                ),
                
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$m:$s',
                      style: TextStyle(fontSize: 84, fontWeight: FontWeight.w400, color: textColor, fontFamily: 'Playfair Display'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isBreak ? LucideIcons.coffee : LucideIcons.sparkles, color: activeColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          isBreak ? 'pomodoro.deep_relaxation'.tr() : 'pomodoro.in_flow'.tr(),
                          style: TextStyle(color: activeColor, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            const Spacer(flex: 1),
            
            // 🌟 مبدل الأوضاع المبسط
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildModeTab('pomodoro.absolute_focus'.tr(), 0, mode, activeColor, isDark),
                  _buildModeTab('pomodoro.balanced'.tr(), 1, mode, activeColor, isDark),
                  _buildModeTab('pomodoro.relaxed'.tr(), 2, mode, activeColor, isDark),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            // 🌟 المهام المبسطة
            if (currentSuwayaTasks.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: currentSuwayaTasks.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TaskCard(task: currentSuwayaTasks[index]),
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Text('pomodoro.no_tasks'.tr(), style: TextStyle(color: textColor.withValues(alpha: 0.3), fontSize: 14)),
                ),
              ),

            // 🌟 شريط السويعات المصغر والهادئ
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: currentPeriod.suwayasCount,
                itemBuilder: (context, index) {
                  final sNum = index + 1;
                  final isCurrent = sNum == astroState.currentSuwaya;
                  final isPast = sNum < astroState.currentSuwaya;
                  final dotColor = isCurrent ? activeColor : (isDark ? Colors.white24 : Colors.black26);
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isPast ? LucideIcons.circle_check : (isCurrent ? LucideIcons.circle_dot : LucideIcons.circle), color: dotColor, size: 16),
                        const SizedBox(height: 4),
                        Text(sNum.toString(), style: TextStyle(color: dotColor, fontSize: 12, fontFamily: 'Playfair Display', fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 100), // مساحة للشريط السفلي
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(String title, int value, int currentValue, Color activeColor, bool isDark) {
    final isSelected = value == currentValue;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(pomodoroModeProvider.notifier).state = value;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? activeColor : (isDark ? Colors.white54 : Colors.black54), 
            fontSize: 13, 
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ZenTimerPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final bool isDark;

  _ZenTimerPainter({required this.progress, required this.activeColor, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // الدائرة الخلفية النحيفة المريحة
    final trackPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, trackPaint);

    // دائرة التقدم
    final progressPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      progress * 2 * pi,
      false,
      progressPaint,
    );

    // مؤشر النهاية (Knob)
    final knobAngle = -pi / 2 + (progress * 2 * pi);
    final knobCenter = Offset(
      center.dx + cos(knobAngle) * radius,
      center.dy + sin(knobAngle) * radius,
    );
    canvas.drawCircle(knobCenter, 8, Paint()..color = activeColor);
    canvas.drawCircle(knobCenter, 4, Paint()..color = isDark ? Colors.black : Colors.white);
  }

  @override
  bool shouldRepaint(covariant _ZenTimerPainter old) => old.progress != progress || old.activeColor != activeColor || old.isDark != isDark;
}