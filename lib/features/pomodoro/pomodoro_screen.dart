import 'dart:math' show pi, cos, sin;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:timezone/timezone.dart' as tz;

import '../../core/astro_engine/astro_provider.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../core/providers/ui_providers.dart'; 
import '../../features/settings/settings_provider.dart'; 

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

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  // 🌟 هذا المتغير الآن يحمل "الثواني الافتراضية" (من 0 إلى 1800)
  final ValueNotifier<double> _virtualElapsedSecs = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) => _updateTime());
    _ticker.start();
  }

  void _updateTime() {
    final astro = ref.read(astroProvider);
    if (astro.periods.isEmpty) return;

    final settings = ref.read(settingsProvider);
    final loc = settings.activeLocation;
    DateTime cityNow;
    
    if (loc != null && loc.isAutoLocation == false && loc.timezone != null) {
      try {
        final location = tz.getLocation(loc.timezone!);
        final nowInTarget = tz.TZDateTime.now(location);
        cityNow = DateTime.utc(nowInTarget.year, nowInTarget.month, nowInTarget.day, nowInTarget.hour, nowInTarget.minute, nowInTarget.second, nowInTarget.millisecond);
      } catch (_) {
        final now = DateTime.now();
        cityNow = DateTime.utc(now.year, now.month, now.day, now.hour, now.minute, now.second, now.millisecond);
      }
    } else {
      final now = DateTime.now();
      cityNow = DateTime.utc(now.year, now.month, now.day, now.hour, now.minute, now.second, now.millisecond);
    }

    final currentPeriod = astro.currentPeriod;
    final totalMicroseconds = currentPeriod.totalDuration.inMicroseconds;
    if (totalMicroseconds <= 0) return;

    int sCount = currentPeriod.suwayasCount > 0 ? currentPeriod.suwayasCount : 7;
    final suwayaDurationMicroseconds = totalMicroseconds / sCount;

    int elapsedMicroseconds = cityNow.difference(currentPeriod.startTime).inMicroseconds;
    if (elapsedMicroseconds < 0) elapsedMicroseconds = 0;

    // 🌟 حساب النسبة المئوية الدقيقة لمرور الوقت داخل السويعة الحالية (0.0 إلى 1.0)
    final double progress = ((elapsedMicroseconds % suwayaDurationMicroseconds) / suwayaDurationMicroseconds).clamp(0.0, 1.0);
    
    // 🌟 تحويل النسبة إلى "ثواني افتراضية" (دائماً من 0 إلى 1800 ثانية = 30 دقيقة)
    _virtualElapsedSecs.value = progress * 1800.0;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _virtualElapsedSecs.dispose();
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

    // 🌟 حل مشكلة التحميل اللانهائي
    if (astroState.periods.isEmpty) {
      return Scaffold(
        backgroundColor: scaffoldBgColor, 
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.read(astroProvider.notifier).resetToRealTime(),
                icon: const Icon(Icons.refresh),
                label: Text('common.retry'.tr()),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              )
            ],
          )
        )
      );
    }
    
    if (astroState.periods.isEmpty) {
      return Scaffold(backgroundColor: scaffoldBgColor, body: const Center(child: CircularProgressIndicator()));
    }

    // 🌟 ثوابت الزمن الافتراضي الدائمة (دائماً 30 دقيقة = 1800 ثانية)
    const double totalVirtualSecs = 1800.0; 
    double focusVirtualSecs = 1500.0; // الوضع الافتراضي 25 دقيقة تركيز
    if (mode == 0) focusVirtualSecs = 1800.0; // 30 دقيقة تركيز
    if (mode == 2) focusVirtualSecs = 1200.0; // 20 دقيقة تركيز

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
          valueListenable: _virtualElapsedSecs,
          builder: (context, elapsedVirtual, child) {
            
            // تحديد هل نحن في وقت التركيز أم الراحة
            final bool breakStatus = elapsedVirtual >= focusVirtualSecs;
            
            // حساب الثواني (الافتراضية) المتبقية
            double remainingVirtual = breakStatus 
                ? (totalVirtualSecs - elapsedVirtual) 
                : (focusVirtualSecs - elapsedVirtual);
                
            if (remainingVirtual < 0) remainingVirtual = 0;

            // حساب نسبة تقدم الدائرة
            double phaseProgress = 0.0;
            if (!breakStatus) {
              phaseProgress = focusVirtualSecs > 0 ? (elapsedVirtual / focusVirtualSecs) : 0.0;
            } else {
              final double breakTotal = totalVirtualSecs - focusVirtualSecs;
              final double breakElapsed = elapsedVirtual - focusVirtualSecs;
              phaseProgress = breakTotal > 0 ? (breakElapsed / breakTotal) : 0.0;
            }

            // 🌟 استخدام ceil() يضمن ظهور 25:00 كاملة في بداية الثواني
            final int remInt = remainingVirtual.ceil();
            final m = (remInt ~/ 60).toString().padLeft(2, '0');
            final s = (remInt % 60).toString().padLeft(2, '0');
            
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