import 'package:isar_community/isar.dart';

part 'daily_stats_model.g.dart';

@collection
class DailyCosmicStats {
  Id id = Isar.autoIncrement;

  // 🟢 تاريخ اليوم بصيغة (YYYY-MM-DD) ليكون فريداً وسريعاً جداً في البحث
  @Index(unique: true, replace: true) 
  late String dateString;

  // 🟢 عدد المهام المنجزة في كل فترة فلكية (للمصفوفة والتحليلات)
  int fajrCount = 0;
  int duhaCount = 0;
  int dhuhrCount = 0;
  int asrCount = 0;
  int maghribCount = 0;
  int ishaCount = 0;
  int qiyamCount = 0;

  // 🟢 عدد المهام المنجزة حسب التصنيف (التوازن الحياتي)
  int awradCount = 0;
  int maashCount = 0;
  int miadCount = 0;
  int tarweehCount = 0;

  // 🟢 إجمالي المهام (لتسريع الإحصائيات العامة)
  int totalCompleted = 0;
  int totalMigrated = 0; // مقياس التسويف
}