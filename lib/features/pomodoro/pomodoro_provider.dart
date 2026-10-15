import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/astro_engine/astro_provider.dart';

enum PomodoroView { selector, traditional, suwayaSetup, suwayaActive }

enum PomodoroPhase { work, shortBreak, longBreak }

enum PomodoroStatus { idle, running, paused, finished }

// 🌟 1. إعدادات البومودورو التقليدي القابلة للتخصيص
class TraditionalPomodoroSettings {
  final int workMinutes; // 25..60 (بمضاعفات 5) - الافتراضي 25
  final int shortBreakMinutes; // 5 أو 10 - الافتراضي 5
  final int longBreakMinutes; // 20..40 (بمضاعفات 5) - الافتراضي 30
  final int cyclesBeforeLongBreak; // 1..6 - الافتراضي 4

  const TraditionalPomodoroSettings({
    this.workMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 30,
    this.cyclesBeforeLongBreak = 4,
  });

  TraditionalPomodoroSettings copyWith({
    int? workMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? cyclesBeforeLongBreak,
  }) {
    return TraditionalPomodoroSettings(
      workMinutes: workMinutes ?? this.workMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      cyclesBeforeLongBreak:
          cyclesBeforeLongBreak ?? this.cyclesBeforeLongBreak,
    );
  }
}

// 🌟 2. خيار سرعة التدفق للبومودورو السُويعي
class SuwayaFlowOption {
  final int pomodoroCount; // عدد البومودورات الصحيح (N)
  final double flowSpeed; // سرعة التدفق (0.5x .. 2.0x)
  final String tag; // 'slower' | 'recommended' | 'faster'

  const SuwayaFlowOption({
    required this.pomodoroCount,
    required this.flowSpeed,
    required this.tag,
  });
}

// 🌟 3. إعدادات جلسة البومودورو السُويعي النشطة
class SuwayaSessionConfig {
  final DateTime anchoredStartTime; // دقيقة دخول المستخدم لصفحة الإعداد
  final DateTime endTime; // وقت النهاية (الصلاة القادمة أو الوقت المخصص)
  final String endLabel; // اسم وقت النهاية
  final int totalPomodoros; // إجمالي عدد البومودورات (N)
  final double flowSpeed; // سرعة التدفق المختارة
  final int workVirtualMinutes; // 25 دقيقة افتراضية
  final int breakVirtualMinutes; // 5 دقائق افتراضية

  const SuwayaSessionConfig({
    required this.anchoredStartTime,
    required this.endTime,
    required this.endLabel,
    required this.totalPomodoros,
    required this.flowSpeed,
    this.workVirtualMinutes = 25,
    this.breakVirtualMinutes = 5,
  });
}

// 🌟 4. الحالة الشاملة للبومودورو
class PomodoroState {
  final PomodoroView currentView;
  final PomodoroStatus status;
  final PomodoroPhase phase;
  final TraditionalPomodoroSettings traditionalSettings;
  final int currentCycle; // رقم الدورة الحالية (1-based)
  final double remainingSeconds; // الثواني المتبقية (فعلية للتقليدي، افتراضية للسويعي)
  final double phaseProgress; // نسبة التقدم في المرحلة الحالية (0.0 .. 1.0)
  final SuwayaSessionConfig? suwayaConfig;
  final bool isFinished; // هل انتهت الجلسة السويعية لبلوغ وقت النهاية/الصلاة

  const PomodoroState({
    this.currentView = PomodoroView.selector,
    this.status = PomodoroStatus.idle,
    this.phase = PomodoroPhase.work,
    this.traditionalSettings = const TraditionalPomodoroSettings(),
    this.currentCycle = 1,
    this.remainingSeconds = 25 * 60.0,
    this.phaseProgress = 0.0,
    this.suwayaConfig,
    this.isFinished = false,
  });

  bool get isBreak =>
      phase == PomodoroPhase.shortBreak || phase == PomodoroPhase.longBreak;

