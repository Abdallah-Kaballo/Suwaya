import '../models/astro_models.dart';

/// نمط توزيع السويعات الأربع والعشرين على الفترات السبع
enum SuwayaDistributionMode {
  canonicalMadhab,
  dynamicProportional,
}

/// اسم بديل متوافق مع SuwayaTimeEngine لمنع خطأ undefined_class
typedef SuwayaAllocationMode = SuwayaDistributionMode;

class SuwayaDistributor {
  static const List<int> _jumhurDistribution = [1, 4, 6, 1, 6, 3, 3];
  static const List<int> _hanafiDistribution = [1, 4, 6, 1, 6, 4, 2];

  /// جلب التوزيع القياسي الثابت بناءً على المذهب (متوافق 100% مع الكود الحالي)
  static List<int> getDistributionForMadhab(MadhabType madhab) {
    return madhab == MadhabType.hanafi
        ? _hanafiDistribution
        : _jumhurDistribution;
  }

  /// حساب توزيع الـ 24 سويعة بناءً على النمط المختار (ثابت أو تناسبي ديناميكي)
  static List<int> resolveDistribution({
    required MadhabType madhab,
    required SuwayaCycleAnchors anchors,
    SuwayaDistributionMode mode = SuwayaDistributionMode.canonicalMadhab,
  }) {
    if (mode == SuwayaDistributionMode.canonicalMadhab ||
        !anchors.isValidSequence) {
      return getDistributionForMadhab(madhab);
    }

    // 1. النصف الأول من الليل (الفترتان 1 و 2) يتقاسم 5 سويعات بحد أدنى 1 سويعة لكل فترة
    final d1 = _spanMicro(
      anchors.cycleStartMaghrib,
      anchors.cycleIsha,
      anchors.cycleStartMaghribUtc,
      anchors.cycleIshaUtc,
    );
    final d2 = _spanMicro(
      anchors.cycleIsha,
      anchors.sharIMidnight,
      anchors.cycleIshaUtc,
      anchors.sharIMidnightUtc,
    );
    final firstHalfNight = _allocateProportional(
      durations: [d1, d2],
      totalSlots: 5,
      minPerPeriod: 1,
    );

    // 2. النصف الثاني من الليل (الفترة 3 = 6 سويعات ثابتة) والفجر (الفترة 4 = 1 سويعة ثابتة)
    const int p3Slots = 6;
    const int p4Slots = 1;

    // 3. طور النهار (الفترات 5 و 6 و 7) يتقاسم 12 سويعة بحد أدنى 1 سويعة لكل فترة
    final d5 = _spanMicro(
      anchors.cycleSunrise,
      anchors.cycleDhuhr,
      anchors.cycleSunriseUtc,
      anchors.cycleDhuhrUtc,
    );
    final d6 = _spanMicro(
      anchors.cycleDhuhr,
      anchors.cycleAsr,
      anchors.cycleDhuhrUtc,
      anchors.cycleAsrUtc,
    );
    final d7 = _spanMicro(
      anchors.cycleAsr,
      anchors.cycleEndMaghrib,
      anchors.cycleAsrUtc,
      anchors.cycleEndMaghribUtc,
    );
    final dayPhase = _allocateProportional(
      durations: [d5, d6, d7],
      totalSlots: 12,
      minPerPeriod: 1,
    );

    return [
      firstHalfNight[0],
      firstHalfNight[1],
      p3Slots,
      p4Slots,
      dayPhase[0],
      dayPhase[1],
      dayPhase[2],
    ];
  }

  static int _spanMicro(
    DateTime startWall,
    DateTime endWall,
    DateTime? startUtc,
    DateTime? endUtc,
  ) {
    final micro = (startUtc != null && endUtc != null)
        ? endUtc.difference(startUtc).inMicroseconds
        : endWall.difference(startWall).inMicroseconds;
    return micro > 0 ? micro : 1;
  }

  /// خوارزمية هاملتون (Largest Remainder Method) لتوزيع عدد صحيح من السويعات دون أي فقد في المجموع
  static List<int> _allocateProportional({
    required List<int> durations,
    required int totalSlots,
    required int minPerPeriod,
  }) {
    final count = durations.length;
    final baseAlloc = List<int>.filled(count, minPerPeriod);
    final remainingToDistribute = totalSlots - (count * minPerPeriod);
    if (remainingToDistribute <= 0) return baseAlloc;

    final totalDuration = durations.fold<int>(0, (s, d) => s + d);
    if (totalDuration <= 0) {
      baseAlloc[0] += remainingToDistribute;
      return baseAlloc;
    }

    final quotas = List<double>.generate(
      count,
      (i) => (durations[i] / totalDuration) * remainingToDistribute,
    );
    final wholeParts = quotas.map((q) => q.floor()).toList();
    final remainders = List<({int index, double rem})>.generate(
      count,
      (i) => (index: i, rem: quotas[i] - wholeParts[i]),
    )..sort((a, b) => b.rem.compareTo(a.rem));

    int allocatedExtra = wholeParts.fold<int>(0, (s, w) => s + w);
    for (int i = 0; i < count; i++) {
      baseAlloc[i] += wholeParts[i];
    }

    int remIdx = 0;
    while (allocatedExtra < remainingToDistribute) {
      baseAlloc[remainders[remIdx % count].index] += 1;
      allocatedExtra++;
      remIdx++;
    }

    return baseAlloc;
  }
}
