import 'dart:math' as math;
import 'package:adhan/adhan.dart';
import '../engine/temporal_context_engine.dart';
import '../models/astro_models.dart';
import 'night_division.dart';
import 'polar_cycle_synthesizer.dart';
import 'solar_ephemeris_calculator.dart';

class PrayerCalculator {
  static const UmmAlQuraHijriProvider _ummAlQuraHijri =
      UmmAlQuraHijriProvider();

  static CalculationParameters _getParams(
    CalculationMethodType methodType,
    MadhabType madhabType,
    HighLatitudeRuleType highLatRuleType,
    double customFajr,
    double customIsha,
  ) {
    CalculationParameters params;
    switch (methodType) {
      case CalculationMethodType.muslimWorldLeague:
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case CalculationMethodType.egyptian:
        params = CalculationMethod.egyptian.getParameters();
        break;
      case CalculationMethodType.karachi:
        params = CalculationMethod.karachi.getParameters();
        break;
      case CalculationMethodType.ummAlQura:
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case CalculationMethodType.dubai:
        params = CalculationMethod.dubai.getParameters();
        break;
      case CalculationMethodType.qatar:
        params = CalculationMethod.qatar.getParameters();
        break;
      case CalculationMethodType.kuwait:
        params = CalculationMethod.kuwait.getParameters();
        break;
      case CalculationMethodType.singapore:
        params = CalculationMethod.singapore.getParameters();
        break;
      case CalculationMethodType.northAmerica:
        params = CalculationMethod.north_america.getParameters();
        break;
      case CalculationMethodType.tehran:
        params = CalculationMethod.tehran.getParameters();
        break;
      case CalculationMethodType.turkey:
        params = CalculationMethod.turkey.getParameters();
        break;
      case CalculationMethodType.franceUoif:
        params = CalculationMethod.other.getParameters();
        params.fajrAngle = 12.0;
        params.ishaAngle = 12.0;
        break;
      case CalculationMethodType.russia:
        params = CalculationMethod.other.getParameters();
        params.fajrAngle = 16.0;
        params.ishaAngle = 15.0;
        break;
      case CalculationMethodType.morocco:
        params = CalculationMethod.other.getParameters();
        params.fajrAngle = 19.0;
        params.ishaAngle = 17.0;
        params.methodAdjustments = PrayerAdjustments(dhuhr: 5, maghrib: 5);
        break;
      case CalculationMethodType.algeria:
        params = CalculationMethod.other.getParameters();
        params.fajrAngle = 18.0;
        params.ishaAngle = 17.0;
        params.methodAdjustments = PrayerAdjustments(maghrib: 3);
        break;
      case CalculationMethodType.tunisia:
        params = CalculationMethod.other.getParameters();
        params.fajrAngle = 18.0;
        params.ishaAngle = 18.0;
        params.methodAdjustments = PrayerAdjustments(dhuhr: 2, maghrib: 2);
        break;
      case CalculationMethodType.malaysiaJakim:
        params = CalculationMethod.other.getParameters();
        params.fajrAngle = 20.0;
        params.ishaAngle = 18.0;
        params.methodAdjustments = PrayerAdjustments(
          dhuhr: 2,
          asr: 1,
          maghrib: 2,
        );
        break;
      case CalculationMethodType.indonesiaKemenag:
        params = CalculationMethod.other.getParameters();
        params.fajrAngle = 20.0;
        params.ishaAngle = 18.0;
        params.methodAdjustments = PrayerAdjustments(
          fajr: 2,
          dhuhr: 2,
          asr: 2,
          maghrib: 2,
          isha: 2,
        );
        break;
      case CalculationMethodType.jordan:
        params = CalculationMethod.other.getParameters();
        params.fajrAngle = 18.0;
        params.ishaAngle = 18.0;
        params.methodAdjustments = PrayerAdjustments(maghrib: 4);
        break;
      case CalculationMethodType.oman:
        params = CalculationMethod.other.getParameters();
        params.fajrAngle = 18.0;
        params.ishaAngle = 18.0;
        params.methodAdjustments = PrayerAdjustments(dhuhr: 2, maghrib: 3);
        break;
      case CalculationMethodType.custom:
        params = CalculationMethod.other.getParameters();
        params.fajrAngle = customFajr;
        params.ishaAngle = customIsha;
        break;
    }

    params.madhab = (madhabType == MadhabType.hanafi)
        ? Madhab.hanafi
        : Madhab.shafi;

    switch (highLatRuleType) {
    case HighLatitudeRuleType.seventhOfTheNight:
    case HighLatitudeRuleType.aqrabAlAyyam:
    case HighLatitudeRuleType.aqrabAlBilad:
      params.highLatitudeRule = HighLatitudeRule.seventh_of_the_night;
      break;
    case HighLatitudeRuleType.twilightAngle:
      params.highLatitudeRule = HighLatitudeRule.twilight_angle;
      params.ishaAngle ??= 18.0;
      break;
    case HighLatitudeRuleType.middleOfTheNight:
      params.highLatitudeRule = HighLatitudeRule.middle_of_the_night;
      break;
    }
    return params;
  }

