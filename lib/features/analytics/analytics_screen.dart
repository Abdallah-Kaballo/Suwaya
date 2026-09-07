import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/app_drawer.dart';
import '../tasks/tasks_provider.dart';
import '../../core/providers/ui_providers.dart'; // 🌟

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;
    final surfaceColor = isDark ? const Color(0xFF1E2530) : Colors.white;

    final tasksState = ref.watch(tasksProvider);
    final todayTasks = tasksState.todayTasks;
    final totalTasks = todayTasks.length;
    final completedTasks = todayTasks.where((t) => t.isCompletedToday).length;
    final progress = totalTasks == 0 ? 0.0 : (completedTasks / totalTasks);

    final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      // 🌟 تفعيل الإخفاء
      onDrawerChanged: (isOpen) => ref.read(isDrawerOpenProvider.notifier).state = isOpen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(LucideIcons.menu, color: textColor),
            onPressed: () {
              HapticFeedback.lightImpact();
              Scaffold.of(ctx).openDrawer();
            },
          ),
        ),
        title: Text('analytics.title'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
              boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 110, height: 110,
                  child: CustomPaint(
                    painter: _RealisticRingPainter(progress: progress, color: primaryColor, isDark: isDark),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Playfair Display'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('analytics.daily_progress'.tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(
                        totalTasks == 0 
                            ? '0 / 0' 
                            : '$completedTasks ${'common.of'.tr()} $totalTasks',
                        style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        totalTasks == 0 
                            ? 'analytics.coming_soon'.tr() 
                            : (completedTasks == totalTasks ? 'analytics.perfect_day'.tr() : 'analytics.keep_going'.tr()),
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _buildRealisticStatCard(context, LucideIcons.flame, 'analytics.current_streak'.tr(), totalTasks == 0 ? '0' : (completedTasks > 0 ? '1' : '0'), 'analytics.days'.tr(), Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _buildRealisticStatCard(context, LucideIcons.check, 'tasks.tab_casual'.tr(), '$completedTasks', 'common.done'.tr(), Colors.green)),
            ],
          ),

          const SizedBox(height: 32),
          Text('analytics.weekly_overview'.tr(), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          Container(
            height: 220,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final barProgress = (index == todayIndex) ? progress : 0.0;
                return _buildRealisticBar(context, weekDays[index], barProgress, primaryColor, isToday: index == todayIndex);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealisticStatCard(BuildContext context, IconData icon, String title, String value, String unit, Color iconColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2530) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Playfair Display')),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(unit, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRealisticBar(BuildContext context, String label, double fillPercent, Color color, {bool isToday = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            width: 14,
            alignment: Alignment.bottomCenter,
            decoration: BoxDecoration(
              color: emptyColor,
              borderRadius: BorderRadius.circular(7),
            ),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final height = (constraints.maxHeight * fillPercent).clamp(0.0, constraints.maxHeight);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  height: height,
                  decoration: BoxDecoration(
                    color: isToday ? color : color.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(7),
                  ),
                );
              }
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: isToday ? color : (isDark ? Colors.white54 : Colors.black54),
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RealisticRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _RealisticRingPainter({required this.progress, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    
    if (progress > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, progress * 2 * pi, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticRingPainter old) => old.progress != progress;
}