import 'package:suwaya_time/suwaya_time.dart';

/// يحدد النطاق العام للسويعة (ليل أم نهار)
enum SuwayaPhase {
  night,
  day;

  bool get isNight => this == SuwayaPhase.night;
  bool get isDay => this == SuwayaPhase.day;
}

enum PeriodKey {
  nightMaghribIsha,
  nightIshaMidnight,
  nightMidnightFajr,
  nightFajrSunrise,
  daySunriseDhuhr,
  dayDhuhrAsr,
  dayAsrMaghrib,
}

class SuwayaCycleAnchors {
  final DateTime cycleStartMaghrib,
      cycleIsha,
      sharIMidnight,
      cycleFajr,
      cycleSunrise,
      cycleDhuhr,
      cycleAsr,
      cycleEndMaghrib;

  final DateTime? cycleStartMaghribUtc,
      cycleIshaUtc,
      sharIMidnightUtc,
      cycleFajrUtc,
      cycleSunriseUtc,
      cycleDhuhrUtc,
      cycleAsrUtc,
      cycleEndMaghribUtc;

  final DateTime? calculatedStartSunset, calculatedEndSunset;
  final DateTime? calculatedStartSunsetUtc, calculatedEndSunsetUtc;

  const SuwayaCycleAnchors({
    required this.cycleStartMaghrib,
    required this.cycleIsha,
    required this.sharIMidnight,
    required this.cycleFajr,
    required this.cycleSunrise,
    required this.cycleDhuhr,
    required this.cycleAsr,
    required this.cycleEndMaghrib,
    this.cycleStartMaghribUtc,
    this.cycleIshaUtc,
    this.sharIMidnightUtc,
    this.cycleFajrUtc,
    this.cycleSunriseUtc,
    this.cycleDhuhrUtc,
    this.cycleAsrUtc,
    this.cycleEndMaghribUtc,
    this.calculatedStartSunset,
    this.calculatedEndSunset,
    this.calculatedStartSunsetUtc,
    this.calculatedEndSunsetUtc,
  });

  bool get isValidSequence {
    if (cycleStartMaghribUtc != null &&
        cycleIshaUtc != null &&
        sharIMidnightUtc != null &&
        cycleFajrUtc != null &&
        cycleSunriseUtc != null &&
        cycleDhuhrUtc != null &&
        cycleAsrUtc != null &&
        cycleEndMaghribUtc != null) {
      return cycleStartMaghribUtc!.isBefore(cycleIshaUtc!) &&
          cycleIshaUtc!.isBefore(sharIMidnightUtc!) &&
          sharIMidnightUtc!.isBefore(cycleFajrUtc!) &&
          cycleFajrUtc!.isBefore(cycleSunriseUtc!) &&
          cycleSunriseUtc!.isBefore(cycleDhuhrUtc!) &&
          cycleDhuhrUtc!.isBefore(cycleAsrUtc!) &&
          cycleAsrUtc!.isBefore(cycleEndMaghribUtc!);
    }
    return cycleStartMaghrib.isBefore(cycleIsha) &&
        cycleIsha.isBefore(sharIMidnight) &&
        sharIMidnight.isBefore(cycleFajr) &&
        cycleFajr.isBefore(cycleSunrise) &&
        cycleSunrise.isBefore(cycleDhuhr) &&
        cycleDhuhr.isBefore(cycleAsr) &&
        cycleAsr.isBefore(cycleEndMaghrib);
  }

