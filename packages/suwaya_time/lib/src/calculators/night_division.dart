import '../models/astro_models.dart';

class NightDivision {
  static List<NightPart> calculateNightParts(DateTime maghrib, DateTime nextFajr) {
    final nightMicro = nextFajr.difference(maghrib).inMicroseconds;
    final suwayaMicro = nightMicro ~/ 12;

    DateTime getTime(int suwayaIndex) => maghrib.add(Duration(microseconds: suwayaMicro * suwayaIndex));

    final s4Start = getTime(5);
    final s4End = getTime(7);

    final s5Start = getTime(7);
    final s5End = getTime(9);

    final s6Start = getTime(9);
    final s6End = getTime(11);

    final third3Start = getTime(7);
    final third3End = getTime(11);

    // 🌟 إضافة النصف الثاني: يبدأ من السويعة 7 (الفهرس 6) وينتهي مع الفجر (الفهرس 12)
    final half2Start = getTime(6);
    final half2End = getTime(12);

    return [
      NightPart(id: 'sixth_4', nameKey: 'np_sixth_4', startTime: s4Start, endTime: s4End),
      NightPart(id: 'sixth_5', nameKey: 'np_sixth_5', startTime: s5Start, endTime: s5End),
      NightPart(id: 'sixth_6', nameKey: 'np_sixth_6', startTime: s6Start, endTime: s6End),
      NightPart(id: 'third_3', nameKey: 'np_third_3', startTime: third3Start, endTime: third3End),
      NightPart(id: 'half_2', nameKey: 'np_half_2', startTime: half2Start, endTime: half2End), // 🌟 تم إضافة النصف الثاني
    ];
  }
}