import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../core/providers/ui_providers.dart';
import '../../shared/widgets/app_drawer.dart';
import '../settings/settings_provider.dart';
import 'pomodoro_provider.dart';
import 'widgets/pomodoro_shared_widgets.dart';
import 'widgets/pomodoro_views.dart';

class PomodoroScreen extends ConsumerWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pomodoroState = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = pomodoroState.isFullScreen
        ? const Color(0xFF07090E)
        : Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;

    final isSubView = pomodoroState.currentView != PomodoroView.selector;
    final isTimerView =
        pomodoroState.currentView == PomodoroView.traditional ||
        pomodoroState.currentView == PomodoroView.suwayaActive;

    // 🌟 حماية الجلسة النشطة من الإلغاء غير المقصود عند ضغط زر الرجوع للخروج من التطبيق
    return PopScope(
      canPop:
          !pomodoroState.isFullScreen &&
          (!isSubView || pomodoroState.hasActiveSession),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (pomodoroState.isFullScreen) {
          notifier.setFullScreen(false);
        } else if (isSubView && !pomodoroState.hasActiveSession) {
          notifier.backToSelector();
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        drawerEnableOpenDragGesture: !isSubView && !pomodoroState.isFullScreen,
        drawerEdgeDragWidth: MediaQuery.of(context).size.width,
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
                          Directionality.of(context) == TextDirection.rtl
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
                  if (isTimerView) ...[
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Mute / Unmute',
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
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Zen Mode',
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
                  ],
                  if (pomodoroState.currentView == PomodoroView.traditional)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        LucideIcons.settings_2,
                        color: primaryColor,
                        size: 20,
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        showTraditionalSettingsSheet(context, ref);
                      },
                    ),
                  // إظهار مفتاح الوقت السويعي في شاشة الإعداد فقط لمنع الزحمة أثناء التركيز
                  if (pomodoroState.currentView == PomodoroView.suwayaSetup)
                    Consumer(
                      builder: (context, ref, _) {
                        final settings = ref.watch(settingsProvider);
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              trPomodoro(
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
                                activeThumbColor: isDark
                                    ? Colors.black
                                    : Colors.white,
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
                  const SizedBox(width: 6),
                ],
              ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: switch (pomodoroState.currentView) {
              PomodoroView.selector => const ModeSelectorView(
                key: ValueKey('selector'),
              ),
              PomodoroView.traditional => const TraditionalTimerView(
                key: ValueKey('traditional'),
              ),
              PomodoroView.suwayaSetup => const SuwayaSetupView(
                key: ValueKey('suwaya_setup'),
              ),
              PomodoroView.suwayaActive => const SuwayaActiveTimerView(
                key: ValueKey('suwaya_active'),
              ),
            },
          ),
        ),
      ),
    );
  }
}