  Map<String, dynamic> toJson() => {
    'cycleStartMaghrib': cycleStartMaghrib.toIso8601String(),
    'cycleIsha': cycleIsha.toIso8601String(),
    'sharIMidnight': sharIMidnight.toIso8601String(),
    'cycleFajr': cycleFajr.toIso8601String(),
    'cycleSunrise': cycleSunrise.toIso8601String(),
    'cycleDhuhr': cycleDhuhr.toIso8601String(),
    'cycleAsr': cycleAsr.toIso8601String(),
    'cycleEndMaghrib': cycleEndMaghrib.toIso8601String(),
    if (cycleStartMaghribUtc != null)
      'cycleStartMaghribUtc': cycleStartMaghribUtc!.toIso8601String(),
    if (cycleIshaUtc != null) 'cycleIshaUtc': cycleIshaUtc!.toIso8601String(),
    if (sharIMidnightUtc != null)
      'sharIMidnightUtc': sharIMidnightUtc!.toIso8601String(),
    if (cycleFajrUtc != null) 'cycleFajrUtc': cycleFajrUtc!.toIso8601String(),
    if (cycleSunriseUtc != null)
      'cycleSunriseUtc': cycleSunriseUtc!.toIso8601String(),
    if (cycleDhuhrUtc != null)
      'cycleDhuhrUtc': cycleDhuhrUtc!.toIso8601String(),
    if (cycleAsrUtc != null) 'cycleAsrUtc': cycleAsrUtc!.toIso8601String(),
    if (cycleEndMaghribUtc != null)
      'cycleEndMaghribUtc': cycleEndMaghribUtc!.toIso8601String(),
    if (calculatedStartSunset != null)
      'calculatedStartSunset': calculatedStartSunset!.toIso8601String(),
    if (calculatedEndSunset != null)
      'calculatedEndSunset': calculatedEndSunset!.toIso8601String(),
    if (calculatedStartSunsetUtc != null)
      'calculatedStartSunsetUtc': calculatedStartSunsetUtc!.toIso8601String(),
    if (calculatedEndSunsetUtc != null)
      'calculatedEndSunsetUtc': calculatedEndSunsetUtc!.toIso8601String(),
  };

  factory SuwayaCycleAnchors.fromJson(Map<String, dynamic> json) {
    DateTime? parseOpt(String key) =>
        json[key] is String ? DateTime.parse(json[key] as String) : null;

    return SuwayaCycleAnchors(
      cycleStartMaghrib: DateTime.parse(json['cycleStartMaghrib'] as String),
      cycleIsha: DateTime.parse(json['cycleIsha'] as String),
      sharIMidnight: DateTime.parse(json['sharIMidnight'] as String),
      cycleFajr: DateTime.parse(json['cycleFajr'] as String),
      cycleSunrise: DateTime.parse(json['cycleSunrise'] as String),
      cycleDhuhr: DateTime.parse(json['cycleDhuhr'] as String),
      cycleAsr: DateTime.parse(json['cycleAsr'] as String),
      cycleEndMaghrib: DateTime.parse(json['cycleEndMaghrib'] as String),
      cycleStartMaghribUtc: parseOpt('cycleStartMaghribUtc')?.toUtc(),
      cycleIshaUtc: parseOpt('cycleIshaUtc')?.toUtc(),
      sharIMidnightUtc: parseOpt('sharIMidnightUtc')?.toUtc(),
      cycleFajrUtc: parseOpt('cycleFajrUtc')?.toUtc(),
      cycleSunriseUtc: parseOpt('cycleSunriseUtc')?.toUtc(),
      cycleDhuhrUtc: parseOpt('cycleDhuhrUtc')?.toUtc(),
      cycleAsrUtc: parseOpt('cycleAsrUtc')?.toUtc(),
      cycleEndMaghribUtc: parseOpt('cycleEndMaghribUtc')?.toUtc(),
      calculatedStartSunset: parseOpt('calculatedStartSunset'),
      calculatedEndSunset: parseOpt('calculatedEndSunset'),
      calculatedStartSunsetUtc: parseOpt('calculatedStartSunsetUtc')?.toUtc(),
      calculatedEndSunsetUtc: parseOpt('calculatedEndSunsetUtc')?.toUtc(),
    );
  }
}

class SuwayaClockTime {
  final SuwayaPhase phase;
  final int phaseSlotNumber;
  final PeriodKey periodKey;
  final int periodLocalSlotNumber;
  final double slotProgress;
  final DateTime cycleStartDate;
  final DateTime instant;

  const SuwayaClockTime({
    required this.phase,
    required this.phaseSlotNumber,
    required this.periodKey,
    required this.periodLocalSlotNumber,
    required this.slotProgress,
    required this.cycleStartDate,
    required this.instant,
  });

  int get virtualMinute => ((slotProgress * 3600) ~/ 60).clamp(0, 59);
  int get virtualSecond => ((slotProgress * 3600).floor() % 60).clamp(0, 59);

  Map<String, dynamic> toJson() => {
    'phase': phase.name,
    'phaseSlotNumber': phaseSlotNumber,
    'periodKey': periodKey.name,
    'periodLocalSlotNumber': periodLocalSlotNumber,
    'virtualMinute': virtualMinute,
    'virtualSecond': virtualSecond,
    'slotProgress': slotProgress,
    'cycleStartDate': cycleStartDate.toIso8601String(),
    'instant': instant.toIso8601String(),
  };

