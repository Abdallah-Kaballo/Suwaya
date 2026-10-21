import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:easy_localization/easy_localization.dart';

part 'task_model.g.dart';

enum TaskCategory {
  unspecified,
  work,
  study,
  sport,
  entertainment,
  worship,
  personal,
  social,
}

enum TaskType { casual, permanent }

extension TaskCategoryExtension on TaskCategory {
  String get displayName {
    switch (this) {
      case TaskCategory.unspecified:
        return 'categories.unspecified'.tr();
      case TaskCategory.work:
        return 'categories.work'.tr();
      case TaskCategory.study:
        return 'categories.study'.tr();
      case TaskCategory.sport:
        return 'categories.sport'.tr();
      case TaskCategory.entertainment:
        return 'categories.entertainment'.tr();
      case TaskCategory.worship:
        return 'categories.worship'.tr();
      case TaskCategory.personal:
        return 'categories.personal'.tr();
      case TaskCategory.social:
        return 'categories.social'.tr();
    }
  }

  Color get dialColor {
    switch (this) {
      case TaskCategory.work:
        return const Color(0xFF00E5FF);
      case TaskCategory.study:
        return const Color(0xFF00E676);
      case TaskCategory.sport:
        return const Color(0xFFFF3D00);
      case TaskCategory.worship:
        return const Color(0xFFFFC400);
      case TaskCategory.entertainment:
        return const Color(0xFFFF4081);
      case TaskCategory.personal:
        return const Color(0xFFD500F9);
      case TaskCategory.social:
        return const Color(0xFF76FF03);
      case TaskCategory.unspecified:
        return const Color(0xFF18FFFF);
    }
  }

  Color uiColor(bool isDark) {
    if (isDark) return dialColor;
    switch (this) {
      case TaskCategory.work:
        return const Color(0xFF006978);
      case TaskCategory.study:
        return const Color(0xFF1B5E20);
      case TaskCategory.sport:
        return const Color(0xFFBF360C);
      case TaskCategory.worship:
        return const Color(0xFF8A5A00);
      case TaskCategory.entertainment:
        return const Color(0xFFAD1457);
      case TaskCategory.personal:
        return const Color(0xFF6A1B9A);
      case TaskCategory.social:
        return const Color(0xFF33691E);
      case TaskCategory.unspecified:
        return const Color(0xFF006064);
    }
  }
}

@collection
class TaskModel {
  Id id = Isar.autoIncrement;

  String title = '';
  
  @enumerated
  TaskType type = TaskType.casual;

  @enumerated
  TaskCategory category = TaskCategory.unspecified; 

  bool isCompleted = false;
  DateTime? completedAt;

  @Index()
  DateTime? targetDate;

  // 🌟 التعديل الجوهري: إضافة إصدار النموذج للتفرقة بين جداول 48 القديمة و 24 الجديدة
  int scheduleModelVersion = 2;

  @Index()
  int? targetPeriodId;

  List<int> targetSuwayas = [];
  int targetVirtualMinute = 0;

  bool isAstroTime = true;
  int? targetCivilTimeMinutes;
  
  List<int>? recurrenceDays; 

  bool notifyMode = true;   
  bool alarmMode = false;   
  bool vibrateMode = false; 

  String alarmTone = 'assets/audio/default.mp3'; 
  double alarmVolume = 1.0;

  bool showOnDial = false;
  String? dialShortName;

  List<DateTime> completionHistory = [];
  @Index()
  DateTime? lastCompletedDate; 
  int currentStreak = 0;
  int longestStreak = 0;

  int migrationCount = 0;
  DateTime createdAt = DateTime.now();

  @ignore
  bool get isCompletedToday {
    if (type == TaskType.casual) return isCompleted;
    if (lastCompletedDate == null) return false;
    final now = DateTime.now();
    return lastCompletedDate!.year == now.year &&
           lastCompletedDate!.month == now.month &&
           lastCompletedDate!.day == now.day;
  }

  /// 🌟 فحص إنجاز المهمة/العادة بناءً على التاريخ المنطقي (السويعي من المغرب أو المدني من منتصف الليل)
  bool isCompletedOnDate(DateTime logicalDate) {
    if (type == TaskType.casual) return isCompleted;
    if (lastCompletedDate == null) return false;
    return lastCompletedDate!.year == logicalDate.year &&
           lastCompletedDate!.month == logicalDate.month &&
           lastCompletedDate!.day == logicalDate.day;
  }
}