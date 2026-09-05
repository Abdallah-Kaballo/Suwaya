import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/home_screen.dart';
import '../tasks/tasks_screen.dart';
import '../ibadat/ibadat_screen.dart';
import '../pomodoro/pomodoro_screen.dart';
import '../settings/settings_screen.dart';

// 🌟 مزود حالة عام للتحكم في الشريط السفلي من أي مكان في التطبيق
final mainNavIndexProvider = StateProvider<int>((ref) => 2);

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  final List<Widget> _screens = const [
    TasksScreen(),      
    IbadatScreen(),     
    HomeScreen(),       
    PomodoroScreen(),   
    SettingsScreen(),   
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // الاستماع لمؤشر الشاشة الحالي
    final currentIndex = ref.watch(mainNavIndexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = isDark ? Colors.black : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true, 
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildFloatingNavBar(ref, currentIndex, isDark, primaryColor),
    );
  }

  Widget _buildFloatingNavBar(WidgetRef ref, int currentIndex, bool isDark, Color primaryColor) {
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
                _buildNavItem(ref, LucideIcons.calendar_clock, 0, currentIndex, isDark, primaryColor),
                _buildNavItem(ref, LucideIcons.book_open, 1, currentIndex, isDark, primaryColor),
                _buildCenterItem(ref, currentIndex, primaryColor), 
                _buildNavItem(ref, LucideIcons.timer, 3, currentIndex, isDark, primaryColor),
                _buildNavItem(ref, LucideIcons.settings, 4, currentIndex, isDark, primaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(WidgetRef ref, IconData icon, int index, int currentIndex, bool isDark, Color primaryColor) {
    final isSelected = currentIndex == index;
    final scale = isSelected ? 1.15 : 1.0; 
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(mainNavIndexProvider.notifier).state = index;
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          transformAlignment: Alignment.center, 
          transform: Matrix4.diagonal3Values(scale, scale, 1.0), 
          child: Icon(icon, size: 24, color: isSelected ? primaryColor : (isDark ? Colors.white54 : Colors.black45)),
        ),
      ),
    );
  }

  Widget _buildCenterItem(WidgetRef ref, int currentIndex, Color primaryColor) {
    final isSelected = currentIndex == 2;
    final scale = isSelected ? 1.05 : 1.0; 

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        ref.read(mainNavIndexProvider.notifier).state = 2;
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
    );
  }
}