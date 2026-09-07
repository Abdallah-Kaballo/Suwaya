import 'package:isar_community/isar.dart';

part 'geo_models.g.dart';

@collection
class GeoCountry {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String code; 

  @Index(type: IndexType.value)
  late String nameAr; 

  @Index(type: IndexType.value)
  late String nameEn; 

  late String defaultMethod; 
  late String defaultMadhab; 

  bool isDownloaded = false; 
}

@collection
class GeoPlace {
  Id id = Isar.autoIncrement;

  @Index()
  late String countryCode; 

  @Index(type: IndexType.value)
  late String nameAr; 

  @Index(type: IndexType.value)
  late String nameEn; 

  late double latitude;
  late double longitude;

  late String type; 
  
  late String? timezone;
}