import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'core/bootstrap/app_bootstrap.dart';
import 'core/database/database_provider.dart';
import 'core/database/database_service.dart';
import 'core/localization/app_locales.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_color_provider.dart';
import 'core/astro_engine/astro_provider.dart';
import 'features/settings/settings_provider.dart';
import 'core/router/app_router.dart';

void main() async {
  await AppBootstrap.initialize(); 
  runApp(const LoadingBootstrapScreen());
}

class LoadingBootstrapScreen extends StatefulWidget {
  const LoadingBootstrapScreen({super.key});
  @override
  State<LoadingBootstrapScreen> createState() => _LoadingBootstrapScreenState();
}

class _LoadingBootstrapScreenState extends State<LoadingBootstrapScreen> {
  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    try {
      final isar = await DatabaseService.init(); 
      if (!mounted) return;
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
      if (!mounted) return;
      runApp(BootstrapFailureScreen(error: e.toString(), onRetry: _loadDatabase));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF13131A), 
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      ),
    );
  }
}

class BootstrapFailureScreen extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const BootstrapFailureScreen({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // استخدمنا TextDirection ثابت لضمان ظهور شاشة الخطأ بشكل سليم قبل تهيئة EasyLocalization
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF13131A),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 64),
                  const SizedBox(height: 24),
                  const Text('عذراً، حدث خطأ أثناء بدء التشغيل', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(12)),
                    child: Text(error, textAlign: TextAlign.left, style: const TextStyle(color: Colors.redAccent, fontSize: 12), maxLines: 5, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      onPressed: () {
                        runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: Scaffold(backgroundColor: Color(0xFF13131A), body: Center(child: CircularProgressIndicator(color: Colors.amber)))));
                        onRetry();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
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