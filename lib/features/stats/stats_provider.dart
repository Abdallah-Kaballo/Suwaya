import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import '../../core/database/local_db_service.dart';
import '../../models/activity_log_model.dart'; // 🌟 استيراد سجل الأحداث

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
    final db = LocalDbService.isar;
    final now = DateTime.now().toUtc();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    
    // 🌟 1. استدعاء الأحداث من ActivityLog بدلاً من المهام
    // نستثني الأحداث التي تراجع عنها المستخدم (isDeleted = true)
    final recentLogs = await db.activityLogs
        .filter()
        .isDeletedEqualTo(false)
        .completedAtUtcGreaterThan(sevenDaysAgo)
        .findAll();

    if (recentLogs.isEmpty) {
      state = StatsState(isLoading: false);
      return;
    }

    final heatmap = <int, int>{};
    int topPeriodId = 1;
    int maxTasks = 0;
    
    // 🌟 2. تتبع الأيام الفريدة النشطة لحساب مؤشر التناغم
    final activeDays = <String>{};

    for (var log in recentLogs) {
      final pId = log.periodId ?? 1;
      // نجمع عدد السويعات (الجهد الفعلي) وليس مجرد عدد المهام
      heatmap[pId] = (heatmap[pId] ?? 0) + log.suwayasCount;
      activeDays.add(log.activeDayDate);
      
      if (heatmap[pId]! > maxTasks) {
        maxTasks = heatmap[pId]!;
        topPeriodId = pId;
      }
    }

    final archetypeInfo = _determineArchetype(topPeriodId);

    // 🌟 3. حساب مؤشر التناغم (Harmony) 
    // يرتكز الآن على عدد الأيام التي أُنجزت فيها مهام من أصل آخر 7 أيام
    int harmony = ((activeDays.length / 7) * 100).round().clamp(0, 100);

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
      case 1: return {'title': 'نسمة الفجر 🕊️', 'desc': 'طاقة البدايات والبركة تتجلى في إنجازاتك الصباحية.'};
      case 2: return {'title': 'رائد الضُّحى 🌤️', 'desc': 'شمس الضحى تضيء إنتاجيتك، أنت في قمة تركيزك نهاراً.'};
      case 3: 
      case 4: return {'title': 'فارس النهار 🐎', 'desc': 'لا تعرف الكسل في كبد النهار، إنجازاتك مستمرة وقوية.'};
      case 5:
      case 6:
      case 7: return {'title': 'ساهر السَّحَر 🌙', 'desc': 'في الوقت الذي ينام فيه الناس، ترتفع أعمالك وإنجازاتك بهدوء.'};
      default: return {'title': 'متوازن ⚖️', 'desc': 'توزع مجهودك ببراعة على مدار اليوم.'};
    }
  }

  List<String> _generateSmartInsights(Map<int, int> heatmap, int harmony, int topPeriodId) {
    List<String> insights = [];
    
    if (harmony >= 80) {
      insights.add("تناغمك الفلكي مرتفع جداً! استمرارية رائعة خلال الأسبوع الماضي.");
    } else if (harmony <= 40) {
      insights.add("يبدو أنك مررت بأسبوع حافل. حاول توزيع مهامك لتقليل الضغط.");
    }

    if (topPeriodId == 1) {
      insights.add("تركيزك في الفجر يمنحك أفضلية مذهلة وصفاءً ذهنياً لباقي اليوم.");
    } else if (topPeriodId >= 5) {
      insights.add("نشاطك الليلي ممتاز، لكن تأكد من أخذ قسط كافٍ من الراحة الجسدية.");
    }

    if (insights.isEmpty) {
      insights.add("أداؤك مستقر وتوزع طاقتك بشكل جيد على الفترات المختلفة.");
    }

    return insights;
  }

  void refreshStats() {
    _calculateAstroStats();
  }
}

final statsProvider = NotifierProvider<StatsNotifier, StatsState>(StatsNotifier.new);