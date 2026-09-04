import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌟

import '../home/home_screen.dart';
import '../tasks/tasks_screen.dart';
import '../ibadat/ibadat_screen.dart';
import '../pomodoro/pomodoro_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    TasksScreen(), 
    IbadatScreen(),     
    PomodoroScreen(),   
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final bgColor = isDark ? Colors.black : const Color(0xFFF5F7FA);
    final navColor = isDark ? const Color(0xFF0D0D12) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.black12, width: 0.5)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          backgroundColor: navColor,
          indicatorColor: primaryColor.withValues(alpha: 0.2),
          destinations: [
            // 🌟 استخدام القاموس للترجمة الفورية
            NavigationDestination(
              icon: const Icon(LucideIcons.compass), 
              selectedIcon: const Icon(LucideIcons.compass, color: Color(0xFFD4AF37)),
              label: 'nav.home'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.calendar_clock), 
              selectedIcon: const Icon(LucideIcons.calendar_clock, color: Color(0xFFD4AF37)),
              label: 'nav.tasks'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.book_open), 
              selectedIcon: const Icon(LucideIcons.book_open, color: Color(0xFFD4AF37)),
              label: 'nav.ibadat'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.timer), 
              selectedIcon: const Icon(LucideIcons.timer, color: Color(0xFFD4AF37)),
              label: 'nav.pomodoro'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}