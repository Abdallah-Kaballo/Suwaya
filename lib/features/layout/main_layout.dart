import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:suwaya/core/providers/ui_providers.dart';

class MainLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    final isDrawerOpen = ref.watch(isDrawerOpenProvider);
    final isPomodoroFullScreen = ref.watch(isPomodoroFullScreenProvider);
    final hideBottomBar = isDrawerOpen || isPomodoroFullScreen;

    ref.watch(isPomodoroFullScreenProvider);
    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      body: RepaintBoundary(child: navigationShell),
      bottomNavigationBar: RepaintBoundary(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          offset: hideBottomBar ? const Offset(0, 1.5) : Offset.zero,
          child: _buildFloatingNavBar(
            context,
            navigationShell.currentIndex,
            isDark,
            primaryColor,
            navigationShell,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar(
    BuildContext context,
    int currentIndex,
    bool isDark,
    Color primaryColor,
    StatefulNavigationShell shell,
  ) {
    final calLabel = 'nav.calendar'.tr() != 'nav.calendar'
        ? 'nav.calendar'.tr()
        : (context.locale.languageCode == 'ar' ? 'التقويم' : 'Calendar');

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 18),
        height: 72,
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: isDark ? 0.88 : 0.92),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(
                  LucideIcons.list_todo,
                  0,
                  currentIndex,
                  isDark,
                  primaryColor,
                  'nav.tasks'.tr(),
                  shell,
                ),
                _buildNavItem(
                  LucideIcons.moon_star,
                  1,
                  currentIndex,
                  isDark,
                  primaryColor,
                  'nav.ibadat'.tr(),
                  shell,
                ),
                // 🌟 الشاشة الرئيسية (القرص الفلكي) في المنتصف تماماً (الموقع 2)
                _buildNavItem(
                  LucideIcons.compass,
                  2,
                  currentIndex,
                  isDark,
                  primaryColor,
                  'nav.home'.tr(),
                  shell,
                ),
                // 🌟 تبويب التقويم والرزنامة الجديد (الموقع 3)
                _buildNavItem(
                  LucideIcons.calendar_days,
                  3,
                  currentIndex,
                  isDark,
                  primaryColor,
                  calLabel,
                  shell,
                ),
                _buildNavItem(
                  LucideIcons.timer,
                  4,
                  currentIndex,
                  isDark,
                  primaryColor,
                  'nav.pomodoro'.tr(),
                  shell,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    int index,
    int currentIndex,
    bool isDark,
    Color primaryColor,
    String label,
    StatefulNavigationShell shell,
  ) {
    final isSelected = currentIndex == index;
    final scale = isSelected ? 1.05 : 1.0;

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: () {
            if (index == currentIndex) return;
            HapticFeedback.selectionClick();
            // 🌟 تأخير بسيط جداً للسماح للأنيميشن بالعمل قبل تجميد الشاشة في بناء الواجهة الثقيلة
            Future.delayed(const Duration(milliseconds: 50), () {
              shell.goBranch(index, initialLocation: index == currentIndex);
            });
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            transformAlignment: Alignment.center,
            transform: Matrix4.diagonal3Values(scale, scale, 1.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 23,
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.white54 : Colors.black45),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? primaryColor
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}