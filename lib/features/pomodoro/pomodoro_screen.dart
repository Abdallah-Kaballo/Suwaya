import 'dart:async';
import 'dart:math' show pi, cos, sin;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../core/astro_engine/astro_provider.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../core/providers/ui_providers.dart'; 

final pomodoroModeProvider = StateProvider<int>((ref) => 1);

Color _getSafePeriodColor(int id) {
  switch (id) {
    case 1: return const Color(0xFF64B5F6);
    case 2: return Colors.orangeAccent;
    case 3: return const Color(0xFFFFCA28);
    case 4: return const Color(0xFFFF9800);
    case 5: return const Color(0xFFE53935);
    case 6: return const Color(0xFF3F51B5);
    case 7: return const Color(0xFF1A237E);
    default: return Colors.grey;
  }
}

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> {
  Timer? _timer;
  final ValueNotifier<double> _exactElapsedSecs = ValueNotifier(0.0);
  int _currentPeriodId = -1;

  @override
  void initState() {
    super.initState();
    _startDynamicTimer();
  }

  void _startDynamicTimer() {
    _timer?.cancel();
    final astro = ref.read(astroProvider);
    if (astro.periods.isEmpty) return;
    
    _currentPeriodId = astro.currentPeriod.id;
    final speed = astro.timeSpeedMultiplier;
    final msPerVirtualSec = speed > 0 ? (1000 / speed).round() : 1000;

    _updateTime(); 
    _timer = Timer.periodic(Duration(milliseconds: msPerVirtualSec), (_) {
      final currentAstro = ref.read(astroProvider);
      if (currentAstro.currentPeriod.id != _currentPeriodId) {
         _startDynamicTimer();
         return;
      }
      _updateTime();
    });
  }

  void _updateTime() {
    final astro = ref.read(astroProvider);
    if (astro.periods.isEmpty) return;
    final now = DateTime.now();
    final realDiff = now.difference(astro.currentPeriod.startTime);
    final virtualSeconds = (realDiff.inMicroseconds / 1000000.0) * astro.timeSpeedMultiplier;
    _exactElapsedSecs.value = virtualSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _exactElapsedSecs.dispose();
    super.dispose();
  }

  void _showInfoDialog(BuildContext context, dynamic astroState) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final surfaceColor = Theme.of(context).cardColor;
    
    final pColor = _getSafePeriodColor(astroState.currentPeriod.id);

    final speed = astroState.timeSpeedMultiplier;
    final actualTotalSecs = speed > 0 ? (1800 / speed).round() : 1800;
    final actMins = (actualTotalSecs ~/ 60).toString().padLeft(2, '0');
    final actSecs = (actualTotalSecs % 60).toString().padLeft(2, '0');

    String currentPeriodName = '';
    switch(astroState.currentPeriod.id) {
      case 1: currentPeriodName = 'periods.fajr'.tr(); break;
      case 2: currentPeriodName = 'periods.duha'.tr(); break;
      case 3: currentPeriodName = 'periods.dhuhr'.tr(); break;
      case 4: currentPeriodName = 'periods.asr'.tr(); break;
      case 5: currentPeriodName = 'periods.maghrib'.tr(); break;
      case 6: currentPeriodName = 'periods.middle_third'.tr(); break;
      case 7: currentPeriodName = 'periods.last_third'.tr(); break;
      default: currentPeriodName = astroState.currentPeriod.nameKey.tr();
    }

    final currentTimeStr = astroState.currentFormattedVirtualTime;
    final int displaySuwaya = astroState.currentSuwaya;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.info, color: pColor, size: 32),
              const SizedBox(height: 16),
              Text('pomodoro.suwaya_info'.tr(), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildInfoRow('pomodoro.current_time'.tr(), currentTimeStr, textColor, pColor),
              _buildInfoRow('common.period'.tr(), currentPeriodName, textColor, pColor),
              _buildInfoRow('common.suwaya'.tr(), '$displaySuwaya ${'common.of'.tr()} ${astroState.currentPeriod.suwayasCount}', textColor, pColor),
              _buildInfoRow('pomodoro.time_speed'.tr(), '${speed.toStringAsFixed(2)}x', textColor, pColor),
              _buildInfoRow('pomodoro.actual_length'.tr(), '$actMins:$actSecs', textColor, pColor),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: pColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('common.done'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildInfoRow(String title, String value, Color textColor, Color pColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 14)),
          Text(value, style: TextStyle(color: pColor, fontSize: 14, fontWeight: FontWeight.normal)),
        ],
      ),
    );
  }

  void _showModeSheet(BuildContext context, int currentMode, Color activeColor) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('pomodoro.customize_suwaya'.tr(), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _buildModeOption(ctx, 0, currentMode, 'pomodoro.absolute_focus'.tr(), 'pomodoro.absolute_focus_desc'.tr(), '30/0', activeColor, textColor),
              _buildModeOption(ctx, 1, currentMode, 'pomodoro.balanced_default'.tr(), 'pomodoro.balanced_desc'.tr(), '25/5', activeColor, textColor),
              _buildModeOption(ctx, 2, currentMode, 'pomodoro.relaxed'.tr(), 'pomodoro.relaxed_desc'.tr(), '20/10', activeColor, textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeOption(BuildContext ctx, int value, int currentValue, String title, String subtitle, String ratio, Color activeColor, Color textColor) {
    final isSelected = value == currentValue;
    return ListTile(
      onTap: () {
        HapticFeedback.lightImpact();
        ref.read(pomodoroModeProvider.notifier).state = value;
        Navigator.pop(ctx);
      },
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.transparent, shape: BoxShape.circle, border: Border.all(color: isSelected ? activeColor : textColor.withValues(alpha: 0.1))),
        child: Center(child: Text(ratio, style: TextStyle(color: isSelected ? activeColor : textColor.withValues(alpha: 0.5), fontWeight: FontWeight.bold, fontSize: 12))),
      ),
      title: Text(title, style: TextStyle(color: isSelected ? activeColor : textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 12)),
      trailing: isSelected ? Icon(LucideIcons.circle_check, color: activeColor) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final astroState = ref.watch(astroProvider);
    final mode = ref.watch(pomodoroModeProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (astroState.periods.isEmpty) {
      return Scaffold(backgroundColor: scaffoldBgColor, body: const Center(child: CircularProgressIndicator()));
    }

    const totalSuwayaSecs = 1800; 
    int focusDuration = 1500; 
    if (mode == 0) focusDuration = 1800; 
    if (mode == 2) focusDuration = 1200; 

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      drawer: const AppDrawer(),
      onDrawerChanged: (isOpen) => ref.read(isDrawerOpenProvider.notifier).state = isOpen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(LucideIcons.menu, color: textColor),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: Icon(LucideIcons.info, color: textColor.withValues(alpha: 0.5)),
              onPressed: () => _showInfoDialog(ctx, astroState),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<double>(
          valueListenable: _exactElapsedSecs,
          builder: (context, exactElapsed, child) {
            final double elapsedDouble = exactElapsed % totalSuwayaSecs;
            final int elapsedSecs = elapsedDouble.floor();
            final breakStatus = elapsedSecs >= focusDuration;
            final remainingSecs = breakStatus ? (totalSuwayaSecs - elapsedSecs) : (focusDuration - elapsedSecs);
            
            // 🌟 الفكرة الجديدة: حساب تقدم الدائرة كدائرة كاملة لكل مرحلة
            double phaseProgress = 0.0;
            if (!breakStatus) {
              phaseProgress = elapsedDouble / focusDuration;
            } else {
              final double breakTotal = (totalSuwayaSecs - focusDuration).toDouble();
              final double breakElapsed = elapsedDouble - focusDuration;
              phaseProgress = breakTotal > 0 ? (breakElapsed / breakTotal) : 0.0;
            }

            final m = (remainingSecs ~/ 60).toString().padLeft(2, '0');
            final s = (remainingSecs % 60).toString().padLeft(2, '0');
            
            final activeColor = breakStatus ? const Color(0xFF64B5F6) : const Color(0xFFE53935);

            return SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 320, height: 320,
                        // 🌟 تمرير التقدم المنفصل إلى رسام الدائرة
                        child: CustomPaint(painter: _ZenTimerPainter(progress: phaseProgress, activeColor: activeColor, isDark: isDark)),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Text('$m:$s', style: TextStyle(fontSize: 84, fontWeight: FontWeight.normal, fontFamily: 'Playfair Display', foreground: Paint()..style=PaintingStyle.stroke..strokeWidth=4.0..color=Colors.white)),
                              Text('$m:$s', style: const TextStyle(fontSize: 84, fontWeight: FontWeight.normal, color: Color(0xFFF2C94C), fontFamily: 'Playfair Display')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(breakStatus ? LucideIcons.coffee : LucideIcons.sparkles, color: activeColor, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                breakStatus ? 'pomodoro.deep_relaxation'.tr() : 'pomodoro.in_flow'.tr(),
                                style: TextStyle(color: activeColor, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  GestureDetector(
                    onTap: () => _showModeSheet(context, mode, activeColor),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: activeColor.withValues(alpha: 0.3))),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.sliders_horizontal, color: activeColor, size: 16),
                          const SizedBox(width: 8),
                          Text('pomodoro.focus_rest'.tr(), style: TextStyle(color: activeColor, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            );
          }
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

    final trackPaint = Paint()..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)..style = PaintingStyle.stroke..strokeWidth = 3.0;
    canvas.drawCircle(center, radius, trackPaint);

    final progressPaint = Paint()..color = activeColor..style = PaintingStyle.stroke..strokeWidth = 6.0..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, progress * 2 * pi, false, progressPaint);

    final knobAngle = -pi / 2 + (progress * 2 * pi);
    final knobCenter = Offset(center.dx + cos(knobAngle) * radius, center.dy + sin(knobAngle) * radius);
    canvas.drawCircle(knobCenter, 8, Paint()..color = activeColor);
    canvas.drawCircle(knobCenter, 4, Paint()..color = isDark ? Colors.black : Colors.white);
  }
  @override bool shouldRepaint(covariant _ZenTimerPainter old) => old.progress != progress || old.activeColor != activeColor || old.isDark != isDark;
}