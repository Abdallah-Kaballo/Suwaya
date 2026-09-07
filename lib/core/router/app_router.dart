import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/layout/main_layout.dart';
import '../../features/home/home_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/ibadat/ibadat_screen.dart';
import '../../features/pomodoro/pomodoro_screen.dart';
import '../../features/analytics/analytics_screen.dart';
import '../../features/tasks/universal_add_screen.dart';

// مسارات Onboarding
import '../../features/onboarding/onboarding_language_screen.dart';
import '../../features/onboarding/onboarding_location_screen.dart';

// مسارات الإعدادات
import '../../features/settings/settings_screen.dart';
import '../../features/settings/notifications_settings_screen.dart';
import '../../features/settings/astro_calculations_screen.dart';
import '../../features/settings/permissions_screen.dart';

// 🌟 مفتاح التوجيه الجذري (Full Screen)
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// 🌟 مفتاح توجيه الحاوية (Bottom Nav Bar)

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      
      // 🌟 قسم Onboarding بالكامل خارج الشريط
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingLanguageScreen(),
      ),
      GoRoute(
        path: '/onboarding-location',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingLocationScreen(),
      ),

      // 🌟 قسم الإعدادات وشاشاتها الفرعية خارج الشريط
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/settings/notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsSettingsScreen(),
      ),
      GoRoute(
        path: '/settings/astro',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AstroCalculationsScreen(),
      ),
      GoRoute(
        path: '/settings/permissions',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PermissionsScreen(),
      ),

      // 🌟 شاشة الإضافة خارج الشريط
      GoRoute(
        path: '/add-task',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return UniversalAddScreen(
            currentPeriodId: extra['currentPeriodId'] ?? 1,
            currentSuwaya: extra['currentSuwaya'] ?? 1,
          );
        },
      ),

      // 🌟 الحاوية المغلقة: مخصصة حصرياً للشاشات الخمسة
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/tasks', builder: (context, state) => const TasksScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/ibadat', builder: (context, state) => const IbadatScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/pomodoro', builder: (context, state) => const PomodoroScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/analytics', builder: (context, state) => const AnalyticsScreen())]),
        ],
      ),
    ],
  );
});