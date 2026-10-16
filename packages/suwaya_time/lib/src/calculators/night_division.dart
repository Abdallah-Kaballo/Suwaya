import '../models/astro_models.dart';

class NightDivision {
  static List<NightPart> calculateNightParts(DateTime maghrib, DateTime nextFajr) {
    final nightMicro = nextFajr.difference(maghrib).inMicroseconds;
    final sixthMicro = nightMicro ~/ 6;
    final halfMicro = nightMicro ~/ 2;
    final twoThirdsMicro = (nightMicro * 2) ~/ 3;

    // 🌟 النصف الثاني من الليل يبدأ من منتصف الليل الشرعي وينتهي عند الفجر
    final half2Start = maghrib.add(Duration(microseconds: halfMicro));
    final half2End = nextFajr;

    // 🌟 الثلث الأخير من الليل يبدأ بعد ثلثي الليل وينتهي عند الفجر
    final third3Start = maghrib.add(Duration(microseconds: twoThirdsMicro));
    final third3End = nextFajr;

    // 🌟 الأسداس الثلاثة الأخيرة (الرابع، الخامس، السادس) تقسم النصف الثاني بالتساوي
    final s4Start = half2Start;
    final s4End = maghrib.add(Duration(microseconds: sixthMicro * 4));

    final s5Start = s4End;
    final s5End = maghrib.add(Duration(microseconds: sixthMicro * 5));

    final s6Start = s5End;
    final s6End = nextFajr;

    return [
      NightPart(id: 'sixth_4', nameKey: 'np_sixth_4', startTime: s4Start, endTime: s4End),
      NightPart(id: 'sixth_5', nameKey: 'np_sixth_5', startTime: s5Start, endTime: s5End),
      NightPart(id: 'sixth_6', nameKey: 'np_sixth_6', startTime: s6Start, endTime: s6End),
      NightPart(id: 'third_3', nameKey: 'np_third_3', startTime: third3Start, endTime: third3End),
      NightPart(id: 'half_2', nameKey: 'np_half_2', startTime: half2Start, endTime: half2End),
    ];
  }
}