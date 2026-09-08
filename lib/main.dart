import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'core/bootstrap/app_bootstrap.dart';
import 'core/database/database_provider.dart';
import 'core/localization/app_locales.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_color_provider.dart';
import 'core/astro_engine/astro_provider.dart';
import 'features/settings/settings_provider.dart';
import 'core/router/app_router.dart';

void main() async {
  try {
    final isar = await AppBootstrap.initialize(); // 🌟 هذا هو السطر الذي يحل الخطأ

    runApp(
      ProviderScope(
        overrides: [
          isarProvider.overrideWithValue(isar),
        ],
        child: EasyLocalization(
          supportedLocales: AppLocales.supported,
          path: AppLocales.path,
          fallbackLocale: AppLocales.fallback,
          useOnlyLangCode: true,
          child: const SuwayaApp(),
        ),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('💥 فشل في التهيئة: $e\n$stackTrace');
    runApp(const BootstrapFailureScreen());
  }
}

class BootstrapFailureScreen extends StatelessWidget {
  const BootstrapFailureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'حدث خطأ أثناء التشغيل. يرجى إعادة المحاولة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16),
          ),
        ),
      ),
    );
  }
}

class SuwayaApp extends ConsumerWidget {
  const SuwayaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final activeColorTheme = ref.watch(themeColorProvider);
    final goRouter = ref.watch(routerProvider); 

    final bool isDayTime = ref.watch(astroProvider.select((state) {
      if (state.periods.isEmpty) {
        final hour = DateTime.now().hour;
        return hour >= 6 && hour < 18;
      }
      final pId = state.currentPeriod.id;
      return pId >= 1 && pId <= 4;
    }));

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Suwaya',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      themeMode: AppTheme.getThemeMode(settings.themeMode, isDayTime: isDayTime),
      theme: AppTheme.getLightTheme(activeColorTheme),
      darkTheme: AppTheme.getDarkTheme(activeColorTheme),
      routerConfig: goRouter,
    );
  }
}