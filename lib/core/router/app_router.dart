import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:suwaya/features/ibadat/astro_timeline_screen.dart';
import 'package:suwaya/features/settings/manual_offsets_screen.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/layout/main_layout.dart';
import '../../features/home/home_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/ibadat/ibadat_screen.dart';
import '../../features/pomodoro/pomodoro_screen.dart';
import '../../features/tasks/universal_add_screen.dart';

// مسارات Onboarding
import '../../features/onboarding/onboarding_language_screen.dart';
import '../../features/onboarding/onboarding_location_screen.dart';

// مسارات الإعدادات
import '../../features/settings/settings_screen.dart';
import '../../features/settings/notifications_settings_screen.dart';
import '../../features/settings/astro_calculations_screen.dart';
import '../../features/settings/permissions_screen.dart';


// مفتاح التوجيه الجذري (Full Screen)
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

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
      
      // قسم Onboarding بالكامل خارج الشريط
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

      // قسم الإعدادات وشاشاتها الفرعية خارج الشريط
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'notifications',
            builder: (context, state) => const NotificationsSettingsScreen(),
          ),
          GoRoute(
            path: 'astro',
            builder: (context, state) => const AstroCalculationsScreen(),
          ),
          GoRoute(
            path: 'permissions',
            builder: (context, state) => const PermissionsScreen(),
          ),
          // 🌟 إضافة المسارات الجديدة هنا
          GoRoute(
            path: 'manual-offsets',
            builder: (context, state) => const ManualOffsetsScreen(),
          ),
        ],
      ),

      // شاشة الإضافة خارج الشريط
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
      
      // 🌟 مسار التايم لاين
      GoRoute(
        path: '/ibadat/timeline',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AstroTimelineScreen(),
      ),

      // الحاوية المغلقة: أصبحت تحتوي على 4 شاشات أساسية فقط
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/tasks', builder: (context, state) => const TasksScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/ibadat', builder: (context, state) => const IbadatScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/pomodoro', builder: (context, state) => const PomodoroScreen())]),
        ],
      ),
    ],
  );
});