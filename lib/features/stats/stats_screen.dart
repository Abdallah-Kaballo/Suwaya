import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/astro_engine/astro_models.dart';

import '../../core/astro_engine/astro_provider.dart';
import 'stats_provider.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(statsProvider.notifier).refreshStats());
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    final astroState = ref.watch(astroProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('المرآة الفلكية ✨', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: stats.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24).copyWith(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildArchetypeCard(stats, isDark),
                  const SizedBox(height: 24),
                  
                  _buildHarmonyCard(stats, isDark),
                  const SizedBox(height: 32),
                  
                  Text('خريطة نبضك الفلكي', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildHeatmapSection(stats, astroState, isDark, context),
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      const Icon(LucideIcons.sparkles, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text('همسات السُّوَيْعَة', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInsightsList(stats, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildArchetypeCard(StatsState stats, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withValues(alpha: isDark ? 0.15 : 0.2), Colors.amber.withValues(alpha: isDark ? 0.02 : 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.compass, color: Colors.amber, size: 40),
          ),
          const SizedBox(height: 16),
          Text('أنت هذا الأسبوع', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
          const SizedBox(height: 8),
          Text(stats.archetypeTitle, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            stats.archetypeDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 15, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildHarmonyCard(StatsState stats, bool isDark) {
    String moonPhase;
    if (stats.harmonyScore >= 90) {
      moonPhase = '🌕';
    } else if (stats.harmonyScore >= 70) {
      moonPhase = '🌖';
    } else if (stats.harmonyScore >= 50) {
      moonPhase = '🌗';
    } else if (stats.harmonyScore >= 30) {
      moonPhase = '🌘';
    } else {
      moonPhase = '🌑';
    }

    final cardColor = isDark ? const Color(0xFF1E2530) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Text(moonPhase, style: const TextStyle(fontSize: 42)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مؤشر التناغم الفلكي', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${stats.harmonyScore}', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 28, fontWeight: FontWeight.bold)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, right: 4),
                      child: Text('%', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: stats.harmonyScore / 100,
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      stats.harmonyScore >= 70 ? Colors.greenAccent : (stats.harmonyScore >= 40 ? Colors.amber : Colors.deepOrangeAccent),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSection(StatsState stats, AstroState astroState, bool isDark, BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E2530) : Colors.white;

    if (astroState.periods.isEmpty || stats.periodHeatmap.isEmpty) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, color: isDark ? Colors.white24 : Colors.black26, size: 32), // 🌟 الإصلاح: تغيير الأيقونة
            const SizedBox(height: 12),
            Text('لا توجد مهام منجزة كافية لرسم خريطتك بعد', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)),
          ],
        ),
      );
    }

    final maxTasks = stats.periodHeatmap.values.reduce(max);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: astroState.periods.map<Widget>((period) {
          final taskCount = stats.periodHeatmap[period.id] ?? 0;
          final barHeight = maxTasks > 0 ? (taskCount / maxTasks) * 80.0 : 0.0;
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(taskCount > 0 ? '$taskCount' : '', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              Container(
                width: 16,
                height: barHeight == 0 ? 4 : barHeight, 
                decoration: BoxDecoration(
                  color: taskCount > 0 ? period.color : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: taskCount > 0 ? [BoxShadow(color: period.color.withValues(alpha: 0.4), blurRadius: 8)] : null,
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                period.shortName,
                style: TextStyle(
                  color: taskCount > 0 ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white38 : Colors.black38),
                  fontSize: 10,
                  fontWeight: taskCount > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightsList(StatsState stats, bool isDark) {
    if (stats.insights.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Center(
          child: Column(
            children: [
              Icon(LucideIcons.lightbulb, color: isDark ? Colors.white24 : Colors.black26, size: 32),
              const SizedBox(height: 12),
              Text('اكتشف همساتك هنا قريباً...', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: stats.insights.map((insight) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✨', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight,
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.6),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}