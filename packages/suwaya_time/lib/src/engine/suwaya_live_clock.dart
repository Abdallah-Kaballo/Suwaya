import 'dart:async';
import '../models/astro_models.dart';
import 'temporal_context_engine.dart';

/// 1. ساعة البث التفاعلي النقية (Pure Dart Reactive Virtual Clock)
/// تصدر تدفقاً (Stream) يتحدث تلقائياً عند بداية كل ثانية افتراضية متغيرة الطول
class SuwayaLiveClock {
  final double latitude;
  final double longitude;
  final String? timezoneId;
  final CalculationMethodType methodType;
  final MadhabType madhabType;
  final HighLatitudeRuleType highLatRuleType;
  final double customFajrAngle;
  final double customIshaAngle;
  final Map<PrayerKey, int>? manualOffsets;
  final DateTime Function() _nowUtcProvider;

  Timer? _adaptiveTimer;
  final StreamController<SuwayaTemporalContext> _tickController =
      StreamController<SuwayaTemporalContext>.broadcast();

  SuwayaLiveClock({
    required this.latitude,
    required this.longitude,
    this.timezoneId,
    this.methodType = CalculationMethodType.muslimWorldLeague,
    this.madhabType = MadhabType.shafi,
    this.highLatRuleType = HighLatitudeRuleType.middleOfTheNight,
    this.customFajrAngle = 18.0,
    this.customIshaAngle = 18.0,
    this.manualOffsets,
    DateTime Function()? nowUtcProvider,
  }) : _nowUtcProvider = nowUtcProvider ?? (() => DateTime.now().toUtc());

  /// تدفق حي يصدر السياق الزمني الكامل عند بداية كل ثانية افتراضية
  Stream<SuwayaTemporalContext> get stream => _tickController.stream;

  void start() {
    _scheduleNextVirtualSecond();
  }

  void stop() {
    _adaptiveTimer?.cancel();
    _adaptiveTimer = null;
  }

  Future<void> dispose() async {
    stop();
    await _tickController.close();
  }

  void _scheduleNextVirtualSecond() {
    _adaptiveTimer?.cancel();
    if (_tickController.isClosed) return;

    final nowUtc = _nowUtcProvider().toUtc();
    final ctx = TemporalContextEngine.evaluate(
      instantUtc: nowUtc,
      latitude: latitude,
      longitude: longitude,
      timezoneId: timezoneId,
      methodType: methodType,
      madhabType: madhabType,
      highLatRuleType: highLatRuleType,
      customFajrAngle: customFajrAngle,
      customIshaAngle: customIshaAngle,
      manualOffsets: manualOffsets,
    );

    if (!_tickController.isClosed) {
      _tickController.add(ctx);
    }

    final activePeriod = ctx.astroState.currentPeriod;
    final sCount =
        activePeriod.suwayasCount > 0 ? activePeriod.suwayasCount : 1;
    final periodMicro = activePeriod.totalDuration.inMicroseconds;

    Duration nextDelay;
    if (periodMicro > 0 && activePeriod.startUtc != null) {
      final totalVirtualSecs = sCount * 3600;
      final elapsedMicro =
          nowUtc.difference(activePeriod.startUtc!).inMicroseconds;
      final nextVirtualSecIdx =
          ((elapsedMicro * totalVirtualSecs) ~/ periodMicro) + 1;
      final nextBoundaryMicro =
          (nextVirtualSecIdx * periodMicro + totalVirtualSecs - 1) ~/
              totalVirtualSecs;
      final remMicro = nextBoundaryMicro - elapsedMicro;
      nextDelay = Duration(microseconds: remMicro.clamp(50000, 2000000));
    } else {
      nextDelay = Duration(milliseconds: 1000 - (nowUtc.millisecond % 1000));
    }

    _adaptiveTimer = Timer(nextDelay, _scheduleNextVirtualSecond);
  }
}