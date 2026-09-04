import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/local_db_service.dart';
import '../../models/task_model.dart';

class StatsState {
  final String archetypeTitle;       
  final String archetypeDescription; 
  final int harmonyScore;            
  final Map<int, int> periodHeatmap; 
  final List<String> insights;       
  final bool isLoading;

  StatsState({
    this.archetypeTitle = 'في طور الاكتشاف 🔭',
    this.archetypeDescription = 'أنجز المزيد من المهام لنكتشف نمطك الفلكي.',
    this.harmonyScore = 100,
    this.periodHeatmap = const {},
    this.insights = const [],
    this.isLoading = true,
  });
}

class StatsNotifier extends Notifier<StatsState> {
  @override
  StatsState build() {
    _calculateAstroStats();
    return StatsState(); 
  }

  Future<void> _calculateAstroStats() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    final recentCompletedTasks = await LocalDbService.getRecentCompletedTasks(sevenDaysAgo);

    if (recentCompletedTasks.isEmpty) {
      state = StatsState(isLoading: false);
      return;
    }

    final heatmap = <int, int>{};
    int topPeriodId = 1;
    int maxTasks = 0;

    for (var task in recentCompletedTasks) {
      final pId = task.targetPeriodId ?? 1;
      heatmap[pId] = (heatmap[pId] ?? 0) + 1;
      
      if (heatmap[pId]! > maxTasks) {
        maxTasks = heatmap[pId]!;
        topPeriodId = pId;
      }
    }

    final archetypeInfo = _determineArchetype(topPeriodId);

    int unmigratedTasksCount = recentCompletedTasks.where((t) => t.migrationCount == 0).length;
    int harmony = ((unmigratedTasksCount / recentCompletedTasks.length) * 100).round();

    final generatedInsights = _generateSmartInsights(recentCompletedTasks, harmony, topPeriodId);

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
      case 1: return {'title': 'title_fajr', 'desc': 'desc_fajr'};
      case 2: return {'title': 'title_duha', 'desc': 'desc_duha'};
      case 3: return {'title': 'title_dhuhr', 'desc': 'desc_dhuhr'};
      case 4: return {'title': 'title_asr', 'desc': 'desc_asr'};
      case 5:
      case 6:
      case 7: return {'title': 'title_night', 'desc': 'desc_night'};
      default: return {'title': 'title_balanced', 'desc': 'desc_balanced'};
    }
  }

  List<String> _generateSmartInsights(List<TaskModel> recentTasks, int harmony, int topPeriodId) {
    List<String> insights = [];

    final tarweehMigrated = recentTasks.where((t) => t.category == TaskCategory.unspecified && t.migrationCount > 3).length;
  
    if (tarweehMigrated > 0) {
      insights.add("insight_tarweeh"); 
    }
    
    if (harmony >= 90) {
      insights.add("insight_harmony_high");
    } else if (harmony < 50) {
      insights.add("insight_harmony_low");
    }

    if (topPeriodId == 2) {
      insights.add("insight_duha");
    } else if (topPeriodId >= 5) {
      insights.add("insight_night");
    }

    if (insights.isEmpty) {
      insights.add("insight_stable");
    }

    return insights;
  }

  void refreshStats() {
    _calculateAstroStats();
  }
}

final statsProvider = NotifierProvider<StatsNotifier, StatsState>(StatsNotifier.new);