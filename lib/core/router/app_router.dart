import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:suwaya/features/ibadat/astro_timeline_screen.dart';
import 'package:suwaya/features/settings/manual_offsets_screen.dart';

import '../../features/layout/main_layout.dart';
import '../../features/home/home_screen.dart';
import '../../features/tasks/tasks_screen.dart';
import '../../features/ibadat/ibadat_screen.dart';
import '../../features/pomodoro/pomodoro_screen.dart';
import '../../features/tasks/universal_add_screen.dart';
import '../../features/calendar/calendar_screen.dart';

// مسارات Onboarding
import '../../features/onboarding/onboarding_language_screen.dart';
import '../../features/onboarding/onboarding_location_screen.dart';

// مسارات الإعدادات
import '../../features/settings/settings_screen.dart';
import '../../features/settings/notifications_settings_screen.dart';
import '../../features/settings/astro_calculations_screen.dart';
import '../../features/settings/permissions_screen.dart';
import 'startup_gate.dart';

import '../../features/settings/faq_screen.dart';
import '../../features/settings/privacy_screen.dart';
import '../../features/settings/support_screen.dart';

// مفتاح التوجيه الجذري (Full Screen)
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/startup',
    routes: [
      GoRoute(
        path: '/startup',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const StartupGate(),
      ),
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
          GoRoute(
            path: 'manual-offsets',
            builder: (context, state) => const ManualOffsetsScreen(),
          ),
        ],
      ),
       GoRoute(
        path: '/faq',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FAQScreen(),
      ),
      GoRoute(
        path: '/privacy',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/add-task',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return UniversalAddScreen(
            currentPeriodId: extra['currentPeriodId'] ?? 1,
            currentSuwaya: extra['currentSuwaya'] ?? 1,
            initialTab: extra['initialTab'] ?? 0,
            existingTask: extra['existingTask'],
            existingRoutine: extra['existingRoutine'],
            initialDate: extra['initialDate'] as DateTime?, // 🌟 دعم التاريخ المحدد من التقويم
          );
        },
      ),
      GoRoute(
        path: '/support',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/ibadat/timeline',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AstroTimelineScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tasks',
                builder: (context, state) => TasksScreen(
                  initialTab:
                      state.uri.queryParameters['tab'] == 'periods' ? 2 : 0,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ibadat',
                builder: (context, state) => const IbadatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // 🌟 الفرع الرابع (index 3): شاشة التقويم والرزنامة المزدوجة
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          // 🌟 الفرع الخامس (index 4): شاشة البومودورو
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pomodoro',
                builder: (context, state) => const PomodoroScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});