import '../models/astro_models.dart';
import '../models/temporal_primitives.dart';
import 'suwaya_coordinate_mapper.dart';

/// ضغط وفك ضغط الإحداثيات السويعية والتواريخ الهجرية في عدد صحيح واحد (47-bit Safe Integer)
/// تخطيط البتات (من الأقل للأعلى):
/// - Bits 0..5   (6 bits) : virtualSecond (0..59)
/// - Bits 6..11  (6 bits) : virtualMinute (0..59)
/// - Bits 12..15 (4 bits) : periodLocalSlotNumber (1..12)
/// - Bits 16..18 (3 bits) : periodId (1..7)
/// - Bits 19..23 (5 bits) : globalSlotIndex (0..23)
/// - Bits 24..28 (5 bits) : hijriDay (1..30)
/// - Bits 29..32 (4 bits) : hijriMonth (1..12)
/// - Bits 33..46 (14 bits): hijriYear (0..16383)
class SuwayaBinaryCodec {
  static final RegExp _isoSuwayaRegex = RegExp(
    r'^SWY-([ND])(0[1-9]|1[0-2]):([0-5][0-9])(?::([0-5][0-9]))?$',
    caseSensitive: false,
  );

  /// ضغط التاريخ الهجري والإحداثي السويعي في عدد صحيح واحد (47-bit)
  static int pack({
    int hijriYear = 0,
    int hijriMonth = 1,
    int hijriDay = 1,
    required SuwayaCoordinate coordinate,
  }) {
    final y = hijriYear.clamp(0, 16383);
    final m = hijriMonth.clamp(1, 12);
    final d = hijriDay.clamp(1, 30);
    final g = coordinate.globalSlotIndex.clamp(0, 23);
    final pId = coordinate.periodId.clamp(1, 7);
    final lSlot = coordinate.periodLocalSlotNumber.clamp(1, 12);
    final vMin = coordinate.virtualMinute.clamp(0, 59);
    final vSec = coordinate.virtualSecond.clamp(0, 59);

    int packed = vSec;
    packed |= (vMin << 6);
    packed |= (lSlot << 12);
    packed |= (pId << 16);
    packed |= (g << 19);
    packed |= (d << 24);
    packed |= (m << 29);
    packed |= (y << 33);
    return packed;
  }

  /// فك ضغط العدد الصحيح (47-bit) واسترجاع التاريخ الهجري والإحداثي السويعي بدقة 100%
  static ({
    int hijriYear,
    int hijriMonth,
    int hijriDay,
    SuwayaCoordinate coordinate,
  }) unpack(int packed) {
    final vSec = packed & 0x3F;
    final vMin = (packed >> 6) & 0x3F;
    final lSlot = (packed >> 12) & 0x0F;
    final pId = ((packed >> 16) & 0x07).clamp(1, 7);
    final g = ((packed >> 19) & 0x1F).clamp(0, 23);
    final d = ((packed >> 24) & 0x1F).clamp(1, 30);
    final m = ((packed >> 29) & 0x0F).clamp(1, 12);
    final y = (packed >> 33) & 0x3FFF;

    final uiPhase = SuwayaCoordinateMapper.globalToUiPhase(g);
    final progress = ((vMin * 60 + vSec) / 3600.0).clamp(0.0, 0.999999);

    return (
      hijriYear: y,
      hijriMonth: m,
      hijriDay: d,
      coordinate: SuwayaCoordinate(
        globalSlotIndex: g,
        phase: uiPhase.phase,
        phaseSlotNumber: uiPhase.uiHour,
        periodId: pId,
        periodKey: PeriodKey.values[pId - 1],
        periodLocalSlotNumber: lSlot,
        virtualMinute: vMin,
        virtualSecond: vSec,
        slotProgress: progress,
      ),
    );
  }

  /// تحليل النص القياسي (مثل "SWY-N04:15" أو "SWY-D09:42:30") إلى إحداثي سويعي
  static SuwayaCoordinate? tryParseIsoSuwaya(
    String input, {
    List<AstroPeriod>? periods,
  }) {
    final match = _isoSuwayaRegex.firstMatch(input.trim());
    if (match == null) return null;

    final isNight = match.group(1)!.toUpperCase() == 'N';
    final phaseHour = int.parse(match.group(2)!);
    final vMin = int.parse(match.group(3)!);
    final vSec = match.group(4) != null ? int.parse(match.group(4)!) : 0;

    final globalSlot =
        SuwayaCoordinateMapper.uiPhaseToGlobal(phaseHour, isNight);

    final mapped = periods != null && periods.isNotEmpty
        ? SuwayaCoordinateMapper.globalToLocal(globalSlot, periods)
        : (
            periodId: isNight ? 1 : 5,
            periodKey: isNight
                ? PeriodKey.nightMaghribIsha
                : PeriodKey.daySunriseDhuhr,
            localSuwaya: 1,
            suwayasCount: 1,
          );

    return SuwayaCoordinate(
      globalSlotIndex: globalSlot,
      phase: isNight ? SuwayaPhase.night : SuwayaPhase.day,
      phaseSlotNumber: phaseHour,
      periodId: mapped.periodId,
      periodKey: mapped.periodKey,
      periodLocalSlotNumber: mapped.localSuwaya,
      virtualMinute: vMin,
      virtualSecond: vSec,
      slotProgress: ((vMin * 60 + vSec) / 3600.0).clamp(0.0, 0.999999),
    );
  }
}