  static bool _isStrictlyMonotonicPair(PrayerTimes d1, PrayerTimes d2) {
    final f1 = d1.fajr.toUtc();
    final sr1 = d1.sunrise.toUtc();
    final dh1 = d1.dhuhr.toUtc();
    final as1 = d1.asr.toUtc();
    final mg1 = d1.maghrib.toUtc();
    final is1 = d1.isha.toUtc();

    final f2 = d2.fajr.toUtc();
    final sr2 = d2.sunrise.toUtc();
    final dh2 = d2.dhuhr.toUtc();
    final as2 = d2.asr.toUtc();
    final mg2 = d2.maghrib.toUtc();

    final validOrder =
        f1.isBefore(sr1) &&
        sr1.isBefore(dh1) &&
        dh1.isBefore(as1) &&
        as1.isBefore(mg1) &&
        mg1.isBefore(is1) &&
        is1.isBefore(f2) &&
        f2.isBefore(sr2) &&
        sr2.isBefore(dh2) &&
        dh2.isBefore(as2) &&
        as2.isBefore(mg2);

    if (!validOrder) return false;

    final cycleHours = mg2.difference(mg1).inHours;
    return cycleHours >= 20 && cycleHours <= 28;
  }

  static ({PrayerTimes day1, PrayerTimes day2, double effectiveLat})
  _safeComputePrayerTimesPair({
    required double lat,
    required double lng,
    required DateTime date,
    required CalculationParameters params,
  }) {
    final safeLat = lat.clamp(-90.0, 90.0);
    final safeLng = lng.clamp(-180.0, 180.0);
    final d1 = DateComponents.from(date);
    final d2 = DateComponents.from(date.add(const Duration(days: 1)));

    // المنطقة الأولى والثانية (حتى 66°): تُحسب فيها الأوقات الشمسية الظاهرية (الشروق والظهر والعصر والمغرب)
    // على خط عرض المدينة الحقيقي طالما تشرق الشمس وتغرب
    if (safeLat.abs() <= PolarCycleSynthesizer.polarThresholdLatitude) {
      try {
        final coords = Coordinates(safeLat, safeLng);
        final p1 = PrayerTimes(coords, d1, params);
        final p2 = PrayerTimes(coords, d2, params);
        if (_isStrictlyMonotonicPair(p1, p2)) {
          return (day1: p1, day2: p2, effectiveLat: safeLat);
        }
      } catch (_) {}
    }

    // المنطقة الثالثة (فوق 66° أو عند انعدام الشروق والغروب): القياس الزمني على خط عرض 45° (قرار المجمع الفقهي ص 219 وص 488)
    final clampedLat = safeLat >= 0 ? 45.0 : -45.0;
    final fallbackCoords = Coordinates(clampedLat, safeLng);
    return (
      day1: PrayerTimes(fallbackCoords, d1, params),
      day2: PrayerTimes(fallbackCoords, d2, params),
      effectiveLat: clampedLat,
    );
  }

  /// التحقق مما إذا كان الشفق الفلكي (زاوية الفجر أو العشاء) ينعدم في هذا اليوم عند خط العرض المعطى
  static bool _isTwilightPersistentOnDate({
    required double latitude,
    required DateTime date,
    required double maxDepressionAngle,
  }) {
    if (latitude.abs() <= 48.0) return false;
    final startOfYear = DateTime.utc(date.year, 1, 1);
    final dayOfYear = date.difference(startOfYear).inDays + 1;
    final declDeg =
        23.44 * math.sin((2.0 * math.pi / 365.0) * (dayOfYear - 81));
    // ينعدم الشفق الفلكي عندما لا تنخفض الشمس عند منتصف الليل إلى الزاوية المطلوبة: |lat + decl| > 90 - angle
    final sameHemisphere = (latitude >= 0 && declDeg >= 0) ||
        (latitude < 0 && declDeg < 0);
    if (!sameHemisphere) return false;
    return (latitude.abs() + declDeg.abs()) >= (90.0 - maxDepressionAngle);
  }

