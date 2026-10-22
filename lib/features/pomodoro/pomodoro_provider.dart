import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/astro_engine/astro_provider.dart';
import '../../core/notification/notification_service.dart';
import '../../core/providers/ui_providers.dart';

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

class SuwayaSessionConfig {
  final DateTime anchoredStartTime;
  final DateTime endTime;
  final DateTime anchoredStartUtc;
  final DateTime endUtc;
  final String endLabel;
  final int totalPomodoros;
  final double flowSpeed;
  final int workVirtualMinutes;
  final int breakVirtualMinutes;

  SuwayaSessionConfig({
    required this.anchoredStartTime,
    required this.endTime,
    DateTime? anchoredStartUtc,
    DateTime? endUtc,
    required this.endLabel,
    required this.totalPomodoros,
    required this.flowSpeed,
    this.workVirtualMinutes = 25,
    this.breakVirtualMinutes = 5,
  })  : anchoredStartUtc = anchoredStartUtc ??
            DateTime.now().toUtc().subtract(
                  Duration(
                    seconds: DateTime.now()
                        .toUtc()
                        .second, // محاذاة لبداية الدقيقة الحالية بـ UTC
                  ),
                ),
        endUtc = endUtc ??
            (anchoredStartUtc ??
                    DateTime.now().toUtc().subtract(
                          Duration(seconds: DateTime.now().toUtc().second),
                        ))
                .add(endTime.difference(anchoredStartTime));
}

// 🌟 4. الحالة الشاملة للبومودورو الاحترافي
class PomodoroState {
  final PomodoroView currentView;
  final PomodoroStatus status;
  final PomodoroPhase phase;
  final TraditionalPomodoroSettings traditionalSettings;
  final int currentCycle; // رقم الدورة الحالية (1-based)
  final double remainingSeconds; // الثواني المتبقية
  final double phaseProgress; // نسبة التقدم في المرحلة الحالية (0.0 .. 1.0)
  final double cycleProgress; // نسبة التقدم في الدورة الكاملة (عمل + راحة) للأسطرلاب
  final double focusRatio; // نسبة وقت العمل من إجمالي الدورة للأسطرلاب
  final SuwayaSessionConfig? suwayaConfig;
  final bool isFinished;
  final bool isMuted; // كتم أصوات الانتقال
  final bool isFullScreen; // وضع ملء الشاشة الغامر
  final int? linkedTaskId; // المهمة المرتبطة بالتركيز حالياً
  final int dailyCompletedSessions; // عدد جلسات التركيز المنجزة اليوم
  final bool isPrePrayerWarningActive; // تنبيه ما قبل الصلاة بدقيقتين

  const PomodoroState({
    this.currentView = PomodoroView.selector,
    this.status = PomodoroStatus.idle,
    this.phase = PomodoroPhase.work,
    this.traditionalSettings = const TraditionalPomodoroSettings(),
    this.currentCycle = 1,
    this.remainingSeconds = 25 * 60.0,
    this.phaseProgress = 0.0,
    this.cycleProgress = 0.0,
    this.focusRatio = 25.0 / 30.0,
    this.suwayaConfig,
    this.isFinished = false,
    this.isMuted = false,
    this.isFullScreen = false,
    this.linkedTaskId,
    this.dailyCompletedSessions = 0,
    this.isPrePrayerWarningActive = false,
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
    double? cycleProgress,
    double? focusRatio,
    SuwayaSessionConfig? suwayaConfig,
    bool clearSuwayaConfig = false,
    bool? isFinished,
    bool? isMuted,
    bool? isFullScreen,
    int? linkedTaskId,
    bool clearLinkedTask = false,
    int? dailyCompletedSessions,
    bool? isPrePrayerWarningActive,
  }) {
    return PomodoroState(
      currentView: currentView ?? this.currentView,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      traditionalSettings: traditionalSettings ?? this.traditionalSettings,
      currentCycle: currentCycle ?? this.currentCycle,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      phaseProgress: phaseProgress ?? this.phaseProgress,
      cycleProgress: cycleProgress ?? this.cycleProgress,
      focusRatio: focusRatio ?? this.focusRatio,
      suwayaConfig:
          clearSuwayaConfig ? null : (suwayaConfig ?? this.suwayaConfig),
      isFinished: isFinished ?? this.isFinished,
      isMuted: isMuted ?? this.isMuted,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      linkedTaskId:
          clearLinkedTask ? null : (linkedTaskId ?? this.linkedTaskId),
      dailyCompletedSessions:
          dailyCompletedSessions ?? this.dailyCompletedSessions,
      isPrePrayerWarningActive:
          isPrePrayerWarningActive ?? this.isPrePrayerWarningActive,
    );
  }
}

