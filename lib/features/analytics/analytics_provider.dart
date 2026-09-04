import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/local_db_service.dart';
import '../../models/task_model.dart';
import 'package:isar_community/isar.dart';

class AnalyticsState {
  final int totalCompleted;
  final String cosmicTitle;
  final String titleDescription;
  final Map<int, int> completionByPeriod; // معرف الفترة : عدد المهام
  final bool isLoading;

  AnalyticsState({
    required this.totalCompleted,
    required this.cosmicTitle,
    required this.titleDescription,
    required this.completionByPeriod,
    this.isLoading = false,
  });

  // الحالة الافتراضية
   factory AnalyticsState.empty() => AnalyticsState(
     totalCompleted: 0,
     cosmicTitle: 'title_new_explorer', // 🟢 مفتاح
     titleDescription: 'desc_new_explorer', // 🟢 مفتاح
     completionByPeriod: {},
     isLoading: true,
   );
}

class AnalyticsNotifier extends Notifier<AnalyticsState> {
  @override
  AnalyticsState build() {
    _loadAnalytics();
    return AnalyticsState.empty();
  }

  Future<void> _loadAnalytics() async {
    final isar = LocalDbService.isar;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    // جلب المهام المنجزة في آخر 7 أيام
    final completedTasks = await isar.taskModels
        .filter()
        .isCompletedEqualTo(true)
        .completedAtGreaterThan(sevenDaysAgo)
        .findAll();

    Map<int, int> periodCounts = {};
    for (var task in completedTasks) {
      if (task.targetPeriodId != null) {
        periodCounts[task.targetPeriodId!] = (periodCounts[task.targetPeriodId!] ?? 0) + 1;
      }
    }

    // 🏆 محرك الألقاب الذكي (Gamification Engine)
    String title = 'مستكشف كوني';
    String desc = 'أنت توزع جهدك بشكل متوازن على مدار اليوم';
    
    if (periodCounts.isNotEmpty) {
      // إيجاد الفترة الأكثر إنجازاً
      final topPeriod = periodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      
      switch (topPeriod) {
        case 1:
          title = 'نسمة الفجر 🕊️';
          desc = 'طاقة البدايات والبركة تتجلى في إنجازاتك الصباحية المبكرة.';
          break;
        case 2:
          title = 'رائد الضُّحى 🌤️';
          desc = 'شمس الضحى تضيء إنتاجيتك، أنت في قمة تركيزك نهاراً.';
          break;
        case 3:
        case 4:
          title = 'فارس النهار 🐎';
          desc = 'لا تعرف الكسل في كبد النهار، إنجازاتك مستمرة وقوية.';
          break;
        case 5:
        case 6:
          title = 'نجم المساء 🌟';
          desc = 'تتألق إنجازاتك مع غياب الشمس، هدوء الليل يلهمك.';
          break;
        case 7:
          title = 'ساهر السَّحَر 🌙';
          desc = 'في الوقت الذي ينام فيه الناس، ترتفع أعمالك وإنجازاتك بهدوء.';
          break;
      }
    }

    state = AnalyticsState(
      totalCompleted: completedTasks.length,
      cosmicTitle: title,
      titleDescription: desc,
      completionByPeriod: periodCounts,
      isLoading: false,
    );
  }

  void refresh() => _loadAnalytics();
}

final analyticsProvider = NotifierProvider<AnalyticsNotifier, AnalyticsState>(AnalyticsNotifier.new);