  /// تطبيق القواعد الفقهية للمنطقة الثانية (48°..66°):
  /// 1. القياس النسبي لوقتي العشاء والفجر على نظيريهما في ليل خط عرض 45° (قرار المجمع الفقهي ص 219 وص 488).
  /// 2. أو أقرب الأيام الاعتدالية التي تميزت فيها علامات العشاء والفجر في البلد نفسه.
  static ({DateTime todayFajrUtc, DateTime todayIshaUtc, DateTime nextFajrUtc})
  _resolveHighLatitudeTwilight({
    required double lat,
    required double lng,
    required DateTime date,
    required CalculationParameters params,
    required HighLatitudeRuleType highLatRuleType,
    required DateTime defaultTodayFajrUtc,
    required DateTime defaultTodayIshaUtc,
    required DateTime defaultNextFajrUtc,
    required DateTime todaySunriseUtc,
    required DateTime todaySunsetUtc,
    required DateTime tomorrowSunriseUtc,
  }) {
    final safeLat = lat.clamp(-90.0, 90.0);
    final safeLng = lng.clamp(-180.0, 180.0);
    final maxAngle = math.max(params.fajrAngle, params.ishaAngle ?? 18.0);

    if (safeLat.abs() <= 48.0) {
      return (
        todayFajrUtc: defaultTodayFajrUtc,
        todayIshaUtc: defaultTodayIshaUtc,
        nextFajrUtc: defaultNextFajrUtc,
      );
    }

    // 1. قاعدة القياس النسبي على خط عرض 45° (قرار المجمع الفقهي - البند خامساً ص 219، والبند ثانياً ص 488)
    if (highLatRuleType == HighLatitudeRuleType.aqrabAlBilad) {
      final refLat = safeLat >= 0 ? 45.0 : -45.0;
      final refCoords = Coordinates(refLat, safeLng);
      final d0 = DateComponents.from(date.subtract(const Duration(days: 1)));
      final d1 = DateComponents.from(date);
      final d2 = DateComponents.from(date.add(const Duration(days: 1)));

      final refP0 = PrayerTimes(refCoords, d0, params);
      final refP1 = PrayerTimes(refCoords, d1, params);
      final refP2 = PrayerTimes(refCoords, d2, params);

      final refNight1Micro = refP2.sunrise
          .toUtc()
          .difference(refP1.maghrib.toUtc())
          .inMicroseconds;
      final localNight1Micro = tomorrowSunriseUtc
          .difference(todaySunsetUtc)
          .inMicroseconds;

      if (refNight1Micro > 0 && localNight1Micro > 0) {
        final ishaRatio =
            refP1.isha
                .toUtc()
                .difference(refP1.maghrib.toUtc())
                .inMicroseconds /
            refNight1Micro;
        final fajrLeadRatio =
            refP2.sunrise
                .toUtc()
                .difference(refP2.fajr.toUtc())
                .inMicroseconds /
            refNight1Micro;

        final prevSunsetEstUtc = todaySunsetUtc.subtract(
          const Duration(hours: 24),
        );
        final localNight0Micro = todaySunriseUtc
            .difference(prevSunsetEstUtc)
            .inMicroseconds;
        final prevFajrLeadRatio =
            refP1.sunrise
                .toUtc()
                .difference(refP1.fajr.toUtc())
                .inMicroseconds /
            math.max(
              1,
              refP1.sunrise
                  .toUtc()
                  .difference(refP0.maghrib.toUtc())
                  .inMicroseconds,
            );

        final calcTodayFajr = todaySunriseUtc.subtract(
          Duration(
            microseconds:
                (localNight0Micro * prevFajrLeadRatio.clamp(0.08, 0.45))
                    .round(),
          ),
        );
        final calcTodayIsha = todaySunsetUtc.add(
          Duration(
            microseconds: (localNight1Micro * ishaRatio.clamp(0.08, 0.45))
                .round(),
          ),
        );
        final calcNextFajr = tomorrowSunriseUtc.subtract(
          Duration(
            microseconds: (localNight1Micro * fajrLeadRatio.clamp(0.08, 0.45))
                .round(),
          ),
        );

        if (calcTodayIsha.isBefore(calcNextFajr)) {
          return (
            todayFajrUtc: calcTodayFajr,
            todayIshaUtc: calcTodayIsha,
            nextFajrUtc: calcNextFajr,
          );
        }
      }
    }

    // 2. قاعدة أقرب الأيام (Aqrab al-Ayyam)
    if (highLatRuleType == HighLatitudeRuleType.aqrabAlAyyam &&
        _isTwilightPersistentOnDate(
          latitude: safeLat,
          date: date,
          maxDepressionAngle: maxAngle,
        )) {
      DateTime probeDate = date;
      for (int step = 1; step <= 120; step++) {
        probeDate = date.subtract(Duration(days: step));
        if (!_isTwilightPersistentOnDate(
          latitude: safeLat,
          date: probeDate,
          maxDepressionAngle: maxAngle,
        )) {
          break;
        }
      }

      try {
        final coords = Coordinates(safeLat.clamp(-64.5, 64.5), safeLng);
        final pValid1 = PrayerTimes(
          coords,
          DateComponents.from(probeDate),
          params,
        );
        final pValid2 = PrayerTimes(
          coords,
          DateComponents.from(probeDate.add(const Duration(days: 1))),
          params,
        );

        final ishaDuration = pValid1.isha.toUtc().difference(
          pValid1.maghrib.toUtc(),
        );
        final fajrLeadDuration = pValid2.sunrise.toUtc().difference(
          pValid2.fajr.toUtc(),
        );

        var calcTodayIsha = todaySunsetUtc.add(ishaDuration);
        var calcNextFajr = tomorrowSunriseUtc.subtract(fajrLeadDuration);
        final calcTodayFajr = todaySunriseUtc.subtract(fajrLeadDuration);

        if (!calcTodayIsha.isBefore(
          calcNextFajr.subtract(const Duration(minutes: 20)),
        )) {
          final totalValidTwilightMicro =
              ishaDuration.inMicroseconds + fajrLeadDuration.inMicroseconds;
          final localNightMicro = tomorrowSunriseUtc
              .difference(todaySunsetUtc)
              .inMicroseconds;
          if (totalValidTwilightMicro > 0 && localNightMicro > 0) {
            final ishaShare =
                (ishaDuration.inMicroseconds / totalValidTwilightMicro).clamp(
                  0.2,
                  0.6,
                );
            calcTodayIsha = todaySunsetUtc.add(
              Duration(
                microseconds: (localNightMicro * ishaShare * 0.85).round(),
              ),
            );
            calcNextFajr = tomorrowSunriseUtc.subtract(
              Duration(
                microseconds:
                    (localNightMicro * (1.0 - ishaShare) * 0.85).round(),
              ),
            );
          }
        }

        return (
          todayFajrUtc: calcTodayFajr,
          todayIshaUtc: calcTodayIsha,
          nextFajrUtc: calcNextFajr,
        );
      } catch (_) {}
    }

    return (
      todayFajrUtc: defaultTodayFajrUtc,
      todayIshaUtc: defaultTodayIshaUtc,
      nextFajrUtc: defaultNextFajrUtc,
    );
  }