  PomodoroState copyWith({
    PomodoroView? currentView,
    PomodoroStatus? status,
    PomodoroPhase? phase,
    TraditionalPomodoroSettings? traditionalSettings,
    int? currentCycle,
    double? remainingSeconds,
    double? phaseProgress,
    SuwayaSessionConfig? suwayaConfig,
    bool clearSuwayaConfig = false,
    bool? isFinished,
  }) {
    return PomodoroState(
      currentView: currentView ?? this.currentView,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      traditionalSettings: traditionalSettings ?? this.traditionalSettings,
      currentCycle: currentCycle ?? this.currentCycle,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      phaseProgress: phaseProgress ?? this.phaseProgress,
      suwayaConfig:
          clearSuwayaConfig ? null : (suwayaConfig ?? this.suwayaConfig),
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

// 🌟 5. المحرك (PomodoroEngine)
class PomodoroEngine extends Notifier<PomodoroState> {
  Timer? _timer;

  // متغيرات تتبع الزمن الدقيق للبومودورو التقليدي
  DateTime? _traditionalPhaseStartedAt;
  int _traditionalAccumulatedElapsedSecs = 0;

  static const _prefWorkKey = 'pomo_trad_work_mins';
  static const _prefShortBreakKey = 'pomo_trad_short_break_mins';
  static const _prefLongBreakKey = 'pomo_trad_long_break_mins';
  static const _prefCyclesKey = 'pomo_trad_cycles_count';

  @override
  PomodoroState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    _loadTraditionalSettings();
    return const PomodoroState();
  }

  Future<void> _loadTraditionalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final work = prefs.getInt(_prefWorkKey) ?? 25;
    final shortB = prefs.getInt(_prefShortBreakKey) ?? 5;
    final longB = prefs.getInt(_prefLongBreakKey) ?? 30;
    final cycles = prefs.getInt(_prefCyclesKey) ?? 4;

    final loaded = TraditionalPomodoroSettings(
      workMinutes: work,
      shortBreakMinutes: shortB,
      longBreakMinutes: longB,
      cyclesBeforeLongBreak: cycles,
    );

    if (state.status == PomodoroStatus.idle &&
        state.currentView != PomodoroView.suwayaActive) {
      state = state.copyWith(
        traditionalSettings: loaded,
        remainingSeconds: loaded.workMinutes * 60.0,
        phaseProgress: 0.0,
      );
    } else {
      state = state.copyWith(traditionalSettings: loaded);
    }
  }

  Future<void> updateTraditionalSettings(
      TraditionalPomodoroSettings newSettings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefWorkKey, newSettings.workMinutes);
    await prefs.setInt(_prefShortBreakKey, newSettings.shortBreakMinutes);
    await prefs.setInt(_prefLongBreakKey, newSettings.longBreakMinutes);
    await prefs.setInt(_prefCyclesKey, newSettings.cyclesBeforeLongBreak);

    // إذا كان المؤقت في وضع الاستعداد (idle)، نحدث الرقم المعروض فوراً
    if (state.status == PomodoroStatus.idle &&
        state.currentView == PomodoroView.traditional) {
      final totalSecs = _getTraditionalPhaseDurationSecs(
          state.phase, newSettings);
      state = state.copyWith(
        traditionalSettings: newSettings,
        currentCycle:
            state.currentCycle.clamp(1, newSettings.cyclesBeforeLongBreak),
        remainingSeconds: totalSecs.toDouble(),
        phaseProgress: 0.0,
      );
    } else {
      state = state.copyWith(traditionalSettings: newSettings);
    }
  }

  int _getTraditionalPhaseDurationSecs(
    PomodoroPhase phase,
    TraditionalPomodoroSettings settings,
  ) {
    switch (phase) {
      case PomodoroPhase.work:
        return settings.workMinutes * 60;
      case PomodoroPhase.shortBreak:
        return settings.shortBreakMinutes * 60;
      case PomodoroPhase.longBreak:
        return settings.longBreakMinutes * 60;
    }
  }

