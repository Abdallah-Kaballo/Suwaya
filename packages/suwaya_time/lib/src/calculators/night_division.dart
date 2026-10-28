import '../models/astro_models.dart';

class NightDivision {
  /// حساب أجزاء النصف الثاني من الليل الخمسة المعتمدة في شاشة العبادات والقرص الفلكي
  /// يضمن التطابق الرياضي المطلق (0 microsecond drift):
  /// - half_2.startUtc == sixth_4.startUtc
  /// - third_3.startUtc == sixth_5.startUtc
  /// - sixth_4 + sixth_5 + sixth_6 == half_2
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

    final int nightMicro = baseEnd.difference(baseStart).inMicroseconds;

    // نقاط التقسيم السدسية الدقيقة (0/6, 3/6, 4/6, 5/6, 6/6) بدون خطأ اقتطاع تراكمي
    final DateTime boundary3of6Utc = baseStart.add(
      Duration(microseconds: (nightMicro * 3) ~/ 6),
    );
    final DateTime boundary4of6Utc = baseStart.add(
      Duration(microseconds: (nightMicro * 4) ~/ 6),
    );
    final DateTime boundary5of6Utc = baseStart.add(
      Duration(microseconds: (nightMicro * 5) ~/ 6),
    );
    final DateTime boundary6of6Utc = baseEnd;

    final DateTime boundary3of6Wall = mapper(boundary3of6Utc);
    final DateTime boundary4of6Wall = mapper(boundary4of6Utc);
    final DateTime boundary5of6Wall = mapper(boundary5of6Utc);
    final DateTime boundary6of6Wall = mapper(boundary6of6Utc);

    return [
      NightPart(
        id: 'sixth_4',
        nameKey: 'np_sixth_4',
        startTime: boundary3of6Wall,
        endTime: boundary4of6Wall,
        startUtc: boundary3of6Utc,
        endUtc: boundary4of6Utc,
      ),
      NightPart(
        id: 'sixth_5',
        nameKey: 'np_sixth_5',
        startTime: boundary4of6Wall,
        endTime: boundary5of6Wall,
        startUtc: boundary4of6Utc,
        endUtc: boundary5of6Utc,
      ),
      NightPart(
        id: 'sixth_6',
        nameKey: 'np_sixth_6',
        startTime: boundary5of6Wall,
        endTime: boundary6of6Wall,
        startUtc: boundary5of6Utc,
        endUtc: boundary6of6Utc,
      ),
      NightPart(
        id: 'third_3',
        nameKey: 'np_third_3',
        startTime: boundary4of6Wall,
        endTime: boundary6of6Wall,
        startUtc: boundary4of6Utc,
        endUtc: boundary6of6Utc,
      ),
      NightPart(
        id: 'half_2',
        nameKey: 'np_half_2',
        startTime: boundary3of6Wall,
        endTime: boundary6of6Wall,
        startUtc: boundary3of6Utc,
        endUtc: boundary6of6Utc,
      ),
    ];
  }

  /// حساب جميع تقسيمات الليل الشرعي الـ 11 (النصفان، الأثلاث الثلاثة، والأسداس الستة)
  static List<NightPart> calculateAllCanonicalNightParts(
    DateTime maghrib,
    DateTime nextFajr, {
    DateTime? maghribUtc,
    DateTime? nextFajrUtc,
    DateTime Function(DateTime utcInstant)? toWallClock,
  }) {
    final baseStart = maghribUtc ?? maghrib;
    final baseEnd = nextFajrUtc ?? nextFajr;
    final mapper = toWallClock ?? ((DateTime dt) => dt);
    final int nightMicro = baseEnd.difference(baseStart).inMicroseconds;

    DateTime pointUtc(int numerator) => numerator == 6
        ? baseEnd
        : baseStart.add(Duration(microseconds: (nightMicro * numerator) ~/ 6));

    final p0 = pointUtc(0);
    final p1 = pointUtc(1);
    final p2 = pointUtc(2);
    final p3 = pointUtc(3);
    final p4 = pointUtc(4);
    final p5 = pointUtc(5);
    final p6 = pointUtc(6);

    return [
      NightPart(
        id: 'half_1',
        nameKey: 'np_half_1',
        startTime: mapper(p0),
        endTime: mapper(p3),
        startUtc: p0,
        endUtc: p3,
      ),
      NightPart(
        id: 'half_2',
        nameKey: 'np_half_2',
        startTime: mapper(p3),
        endTime: mapper(p6),
        startUtc: p3,
        endUtc: p6,
      ),
      NightPart(
        id: 'third_1',
        nameKey: 'np_third_1',
        startTime: mapper(p0),
        endTime: mapper(p2),
        startUtc: p0,
        endUtc: p2,
      ),
      NightPart(
        id: 'third_2',
        nameKey: 'np_third_2',
        startTime: mapper(p2),
        endTime: mapper(p4),
        startUtc: p2,
        endUtc: p4,
      ),
      NightPart(
        id: 'third_3',
        nameKey: 'np_third_3',
        startTime: mapper(p4),
        endTime: mapper(p6),
        startUtc: p4,
        endUtc: p6,
      ),
      NightPart(
        id: 'sixth_1',
        nameKey: 'np_sixth_1',
        startTime: mapper(p0),
        endTime: mapper(p1),
        startUtc: p0,
        endUtc: p1,
      ),
      NightPart(
        id: 'sixth_2',
        nameKey: 'np_sixth_2',
        startTime: mapper(p1),
        endTime: mapper(p2),
        startUtc: p1,
        endUtc: p2,
      ),
      NightPart(
        id: 'sixth_3',
        nameKey: 'np_sixth_3',
        startTime: mapper(p2),
        endTime: mapper(p3),
        startUtc: p2,
        endUtc: p3,
      ),
      NightPart(
        id: 'sixth_4',
        nameKey: 'np_sixth_4',
        startTime: mapper(p3),
        endTime: mapper(p4),
        startUtc: p3,
        endUtc: p4,
      ),
      NightPart(
        id: 'sixth_5',
        nameKey: 'np_sixth_5',
        startTime: mapper(p4),
        endTime: mapper(p5),
        startUtc: p4,
        endUtc: p5,
      ),
      NightPart(
        id: 'sixth_6',
        nameKey: 'np_sixth_6',
        startTime: mapper(p5),
        endTime: mapper(p6),
        startUtc: p5,
        endUtc: p6,
      ),
    ];
  }
}