  /// تصحيح وقت العشاء في تقويم أم القرى بناءً على التاريخ الهجري لليلة الشرعية (التي تبدأ بغروب شمس اليوم D)
  static DateTime _resolveUmmAlQuraIshaUtc({
    required DateTime sunsetUtc,
    required DateTime civilDate,
    int hijriAdjustmentDays = 0,
  }) {
    // الليلة الشرعية التي تبدأ عند غروب شمس `civilDate` تتبع تاريخ اليوم التالي هجرياً
    final islamicNightCivilDate = CivilDate(
      civilDate.year,
      civilDate.month,
      civilDate.day,
    ).addDays(1);
    final hijriNight = _ummAlQuraHijri.dateForGregorianDate(
      date: islamicNightCivilDate,
      adjustmentDays: hijriAdjustmentDays,
    );

    final int intervalMinutes = (hijriNight.month == 9) ? 120 : 90;
    return sunsetUtc.add(Duration(minutes: intervalMinutes));
  }

  /// الدالة المرجعية الموحدة لحساب انخفاض الأفق الناتج عن الارتفاع عن سطح البحر (بالمتر)
  static Duration computeElevationHorizonDip(
    double latitude,
    double elevationMeters,
  ) {
    if (elevationMeters <= 0.0) return Duration.zero;
    final clampedElevation = elevationMeters.clamp(0.0, 10000.0);
    final dipDegrees = 0.0347 * math.sqrt(clampedElevation);
    final latRad = (latitude.abs().clamp(0.0, 60.0)) * (math.pi / 180.0);
    final minutesShift = (dipDegrees * 4.0) / math.cos(latRad);
    return Duration(microseconds: (minutesShift * 60 * 1000000).round());
  }