  factory SuwayaClockTime.fromJson(Map<String, dynamic> json) {
    final phaseStr = (json['phase'] as String?) ?? 'night';
    final pKeyStr = (json['periodKey'] as String?) ?? 'nightMaghribIsha';
    final nowFallback = DateTime.now().toUtc();

    return SuwayaClockTime(
      phase: phaseStr == 'day' ? SuwayaPhase.day : SuwayaPhase.night,
      phaseSlotNumber: ((json['phaseSlotNumber'] as num?)?.toInt() ?? 1).clamp(
        1,
        12,
      ),
      periodKey: PeriodKey.values.firstWhere(
        (e) => e.name == pKeyStr,
        orElse: () => PeriodKey.nightMaghribIsha,
      ),
      periodLocalSlotNumber:
          ((json['periodLocalSlotNumber'] as num?)?.toInt() ?? 1).clamp(1, 12),
      slotProgress: ((json['slotProgress'] as num?)?.toDouble() ?? 0.0).clamp(
        0.0,
        0.999999,
      ),
      cycleStartDate: json['cycleStartDate'] is String
          ? DateTime.parse(json['cycleStartDate'] as String)
          : nowFallback,
      instant: json['instant'] is String
          ? DateTime.parse(json['instant'] as String)
          : nowFallback,
    );
  }
}

class AstroPeriod {
  final int id;
  final PeriodKey periodKey;
  final String nameKey;
  final DateTime startTime, endTime;
  final DateTime? startUtc, endUtc;
  final int suwayasCount, colorValue;

  const AstroPeriod({
    required this.id,
    required this.periodKey,
    required this.nameKey,
    required this.startTime,
    required this.endTime,
    this.startUtc,
    this.endUtc,
    required this.suwayasCount,
    required this.colorValue,
  });

  InstantUtc get startInstant =>
      InstantUtc.fromDateTime(startUtc ?? startTime.toUtc());
  InstantUtc get endInstant =>
      InstantUtc.fromDateTime(endUtc ?? endTime.toUtc());

  ZonedWallTime get startWall => ZonedWallTime(
    instant: startInstant,
    utcOffset: startTime.difference(startInstant.toDateTimeUtc()),
  );

  ZonedWallTime get endWall => ZonedWallTime(
    instant: endInstant,
    utcOffset: endTime.difference(endInstant.toDateTimeUtc()),
  );

  Duration get totalDuration {
    if (startUtc != null && endUtc != null) {
      return endUtc!.difference(startUtc!);
    }
    return endTime.difference(startTime);
  }

  Duration get actualSuwayaDuration {
    if (suwayasCount <= 0) return Duration.zero;
    final actualMicro = totalDuration.inMicroseconds ~/ suwayasCount;
    return actualMicro > 0
        ? Duration(microseconds: actualMicro)
        : Duration.zero;
  }

  double get flowSpeed {
    final micro = actualSuwayaDuration.inMicroseconds;
    if (micro <= 0) return 0.0;
    return 3600.0 / (micro / Duration.microsecondsPerSecond);
  }

  ZonedWallTime resolveSlotZonedTime(
    int localSuwaya,
    int virtualMinute, {
    int virtualSecond = 0,
    String? timezoneId,
    Duration? fallbackOffset,
  }) {
    final resolved = SuwayaCoordinateMapper.periodSlotToInstant(
      period: this,
      localSuwaya: localSuwaya,
      virtualMinute: virtualMinute,
      virtualSecond: virtualSecond,
    );
    return ZonedWallTime.fromInstant(
      InstantUtc.fromDateTime(resolved.instantUtc),
      timezoneId: timezoneId,
      fallbackOffset: fallbackOffset ?? startWall.utcOffset,
    );
  }

  DateTime resolveSlotUtc(
    int localSuwaya,
    int virtualMinute, [
    int virtualSecond = 0,
  ]) {
    return SuwayaCoordinateMapper.periodSlotToInstant(
      period: this,
      localSuwaya: localSuwaya,
      virtualMinute: virtualMinute,
      virtualSecond: virtualSecond,
    ).instantUtc;
  }

  DateTime resolveSlotWallTime(
    int localSuwaya,
    int virtualMinute, {
    int virtualSecond = 0,
    DateTime Function(DateTime utcInstant)? toWallClock,
  }) {
    return SuwayaCoordinateMapper.periodSlotToInstant(
      period: this,
      localSuwaya: localSuwaya,
      virtualMinute: virtualMinute,
      virtualSecond: virtualSecond,
      toWallClock: toWallClock,
    ).wallTime;
  }

