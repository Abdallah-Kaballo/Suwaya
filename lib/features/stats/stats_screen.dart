import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suwaya/core/astro_engine/astro_models.dart';

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
      ),
      body: stats.isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : RefreshIndicator(
              color: Colors.amber,
              backgroundColor: isDark ? const Color(0xFF1E2530) : Colors.white,
              onRefresh: () async {
                HapticFeedback.lightImpact();
                ref.read(statsProvider.notifier).refreshStats();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.all(24).copyWith(bottom: 100),
                children: [
                  _buildArchetypeCard(stats, isDark),
                  const SizedBox(height: 24),
                  
                  _buildHarmonyCard(stats, isDark),
                  const SizedBox(height: 32),
                  
                  Text('الخريطة الحرارية (آخر 7 أيام)', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildHeatmapGrid(stats, astroState, isDark),
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      const Icon(LucideIcons.sparkles, color: Colors.amber, size: 20),
                      const SizedBox(width: 8),
                      Text('رؤى السُّوَيْعَة الذكية', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
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
          colors: [
            Colors.amber.withValues(alpha: isDark ? 0.15 : 0.3), 
            Colors.amber.withValues(alpha: isDark ? 0.02 : 0.05)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1.5),
        boxShadow: isDark ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5)] : [],
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
          Text('نمطك الفلكي الحالي', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(stats.archetypeTitle, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Text(
            stats.archetypeDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildHarmonyCard(StatsState stats, bool isDark) {
    String moonPhase;
    Color phaseColor;
    if (stats.harmonyScore >= 80) { moonPhase = '🌕'; phaseColor = Colors.amber; } 
    else if (stats.harmonyScore >= 60) { moonPhase = '🌖'; phaseColor = Colors.blueAccent; } 
    else if (stats.harmonyScore >= 40) { moonPhase = '🌗'; phaseColor = Colors.orangeAccent; } 
    else if (stats.harmonyScore >= 20) { moonPhase = '🌘'; phaseColor = Colors.deepOrange; } 
    else { moonPhase = '🌑'; phaseColor = Colors.redAccent; }

    final cardColor = isDark ? const Color(0xFF1E2530) : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 70, height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: phaseColor.withValues(alpha: 0.1),
              border: Border.all(color: phaseColor.withValues(alpha: 0.3)),
            ),
            child: Text(moonPhase, style: const TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('مؤشر التناغم', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${stats.harmonyScore}', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 32, fontWeight: FontWeight.w900)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, right: 4),
                      child: Text('%', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: stats.harmonyScore / 100,
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🌟 هنا السر: الخريطة الحرارية بأسلوب المربعات
  Widget _buildHeatmapGrid(StatsState stats, AstroState astroState, bool isDark) {
    final cardColor = isDark ? const Color(0xFF1E2530) : Colors.white;

    if (astroState.periods.isEmpty || stats.periodHeatmap.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cardColor, 
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.activity, color: isDark ? Colors.white24 : Colors.black26, size: 36),
            const SizedBox(height: 12),
            Text('سجل إنجازاتك فارغ هذا الأسبوع', style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 14)),
          ],
        ),
      );
    }

    final maxTasks = stats.periodHeatmap.values.reduce(max);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: astroState.periods.map<Widget>((period) {
          final count = stats.periodHeatmap[period.id] ?? 0;
          
          // حساب مستوى الإضاءة (من 0 إلى 5 مربعات)
          int activeBlocks = 0;
          if (count > 0) {
            activeBlocks = ((count / maxTasks) * 5).ceil().clamp(1, 5);
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(count > 0 ? '$count' : '', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              // بناء عمود المربعات
              Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  // المربعات ترسم من الأسفل للأعلى (index 0 هو الأعلى)
                  final isLit = (4 - index) < activeBlocks;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    margin: const EdgeInsets.only(bottom: 4),
                    width: 20,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isLit 
                          ? period.color 
                          : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: isLit && isDark 
                          ? [BoxShadow(color: period.color.withValues(alpha: 0.4), blurRadius: 6)] 
                          : null,
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 12),
              Text(
                period.shortName,
                style: TextStyle(
                  color: count > 0 ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white38 : Colors.black38),
                  fontSize: 11,
                  fontWeight: count > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInsightsList(StatsState stats, bool isDark) {
    if (stats.insights.isEmpty) return const SizedBox.shrink();

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
              Icon(LucideIcons.zap, color: Colors.amber.withValues(alpha: 0.8), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight,
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13, height: 1.6, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}