// 🌟 5. المحرك (PomodoroEngine)
class PomodoroEngine extends Notifier<PomodoroState> {
  Timer? _timer;

  DateTime? _traditionalPhaseStartedAt;
  int _traditionalAccumulatedElapsedSecs = 0;

  // متغيرات لتتبع التحولات في البومودورو السُويعي وإطلاق الجرس والاهتزاز
  PomodoroPhase _lastSuwayaPhase = PomodoroPhase.work;
  int _lastSuwayaCycle = 1;
  bool _prePrayerWarningTriggered = false;

  static const _prefWorkKey = 'pomo_trad_work_mins';
  static const _prefShortBreakKey = 'pomo_trad_short_break_mins';
  static const _prefLongBreakKey = 'pomo_trad_long_break_mins';
  static const _prefCyclesKey = 'pomo_trad_cycles_count';
  static const _prefMutedKey = 'pomo_is_muted';
  static const _prefDailyDateKey = 'pomo_daily_date';
  static const _prefDailyCountKey = 'pomo_daily_completed_count';

  @override
  PomodoroState build() {
    ref.onDispose(() {
      _timer?.cancel();
      NotificationService().cancelLivePomodoroNotification();
    });
    _loadPreferences();
    return const PomodoroState();
  }

  String _todayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final work = prefs.getInt(_prefWorkKey) ?? 25;
      final shortB = prefs.getInt(_prefShortBreakKey) ?? 5;
      final longB = prefs.getInt(_prefLongBreakKey) ?? 30;
      final cycles = prefs.getInt(_prefCyclesKey) ?? 4;
      final muted = prefs.getBool(_prefMutedKey) ?? false;

      final savedDate = prefs.getString(_prefDailyDateKey) ?? '';
      final todayKey = _todayDateKey();
      int dailyCount = 0;
      if (savedDate == todayKey) {
        dailyCount = prefs.getInt(_prefDailyCountKey) ?? 0;
      } else {
        await prefs.setString(_prefDailyDateKey, todayKey);
        await prefs.setInt(_prefDailyCountKey, 0);
      }

      final loaded = TraditionalPomodoroSettings(
        workMinutes: work,
        shortBreakMinutes: shortB,
        longBreakMinutes: longB,
        cyclesBeforeLongBreak: cycles,
      );

      final ratio = loaded.workMinutes /
          (loaded.workMinutes + loaded.shortBreakMinutes);

