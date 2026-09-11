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
    final bgColor = isDark ? Colors.black : const Color(0xFFF5F7FA);

    final isDrawerOpen = ref.watch(isDrawerOpenProvider);

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true, 
      body: navigationShell,
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        offset: isDrawerOpen ? const Offset(0, 1.5) : Offset.zero,
        child: _buildFloatingNavBar(navigationShell.currentIndex, isDark, primaryColor),
      ),
    );
  }

  Widget _buildFloatingNavBar(int currentIndex, bool isDark, Color primaryColor) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        height: 72,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2530).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildNavItem(LucideIcons.list_todo, 0, currentIndex, isDark, primaryColor, 'tasks.title'.tr()),
                _buildNavItem(LucideIcons.moon_star, 1, currentIndex, isDark, primaryColor, 'ibadat.title'.tr()),
                _buildCenterItem(currentIndex, primaryColor, 'home.title'.tr()),
                _buildNavItem(LucideIcons.timer, 3, currentIndex, isDark, primaryColor, 'pomodoro.title'.tr()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index, int currentIndex, bool isDark, Color primaryColor, String label) {
    final isSelected = currentIndex == index;
    final scale = isSelected ? 1.15 : 1.0; 
    
    // 🌟 دعم الوصولية وقارئ الشاشة والتعريفات المنبثقة (Tooltips)
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            navigationShell.goBranch(index, initialLocation: index == currentIndex); 
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              transformAlignment: Alignment.center, 
              transform: Matrix4.diagonal3Values(scale, scale, 1.0), 
              child: Icon(icon, size: 26, color: isSelected ? primaryColor : (isDark ? Colors.white54 : Colors.black45)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterItem(int currentIndex, Color primaryColor, String label) {
    final isSelected = currentIndex == 2;
    final scale = isSelected ? 1.05 : 1.0; 

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            navigationShell.goBranch(2, initialLocation: 2 == currentIndex);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            transformAlignment: Alignment.center, 
            transform: Matrix4.diagonal3Values(scale, scale, 1.0), 
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(LucideIcons.compass, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}