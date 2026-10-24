import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:suwaya_time/suwaya_time.dart';

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
        return const Color(0xFF22D3EE); // سماوي سيان صافي
      case TaskCategory.study:
        return const Color(0xFF34D399); // زمردي مريح للعين
      case TaskCategory.sport:
        return const Color(0xFFFF6E40); // مرجاني برتقالي نشط وغير مجهد للعين
      case TaskCategory.worship:
        return const Color(0xFFFBBF24); // ذهبي كهرماني دافئ
      case TaskCategory.entertainment:
        return const Color(0xFFF472B6); // وردي ناعم واضح
      case TaskCategory.personal:
        return const Color(0xFFC084FC); // أرجواني لافندر متوازن
      case TaskCategory.social:
        return const Color(
            0xFF4ADE80); // أخضر نعناعي متناغم بدلاً من الليموني الفاقع
      case TaskCategory.unspecified:
        return const Color(0xFF94A3B8); // فضي أردوازي
    }
  }

  Color uiColor(bool isDark) {
    if (isDark) return dialColor;
    switch (this) {
      case TaskCategory.work:
        return const Color(0xFF0E7490);
      case TaskCategory.study:
        return const Color(0xFF15803D);
      case TaskCategory.sport:
        return const Color(0xFFC2410C);
      case TaskCategory.worship:
        return const Color(0xFF8A5A00);
      case TaskCategory.entertainment:
        return const Color(0xFF9D174D);
      case TaskCategory.personal:
        return const Color(0xFF6B21A8);
      case TaskCategory.social:
        return const Color(0xFF166534);
      case TaskCategory.unspecified:
        return const Color(0xFF475569);
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

  @ignore
  CivilDate? get targetCivilDate => targetDate != null
      ? CivilDate(targetDate!.year, targetDate!.month, targetDate!.day)
      : null;

  set targetCivilDate(CivilDate? value) {
    targetDate =
        value != null ? DateTime(value.year, value.month, value.day) : null;
  }

  @ignore
  CivilWallClock? get targetCivilClock => targetCivilTimeMinutes != null
      ? CivilWallClock.fromMinutesSinceMidnight(targetCivilTimeMinutes!)
      : null;

  set targetCivilClock(CivilWallClock? clock) {
    targetCivilTimeMinutes = clock?.minutesSinceMidnight;
  }

  bool isCompletedOnCivilDate(CivilDate logicalDate) {
    if (type == TaskType.casual) return isCompleted;
    if (lastCompletedDate == null) return false;
    return lastCompletedDate!.year == logicalDate.year &&
        lastCompletedDate!.month == logicalDate.month &&
        lastCompletedDate!.day == logicalDate.day;
  }
}
