import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart'; // 🌟 إضافة استيراد الترجمة

import '../settings/settings_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    
    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final settings = ref.read(settingsProvider);
    if (settings.isFirstLaunch) {
      context.go('/onboarding');
    } else {
      context.go('/home'); 
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.compass, size: 80, color: primaryColor), 
                    const SizedBox(height: 24),
                    // 🌟 استبدال النصوص الثابتة بمفاتيح الترجمة
                    Text('splash.app_title_ar'.tr(), style: TextStyle(color: primaryColor, fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('splash.app_title_en'.tr(), style: TextStyle(color: primaryColor.withValues(alpha: 0.5), fontSize: 16, letterSpacing: 4.0)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}