  Duration durationUntilNextSuwaya({
    required int currentLocalSlotNumber,
    required DateTime now,
    DateTime? nowUtc,
  }) {
    final count = suwayasCount > 0 ? suwayasCount : 1;
    final suwayaMicro = totalDuration.inMicroseconds ~/ count;
    if (nowUtc != null && startUtc != null) {
      final nextTransitionUtc = startUtc!.add(
        Duration(microseconds: suwayaMicro * currentLocalSlotNumber),
      );
      return nextTransitionUtc.difference(nowUtc);
    }
    final wallSuwayaMicro =
        endTime.difference(startTime).inMicroseconds ~/ count;
    final nextTransitionWall = startTime.add(
      Duration(microseconds: wallSuwayaMicro * currentLocalSlotNumber),
    );
    return nextTransitionWall.difference(now);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'periodKey': periodKey.name,
    'nameKey': nameKey,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    if (startUtc != null) 'startUtc': startUtc!.toIso8601String(),
    if (endUtc != null) 'endUtc': endUtc!.toIso8601String(),
    'suwayasCount': suwayasCount,
    'durationSeconds': totalDuration.inSeconds,
    'flowSpeed': flowSpeed,
    'colorValue': colorValue,
  };

  factory AstroPeriod.fromJson(Map<String, dynamic> json) {
    final idVal = ((json['id'] as num?)?.toInt() ?? 1).clamp(1, 7);
    final pKeyStr = json['periodKey'] as String?;
    return AstroPeriod(
      id: idVal,
      periodKey: PeriodKey.values.firstWhere(
        (e) => e.name == pKeyStr,
        orElse: () => PeriodKey.values[idVal - 1],
      ),
      nameKey: (json['nameKey'] as String?) ?? 'periods.maghrib',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      startUtc: json['startUtc'] is String
          ? DateTime.parse(json['startUtc'] as String).toUtc()
          : null,
      endUtc: json['endUtc'] is String
          ? DateTime.parse(json['endUtc'] as String).toUtc()
          : null,
      suwayasCount: (json['suwayasCount'] as num?)?.toInt() ?? 1,
      colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFFD4AF37,
    );
  }
}

class NightPart {
  final String id, nameKey;
  final DateTime startTime, endTime;
  final DateTime? startUtc, endUtc;

  const NightPart({
    required this.id,
    required this.nameKey,
    required this.startTime,
    required this.endTime,
    this.startUtc,
    this.endUtc,
  });

  Duration get realDuration => (startUtc != null && endUtc != null)
      ? endUtc!.difference(startUtc!)
      : endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
    'id': id,
    'nameKey': nameKey,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    if (startUtc != null) 'startUtc': startUtc!.toIso8601String(),
    if (endUtc != null) 'endUtc': endUtc!.toIso8601String(),
    'durationSeconds': realDuration.inSeconds,
  };

  factory NightPart.fromJson(Map<String, dynamic> json) {
    final idStr = (json['id'] as String?) ?? 'sixth_5';
    return NightPart(
      id: idStr,
      nameKey: (json['nameKey'] as String?) ?? 'np_$idStr',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      startUtc: json['startUtc'] is String
          ? DateTime.parse(json['startUtc'] as String).toUtc()
          : null,
      endUtc: json['endUtc'] is String
          ? DateTime.parse(json['endUtc'] as String).toUtc()
          : null,
    );
  }
}

class IbadatTimings {
  final DateTime fajr, sunrise, dhuhr, asr, maghrib, isha, nextFajr;
  final DateTime? calculatedSunset;
  final List<NightPart> nightParts;

  const IbadatTimings({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.nextFajr,
    this.calculatedSunset,
    required this.nightParts,
  });

  Map<String, dynamic> toJson() => {
    'fajr': fajr.toIso8601String(),
    'sunrise': sunrise.toIso8601String(),
    'dhuhr': dhuhr.toIso8601String(),
    'asr': asr.toIso8601String(),
    'maghrib': maghrib.toIso8601String(),
    'isha': isha.toIso8601String(),
    'nextFajr': nextFajr.toIso8601String(),
    if (calculatedSunset != null)
      'calculatedSunset': calculatedSunset!.toIso8601String(),
    'nightParts': nightParts.map((np) => np.toJson()).toList(),
  };