  // 🌟 التنقل بين الشاشات
  void openTraditionalMode() {
    _timer?.cancel();
    _traditionalPhaseStartedAt = null;
    _traditionalAccumulatedElapsedSecs = 0;

    final workSecs = state.traditionalSettings.workMinutes * 60.0;
    state = state.copyWith(
      currentView: PomodoroView.traditional,
      status: PomodoroStatus.idle,
      phase: PomodoroPhase.work,
      currentCycle: 1,
      remainingSeconds: workSecs,
      phaseProgress: 0.0,
      clearSuwayaConfig: true,
      isFinished: false,
    );
  }

  void openSuwayaSetup() {
    _timer?.cancel();
    state = state.copyWith(
      currentView: PomodoroView.suwayaSetup,
      status: PomodoroStatus.idle,
      isFinished: false,
    );
  }

  void backToSelector() {
    _timer?.cancel();
    _traditionalPhaseStartedAt = null;
    _traditionalAccumulatedElapsedSecs = 0;

    state = state.copyWith(
      currentView: PomodoroView.selector,
      status: PomodoroStatus.idle,
      phase: PomodoroPhase.work,
      currentCycle: 1,
      remainingSeconds: state.traditionalSettings.workMinutes * 60.0,
      phaseProgress: 0.0,
      clearSuwayaConfig: true,
      isFinished: false,
    );
  }

  // =========================================================
  // أ. التحكم في البومودورو التقليدي (Traditional Mode)
  // =========================================================

