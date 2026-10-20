import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya_time/suwaya_time.dart';
import 'dart:math' show pi, cos, sin;

import '../../core/astro_engine/astro_provider.dart';
import '../../core/notification/routine_time_resolver.dart';
import '../../core/providers/ui_providers.dart';
import '../../core/utils/time_formatters.dart';
import '../../models/settings_model.dart';
import '../../models/task_model.dart';
import '../../shared/widgets/app_drawer.dart';
import '../settings/settings_provider.dart';
import '../tasks/tasks_provider.dart';
import '../tasks/widgets/add_screen_pickers.dart';
import 'pomodoro_provider.dart';

String _tr(
  BuildContext context,
  String key,
  String arFallback,
  String enFallback,
) {
  final translated = key.tr();
  if (translated != key) return translated;
  final isAr = context.locale.languageCode == 'ar';
  return isAr ? arFallback : enFallback;
}

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoroState = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = pomodoroState.isFullScreen
        ? Colors.black
        : Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;

    final isSubView = pomodoroState.currentView != PomodoroView.selector;
    final isTimerView =
        pomodoroState.currentView == PomodoroView.traditional ||
            pomodoroState.currentView == PomodoroView.suwayaActive;

    return PopScope(
      canPop: !pomodoroState.isFullScreen && !isSubView,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (pomodoroState.isFullScreen) {
          notifier.setFullScreen(false);
        } else if (isSubView) {
          notifier.backToSelector();
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        drawerEnableOpenDragGesture:
            !isSubView && !pomodoroState.isFullScreen,
        drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.15,
        drawer: const AppDrawer(),
        onDrawerChanged: (isOpen) =>
            ref.read(isDrawerOpenProvider.notifier).state = isOpen,
        appBar: pomodoroState.isFullScreen
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                titleSpacing: 4,
                leading: isSubView
                    ? IconButton(
                        icon: Icon(
                          context.locale.languageCode == 'ar'
                              ? LucideIcons.arrow_right
                              : LucideIcons.arrow_left,
                          color: textColor,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          notifier.backToSelector();
                        },
                      )
                    : Builder(
                        builder: (ctx) => IconButton(
                          icon: Icon(LucideIcons.menu, color: textColor),
                          onPressed: () => Scaffold.of(ctx).openDrawer(),
                        ),
                      ),
                title: Text(
                  'nav.pomodoro'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                actions: [
                  // 🌟 زر كتم/تفعيل صوت جرس الجلسات
                  if (isTimerView)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: pomodoroState.isMuted
                          ? _tr(
                              context,
                              'pomodoro.unmute',
                              'تفعيل الصوت',
                              'Unmute',
                            )
                          : _tr(
                              context,
                              'pomodoro.mute',
                              'كتم الصوت',
                              'Mute',
                            ),
                      icon: Icon(
                        pomodoroState.isMuted
                            ? LucideIcons.volume_x
                            : LucideIcons.volume_2,
                        color: pomodoroState.isMuted
                            ? Colors.grey
                            : primaryColor,
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        notifier.toggleMute();
                      },
                    ),

                  // 🌟 زر وضع ملء الشاشة الغامر
                  if (isTimerView)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: _tr(
                        context,
                        'pomodoro.fullscreen',
                        'ملء الشاشة',
                        'Full Screen',
                      ),
                      icon: Icon(
                        LucideIcons.maximize_2,
                        color: primaryColor,
                        size: 19,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        notifier.toggleFullScreen();
                      },
                    ),

                  // 🌟 زر إعدادات البومودورو التقليدي
                  if (pomodoroState.currentView == PomodoroView.traditional)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: _tr(
                        context,
                        'settings.title',
                        'الإعدادات',
                        'Settings',
                      ),
                      icon: Icon(
                        LucideIcons.settings_2,
                        color: primaryColor,
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        _showTraditionalSettingsSheet(context, ref);
                      },
                    ),

                  // 🌟 مفتاح الوقت السُويعي الموحد
                  Consumer(
                    builder: (context, ref, _) {
                      final settings = ref.watch(settingsProvider);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _tr(
                              context,
                              'common.suwaya_time',
                              'الوقت السُويعي',
                              'Suwaya Time',
                            ),
                            style: TextStyle(
                              color: settings.useAstroTimeForIbadat
                                  ? primaryColor
                                  : (isDark
                                      ? Colors.white70
                                      : Colors.black54),
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.70,
                            child: Switch(
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              value: settings.useAstroTimeForIbadat,
                              activeThumbColor:
                                  isDark ? Colors.black : Colors.white,
                              activeTrackColor: primaryColor,
                              onChanged: (val) {
                                HapticFeedback.lightImpact();
                                ref
                                    .read(settingsProvider.notifier)
                                    .updateUseAstroTimeForIbadat(val);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _buildCurrentView(pomodoroState.currentView),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView(PomodoroView view) {
    switch (view) {
      case PomodoroView.selector:
        return const _ModeSelectorView(key: ValueKey('selector'));
      case PomodoroView.traditional:
        return const _TraditionalTimerView(key: ValueKey('traditional'));
      case PomodoroView.suwayaSetup:
        return const _SuwayaSetupView(key: ValueKey('suwaya_setup'));
      case PomodoroView.suwayaActive:
        return const _SuwayaActiveTimerView(key: ValueKey('suwaya_active'));
    }
  }
}

// ============================================================================
// شريط ربط المهمة ("أركز الآن على...") مع الإنجاز السريع
// ============================================================================
class _LinkedTaskBar extends ConsumerWidget {
  final Color accentColor;
  final bool isCompact;

  const _LinkedTaskBar({
    required this.accentColor,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedTaskId = ref.watch(
      pomodoroProvider.select((s) => s.linkedTaskId),
    );
    final tasksState = ref.watch(tasksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    TaskModel? linkedTask;
    if (linkedTaskId != null) {
      for (final t in tasksState.allTasks) {
        if (t.id == linkedTaskId) {
          linkedTask = t;
          break;
        }
      }
    }

    return GestureDetector(
      onTap: () => _showTaskPickerSheet(context, ref),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: isCompact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: linkedTask != null
                ? accentColor.withValues(alpha: 0.45)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.target,
              size: 16,
              color: linkedTask != null
                  ? accentColor
                  : textColor.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                linkedTask != null
                    ? linkedTask.title
                    : _tr(
                        context,
                        'pomodoro.select_focus_task',
                        'اختر مهمة للتركيز عليها (اختياري)',
                        'Select a task to focus on (optional)',
                      ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: linkedTask != null
                      ? textColor
                      : textColor.withValues(alpha: 0.55),
                  fontSize: 13,
                  fontWeight: linkedTask != null
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
              ),
            ),
            if (linkedTask != null) ...[
              const SizedBox(width: 10),
              // 🌟 زر إنجاز المهمة السريع مباشرة من شاشة البومودورو
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.heavyImpact();
                  ref
                      .read(tasksProvider.notifier)
                      .toggleTaskStatus(linkedTask!);
                  ref
                      .read(pomodoroProvider.notifier)
                      .selectLinkedTask(null);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _tr(
                          context,
                          'pomodoro.task_completed_msg',
                          'تم إنجاز المهمة بنجاح! 🎯',
                          'Task completed! 🎯',
                        ),
                      ),
                      backgroundColor: Colors.green.shade700,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.check,
                        size: 13,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'common.done'.tr(),
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(width: 6),
              Icon(
                LucideIcons.chevron_down,
                size: 15,
                color: textColor.withValues(alpha: 0.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTaskPickerSheet(BuildContext context, WidgetRef ref) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;

    final todayTasks = ref.read(tasksProvider).todayTasks;
    final currentLinkedId = ref.read(pomodoroProvider).linkedTaskId;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                _tr(
                  context,
                  'pomodoro.select_focus_task',
                  'اختر مهمة للتركيز عليها',
                  'Select a Task to Focus On',
                ),
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (todayTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'tasks.empty_tasks'.tr(),
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: todayTasks.length,
                    itemBuilder: (context, index) {
                      final task = todayTasks[index];
                      final isSelected = task.id == currentLinkedId;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? LucideIcons.circle_check
                              : LucideIcons.circle,
                          color: isSelected ? primaryColor : Colors.grey,
                        ),
                        title: Text(
                          task.title,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          task.category.displayName,
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref
                              .read(pomodoroProvider.notifier)
                              .selectLinkedTask(task.id);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              if (currentLinkedId != null) ...[
                const Divider(),
                TextButton.icon(
                  onPressed: () {
                    ref
                        .read(pomodoroProvider.notifier)
                        .selectLinkedTask(null);
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(LucideIcons.x, color: Colors.redAccent),
                  label: Text(
                    _tr(
                      context,
                      'pomodoro.unlink_task',
                      'إلغاء ربط المهمة',
                      'Unlink Task',
                    ),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 1. شاشة الاختيار الرئيسية (بومودورو سُويعي / بومودورو تقليدي)
// ============================================================================
class _ModeSelectorView extends ConsumerWidget {
  const _ModeSelectorView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final dailyCount = ref.watch(
      pomodoroProvider.select((s) => s.dailyCompletedSessions),
    );

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🌟 شارة عداد الإنجاز اليومي للبومودورو
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.flame, color: primaryColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  context.locale.languageCode == 'ar'
                      ? 'إنجاز اليوم: $dailyCount جلسات تركيز'
                      : 'Completed Today: $dailyCount focus sessions',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'pomodoro.choose_mode'.tr(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _LinkedTaskBar(accentColor: primaryColor),
          const SizedBox(height: 24),
          _buildModeCard(
            context: context,
            title: 'pomodoro.suwaya_mode'.tr(),
            subtitle: 'pomodoro.suwaya_mode_desc'.tr(),
            icon: LucideIcons.moon_star,
            color: const Color(0xFFE53935),
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(pomodoroProvider.notifier).openSuwayaSetup();
            },
          ),
          const SizedBox(height: 16),
          _buildModeCard(
            context: context,
            title: 'pomodoro.traditional'.tr(),
            subtitle: 'pomodoro.traditional_desc'.tr(),
            icon: LucideIcons.clock,
            color: const Color(0xFF64B5F6),
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(pomodoroProvider.notifier).openTraditionalMode();
            },
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1D24) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 2. شاشة البومودورو التقليدي (تدعم الأسطرلاب ووضع ملء الشاشة والوضع الأفقي)
// ============================================================================
class _TraditionalTimerView extends ConsumerWidget {
  const _TraditionalTimerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final isDark =
        state.isFullScreen || Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    final int remInt = state.remainingSeconds.ceil();
    final String m = (remInt ~/ 60).toString().padLeft(2, '0');
    final String s = (remInt % 60).toString().padLeft(2, '0');

    final Color activeColor = switch (state.phase) {
      PomodoroPhase.work => const Color(0xFFE53935),
      PomodoroPhase.shortBreak => const Color(0xFF64B5F6),
      PomodoroPhase.longBreak => const Color(0xFF00E676),
    };

    final String phaseLabel = switch (state.phase) {
      PomodoroPhase.work => 'pomodoro.in_flow'.tr(),
      PomodoroPhase.shortBreak => 'pomodoro.deep_relaxation'.tr(),
      PomodoroPhase.longBreak => _tr(
          context,
          'pomodoro.long_break',
          'راحة طويلة',
          'Long Break',
        ),
    };

    final totalCycles = state.traditionalSettings.cyclesBeforeLongBreak;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget buildControls() {
      if (state.status == PomodoroStatus.idle) {
        return SizedBox(
          width: 220,
          height: 54,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 4,
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              notifier.startTraditional();
            },
            icon: const Icon(LucideIcons.play, size: 20),
            label: Text(
              _tr(context, 'pomodoro.start', 'بدء', 'Start'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              padding: const EdgeInsets.all(15),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              notifier.resetTraditional();
            },
            icon: Icon(LucideIcons.rotate_ccw, color: textColor, size: 21),
            tooltip: _tr(
              context,
              'pomodoro.reset',
              'إيقاف وإعادة',
              'Stop & Reset',
            ),
          ),
          const SizedBox(width: 18),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 26),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                if (state.status == PomodoroStatus.running) {
                  notifier.pauseTraditional();
                } else {
                  notifier.resumeTraditional();
                }
              },
              icon: Icon(
                state.status == PomodoroStatus.running
                    ? LucideIcons.pause
                    : LucideIcons.play,
                size: 21,
              ),
              label: Text(
                state.status == PomodoroStatus.running
                    ? _tr(context, 'pomodoro.pause', 'إيقاف مؤقت', 'Pause')
                    : _tr(context, 'pomodoro.resume', 'استئناف', 'Resume'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              padding: const EdgeInsets.all(15),
            ),
            onPressed: notifier.skipTraditionalPhase,
            icon: Icon(
              LucideIcons.skip_forward,
              color: textColor,
              size: 21,
            ),
            tooltip: _tr(context, 'pomodoro.skip', 'تخطي', 'Skip'),
          ),
        ],
      );
    }

    Widget buildCycleDots() {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalCycles, (index) {
          final cycleNum = index + 1;
          final isCompleted = cycleNum < state.currentCycle ||
              (cycleNum == state.currentCycle &&
                  state.phase == PomodoroPhase.longBreak);
          final isCurrent = cycleNum == state.currentCycle &&
              state.phase != PomodoroPhase.longBreak;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: isCurrent ? 22 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: (isCompleted || isCurrent)
                  ? activeColor
                  : textColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
          );
        }),
      );
    }

    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: _buildLargeZenTimerDial(
                  context: context,
                  progress: state.phaseProgress,
                  minutesStr: m,
                  secondsStr: s,
                  phaseLabel: phaseLabel,
                  isBreak: state.isBreak,
                  activeColor: activeColor,
                  isDark: isDark,
                  forcedSize: 250,
                  onDoubleTap: () {
                    HapticFeedback.lightImpact();
                    notifier.toggleFullScreen();
                  },
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LinkedTaskBar(accentColor: activeColor, isCompact: true),
                  const SizedBox(height: 16),
                  buildCycleDots(),
                  const SizedBox(height: 24),
                  buildControls(),
                  if (state.isFullScreen) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => notifier.setFullScreen(false),
                      icon: const Icon(
                        LucideIcons.minimize_2,
                        color: Colors.white54,
                        size: 16,
                      ),
                      label: Text(
                        _tr(
                          context,
                          'pomodoro.exit_fullscreen',
                          'خروج من ملء الشاشة',
                          'Exit Full Screen',
                        ),
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        state.isFullScreen ? 16 : 8,
        20,
        state.isFullScreen ? 24 : 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'pomodoro.traditional'.tr(),
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${state.traditionalSettings.workMinutes}/${state.traditionalSettings.shortBreakMinutes} · ${state.currentCycle}/$totalCycles',
                      style: TextStyle(
                        color: activeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  if (state.isFullScreen) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.minimize_2,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => notifier.setFullScreen(false),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LinkedTaskBar(accentColor: activeColor, isCompact: true),
          SizedBox(height: state.isFullScreen ? 28 : 18),
          _buildLargeZenTimerDial(
            context: context,
            progress: state.phaseProgress,
            minutesStr: m,
            secondsStr: s,
            phaseLabel: phaseLabel,
            isBreak: state.isBreak,
            activeColor: activeColor,
            isDark: isDark,
            onDoubleTap: () {
              HapticFeedback.lightImpact();
              notifier.toggleFullScreen();
            },
          ),
          const SizedBox(height: 20),
          buildCycleDots(),
          const SizedBox(height: 28),
          buildControls(),
        ],
      ),
    );
  }
}

void _showTraditionalSettingsSheet(BuildContext context, WidgetRef ref) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surfaceColor = Theme.of(context).cardColor;
  final textColor = isDark ? Colors.white : Colors.black87;
  final primaryColor = Theme.of(context).primaryColor;

  const workOptions = [25, 30, 35, 40, 45, 50, 55, 60];
  const shortBreakOptions = [5, 10];
  const longBreakOptions = [20, 25, 30, 35, 40];
  const cyclesOptions = [1, 2, 3, 4, 5, 6];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Consumer(
        builder: (context, ref, _) {
          final currentSettings =
              ref.watch(pomodoroProvider).traditionalSettings;
          final notifier = ref.read(pomodoroProvider.notifier);

          Widget buildChipSelector({
            required String title,
            required List<int> options,
            required int selectedValue,
            required String unit,
            required ValueChanged<int> onSelect,
          }) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((val) {
                      final isSelected = val == selectedValue;
                      return ChoiceChip(
                        label: Text(unit.isEmpty ? '$val' : '$val $unit'),
                        selected: isSelected,
                        selectedColor: primaryColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? primaryColor : textColor,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          onSelect(val);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }

          final minUnit = 'details.minute'.tr();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _tr(
                          context,
                          'pomodoro.traditional_settings',
                          'إعدادات البومودورو التقليدي',
                          'Traditional Pomodoro Settings',
                        ),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    buildChipSelector(
                      title: _tr(
                        context,
                        'pomodoro.work_duration',
                        'طول البومودورو (العمل الصافي)',
                        'Pomodoro Duration (Work)',
                      ),
                      options: workOptions,
                      selectedValue: currentSettings.workMinutes,
                      unit: minUnit,
                      onSelect: (val) => notifier.updateTraditionalSettings(
                        currentSettings.copyWith(workMinutes: val),
                      ),
                    ),
                    buildChipSelector(
                      title: _tr(
                        context,
                        'pomodoro.short_break_duration',
                        'طول الراحة القصيرة',
                        'Short Break Duration',
                      ),
                      options: shortBreakOptions,
                      selectedValue: currentSettings.shortBreakMinutes,
                      unit: minUnit,
                      onSelect: (val) => notifier.updateTraditionalSettings(
                        currentSettings.copyWith(shortBreakMinutes: val),
                      ),
                    ),
                    buildChipSelector(
                      title: _tr(
                        context,
                        'pomodoro.long_break_duration',
                        'طول الراحة الطويلة',
                        'Long Break Duration',
                      ),
                      options: longBreakOptions,
                      selectedValue: currentSettings.longBreakMinutes,
                      unit: minUnit,
                      onSelect: (val) => notifier.updateTraditionalSettings(
                        currentSettings.copyWith(longBreakMinutes: val),
                      ),
                    ),
                    buildChipSelector(
                      title: _tr(
                        context,
                        'pomodoro.cycles_before_long_break',
                        'الراحة الطويلة بعد كل (عدد البومودورو)',
                        'Long Break After Every',
                      ),
                      options: cyclesOptions,
                      selectedValue: currentSettings.cyclesBeforeLongBreak,
                      unit: '',
                      onSelect: (val) => notifier.updateTraditionalSettings(
                        currentSettings.copyWith(cyclesBeforeLongBreak: val),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'common.done'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ============================================================================
// 3. شاشة إعداد البومودورو السُويعي (_SuwayaSetupView)
// ============================================================================
class _SuwayaSetupView extends ConsumerStatefulWidget {
  const _SuwayaSetupView({super.key});

  @override
  ConsumerState<_SuwayaSetupView> createState() => _SuwayaSetupViewState();
}

class _SuwayaSetupViewState extends ConsumerState<_SuwayaSetupView> {
  late final DateTime _anchoredStartTime;
  bool? _localStartUseAstroOverride;

  bool _useDefaultNextPrayer = true;
  DateTime? _customEndTime;
  String _nextPrayerName = '';
  DateTime? _nextPrayerTime;

  int _selectedOptionIndex = 0;

  @override
  void initState() {
    super.initState();
    final cityNow = virtualDateTimeNotifier.value;
    _anchoredStartTime = DateTime.utc(
      cityNow.year,
      cityNow.month,
      cityNow.day,
      cityNow.hour,
      cityNow.minute,
    );
  }

  ({int globalIndex, int minute}) _dateTimeToAstroParts(
    DateTime time,
    AstroState astroState,
  ) {
    if (astroState.periods.isEmpty) return (globalIndex: 0, minute: 0);

    final anchors = astroState.cycleAnchors;
    final cycleDuration =
        anchors.cycleEndMaghrib.difference(anchors.cycleStartMaghrib);

    if (time.isAtSameMomentAs(anchors.cycleEndMaghrib)) {
      return (globalIndex: 0, minute: 0);
    }

    DateTime evalTime = time;
    if (evalTime.isAfter(anchors.cycleEndMaghrib) &&
        cycleDuration.inMinutes > 0) {
      evalTime = evalTime.subtract(cycleDuration);
    }

    final mockState = SuwayaTimeEngine.calculateCurrentState(
      SuwayaDay(
        ibadatTimings: astroState.ibadatTimings,
        cycleAnchors: astroState.cycleAnchors,
        periods: astroState.periods,
      ),
      evalTime,
    );
    final int global = mockState.currentSuwayaTime.phase == SuwayaPhase.day
        ? 12 + mockState.currentSuwayaTime.phaseSlotNumber - 1
        : mockState.currentSuwayaTime.phaseSlotNumber - 1;
    return (
      globalIndex: global.clamp(0, 23),
      minute: mockState.currentSuwayaTime.virtualMinute.clamp(0, 59),
    );
  }

  DateTime _astroPartsToDateTime(
    int globalIndex,
    int virtualMinute,
    AstroState astroState,
  ) {
    int remaining = globalIndex.clamp(0, 23);
    AstroPeriod targetPeriod = astroState.periods.last;
    int localSuwaya = targetPeriod.suwayasCount;

    for (final p in astroState.periods) {
      if (remaining < p.suwayasCount) {
        targetPeriod = p;
        localSuwaya = remaining + 1;
        break;
      }
      remaining -= p.suwayasCount;
    }

    DateTime resolved = resolveAstroRoutineTime(
      period: targetPeriod,
      localSuwaya: localSuwaya,
      virtualMinute: virtualMinute.clamp(0, 59),
    );

    if (!resolved.isAfter(_anchoredStartTime)) {
      final cycleDuration = astroState.cycleAnchors.cycleEndMaghrib
          .difference(astroState.cycleAnchors.cycleStartMaghrib);
      resolved = resolved.add(
        cycleDuration.inMinutes > 0 ? cycleDuration : const Duration(days: 1),
      );
    }
    return resolved;
  }

  void _resolveNextPrayer(AstroState astro) {
    final now = virtualDateTimeNotifier.value;
    final referenceTime =
        now.isAfter(_anchoredStartTime) ? now : _anchoredStartTime;

    final anchors = astro.cycleAnchors;

    final orderedCyclePrayers = <({String name, DateTime time})>[
      (name: 'prayers.isha'.tr(), time: anchors.cycleIsha),
      (name: 'periods.fajr'.tr(), time: anchors.cycleFajr),
      (name: 'periods.dhuhr'.tr(), time: anchors.cycleDhuhr),
      (name: 'periods.asr'.tr(), time: anchors.cycleAsr),
      (name: 'periods.maghrib'.tr(), time: anchors.cycleEndMaghrib),
    ];

    for (final p in orderedCyclePrayers) {
      if (p.time.isAfter(referenceTime)) {
        _nextPrayerName = p.name;
        _nextPrayerTime = p.time;
        return;
      }
    }

    final cycleDuration =
        anchors.cycleEndMaghrib.difference(anchors.cycleStartMaghrib);
    _nextPrayerName = 'prayers.isha'.tr();
    _nextPrayerTime = anchors.cycleIsha.add(
      cycleDuration.inMinutes > 0 ? cycleDuration : const Duration(days: 1),
    );
  }

  String _formatDisplayedTime({
    required BuildContext context,
    required DateTime time,
    required AstroState astroState,
    required SettingsModel settings,
    required bool useAstro,
  }) {
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    if (!useAstro) {
      return formatCivilTime(
        time,
        format: settings.civilTimeFormat,
        locale: context.locale.languageCode,
        context: context,
      );
    }
    final parts = _dateTimeToAstroParts(time, astroState);
    return formatSuwayaTime(
      parts.globalIndex,
      parts.minute,
      separator: '|',
      isRTL: isRTL,
      iconMode: settings.suwayaIconMode,
    );
  }

  ({bool isValid, String? errorMessage}) _validateEndTime({
    required DateTime candidateEnd,
    required AstroState astroState,
    required bool isAstroMode,
  }) {
    if (!candidateEnd.isAfter(_anchoredStartTime)) {
      return (
        isValid: false,
        errorMessage: _tr(
          context,
          'pomodoro.end_must_be_after_start',
          'يجب أن يكون وقت النهاية بعد وقت البداية',
          'End time must be after start time',
        ),
      );
    }

    if (isAstroMode) {
      final startParts = _dateTimeToAstroParts(_anchoredStartTime, astroState);
      final endParts = _dateTimeToAstroParts(candidateEnd, astroState);
      final startVirtualMins = startParts.globalIndex * 60 + startParts.minute;
      final endVirtualMins = endParts.globalIndex * 60 + endParts.minute;
      int diffVirtualMins = endVirtualMins - startVirtualMins;
      if (diffVirtualMins <= 0) diffVirtualMins += 1440;

      final actualMins = candidateEnd.difference(_anchoredStartTime).inMinutes;
      if (diffVirtualMins < 15 || actualMins < 15) {
        return (
          isValid: false,
          errorMessage: 'pomodoro.time_too_short'.tr(),
        );
      }
      if (diffVirtualMins > 720 || actualMins > 720) {
        return (
          isValid: false,
          errorMessage: _tr(
            context,
            'pomodoro.max_12_hours',
            'لا يمكن أن تزيد المدة عن 12 سويعة / ساعة',
            'Duration cannot exceed 12 Suwayas / hours',
          ),
        );
      }
    } else {
      final diffActualMins =
          candidateEnd.difference(_anchoredStartTime).inMinutes;
      if (diffActualMins < 15) {
        return (
          isValid: false,
          errorMessage: 'pomodoro.time_too_short'.tr(),
        );
      }
      if (diffActualMins > 720) {
        return (
          isValid: false,
          errorMessage: _tr(
            context,
            'pomodoro.max_12_hours',
            'لا يمكن أن تزيد المدة عن 12 ساعة',
            'Duration cannot exceed 12 hours',
          ),
        );
      }
    }

    return (isValid: true, errorMessage: null);
  }

  bool _isCivil12HourActive(BuildContext context, String civilTimeFormat) {
    if (civilTimeFormat == civilTimeFormat12Hour) return true;
    if (civilTimeFormat == civilTimeFormat24Hour) return false;
    return !(MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false);
  }

  Future<void> _showEndTimePickerDialog({
    required BuildContext context,
    required AstroState astroState,
    required SettingsModel settings,
    required DateTime currentEffectiveEnd,
  }) async {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).cardColor;
    final text = isDark ? Colors.white : Colors.black87;
    final pColor = Theme.of(context).primaryColor;
    final use12Hour = _isCivil12HourActive(context, settings.civilTimeFormat);

    int pickerTimeMode = settings.useAstroTimeForIbadat ? 0 : 1;

    final initialAstro =
        _dateTimeToAstroParts(currentEffectiveEnd, astroState);
    int tempGlobalSuwaya = initialAstro.globalIndex;
    int tempVirtualMinute = initialAstro.minute;

    int tempCivilHour = currentEffectiveEnd.hour;
    int tempCivilMinute = currentEffectiveEnd.minute;

    String? dialogError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isNight = tempGlobalSuwaya < 12;
          final uiHour = isNight ? tempGlobalSuwaya + 1 : tempGlobalSuwaya - 11;

          return Dialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'add_screen.select_end_time'.tr(),
                    style: TextStyle(
                      color: text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<int>(
                    segments: [
                      ButtonSegment(
                        value: 0,
                        label: Text('ibadat.astro_time'.tr()),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('add_screen.civil'.tr()),
                      ),
                    ],
                    selected: {pickerTimeMode},
                    onSelectionChanged: (set) {
                      HapticFeedback.selectionClick();
                      setDialogState(() {
                        pickerTimeMode = set.first;
                        dialogError = null;
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? pColor.withValues(alpha: 0.2)
                            : Colors.transparent,
                      ),
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? pColor
                            : text.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (pickerTimeMode == 0)
                    AstroTimePicker(
                      initialHour: uiHour,
                      initialMinute: tempVirtualMinute,
                      initialIsNight: isNight,
                      textColor: text,
                      surfaceColor: surface,
                      accentColor: pColor,
                      iconMode: settings.suwayaIconMode,
                      onChanged: (h, m, night) {
                        tempGlobalSuwaya = night ? (h - 1) : (h + 11);
                        tempVirtualMinute = m;
                        if (dialogError != null) {
                          setDialogState(() => dialogError = null);
                        }
                      },
                    )
                  else
                    DoubleWheelPicker(
                      label1: 'add_screen.civil_hour'.tr(),
                      label2: 'add_screen.minute'.tr(),
                      initialVal1: tempCivilHour,
                      initialVal2: tempCivilMinute,
                      min1: 0,
                      max1: 23,
                      max2: 59,
                      is12HourMode: use12Hour,
                      textColor: text,
                      surfaceColor: surface,
                      onChanged: (h, m) {
                        tempCivilHour = h;
                        tempCivilMinute = m;
                        if (dialogError != null) {
                          setDialogState(() => dialogError = null);
                        }
                      },
                    ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      dialogError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'common.cancel'.tr(),
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: pColor,
                          ),
                          onPressed: () {
                            DateTime candidate;
                            if (pickerTimeMode == 0) {
                              candidate = _astroPartsToDateTime(
                                tempGlobalSuwaya,
                                tempVirtualMinute,
                                astroState,
                              );
                            } else {
                              candidate = DateTime.utc(
                                _anchoredStartTime.year,
                                _anchoredStartTime.month,
                                _anchoredStartTime.day,
                                tempCivilHour,
                                tempCivilMinute,
                              );
                              if (!candidate.isAfter(_anchoredStartTime)) {
                                candidate =
                                    candidate.add(const Duration(days: 1));
                              }
                            }

                            final validation = _validateEndTime(
                              candidateEnd: candidate,
                              astroState: astroState,
                              isAstroMode: pickerTimeMode == 0,
                            );

                            if (!validation.isValid) {
                              HapticFeedback.heavyImpact();
                              setDialogState(
                                () => dialogError = validation.errorMessage,
                              );
                              return;
                            }

                            setState(() {
                              _useDefaultNextPrayer = false;
                              _customEndTime = candidate;
                              _selectedOptionIndex = 0;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            'common.confirm'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final astroState = ref.watch(astroProvider);
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;
    final cardBg = isDark ? const Color(0xFF1A1D24) : Colors.white;

    if (astroState.periods.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    _resolveNextPrayer(astroState);

    final DateTime effectiveEndTime = _useDefaultNextPrayer
        ? _nextPrayerTime!
        : (_customEndTime ?? _nextPrayerTime!);

    final bool startDisplayAstro =
        _localStartUseAstroOverride ?? settings.useAstroTimeForIbadat;
    final bool endDisplayAstro = settings.useAstroTimeForIbadat;

    final String startFormatted = _formatDisplayedTime(
      context: context,
      time: _anchoredStartTime,
      astroState: astroState,
      settings: settings,
      useAstro: startDisplayAstro,
    );

    final String startParallelFormatted = _formatDisplayedTime(
      context: context,
      time: _anchoredStartTime,
      astroState: astroState,
      settings: settings,
      useAstro: !startDisplayAstro,
    );

    final String endFormatted = _formatDisplayedTime(
      context: context,
      time: effectiveEndTime,
      astroState: astroState,
      settings: settings,
      useAstro: endDisplayAstro,
    );

    final validation = _validateEndTime(
      candidateEnd: effectiveEndTime,
      astroState: astroState,
      isAstroMode: settings.useAstroTimeForIbadat,
    );

    final List<SuwayaFlowOption> flowOptions = validation.isValid
        ? PomodoroEngine.calculateSuwayaFlowOptions(
            _anchoredStartTime,
            effectiveEndTime,
          )
        : [];

    if (_selectedOptionIndex >= flowOptions.length) {
      _selectedOptionIndex = 0;
    }

    final int actualMinutes =
        effectiveEndTime.difference(_anchoredStartTime).inMinutes;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LinkedTaskBar(accentColor: primaryColor, isCompact: true),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.play, size: 15, color: primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          'details.start'.tr(),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'pomodoro.starts_now'.tr(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _localStartUseAstroOverride = !startDisplayAstro;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: Text(
                            startFormatted,
                            style: TextStyle(
                              color: startDisplayAstro
                                  ? const Color(0xFFF2C94C)
                                  : textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Directionality(
                          textDirection: ui.TextDirection.ltr,
                          child: Text(
                            '⇄ $startParallelFormatted',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.5),
                              fontSize: 11,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.moon_star,
                          size: 16,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'details.end'.tr(),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.65),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ChoiceChip(
                          label: Text(
                            _tr(
                              context,
                              'ibadat.next_prayer',
                              'الصلاة القادمة',
                              'Next Prayer',
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: _useDefaultNextPrayer,
                          selectedColor: primaryColor.withValues(alpha: 0.2),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _useDefaultNextPrayer = true;
                              _selectedOptionIndex = 0;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(
                            _tr(
                              context,
                              'pomodoro.custom_time',
                              'وقت مخصص',
                              'Custom Time',
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                          selected: !_useDefaultNextPrayer,
                          selectedColor: primaryColor.withValues(alpha: 0.2),
                          onSelected: (_) {
                            _showEndTimePickerDialog(
                              context: context,
                              astroState: astroState,
                              settings: settings,
                              currentEffectiveEnd: effectiveEndTime,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showEndTimePickerDialog(
                    context: context,
                    astroState: astroState,
                    settings: settings,
                    currentEffectiveEnd: effectiveEndTime,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _useDefaultNextPrayer
                                  ? 'pomodoro.ends_at'.tr(
                                      args: [_nextPrayerName],
                                    )
                                  : _tr(
                                      context,
                                      'add_screen.end_time',
                                      'وقت النهاية المحدد',
                                      'Selected End Time',
                                    ),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$actualMinutes ${'pomodoro.actual_minutes_avail'.tr()}',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.55),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Directionality(
                              textDirection: ui.TextDirection.ltr,
                              child: Text(
                                endFormatted,
                                style: TextStyle(
                                  color: endDisplayAstro
                                      ? const Color(0xFFF2C94C)
                                      : textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              LucideIcons.pencil,
                              size: 16,
                              color: primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (!validation.isValid || flowOptions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    LucideIcons.clock,
                    color: Colors.redAccent,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    validation.errorMessage ?? 'pomodoro.time_too_short'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'pomodoro.flow_speed'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '25/5 (30 ${'details.minute'.tr()})',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(flowOptions.length, (index) {
              final opt = flowOptions[index];
              final isSelected = _selectedOptionIndex == index;

              String subtitleText;
              if (opt.tag == 'recommended') {
                subtitleText = _tr(
                  context,
                  'pomodoro.recommended_closest',
                  'الافتراضي (الأقرب لسرعة 1.00x)',
                  'Default (Closest to 1.00x speed)',
                );
              } else if (opt.tag == 'slower') {
                subtitleText = _tr(
                  context,
                  'pomodoro.slower_option',
                  'سرعة أقل (إيقاع أهدأ)',
                  'Lower speed (Calmer pace)',
                );
              } else {
                subtitleText = _tr(
                  context,
                  'pomodoro.faster_option',
                  'سرعة أعلى (إنجاز مكثف)',
                  'Higher speed (Intensive focus)',
                );
              }

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedOptionIndex = index);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.12)
                        : cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : textColor.withValues(alpha: 0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? LucideIcons.circle_check
                            : LucideIcons.circle,
                        color: isSelected
                            ? primaryColor
                            : textColor.withValues(alpha: 0.4),
                        size: 22,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${opt.pomodoroCount} ${'nav.pomodoro'.tr()} · ${opt.flowSpeed.toStringAsFixed(2)}x',
                              style: TextStyle(
                                color: isSelected ? primaryColor : textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitleText,
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.55),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  final selectedOpt = flowOptions[_selectedOptionIndex];
                  final endLabel = _useDefaultNextPrayer
                      ? _nextPrayerName
                      : endFormatted;

                  ref.read(pomodoroProvider.notifier).startSuwayaSession(
                        SuwayaSessionConfig(
                          anchoredStartTime: _anchoredStartTime,
                          endTime: effectiveEndTime,
                          endLabel: endLabel,
                          totalPomodoros: selectedOpt.pomodoroCount,
                          flowSpeed: selectedOpt.flowSpeed,
                        ),
                      );
                },
                icon: const Icon(LucideIcons.check, size: 20),
                label: Text(
                  'pomodoro.start_session'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// 4. شاشة المؤقت السُويعي النشط (_SuwayaActiveTimerView)
// ============================================================================
// ============================================================================
// 4. شاشة المؤقت السُويعي النشط (_SuwayaActiveTimerView)
// ============================================================================
class _SuwayaActiveTimerView extends ConsumerWidget {
  const _SuwayaActiveTimerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final config = state.suwayaConfig;

    if (config == null) return const SizedBox.shrink();

    if (state.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text(
              'pomodoro.time_up_prayer'.tr(),
              textAlign: TextAlign.center,
            ),
            content: Text(
              'pomodoro.time_up_desc'.tr(),
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    notifier.acknowledgeFinish();
                  },
                  child: Text(
                    'common.done'.tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      });
    }

    final isDark =
        state.isFullScreen || Theme.of(context).brightness == Brightness.dark;
    final int remInt = state.remainingSeconds.ceil();
    final String m = (remInt ~/ 60).toString().padLeft(2, '0');
    final String s = (remInt % 60).toString().padLeft(2, '0');

    final Color activeColor =
        state.isBreak ? const Color(0xFF64B5F6) : const Color(0xFFE53935);
    final String phaseLabel = state.isBreak
        ? 'pomodoro.deep_relaxation'.tr()
        : 'pomodoro.in_flow'.tr();
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    Widget buildPrePrayerWarningBanner() {
      if (!state.isPrePrayerWarningActive) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.bell_ring, color: Colors.amber, size: 16),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                context.locale.languageCode == 'ar'
                    ? 'اقترب الميقات (${config.endLabel}) — اختم فكرتك بهدوء'
                    : 'Approaching ${config.endLabel} — wrap up your current thought',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildEndSessionButton() {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          notifier.backToSelector();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black12,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.x,
                color: isDark ? Colors.white70 : Colors.black87,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'pomodoro.end_session'.tr(),
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: _buildLargeZenTimerDial(
                  context: context,
                  progress: state.phaseProgress,
                  minutesStr: m,
                  secondsStr: s,
                  phaseLabel: phaseLabel,
                  isBreak: state.isBreak,
                  activeColor: activeColor,
                  isDark: isDark,
                  forcedSize: 250,
                  onDoubleTap: () {
                    HapticFeedback.lightImpact();
                    notifier.toggleFullScreen();
                  },
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildPrePrayerWarningBanner(),
                  _LinkedTaskBar(accentColor: activeColor, isCompact: true),
                  const SizedBox(height: 20),
                  buildEndSessionButton(),
                  if (state.isFullScreen) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => notifier.setFullScreen(false),
                      icon: const Icon(
                        LucideIcons.minimize_2,
                        color: Colors.white54,
                        size: 16,
                      ),
                      label: Text(
                        _tr(
                          context,
                          'pomodoro.exit_fullscreen',
                          'خروج من ملء الشاشة',
                          'Exit Full Screen',
                        ),
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        state.isFullScreen ? 16 : 8,
        20,
        state.isFullScreen ? 24 : 100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'pomodoro.suwaya_mode'.tr()} (${state.currentCycle}/${config.totalPomodoros})',
                style: TextStyle(
                  color: activeColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: activeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${config.flowSpeed.toStringAsFixed(2)}x',
                      style: TextStyle(
                        color: activeColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  if (state.isFullScreen) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.minimize_2,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => notifier.setFullScreen(false),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          buildPrePrayerWarningBanner(),
          _LinkedTaskBar(accentColor: activeColor, isCompact: true),
          SizedBox(height: state.isFullScreen ? 28 : 18),
          _buildLargeZenTimerDial(
            context: context,
            progress: state.phaseProgress,
            minutesStr: m,
            secondsStr: s,
            phaseLabel: phaseLabel,
            isBreak: state.isBreak,
            activeColor: activeColor,
            isDark: isDark,
            onDoubleTap: () {
              HapticFeedback.lightImpact();
              notifier.toggleFullScreen();
            },
          ),
          const SizedBox(height: 28),
          buildEndSessionButton(),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. الدائرة المكبّرة الموحدة ورسام الحلقة (_ZenTimerPainter)
// ============================================================================
Widget _buildLargeZenTimerDial({
  required BuildContext context,
  required double progress,
  required String minutesStr,
  required String secondsStr,
  required String phaseLabel,
  required bool isBreak,
  required Color activeColor,
  required bool isDark,
  required VoidCallback onDoubleTap,
  double? forcedSize,
}) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final double availableWidth = constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.of(context).size.width - 40;
      final double dialSize =
          forcedSize ?? (availableWidth * 0.92).clamp(280.0, 420.0);
      final double timeFontSize = (dialSize * 0.29).clamp(80.0, 118.0);

      return GestureDetector(
        onDoubleTap: onDoubleTap,
        child: SizedBox(
          width: dialSize,
          height: dialSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: dialSize,
                height: dialSize,
                child: CustomPaint(
                  painter: _ZenTimerPainter(
                    progress: progress,
                    activeColor: activeColor,
                    isDark: isDark,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: dialSize * 0.08),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Directionality(
                        textDirection: ui.TextDirection.ltr,
                        child: Text(
                          '$minutesStr:$secondsStr',
                          style: TextStyle(
                            fontSize: timeFontSize,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF2C94C),
                            fontFamily: 'Inter',
                            letterSpacing: 2.0,
                            fontFeatures: const [
                              ui.FontFeature.tabularFigures(),
                            ],
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.65),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isBreak
                                ? LucideIcons.coffee
                                : LucideIcons.sparkles,
                            color: activeColor,
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            phaseLabel,
                            style: TextStyle(
                              color: activeColor,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ZenTimerPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final bool isDark;

  _ZenTimerPainter({
    required this.progress,
    required this.activeColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 10;

    final trackPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    canvas.drawCircle(center, radius, trackPaint);

    final safeProgress = progress.clamp(0.0, 1.0);

    if (safeProgress > 0) {
      final glowPaint = Paint()
        ..color = activeColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        safeProgress * 2 * pi,
        false,
        glowPaint,
      );
    }

    final progressPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      safeProgress * 2 * pi,
      false,
      progressPaint,
    );

    final knobAngle = -pi / 2 + (safeProgress * 2 * pi);
    final knobCenter = Offset(
      center.dx + cos(knobAngle) * radius,
      center.dy + sin(knobAngle) * radius,
    );
    canvas.drawCircle(knobCenter, 10, Paint()..color = activeColor);
    canvas.drawCircle(
      knobCenter,
      4.5,
      Paint()..color = isDark ? const Color(0xFF121316) : Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _ZenTimerPainter old) =>
      old.progress != progress ||
      old.activeColor != activeColor ||
      old.isDark != isDark;
}