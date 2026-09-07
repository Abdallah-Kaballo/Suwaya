// 🌟 Pure Dart: مسؤول فقط عن تقسيم فترة الليل (القيام)
import 'astro_models.dart';

class NightDivision {
  static List<NightPart> calculateNightParts(DateTime maghrib, DateTime nextFajr) {
    final nightMicro = nextFajr.difference(maghrib).inMicroseconds;
    
    final half = Duration(microseconds: nightMicro ~/ 2);
    final third = Duration(microseconds: nightMicro ~/ 3);
    final sixth = Duration(microseconds: nightMicro ~/ 6);

    final h1End = maghrib.add(half);
    
    final t1End = maghrib.add(third);
    final t2End = t1End.add(third);
    
    final s1End = maghrib.add(sixth);
    final s2End = s1End.add(sixth);
    final s3End = s2End.add(sixth);
    final s4End = s3End.add(sixth);
    final s5End = s4End.add(sixth);

    return [
      NightPart(id: 'half_1', nameKey: 'np_half_1', startTime: maghrib, endTime: h1End),
      NightPart(id: 'half_2', nameKey: 'np_half_2', startTime: h1End, endTime: nextFajr),
      
      NightPart(id: 'third_1', nameKey: 'np_third_1', startTime: maghrib, endTime: t1End),
      NightPart(id: 'third_2', nameKey: 'np_third_2', startTime: t1End, endTime: t2End),
      NightPart(id: 'third_3', nameKey: 'np_third_3', startTime: t2End, endTime: nextFajr),
      
      NightPart(id: 'sixth_1', nameKey: 'np_sixth_1', startTime: maghrib, endTime: s1End),
      NightPart(id: 'sixth_2', nameKey: 'np_sixth_2', startTime: s1End, endTime: s2End),
      NightPart(id: 'sixth_3', nameKey: 'np_sixth_3', startTime: s2End, endTime: s3End),
      NightPart(id: 'sixth_4', nameKey: 'np_sixth_4', startTime: s3End, endTime: s4End),
      NightPart(id: 'sixth_5', nameKey: 'np_sixth_5', startTime: s4End, endTime: s5End),
      NightPart(id: 'sixth_6', nameKey: 'np_sixth_6', startTime: s5End, endTime: nextFajr),
    ];
  }
}