import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/settings_provider.dart';

String startupDestination(bool isFirstLaunch) =>
    isFirstLaunch ? '/onboarding' : '/home';

class StartupGate extends ConsumerStatefulWidget {
  const StartupGate({super.key});

  @override
  ConsumerState<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<StartupGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _routeAfterLoad());
  }

  Future<void> _routeAfterLoad() async {
    try {
      await ref.read(settingsProvider.notifier).initialized;
      if (!mounted) return;
      context.go(startupDestination(ref.read(settingsProvider).isFirstLaunch));
    } catch (_) {
      if (!mounted) return;
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
