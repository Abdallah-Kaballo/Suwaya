import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌟 إضافة استيراد الترجمة
import '../../core/repositories/activity_log_repository.dart';

class StatsState {
  final String archetypeTitle;       
  final String archetypeDescription; 
  final int harmonyScore;            
  final Map<int, int> periodHeatmap; 
  final List<String> insights;       
  final bool isLoading;

  StatsState({
    String? archetypeTitle,
    String? archetypeDescription,
    this.harmonyScore = 100,
    this.periodHeatmap = const {},
    this.insights = const [],
    this.isLoading = true,
  }) : archetypeTitle = archetypeTitle ?? 'stats.discovery_title'.tr(), // 🌟 استخدام الترجمة بأمان
       archetypeDescription = archetypeDescription ?? 'stats.discovery_desc'.tr();
}

class StatsNotifier extends Notifier<StatsState> {
  @override
  StatsState build() {
    _calculateAstroStats();
    return StatsState(); 
  }

  Future<void> _calculateAstroStats() async {
    final repository = ref.read(activityLogRepositoryProvider);
    final now = DateTime.now().toUtc();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    final recentLogs = await repository.getRecentActiveLogs(sevenDaysAgo);

    if (recentLogs.isEmpty) {
      state = StatsState(isLoading: false);
      return;
    }

    final heatmap = <int, int>{};
    int topPeriodId = 1;
    int maxTasks = 0;
    
    final activeDays = <String>{};

    for (var log in recentLogs) {
      final pId = log.periodId ?? 1;
      heatmap[pId] = (heatmap[pId] ?? 0) + log.suwayasCount;
      activeDays.add(log.activeDayDate);
      
      if (heatmap[pId]! > maxTasks) {
        maxTasks = heatmap[pId]!;
        topPeriodId = pId;
      }
    }

    final archetypeInfo = _determineArchetype(topPeriodId);

    int harmony = ((activeDays.length * 100) ~/ 7).clamp(0, 100);

    final generatedInsights = _generateSmartInsights(heatmap, harmony, topPeriodId);

    state = StatsState(
      archetypeTitle: archetypeInfo['title']!,
      archetypeDescription: archetypeInfo['desc']!,
      harmonyScore: harmony,
      periodHeatmap: heatmap,
      insights: generatedInsights,
      isLoading: false,
    );
  }

  Map<String, String> _determineArchetype(int topPeriodId) {
    switch (topPeriodId) {
      case 1: return {'title': 'stats.fajr_title'.tr(), 'desc': 'stats.fajr_desc'.tr()};
      case 2: return {'title': 'stats.duha_title'.tr(), 'desc': 'stats.duha_desc'.tr()};
      case 3: 
      case 4: return {'title': 'stats.day_title'.tr(), 'desc': 'stats.day_desc'.tr()};
      case 5:
      case 6:
      case 7: return {'title': 'stats.night_title'.tr(), 'desc': 'stats.night_desc'.tr()};
      default: return {'title': 'stats.balanced_title'.tr(), 'desc': 'stats.balanced_desc'.tr()};
    }
  }

  List<String> _generateSmartInsights(Map<int, int> heatmap, int harmony, int topPeriodId) {
    List<String> insights = [];
    
    if (harmony >= 80) {
      insights.add('stats.insight_harmony_high'.tr());
    } else if (harmony <= 40) {
      insights.add('stats.insight_harmony_low'.tr());
    }

    if (topPeriodId == 1) {
      insights.add('stats.insight_fajr_focus'.tr());
    } else if (topPeriodId >= 5) {
      insights.add('stats.insight_night_focus'.tr());
    }

    if (insights.isEmpty) {
      insights.add('stats.insight_stable'.tr());
    }

    return insights;
  }

  void refreshStats() {
    _calculateAstroStats();
  }
}

final statsProvider = NotifierProvider<StatsNotifier, StatsState>(StatsNotifier.new);