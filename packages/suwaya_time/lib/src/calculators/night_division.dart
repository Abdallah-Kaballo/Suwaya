import '../models/astro_models.dart';

class NightDivision {
  static List<NightPart> calculateNightParts(
    DateTime maghrib,
    DateTime nextFajr, {
    DateTime? maghribUtc,
    DateTime? nextFajrUtc,
    DateTime Function(DateTime utcInstant)? toWallClock,
  }) {
    final baseStart = maghribUtc ?? maghrib;
    final baseEnd = nextFajrUtc ?? nextFajr;
    final mapper = toWallClock ?? ((DateTime dt) => dt);

    final nightMicro = baseEnd.difference(baseStart).inMicroseconds;
    final sixthMicro = nightMicro ~/ 6;
    final halfMicro = nightMicro ~/ 2;
    final twoThirdsMicro = (nightMicro * 2) ~/ 3;

    final half2StartUtc = baseStart.add(Duration(microseconds: halfMicro));
    final half2EndUtc = baseEnd;

    final third3StartUtc = baseStart.add(Duration(microseconds: twoThirdsMicro));
    final third3EndUtc = baseEnd;

    final s4StartUtc = half2StartUtc;
    final s4EndUtc = baseStart.add(Duration(microseconds: sixthMicro * 4));

    final s5StartUtc = s4EndUtc;
    final s5EndUtc = baseStart.add(Duration(microseconds: sixthMicro * 5));

    final s6StartUtc = s5EndUtc;
    final s6EndUtc = baseEnd;

    return [
      NightPart(
        id: 'sixth_4',
        nameKey: 'np_sixth_4',
        startTime: mapper(s4StartUtc),
        endTime: mapper(s4EndUtc),
        startUtc: s4StartUtc,
        endUtc: s4EndUtc,
      ),
      NightPart(
        id: 'sixth_5',
        nameKey: 'np_sixth_5',
        startTime: mapper(s5StartUtc),
        endTime: mapper(s5EndUtc),
        startUtc: s5StartUtc,
        endUtc: s5EndUtc,
      ),
      NightPart(
        id: 'sixth_6',
        nameKey: 'np_sixth_6',
        startTime: mapper(s6StartUtc),
        endTime: mapper(s6EndUtc),
        startUtc: s6StartUtc,
        endUtc: s6EndUtc,
      ),
      NightPart(
        id: 'third_3',
        nameKey: 'np_third_3',
        startTime: mapper(third3StartUtc),
        endTime: mapper(third3EndUtc),
        startUtc: third3StartUtc,
        endUtc: third3EndUtc,
      ),
      NightPart(
        id: 'half_2',
        nameKey: 'np_half_2',
        startTime: mapper(half2StartUtc),
        endTime: mapper(half2EndUtc),
        startUtc: half2StartUtc,
        endUtc: half2EndUtc,
      ),
    ];
  }
}