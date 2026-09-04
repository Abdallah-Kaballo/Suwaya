import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart'; 
import 'package:easy_localization/easy_localization.dart';

part 'task_model.g.dart';

enum TaskCategory { unspecified, work, study, sport, entertainment, worship, personal, social }
enum TaskType { casual, permanent }

extension TaskCategoryExtension on TaskCategory {
  String get displayName {
    switch (this) {
      case TaskCategory.unspecified: return 'categories.unspecified'.tr();
      case TaskCategory.work: return 'categories.work'.tr();
      case TaskCategory.study: return 'categories.study'.tr();
      case TaskCategory.sport: return 'categories.sport'.tr();
      case TaskCategory.entertainment: return 'categories.entertainment'.tr();
      case TaskCategory.worship: return 'categories.worship'.tr();
      case TaskCategory.personal: return 'categories.personal'.tr();
      case TaskCategory.social: return 'categories.social'.tr();
    }
  }
}

@collection
class TaskModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String syncId = const Uuid().v4(); 
  
  DateTime updatedAt = DateTime.now(); 
  bool isSynced = false; 
  bool isDeleted = false; 

  String title = '';
  
  @enumerated
  TaskType type = TaskType.casual;

  @enumerated
  TaskCategory category = TaskCategory.unspecified; 

  bool isCompleted = false;
  DateTime? completedAt;

  @Index()
  DateTime? targetDate;

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
}