  static DateTime _applyOffset(
    DateTime time,
    PrayerKey key,
    Map<PrayerKey, int> allowedManualOffsets,
  ) {
    if (allowedManualOffsets.containsKey(key)) {
      return time.add(Duration(minutes: allowedManualOffsets[key]!));
    }
    return time;
  }

  static IbadatTimings getIbadatTimings(
    double lat,
    double lng,
    DateTime date,
    CalculationMethodType methodType,
    MadhabType madhabType,
    HighLatitudeRuleType highLatRuleType,
    double customFajr,
    double customIsha,
    Duration cityOffset, {
    Duration? nextDayCityOffset,
    Map<PrayerKey, int>? manualOffsets,
    Duration Function(DateTime utcInstant)? offsetResolver,
    double elevationMeters = 0.0,
    AtmosphericConditions? atmosphericConditions,
    int hijriAdjustmentDays = 0,
    PolarResolutionPolicy polarPolicy = PolarResolutionPolicy.nearestLatitude45,
  }) {
    final effectiveNextOffset = nextDayCityOffset ?? cityOffset;

    if (lat.abs() > PolarCycleSynthesizer.polarThresholdLatitude &&
        polarPolicy == PolarResolutionPolicy.equinoxProportional) {
      final prevDay = date.subtract(const Duration(days: 1));
      final eqPrev = PolarCycleSynthesizer.synthesizeEquinoxCycle(
        targetDate: prevDay,
        longitude: lng,
        cityOffset: cityOffset,
        nextDayCityOffset: cityOffset,
        offsetResolver: offsetResolver,
        manualOffsets: manualOffsets,
      );
      final eqToday = PolarCycleSynthesizer.synthesizeEquinoxCycle(
        targetDate: date,
        longitude: lng,
        cityOffset: cityOffset,
        nextDayCityOffset: effectiveNextOffset,
        offsetResolver: offsetResolver,
        manualOffsets: manualOffsets,
      );

      DateTime toNightWall(DateTime utc) {
        if (offsetResolver != null) return utc.add(offsetResolver(utc));
        final halfNightUtc = eqToday.cycleStartMaghribUtc!.add(
          eqToday.cycleFajrUtc!.difference(eqToday.cycleStartMaghribUtc!) ~/ 2,
        );
        return utc.isBefore(halfNightUtc)
            ? utc.add(cityOffset)
            : utc.add(effectiveNextOffset);
      }

      return IbadatTimings(
        fajr: eqPrev.cycleFajr,
        sunrise: eqPrev.cycleSunrise,
        dhuhr: eqPrev.cycleDhuhr,
        asr: eqPrev.cycleAsr,
        maghrib: eqToday.cycleStartMaghrib,
        isha: eqToday.cycleIsha,
        nextFajr: eqToday.cycleFajr,
        calculatedSunset: eqToday.calculatedStartSunset,
        nightParts: NightDivision.calculateNightParts(
          eqToday.cycleStartMaghrib,
          eqToday.cycleFajr,
          maghribUtc: eqToday.cycleStartMaghribUtc,
          nextFajrUtc: eqToday.cycleFajrUtc,
          toWallClock: toNightWall,
        ),
      );
    }

    final params = _getParams(
      methodType,
      madhabType,
      highLatRuleType,
      customFajr,
      customIsha,
    );

    final pair = _safeComputePrayerTimesPair(
      lat: lat,
      lng: lng,
      date: date,
      params: params,
    );
    final today = pair.day1;
    final tomorrow = pair.day2;

    final allowedManualOffsets = <PrayerKey, int>{};
    if (manualOffsets != null) {
      for (final entry in manualOffsets.entries) {
        if (entry.key != PrayerKey.sunrise) {
          allowedManualOffsets[entry.key] = entry.value.clamp(-30, 30);
        }
      }
    }

    final elevationShift = computeElevationHorizonDip(
      pair.effectiveLat,
      elevationMeters,
    );
    final refractionShift = atmosphericConditions != null
        ? atmosphericConditions.horizonRefractionTimeDelta(pair.effectiveLat)
        : Duration.zero;
    final totalHorizonShift = elevationShift + refractionShift;

    final methodMaghribAdj = Duration(
      minutes: params.methodAdjustments.maghrib,
    );
    final rawSunsetUtc = today.maghrib
        .toUtc()
        .subtract(methodMaghribAdj)
        .add(totalHorizonShift);
    final adjustedTodayMaghribUtc = today.maghrib.toUtc().add(
      totalHorizonShift,
    );
    final sunriseUtc = today.sunrise.toUtc().subtract(totalHorizonShift);
    final tomorrowSunriseUtc = tomorrow.sunrise.toUtc().subtract(
      totalHorizonShift,
    );

    final baseIshaUtc = (methodType == CalculationMethodType.ummAlQura)
        ? _resolveUmmAlQuraIshaUtc(
            sunsetUtc: rawSunsetUtc,
            civilDate: date,
            hijriAdjustmentDays: hijriAdjustmentDays,
          )
        : today.isha.toUtc();

    final resolvedTwilight = _resolveHighLatitudeTwilight(
      lat: lat,
      lng: lng,
      date: date,
      params: params,
      highLatRuleType: highLatRuleType,
      defaultTodayFajrUtc: today.fajr.toUtc(),
      defaultTodayIshaUtc: baseIshaUtc,
      defaultNextFajrUtc: tomorrow.fajr.toUtc(),
      todaySunriseUtc: sunriseUtc,
      todaySunsetUtc: rawSunsetUtc,
      tomorrowSunriseUtc: tomorrowSunriseUtc,
    );

    var fajrUtc = _applyOffset(
      resolvedTwilight.todayFajrUtc,
      PrayerKey.fajr,
      allowedManualOffsets,
    );
    var dhuhrUtc = _applyOffset(
      today.dhuhr.toUtc(),
      PrayerKey.dhuhr,
      allowedManualOffsets,
    );
    var asrUtc = _applyOffset(
      today.asr.toUtc(),
      PrayerKey.asr,
      allowedManualOffsets,
    );
    var maghribUtc = _applyOffset(
      adjustedTodayMaghribUtc,
      PrayerKey.maghrib,
      allowedManualOffsets,
    );
    var ishaUtc = _applyOffset(
      resolvedTwilight.todayIshaUtc,
      PrayerKey.isha,
      allowedManualOffsets,
    );
    var nextFajrUtc = _applyOffset(
      resolvedTwilight.nextFajrUtc,
      PrayerKey.fajr,
      allowedManualOffsets,
    );

    if (!maghribUtc.isBefore(ishaUtc) || !ishaUtc.isBefore(nextFajrUtc)) {
      maghribUtc = rawSunsetUtc;
      ishaUtc = resolvedTwilight.todayIshaUtc;
      nextFajrUtc = resolvedTwilight.nextFajrUtc;
    }

    DateTime toEveningWall(DateTime utc) =>
        utc.add(offsetResolver != null ? offsetResolver(utc) : cityOffset);
    DateTime toNextDayWall(DateTime utc) => utc.add(
      offsetResolver != null ? offsetResolver(utc) : effectiveNextOffset,
    );

    DateTime toNightWall(DateTime utc) {
      if (offsetResolver != null) return utc.add(offsetResolver(utc));
      final halfNightUtc = maghribUtc.add(
        nextFajrUtc.difference(maghribUtc) ~/ 2,
      );
      return utc.isBefore(halfNightUtc)
          ? utc.add(cityOffset)
          : utc.add(effectiveNextOffset);
    }

    final maghribWall = toEveningWall(maghribUtc);
    final nextFajrWall = toNextDayWall(nextFajrUtc);

    return IbadatTimings(
      fajr: toEveningWall(fajrUtc),
      sunrise: toEveningWall(sunriseUtc),
      dhuhr: toEveningWall(dhuhrUtc),
      asr: toEveningWall(asrUtc),
      maghrib: maghribWall,
      isha: toEveningWall(ishaUtc),
      nextFajr: nextFajrWall,
      calculatedSunset: toEveningWall(rawSunsetUtc),
      nightParts: NightDivision.calculateNightParts(
        maghribWall,
        nextFajrWall,
        maghribUtc: maghribUtc,
        nextFajrUtc: nextFajrUtc,
        toWallClock: toNightWall,
      ),
    );
  }