      if (state.status == PomodoroStatus.idle &&
          state.currentView != PomodoroView.suwayaActive) {
        state = state.copyWith(
          traditionalSettings: loaded,
          remainingSeconds: loaded.workMinutes * 60.0,
          phaseProgress: 0.0,
          cycleProgress: 0.0,
          focusRatio: ratio,
          isMuted: muted,
          dailyCompletedSessions: dailyCount,
        );
      } else {
        state = state.copyWith(
          traditionalSettings: loaded,
          isMuted: muted,
          dailyCompletedSessions: dailyCount,
        );
      }
    } catch (_) {}
  }

  Future<void> _incrementDailyCompletedSessions() async {
    final newCount = state.dailyCompletedSessions + 1;
    state = state.copyWith(dailyCompletedSessions: newCount);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefDailyDateKey, _todayDateKey());
      await prefs.setInt(_prefDailyCountKey, newCount);
    } catch (_) {}
  }

  Future<void> toggleMute() async {
    final nextMuted = !state.isMuted;
    state = state.copyWith(isMuted: nextMuted);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefMutedKey, nextMuted);
    } catch (_) {}
  }

  void setFullScreen(bool fullScreen) {
    state = state.copyWith(isFullScreen: fullScreen);
    try {
      ref.read(isPomodoroFullScreenProvider.notifier).state = fullScreen;
      if (fullScreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    } catch (_) {}
  }

  void toggleFullScreen() => setFullScreen(!state.isFullScreen);

  void selectLinkedTask(int? taskId) {
    if (taskId == null) {
      state = state.copyWith(clearLinkedTask: true);
    } else {
      state = state.copyWith(linkedTaskId: taskId);
    }
    _syncLiveCurtainNotification();
  }

  Future<void> updateTraditionalSettings(
    TraditionalPomodoroSettings newSettings,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefWorkKey, newSettings.workMinutes);
      await prefs.setInt(_prefShortBreakKey, newSettings.shortBreakMinutes);
      await prefs.setInt(_prefLongBreakKey, newSettings.longBreakMinutes);
      await prefs.setInt(_prefCyclesKey, newSettings.cyclesBeforeLongBreak);
    } catch (_) {}

    final ratio = _computeTraditionalFocusRatio(state.phase, newSettings);

    if (state.status == PomodoroStatus.idle &&
        state.currentView == PomodoroView.traditional) {
      final totalSecs = _getTraditionalPhaseDurationSecs(
        state.phase,
        newSettings,
      );
      state = state.copyWith(
        traditionalSettings: newSettings,
        currentCycle: state.currentCycle.clamp(
          1,
          newSettings.cyclesBeforeLongBreak,
        ),
        remainingSeconds: totalSecs.toDouble(),
        phaseProgress: 0.0,
        cycleProgress: 0.0,
        focusRatio: ratio,
      );
    } else {
      state = state.copyWith(
        traditionalSettings: newSettings,
        focusRatio: ratio,
      );
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

  double _computeTraditionalFocusRatio(
    PomodoroPhase phase,
    TraditionalPomodoroSettings settings,
  ) {
    final breakMins = phase == PomodoroPhase.longBreak
        ? settings.longBreakMinutes
        : settings.shortBreakMinutes;
    final total = settings.workMinutes + breakMins;
    return total > 0 ? (settings.workMinutes / total).clamp(0.1, 1.0) : 0.8333;
  }

  double _computeTraditionalCycleProgress(
    PomodoroPhase phase,
    double phaseProgress,
    double focusRatio,
  ) {
    if (phase == PomodoroPhase.work) {
      return (phaseProgress * focusRatio).clamp(0.0, 1.0);
    } else {
      return (focusRatio + phaseProgress * (1.0 - focusRatio)).clamp(0.0, 1.0);
    }
  }

  // 🌟 تشغيل الجرس والاهتزاز عند الانتقال بين جلسات العمل والراحة
  Future<void> _triggerPhaseTransitionFeedback({
    required PomodoroPhase newPhase,
    required int cycleNumber,
    required int totalCycles,
  }) async {
    try {
      HapticFeedback.heavyImpact();
      final hasVib = await Vibration.hasVibrator();
      if (hasVib == true) {
        if (newPhase == PomodoroPhase.work) {
          Vibration.vibrate(pattern: [0, 220, 120, 280]);
        } else {
          Vibration.vibrate(pattern: [0, 400]);
        }
      }
    } catch (_) {}

    final isWork = newPhase == PomodoroPhase.work;
    final title = isWork
        ? '${'pomodoro.in_flow'.tr()} ($cycleNumber/$totalCycles)'
        : 'pomodoro.deep_relaxation'.tr();
    final body = isWork
        ? 'pomodoro.start_session'.tr()
        : 'pomodoro.choose_mode'.tr();

    await NotificationService().playPomodoroTransitionAlert(
      title: title,
      body: body,
      isMuted: state.isMuted,
    );
  }

  // 🌟 مزامنة إشعار البومودورو الحي على ستارة النظام
  void _syncLiveCurtainNotification() {
    if (state.status != PomodoroStatus.running) {
      NotificationService().cancelLivePomodoroNotification();
      return;
    }

    DateTime phaseEndRealTime;
    String title;
    String body;

    if (state.currentView == PomodoroView.traditional) {
      final remRealSecs = state.remainingSeconds.round();
      phaseEndRealTime = DateTime.now().add(Duration(seconds: remRealSecs));
      final totalCycles = state.traditionalSettings.cyclesBeforeLongBreak;
      final phaseTitle = state.isBreak
          ? 'pomodoro.deep_relaxation'.tr()
          : 'pomodoro.in_flow'.tr();
      title = '$phaseTitle (${state.currentCycle}/$totalCycles)';
      body = 'pomodoro.traditional'.tr();
    } else if (state.currentView == PomodoroView.suwayaActive &&
        state.suwayaConfig != null) {
      final config = state.suwayaConfig!;
      final speed = config.flowSpeed > 0 ? config.flowSpeed : 1.0;
      final remRealSecs = (state.remainingSeconds / speed).round();
      phaseEndRealTime = DateTime.now().add(Duration(seconds: remRealSecs));
      final phaseTitle = state.isBreak
          ? 'pomodoro.deep_relaxation'.tr()
          : 'pomodoro.in_flow'.tr();
      title =
          '$phaseTitle (${state.currentCycle}/${config.totalPomodoros}) · ${config.flowSpeed.toStringAsFixed(2)}x';
      body = 'pomodoro.suwaya_mode'.tr();
    } else {
      return;
    }

    NotificationService().showLivePomodoroNotification(
      title: title,
      body: body,
      phaseEndTime: phaseEndRealTime,
    );
  }

  // 🌟 التنقل بين الشاشات
  void openTraditionalMode() {
    _timer?.cancel();
    setFullScreen(false);
    NotificationService().cancelLivePomodoroNotification();
    _traditionalPhaseStartedAt = null;
    _traditionalAccumulatedElapsedSecs = 0;

    final workSecs = state.traditionalSettings.workMinutes * 60.0;
    final ratio = _computeTraditionalFocusRatio(
      PomodoroPhase.work,
      state.traditionalSettings,
    );

    state = state.copyWith(
      currentView: PomodoroView.traditional,
      status: PomodoroStatus.idle,
      phase: PomodoroPhase.work,
      currentCycle: 1,
      remainingSeconds: workSecs,
      phaseProgress: 0.0,
      cycleProgress: 0.0,
      focusRatio: ratio,
      clearSuwayaConfig: true,
      isFinished: false,
      isPrePrayerWarningActive: false,
    );
  }

  void openSuwayaSetup() {
    _timer?.cancel();
    setFullScreen(false);
    NotificationService().cancelLivePomodoroNotification();
    state = state.copyWith(
      currentView: PomodoroView.suwayaSetup,
      status: PomodoroStatus.idle,
      isFinished: false,
      isPrePrayerWarningActive: false,
    );
  }

  void backToSelector() {
    _timer?.cancel();
    setFullScreen(false);
    NotificationService().cancelLivePomodoroNotification();
    _traditionalPhaseStartedAt = null;
    _traditionalAccumulatedElapsedSecs = 0;

    state = state.copyWith(
      currentView: PomodoroView.selector,
      status: PomodoroStatus.idle,
      phase: PomodoroPhase.work,
      currentCycle: 1,
      remainingSeconds: state.traditionalSettings.workMinutes * 60.0,
      phaseProgress: 0.0,
      cycleProgress: 0.0,
      clearSuwayaConfig: true,
      isFinished: false,
      isPrePrayerWarningActive: false,
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
      state.phase,
      state.traditionalSettings,
    );
    final ratio = _computeTraditionalFocusRatio(
      state.phase,
      state.traditionalSettings,
    );

    state = state.copyWith(
      status: PomodoroStatus.running,
      remainingSeconds: totalSecs.toDouble(),
      phaseProgress: 0.0,
      cycleProgress: _computeTraditionalCycleProgress(state.phase, 0.0, ratio),
      focusRatio: ratio,
    );

    _syncLiveCurtainNotification();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onTraditionalTick(),
    );
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
    NotificationService().cancelLivePomodoroNotification();
  }

  void resumeTraditional() {
    if (state.status != PomodoroStatus.paused) return;
    _traditionalPhaseStartedAt = DateTime.now();
    state = state.copyWith(status: PomodoroStatus.running);
    _syncLiveCurtainNotification();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onTraditionalTick(),
    );
  }

  void resetTraditional() {
    _timer?.cancel();
    setFullScreen(false);
    NotificationService().cancelLivePomodoroNotification();
    _traditionalPhaseStartedAt = null;
    _traditionalAccumulatedElapsedSecs = 0;

    final workSecs = state.traditionalSettings.workMinutes * 60.0;
    final ratio = _computeTraditionalFocusRatio(
      PomodoroPhase.work,
      state.traditionalSettings,
    );

    state = state.copyWith(
      status: PomodoroStatus.idle,
      phase: PomodoroPhase.work,
      currentCycle: 1,
      remainingSeconds: workSecs,
      phaseProgress: 0.0,
      cycleProgress: 0.0,
      focusRatio: ratio,
    );
  }

  void skipTraditionalPhase() {
    HapticFeedback.mediumImpact();
    _advanceTraditionalPhase(
      keepRunning: state.status == PomodoroStatus.running,
      fromNaturalCompletion: false,
    );
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
      state.phase,
      state.traditionalSettings,
    );

    if (totalElapsed >= phaseTotalSecs) {
      _advanceTraditionalPhase(
        keepRunning: true,
        fromNaturalCompletion: true,
      );
      return;
    }

    final remaining = (phaseTotalSecs - totalElapsed).toDouble();
    final progress = phaseTotalSecs > 0
        ? (totalElapsed / phaseTotalSecs).clamp(0.0, 1.0)
        : 0.0;
    final ratio = _computeTraditionalFocusRatio(
      state.phase,
      state.traditionalSettings,
    );
    final cycProg = _computeTraditionalCycleProgress(
      state.phase,
      progress,
      ratio,
    );

    state = state.copyWith(
      remainingSeconds: remaining,
      phaseProgress: progress,
      cycleProgress: cycProg,
      focusRatio: ratio,
    );
  }

  void _advanceTraditionalPhase({
    required bool keepRunning,
    required bool fromNaturalCompletion,
  }) {
    final settings = state.traditionalSettings;
    final wasWork = state.phase == PomodoroPhase.work;

    PomodoroPhase nextPhase;
    int nextCycle = state.currentCycle;

    if (wasWork) {
      if (fromNaturalCompletion) {
        _incrementDailyCompletedSessions();
      }
      if (state.currentCycle >= settings.cyclesBeforeLongBreak) {
        nextPhase = PomodoroPhase.longBreak;
      } else {
        nextPhase = PomodoroPhase.shortBreak;
      }
    } else if (state.phase == PomodoroPhase.shortBreak) {
      nextPhase = PomodoroPhase.work;
      nextCycle = state.currentCycle + 1;
    } else {
      nextPhase = PomodoroPhase.work;
      nextCycle = 1;
    }

    final nextDurationSecs = _getTraditionalPhaseDurationSecs(
      nextPhase,
      settings,
    );
    final ratio = _computeTraditionalFocusRatio(nextPhase, settings);

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
      cycleProgress: _computeTraditionalCycleProgress(nextPhase, 0.0, ratio),
      focusRatio: ratio,
    );

    if (fromNaturalCompletion) {
      _triggerPhaseTransitionFeedback(
        newPhase: nextPhase,
        cycleNumber: nextCycle,
        totalCycles: settings.cyclesBeforeLongBreak,
      );
    }

    if (keepRunning) {
      _syncLiveCurtainNotification();
    }
  }

  // =========================================================
  // ب. التحكم في البومودورو السُويعي (Suwaya Mode)
  // =========================================================

  DateTime _currentCityTime() {
    return virtualDateTimeNotifier.value;
  }

  static List<SuwayaFlowOption> calculateSuwayaFlowOptions(
    DateTime startTime,
    DateTime endTime,
  ) {
    final totalActualSeconds = endTime.difference(startTime).inSeconds;
    if (totalActualSeconds < 15 * 60) return [];

    final List<({int n, double v})> valid = [];
    for (int n = 1; n <= 48; n++) {
      final double v = (n * 1800.0) / totalActualSeconds;
      if (v >= 0.5 && v <= 2.0) {
        valid.add((n: n, v: v));
      }
    }

    if (valid.isEmpty) return [];

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

    result.add(
      SuwayaFlowOption(
        pomodoroCount: valid[bestIdx].n,
        flowSpeed: valid[bestIdx].v,
        tag: 'recommended',
      ),
    );

    if (bestIdx - 1 >= 0) {
      result.add(
        SuwayaFlowOption(
          pomodoroCount: valid[bestIdx - 1].n,
          flowSpeed: valid[bestIdx - 1].v,
          tag: 'slower',
        ),
      );
    }

    if (bestIdx + 1 < valid.length) {
      result.add(
        SuwayaFlowOption(
          pomodoroCount: valid[bestIdx + 1].n,
          flowSpeed: valid[bestIdx + 1].v,
          tag: 'faster',
        ),
      );
    }

    return result;
  }

  void startSuwayaSession(SuwayaSessionConfig config) {
    _timer?.cancel();
    _prePrayerWarningTriggered = false;
    _lastSuwayaPhase = PomodoroPhase.work;
    _lastSuwayaCycle = 1;

    final ratio = config.workVirtualMinutes /
        (config.workVirtualMinutes + config.breakVirtualMinutes);

    state = state.copyWith(
      currentView: PomodoroView.suwayaActive,
      status: PomodoroStatus.running,
      phase: PomodoroPhase.work,
      suwayaConfig: config,
      focusRatio: ratio,
      isFinished: false,
      isPrePrayerWarningActive: false,
    );

    _onSuwayaTick(isInitialTick: true);
    _syncLiveCurtainNotification();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _onSuwayaTick(isInitialTick: false),
    );
  }

  void _onSuwayaTick({bool isInitialTick = false}) {
    final config = state.suwayaConfig;
    if (config == null ||
        state.currentView != PomodoroView.suwayaActive ||
        state.isFinished) {
      return;
    }

    final nowUtc = DateTime.now().toUtc();
    final nowWall = _currentCityTime();

    // الإنهاء الإجباري عند بلوغ لحظة النهاية العالمية أو المحلية
    if (!nowUtc.isBefore(config.endUtc) || !nowWall.isBefore(config.endTime)) {
      _endSuwayaForcefully();
      return;
    }

    // فحص تنبيه ما قبل الصلاة بدقيقتين فعليتين (120 ثانية عالمية)
    final realSecondsToEnd = config.endUtc.difference(nowUtc).inSeconds;
    final bool isNearPrayer = realSecondsToEnd <= 120 && realSecondsToEnd > 0;
    if (isNearPrayer && !_prePrayerWarningTriggered) {
      _prePrayerWarningTriggered = true;
      try {
        HapticFeedback.mediumImpact();
        Vibration.vibrate(pattern: [0, 150, 100, 150]);
      } catch (_) {}
    }

    final int actualElapsedSecs = max(
      0,
      nowUtc.difference(config.anchoredStartUtc).inSeconds,
    );
    final double totalVirtualElapsed = actualElapsedSecs * config.flowSpeed;

    const double cycleTotalVirtualSecs = 1800.0; // 30 دقيقة افتراضية (25 + 5)
    final double sessionMaxVirtualSecs =
        config.totalPomodoros * cycleTotalVirtualSecs;

    if (totalVirtualElapsed >= sessionMaxVirtualSecs) {
      _endSuwayaForcefully();
      return;
    }

    final int currentPomoIndex =
        (totalVirtualElapsed ~/ cycleTotalVirtualSecs).clamp(
      0,
      config.totalPomodoros - 1,
    );
    final int currentCycleNumber = currentPomoIndex + 1;
    final double elapsedInCurrentPomo =
        totalVirtualElapsed % cycleTotalVirtualSecs;

    final double focusVirtualSecs = config.workVirtualMinutes * 60.0;
    final double breakVirtualSecs = config.breakVirtualMinutes * 60.0;

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

    final double cycProgress =
        (elapsedInCurrentPomo / cycleTotalVirtualSecs).clamp(0.0, 1.0);
    final double ratio = focusVirtualSecs / cycleTotalVirtualSecs;

    final bool phaseChanged = !isInitialTick &&
        (currentPhase != _lastSuwayaPhase ||
            currentCycleNumber != _lastSuwayaCycle);

    if (phaseChanged) {
      if (_lastSuwayaPhase == PomodoroPhase.work &&
          currentPhase == PomodoroPhase.shortBreak) {
        _incrementDailyCompletedSessions();
      }
      _triggerPhaseTransitionFeedback(
        newPhase: currentPhase,
        cycleNumber: currentCycleNumber,
        totalCycles: config.totalPomodoros,
      );
    }

    _lastSuwayaPhase = currentPhase;
    _lastSuwayaCycle = currentCycleNumber;

    state = state.copyWith(
      phase: currentPhase,
      currentCycle: currentCycleNumber,
      remainingSeconds: remainingVirtual,
      phaseProgress: progress,
      cycleProgress: cycProgress,
      focusRatio: ratio,
      isPrePrayerWarningActive: isNearPrayer,
    );

    if (phaseChanged) {
      _syncLiveCurtainNotification();
    }
  }

  void _endSuwayaForcefully() {
    _timer?.cancel();
    setFullScreen(false);
    NotificationService().cancelLivePomodoroNotification();
    _incrementDailyCompletedSessions();
    try {
      HapticFeedback.heavyImpact();
      Vibration.vibrate(pattern: [0, 300, 150, 300]);
    } catch (_) {}
    state = state.copyWith(
      status: PomodoroStatus.finished,
      remainingSeconds: 0,
      phaseProgress: 1.0,
      cycleProgress: 1.0,
      isFinished: true,
      isPrePrayerWarningActive: false,
    );
  }

  void acknowledgeFinish() {
    backToSelector();
  }
}

final pomodoroProvider = NotifierProvider<PomodoroEngine, PomodoroState>(
  PomodoroEngine.new,
);