import 'package:isar_community/isar.dart';

part 'routine_model.g.dart';

@collection
class RoutineModel {
  Id id = Isar.autoIncrement;

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

  // 🌟 الخصائص الجديدة لجدولة تنبيهات الفترات
  int alertLevel = 0; // 0=صامت، 1=إشعار، 2=منبه
  String alarmTone = 'assets/audio/default.mp3';
  double alarmVolume = 1.0;
}