  static SuwayaCycleAnchors getCycleAnchors(
    double lat,
    double lng,
    DateTime targetDate,
    CalculationMethodType methodType,
    MadhabType madhabType,
    HighLatitudeRuleType highLatRuleType,
    double customFajr,
    double customIsha,
    Duration cityOffset, {
    Duration? nextDayCityOffset,
    Map<PrayerKey, int>? manualOffsets,
    Duration Function(DateTime utcInstant)? offsetResolver,
    double elevationMeters = 0.0,
    AtmosphericConditions? atmosphericConditions,
    int hijriAdjustmentDays = 0,
    PolarResolutionPolicy polarPolicy = PolarResolutionPolicy.nearestLatitude45,
  }) {
    final rawAnchors = computeRawCycleAnchors(
      lat,
      lng,
      targetDate,
      methodType,
      madhabType,
      highLatRuleType,
      customFajr,
      customIsha,
      cityOffset,
      nextDayCityOffset: nextDayCityOffset,
      manualOffsets: manualOffsets,
      offsetResolver: offsetResolver,
      elevationMeters: elevationMeters,
      atmosphericConditions: atmosphericConditions,
      hijriAdjustmentDays: hijriAdjustmentDays,
    );

    return PolarCycleSynthesizer.ensureValidAnchors(
      candidateAnchors: rawAnchors,
      latitude: lat,
      longitude: lng,
      targetDate: targetDate,
      methodType: methodType,
      madhabType: madhabType,
      highLatRuleType: highLatRuleType,
      customFajr: customFajr,
      customIsha: customIsha,
      cityOffset: cityOffset,
      nextDayCityOffset: nextDayCityOffset,
      manualOffsets: manualOffsets,
      offsetResolver: offsetResolver,
      elevationMeters: elevationMeters,
      policy: polarPolicy,
    );
  }

