import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';

import 'analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.amber))
            : RefreshIndicator(
                color: Colors.amber,
                backgroundColor: Theme.of(context).cardColor,
                onRefresh: () async => ref.read(analyticsProvider.notifier).refresh(),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildTitleCard(state).animate().fade().slideY(begin: 0.2, curve: Curves.easeOut),
                    const SizedBox(height: 24),
                    _buildStatsRow(state).animate().fade(delay: 100.ms).slideY(begin: 0.2),
                    const SizedBox(height: 32),
                    const Text('نبض الإنجاز الفلكي (آخر 7 أيام)', 
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                    ).animate().fade(delay: 200.ms),
                    const SizedBox(height: 24),
                    _buildChart(state).animate().fade(delay: 300.ms).scale(curve: Curves.easeOutBack),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('analytics_title'.tr(), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('cosmic_harvest'.tr(), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14)),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.bar_chart_rounded, color: Colors.amber), // 🌟 الإصلاح: تغيير الأيقونة
        ),
      ],
    );
  }

  Widget _buildTitleCard(AnalyticsState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2530), Color(0xFF161B22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.amber.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Column(
        children: [
          Text('analytics_cosmic_title'.tr(), style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          const SizedBox(height: 12),
          Text(state.cosmicTitle, style: const TextStyle(color: Colors.amber, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(
            state.titleDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(AnalyticsState state) {
    return Row(
      children: [
        Expanded(child: _buildStatBox('completed_tasks_count'.tr(), '${state.totalCompleted}', LucideIcons.circle_check, Colors.greenAccent)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatBox('commitment_rate'.tr(), 'regular_commitment'.tr(), LucideIcons.trending_up, Colors.blueAccent)),
    ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChart(AnalyticsState state) {
    final periods = [
    'chart_fajr'.tr(), 'chart_duha'.tr(), 'chart_dhuhr'.tr(), 
    'chart_asr'.tr(), 'chart_maghrib'.tr(), 'chart_isha1'.tr(), 'chart_isha2'.tr()
  ];
    List<BarChartGroupData> barGroups = [];
    for (int i = 1; i <= 7; i++) {
      final count = state.completionByPeriod[i] ?? 0;
      barGroups.add(
        BarChartGroupData(
          x: i - 1,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: count > 0 ? Colors.amber : Colors.white12,
              width: 16,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 10,
                color: const Color(0xFF1E2530),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 30, right: 20, left: 20, bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      periods[value.toInt()],
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }
}