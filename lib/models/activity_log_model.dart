import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart';

part 'activity_log_model.g.dart';

@collection
class ActivityLog {
  Id id = Isar.autoIncrement;

  // 🌟 حقول المزامنة الاحترافية (Offline-First)
  @Index(unique: true, replace: true)
  String syncId = const Uuid().v4();
  
  DateTime updatedAt = DateTime.now().toUtc(); 
  bool isSynced = false;
  bool isDeleted = false;

  // 🌟 تفاصيل الحدث (Event Payload)
  String? taskSyncId;      // معرف المهمة (إن وجدت)
  String? routineSyncId;   // معرف العادة/الروتين (إن وجدت)
  String category = 'unspecified'; 
  
  int? periodId;           // في أي فترة تم الإنجاز؟
  int suwayasCount = 1;    // كم سويعة تم إنجازها في هذا الحدث؟

  // 🌟 مقاومة السفر والمناطق الزمنية (Timezone Resilience)
  // يحفظ دائماً بتوقيت UTC العالمي
  DateTime completedAtUtc = DateTime.now().toUtc();
  
  // 🌟 حدود اليوم الإسلامي (Day Boundary)
  // هذا الحقل يحفظ تاريخ اليوم (مثل "2026-09-05") بناءً على متى يبدأ اليوم (من المغرب أم منتصف الليل)
  // يجعل استخراج الإحصاءات سريعاً جداً (O(1) Query)
  @Index()
  String activeDayDate = ''; 
}