  static DateTime _clampBefore(
    DateTime candidate,
    DateTime upperBound, {
    Duration minGap = const Duration(minutes: 5),
  }) {
    final maxAllowed = upperBound.subtract(minGap);
    return candidate.isAfter(maxAllowed) ? maxAllowed : candidate;
  }

  static DateTime _clampAfter(
    DateTime candidate,
    DateTime lowerBound, {
    Duration minGap = const Duration(minutes: 5),
  }) {
    final minAllowed = lowerBound.add(minGap);
    return candidate.isBefore(minAllowed) ? minAllowed : candidate;
  }

  static SuwayaCycleAnchors computeRawCycleAnchors(
    double lat,
    double lng,
    DateTime targetDate,
    CalculationMethodType methodType,
    MadhabType madhabType,
    HighLatitudeRuleType highLatRuleType,
    double customFajr,
    double customIsha,
    Duration cityOffset, {
    Duration? nextDayCityOffset,
    Map<PrayerKey, int>? manualOffsets,
    Duration Function(DateTime utcInstant)? offsetResolver,
    double elevationMeters = 0.0,
    AtmosphericConditions? atmosphericConditions,
    int hijriAdjustmentDays = 0,
  }) {
    final params = _getParams(
      methodType,
      madhabType,
      highLatRuleType,
      customFajr,
      customIsha,
    );

    final pair = _safeComputePrayerTimesPair(
      lat: lat,
      lng: lng,
      date: targetDate,
      params: params,
    );
    final dayD = pair.day1;
    final dayDPlus1 = pair.day2;

    final allowedManualOffsets = <PrayerKey, int>{};
    if (manualOffsets != null) {
      for (final entry in manualOffsets.entries) {
        if (entry.key != PrayerKey.sunrise) {
          allowedManualOffsets[entry.key] = entry.value.clamp(-30, 30);
        }
      }
    }

    final effectiveNextOffset = nextDayCityOffset ?? cityOffset;
    final elevationShift = computeElevationHorizonDip(
      pair.effectiveLat,
      elevationMeters,
    );
    final refractionShift = atmosphericConditions != null
        ? atmosphericConditions.horizonRefractionTimeDelta(pair.effectiveLat)
        : Duration.zero;
    final totalHorizonShift = elevationShift + refractionShift;

    final rawStartSunsetUtc = dayD.maghrib.toUtc().add(totalHorizonShift);
    final rawEndSunsetUtc = dayDPlus1.maghrib.toUtc().add(totalHorizonShift);
    final cycleSunriseUtc = dayDPlus1.sunrise.toUtc().subtract(
      totalHorizonShift,
    );
    final dayDSunriseUtc = dayD.sunrise.toUtc().subtract(totalHorizonShift);

    final baseIshaUtc = (methodType == CalculationMethodType.ummAlQura)
        ? _resolveUmmAlQuraIshaUtc(
            sunsetUtc: rawStartSunsetUtc,
            civilDate: targetDate,
            hijriAdjustmentDays: hijriAdjustmentDays,
          )
        : dayD.isha.toUtc();

    final resolvedTwilight = _resolveHighLatitudeTwilight(
      lat: lat,
      lng: lng,
      date: targetDate,
      params: params,
      highLatRuleType: highLatRuleType,
      defaultTodayFajrUtc: dayD.fajr.toUtc(),
      defaultTodayIshaUtc: baseIshaUtc,
      defaultNextFajrUtc: dayDPlus1.fajr.toUtc(),
      todaySunriseUtc: dayDSunriseUtc,
      todaySunsetUtc: rawStartSunsetUtc,
      tomorrowSunriseUtc: cycleSunriseUtc,
    );

    var cycleStartMaghribUtc = _applyOffset(
      rawStartSunsetUtc,
      PrayerKey.maghrib,
      allowedManualOffsets,
    );
    var cycleIshaUtc = _applyOffset(
      resolvedTwilight.todayIshaUtc,
      PrayerKey.isha,
      allowedManualOffsets,
    );
    var cycleFajrUtc = _applyOffset(
      resolvedTwilight.nextFajrUtc,
      PrayerKey.fajr,
      allowedManualOffsets,
    );
    var cycleDhuhrUtc = _applyOffset(
      dayDPlus1.dhuhr.toUtc(),
      PrayerKey.dhuhr,
      allowedManualOffsets,
    );
    var cycleAsrUtc = _applyOffset(
      dayDPlus1.asr.toUtc(),
      PrayerKey.asr,
      allowedManualOffsets,
    );
    var cycleEndMaghribUtc = _applyOffset(
      rawEndSunsetUtc,
      PrayerKey.maghrib,
      allowedManualOffsets,
    );

    cycleFajrUtc = _clampBefore(cycleFajrUtc, cycleSunriseUtc);
    final realNightMicroseconds = cycleFajrUtc
        .difference(cycleStartMaghribUtc)
        .inMicroseconds;
    final sharIMidnightUtc = cycleStartMaghribUtc.add(
      Duration(microseconds: realNightMicroseconds ~/ 2),
    );

    cycleStartMaghribUtc = _clampBefore(cycleStartMaghribUtc, cycleIshaUtc);
    cycleIshaUtc = _clampAfter(cycleIshaUtc, cycleStartMaghribUtc);
    cycleIshaUtc = _clampBefore(cycleIshaUtc, sharIMidnightUtc);

    cycleDhuhrUtc = _clampAfter(cycleDhuhrUtc, cycleSunriseUtc);
    cycleAsrUtc = _clampAfter(cycleAsrUtc, cycleDhuhrUtc);
    cycleEndMaghribUtc = _clampAfter(cycleEndMaghribUtc, cycleAsrUtc);

    DateTime toEveningWall(DateTime utc) =>
        utc.add(offsetResolver != null ? offsetResolver(utc) : cityOffset);
    DateTime toNextDayWall(DateTime utc) => utc.add(
      offsetResolver != null ? offsetResolver(utc) : effectiveNextOffset,
    );

    return SuwayaCycleAnchors(
      cycleStartMaghrib: toEveningWall(cycleStartMaghribUtc),
      cycleIsha: toEveningWall(cycleIshaUtc),
      sharIMidnight: toEveningWall(sharIMidnightUtc),
      cycleFajr: toNextDayWall(cycleFajrUtc),
      cycleSunrise: toNextDayWall(cycleSunriseUtc),
      cycleDhuhr: toNextDayWall(cycleDhuhrUtc),
      cycleAsr: toNextDayWall(cycleAsrUtc),
      cycleEndMaghrib: toNextDayWall(cycleEndMaghribUtc),
      cycleStartMaghribUtc: cycleStartMaghribUtc,
      cycleIshaUtc: cycleIshaUtc,
      sharIMidnightUtc: sharIMidnightUtc,
      cycleFajrUtc: cycleFajrUtc,
      cycleSunriseUtc: cycleSunriseUtc,
      cycleDhuhrUtc: cycleDhuhrUtc,
      cycleAsrUtc: cycleAsrUtc,
      cycleEndMaghribUtc: cycleEndMaghribUtc,
      calculatedStartSunset: toEveningWall(rawStartSunsetUtc),
      calculatedEndSunset: toNextDayWall(rawEndSunsetUtc),
      calculatedStartSunsetUtc: rawStartSunsetUtc,
      calculatedEndSunsetUtc: rawEndSunsetUtc,
    );
  }
}