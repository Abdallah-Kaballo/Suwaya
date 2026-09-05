import 'package:isar_community/isar.dart';
import 'package:uuid/uuid.dart'; 

part 'routine_model.g.dart';

@collection
class RoutineModel {
  Id id = Isar.autoIncrement;

  // 🌟 حقول المزامنة (تمت إضافتها)
  @Index(unique: true, replace: true)
  String syncId = const Uuid().v4(); 
  
  DateTime updatedAt = DateTime.now().toUtc(); 
  bool isSynced = false; 
  bool isDeleted = false; 

  String title = '';
  int colorValue = 0xFF1E88E5;
  bool isAstroTime = true;
  String pattern = 'linear';

  int? startTimeMinutes;
  int? endTimeMinutes;

  int? startPeriodId;
  int? startSuwaya;
  int? startVirtualMinute;
  int? endPeriodId;
  int? endSuwaya;
  int? endVirtualMinute;

  List<int>? recurrenceDays; 
  @Index()
  bool isActive = true;

  int alertLevel = 0; 
  String alarmTone = 'assets/audio/default.mp3';
  double alarmVolume = 1.0;
}