  void startTraditional() {
    _timer?.cancel();
    _traditionalAccumulatedElapsedSecs = 0;
    _traditionalPhaseStartedAt = DateTime.now();

    final totalSecs = _getTraditionalPhaseDurationSecs(
        state.phase, state.traditionalSettings);
    state = state.copyWith(
      status: PomodoroStatus.running,
      remainingSeconds: totalSecs.toDouble(),
      phaseProgress: 0.0,
    );

    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => _onTraditionalTick());
  }

  void pauseTraditional() {
    if (state.status != PomodoroStatus.running) return;
    _timer?.cancel();
    if (_traditionalPhaseStartedAt != null) {
      _traditionalAccumulatedElapsedSecs +=
          DateTime.now().difference(_traditionalPhaseStartedAt!).inSeconds;
      _traditionalPhaseStartedAt = null;
    }
    state = state.copyWith(status: PomodoroStatus.paused);
  }

  void resumeTraditional() {
    if (state.status != PomodoroStatus.paused) return;
    _traditionalPhaseStartedAt = DateTime.now();
    state = state.copyWith(status: PomodoroStatus.running);
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => _onTraditionalTick());
  }

  void resetTraditional() {
    _timer?.cancel();
    _traditionalPhaseStartedAt = null;
    _traditionalAccumulatedElapsedSecs = 0;

    final workSecs = state.traditionalSettings.workMinutes * 60.0;
    state = state.copyWith(
      status: PomodoroStatus.idle,
      phase: PomodoroPhase.work,
      currentCycle: 1,
      remainingSeconds: workSecs,
      phaseProgress: 0.0,
    );
  }

  void skipTraditionalPhase() {
    HapticFeedback.mediumImpact();
    _advanceTraditionalPhase(keepRunning: state.status == PomodoroStatus.running);
  }

  void _onTraditionalTick() {
    if (state.currentView != PomodoroView.traditional ||
        state.status != PomodoroStatus.running) {
      return;
    }

    final currentRunSecs = _traditionalPhaseStartedAt != null
        ? DateTime.now().difference(_traditionalPhaseStartedAt!).inSeconds
        : 0;
    final totalElapsed = _traditionalAccumulatedElapsedSecs + currentRunSecs;
    final phaseTotalSecs = _getTraditionalPhaseDurationSecs(
        state.phase, state.traditionalSettings);

    if (totalElapsed >= phaseTotalSecs) {
      HapticFeedback.heavyImpact();
      _advanceTraditionalPhase(keepRunning: true);
      return;
    }

    final remaining = (phaseTotalSecs - totalElapsed).toDouble();
    final progress =
        phaseTotalSecs > 0 ? (totalElapsed / phaseTotalSecs).clamp(0.0, 1.0) : 0.0;

    state = state.copyWith(
      remainingSeconds: remaining,
      phaseProgress: progress,
    );
  }

  void _advanceTraditionalPhase({required bool keepRunning}) {
    final settings = state.traditionalSettings;
    PomodoroPhase nextPhase;
    int nextCycle = state.currentCycle;

    if (state.phase == PomodoroPhase.work) {
      if (state.currentCycle >= settings.cyclesBeforeLongBreak) {
        nextPhase = PomodoroPhase.longBreak;
      } else {
        nextPhase = PomodoroPhase.shortBreak;
      }
    } else if (state.phase == PomodoroPhase.shortBreak) {
      nextPhase = PomodoroPhase.work;
      nextCycle = state.currentCycle + 1;
    } else {
      // بعد انتهاء الراحة الطويلة نبدأ دورة جديدة من 1
      nextPhase = PomodoroPhase.work;
      nextCycle = 1;
    }

    final nextDurationSecs =
        _getTraditionalPhaseDurationSecs(nextPhase, settings);

    _traditionalAccumulatedElapsedSecs = 0;
    if (keepRunning) {
      _traditionalPhaseStartedAt = DateTime.now();
    } else {
      _traditionalPhaseStartedAt = null;
    }

    state = state.copyWith(
      phase: nextPhase,
      currentCycle: nextCycle,
      remainingSeconds: nextDurationSecs.toDouble(),
      phaseProgress: 0.0,
    );
  }

  // =========================================================
  // ب. التحكم في البومودورو السُويعي (Suwaya Mode)
  // =========================================================

  DateTime _currentCityTime() {
    return virtualDateTimeNotifier.value;
  }

  /// 🌟 حساب خيارات التقسيم (الأقرب لـ 1.0x، والسرعة الأقل إن وجدت، والسرعة الأعلى إن وجدت)
  static List<SuwayaFlowOption> calculateSuwayaFlowOptions(
      DateTime startTime, DateTime endTime) {
    final totalActualSeconds = endTime.difference(startTime).inSeconds;
    if (totalActualSeconds < 15 * 60) return [];

    // جمع كل القيم الصحيحة N التي تعطي سرعة تدفق بين 0.5x و 2.0x
    final List<({int n, double v})> valid = [];
    for (int n = 1; n <= 48; n++) {
      final double v = (n * 1800.0) / totalActualSeconds;
      if (v >= 0.5 && v <= 2.0) {
        valid.add((n: n, v: v));
      }
    }

    if (valid.isEmpty) return [];

    // إيجاد الخيار صاحب أقرب سرعة للواحد الصحيح (1.0x)
    int bestIdx = 0;
    double minDiff = (valid[0].v - 1.0).abs();
    for (int i = 1; i < valid.length; i++) {
      final diff = (valid[i].v - 1.0).abs();
      if (diff < minDiff) {
        minDiff = diff;
        bestIdx = i;
      }
    }

    final List<SuwayaFlowOption> result = [];

    // 1. الخيار الافتراضي (الأقرب لـ 1.0x) يوضع أولاً ليكون المختار افتراضياً
    result.add(SuwayaFlowOption(
      pomodoroCount: valid[bestIdx].n,
      flowSpeed: valid[bestIdx].v,
      tag: 'recommended',
    ));

    // 2. الخيار التالي لسرعة أقل (إن وجد: N - 1)
    if (bestIdx - 1 >= 0) {
      result.add(SuwayaFlowOption(
        pomodoroCount: valid[bestIdx - 1].n,
        flowSpeed: valid[bestIdx - 1].v,
        tag: 'slower',
      ));
    }

    // 3. الخيار التالي لسرعة أعلى (إن وجد: N + 1)
    if (bestIdx + 1 < valid.length) {
      result.add(SuwayaFlowOption(
        pomodoroCount: valid[bestIdx + 1].n,
        flowSpeed: valid[bestIdx + 1].v,
        tag: 'faster',
      ));
    }

    return result;
  }

  void startSuwayaSession(SuwayaSessionConfig config) {
    _timer?.cancel();
    state = state.copyWith(
      currentView: PomodoroView.suwayaActive,
      status: PomodoroStatus.running,
      phase: PomodoroPhase.work,
      suwayaConfig: config,
      isFinished: false,
    );

    // 🌟 حساب فوري في اللحظة صفر لخصم الوقت المستهلك في الإعداد من البومودورو الأول
    _onSuwayaTick();

    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _onSuwayaTick());
  }

  void _onSuwayaTick() {
    final config = state.suwayaConfig;
    if (config == null ||
        state.currentView != PomodoroView.suwayaActive ||
        state.isFinished) {
      return;
    }

    final now = _currentCityTime();

    // الإنهاء الإجباري عند بلوغ وقت النهاية / الصلاة
    if (!now.isBefore(config.endTime)) {
      _endSuwayaForcefully();
      return;
    }

    final int actualElapsedSecs =
        max(0, now.difference(config.anchoredStartTime).inSeconds);
    final double totalVirtualElapsed = actualElapsedSecs * config.flowSpeed;

    const double cycleTotalVirtualSecs = 1800.0; // 30 دقيقة افتراضية (25 + 5)
    final double sessionMaxVirtualSecs =
        config.totalPomodoros * cycleTotalVirtualSecs;

    if (totalVirtualElapsed >= sessionMaxVirtualSecs) {
      _endSuwayaForcefully();
      return;
    }

    final int currentPomoIndex =
        (totalVirtualElapsed ~/ cycleTotalVirtualSecs)
            .clamp(0, config.totalPomodoros - 1);
    final double elapsedInCurrentPomo =
        totalVirtualElapsed % cycleTotalVirtualSecs;

    final double focusVirtualSecs = config.workVirtualMinutes * 60.0; // 1500s
    final double breakVirtualSecs = config.breakVirtualMinutes * 60.0; // 300s

    final bool inBreak = elapsedInCurrentPomo >= focusVirtualSecs;

    double remainingVirtual;
    double progress;
    PomodoroPhase currentPhase;

    if (!inBreak) {
      currentPhase = PomodoroPhase.work;
      remainingVirtual = focusVirtualSecs - elapsedInCurrentPomo;
      progress = focusVirtualSecs > 0
          ? (elapsedInCurrentPomo / focusVirtualSecs).clamp(0.0, 1.0)
          : 0.0;
    } else {
      currentPhase = PomodoroPhase.shortBreak;
      final double breakElapsed = elapsedInCurrentPomo - focusVirtualSecs;
      remainingVirtual = breakVirtualSecs - breakElapsed;
      progress = breakVirtualSecs > 0
          ? (breakElapsed / breakVirtualSecs).clamp(0.0, 1.0)
          : 0.0;
    }

    if (remainingVirtual < 0) remainingVirtual = 0;

    state = state.copyWith(
      phase: currentPhase,
      currentCycle: currentPomoIndex + 1,
      remainingSeconds: remainingVirtual,
      phaseProgress: progress,
    );
  }

  void _endSuwayaForcefully() {
    _timer?.cancel();
    HapticFeedback.heavyImpact();
    state = state.copyWith(
      status: PomodoroStatus.finished,
      remainingSeconds: 0,
      phaseProgress: 1.0,
      isFinished: true,
    );
  }

  void acknowledgeFinish() {
    backToSelector();
  }
}

final pomodoroProvider = NotifierProvider<PomodoroEngine, PomodoroState>(
  PomodoroEngine.new,
);