  factory IbadatTimings.fromJson(Map<String, dynamic> json) {
    final rawParts = (json['nightParts'] as List<dynamic>?) ?? const [];
    return IbadatTimings(
      fajr: DateTime.parse(json['fajr'] as String),
      sunrise: DateTime.parse(json['sunrise'] as String),
      dhuhr: DateTime.parse(json['dhuhr'] as String),
      asr: DateTime.parse(json['asr'] as String),
      maghrib: DateTime.parse(json['maghrib'] as String),
      isha: DateTime.parse(json['isha'] as String),
      nextFajr: DateTime.parse(json['nextFajr'] as String),
      calculatedSunset: json['calculatedSunset'] is String
          ? DateTime.parse(json['calculatedSunset'] as String)
          : null,
      nightParts: rawParts
          .map((e) => NightPart.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SuwayaDay {
  final IbadatTimings ibadatTimings;
  final IbadatTimings civilDayIbadat;
  final SuwayaCycleAnchors cycleAnchors;
  final List<AstroPeriod> periods;

  const SuwayaDay({
    required this.ibadatTimings,
    IbadatTimings? civilDayIbadat,
    required this.cycleAnchors,
    required this.periods,
  }) : civilDayIbadat = civilDayIbadat ?? ibadatTimings;

  SuwayaDay withCivilDayIbadat(IbadatTimings todayCivilIbadat) {
    return SuwayaDay(
      ibadatTimings: ibadatTimings,
      civilDayIbadat: todayCivilIbadat,
      cycleAnchors: cycleAnchors,
      periods: periods,
    );
  }

  Map<String, dynamic> toJson() => {
    'ibadatTimings': ibadatTimings.toJson(),
    'civilDayIbadat': civilDayIbadat.toJson(),
    'cycleAnchors': cycleAnchors.toJson(),
    'periods': periods.map((p) => p.toJson()).toList(),
  };

  factory SuwayaDay.fromJson(Map<String, dynamic> json) {
    final ibadat = IbadatTimings.fromJson(
      json['ibadatTimings'] as Map<String, dynamic>,
    );
    final civilIbadat = json['civilDayIbadat'] is Map<String, dynamic>
        ? IbadatTimings.fromJson(json['civilDayIbadat'] as Map<String, dynamic>)
        : ibadat;
    final anchors = SuwayaCycleAnchors.fromJson(
      json['cycleAnchors'] as Map<String, dynamic>,
    );
    final rawPeriods = (json['periods'] as List<dynamic>?) ?? const [];

    return SuwayaDay(
      ibadatTimings: ibadat,
      civilDayIbadat: civilIbadat,
      cycleAnchors: anchors,
      periods: rawPeriods
          .map((p) => AstroPeriod.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AstroState {
  final DateTime virtualTime;
  final DateTime? instantUtc;
  final List<AstroPeriod> periods;
  final AstroPeriod currentPeriod;
  final SuwayaClockTime currentSuwayaTime;
  final double timeSpeedMultiplier;
  final IbadatTimings ibadatTimings;
  final IbadatTimings civilDayIbadat;
  final SuwayaCycleAnchors cycleAnchors;

  const AstroState({
    required this.virtualTime,
    this.instantUtc,
    required this.periods,
    required this.currentPeriod,
    required this.currentSuwayaTime,
    required this.timeSpeedMultiplier,
    required this.ibadatTimings,
    IbadatTimings? civilDayIbadat,
    required this.cycleAnchors,
  }) : civilDayIbadat = civilDayIbadat ?? ibadatTimings;

  List<NightPart> get activeOrUpcomingNightParts =>
      currentSuwayaTime.phase.isNight
      ? ibadatTimings.nightParts
      : civilDayIbadat.nightParts;

  Map<String, dynamic> toJson() => {
    'virtualTime': virtualTime.toIso8601String(),
    if (instantUtc != null) 'instantUtc': instantUtc!.toIso8601String(),
    'currentPeriod': currentPeriod.toJson(),
    'currentSuwayaTime': currentSuwayaTime.toJson(),
    'timeSpeedMultiplier': timeSpeedMultiplier,
    'periods': periods.map((p) => p.toJson()).toList(),
    'ibadatTimings': ibadatTimings.toJson(),
    'civilDayIbadat': civilDayIbadat.toJson(),
    'cycleAnchors': cycleAnchors.toJson(),
  };

  factory AstroState.fromJson(Map<String, dynamic> json) {
    final rawPeriods = (json['periods'] as List<dynamic>?) ?? const [];
    final parsedPeriods = rawPeriods
        .map((p) => AstroPeriod.fromJson(p as Map<String, dynamic>))
        .toList();
    final ibadat = IbadatTimings.fromJson(
      json['ibadatTimings'] as Map<String, dynamic>,
    );
    final civilIbadat = json['civilDayIbadat'] is Map<String, dynamic>
        ? IbadatTimings.fromJson(json['civilDayIbadat'] as Map<String, dynamic>)
        : ibadat;

    return AstroState(
      virtualTime: DateTime.parse(json['virtualTime'] as String),
      instantUtc: json['instantUtc'] is String
          ? DateTime.parse(json['instantUtc'] as String).toUtc()
          : null,
      periods: parsedPeriods,
      currentPeriod: AstroPeriod.fromJson(
        json['currentPeriod'] as Map<String, dynamic>,
      ),
      currentSuwayaTime: SuwayaClockTime.fromJson(
        json['currentSuwayaTime'] as Map<String, dynamic>,
      ),
      timeSpeedMultiplier:
          (json['timeSpeedMultiplier'] as num?)?.toDouble() ?? 1.0,
      ibadatTimings: ibadat,
      civilDayIbadat: civilIbadat,
      cycleAnchors: SuwayaCycleAnchors.fromJson(
        json['cycleAnchors'] as Map<String, dynamic>,
      ),
    );
  }
}

enum CalculationMethodType {
  muslimWorldLeague,
  egyptian,
  karachi,
  ummAlQura,
  dubai,
  northAmerica,
  kuwait,
  qatar,
  singapore,
  tehran,
  turkey,
  franceUoif,
  russia,
  morocco,
  algeria,
  tunisia,
  malaysiaJakim,
  indonesiaKemenag,
  jordan,
  oman,
  custom,
}

enum MadhabType { hanafi, shafi }

enum HighLatitudeRuleType {
  middleOfTheNight,
  seventhOfTheNight,
  twilightAngle,
  aqrabAlBilad,
  aqrabAlAyyam,
}

enum PrayerKey { fajr, sunrise, dhuhr, asr, maghrib, isha }

extension AstroStringParsers on String {
  String get _normalized => replaceAll('_', '').toLowerCase();

  CalculationMethodType toCalculationMethod() {
    switch (_normalized) {
      case 'morocco':
        return CalculationMethodType.morocco;
      case 'algeria':
        return CalculationMethodType.algeria;
      case 'tunisia':
        return CalculationMethodType.tunisia;
      case 'malaysia':
      case 'jakim':
      case 'malaysiajakim':
        return CalculationMethodType.malaysiaJakim;
      case 'indonesia':
      case 'kemenag':
      case 'indonesiakemenag':
        return CalculationMethodType.indonesiaKemenag;
      case 'jordan':
        return CalculationMethodType.jordan;
      case 'oman':
        return CalculationMethodType.oman;
      default:
        return CalculationMethodType.values.firstWhere(
          (e) => e.name.toLowerCase() == _normalized,
          orElse: () => CalculationMethodType.muslimWorldLeague,
        );
    }
  }

  MadhabType toMadhab() => MadhabType.values.firstWhere(
    (e) => e.name.toLowerCase() == _normalized,
    orElse: () => MadhabType.shafi,
  );

  HighLatitudeRuleType toHighLatRule() =>
      HighLatitudeRuleType.values.firstWhere(
        (e) => e.name.toLowerCase() == _normalized,
        orElse: () => HighLatitudeRuleType.middleOfTheNight,
      );
}

extension AstroMapParsers on Map<String, int> {
  Map<PrayerKey, int> toPrayerKeyMap() {
    final map = <PrayerKey, int>{};
    forEach((key, value) {
      switch (key.toLowerCase()) {
        case '1':
        case 'fajr':
          map[PrayerKey.fajr] = value;
          break;
        case 'sunrise':
          map[PrayerKey.sunrise] = value;
          break;
        case '3':
        case 'dhuhr':
          map[PrayerKey.dhuhr] = value;
          break;
        case '4':
        case 'asr':
          map[PrayerKey.asr] = value;
          break;
        case '5':
        case 'maghrib':
          map[PrayerKey.maghrib] = value;
          break;
        case '9':
        case 'isha':
          map[PrayerKey.isha] = value;
          break;
      }
    });
    return map;
  }
}
