import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../core/astro_engine/astro_provider.dart';
import '../../../../core/theme/astro_ui_extensions.dart';

class TimeSpeedIndicator extends ConsumerWidget {
  const TimeSpeedIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final astroState = ref.watch(astroProvider);
    if (astroState.periods.isEmpty) return const SizedBox.shrink();

    final speedMultiplier = astroState.timeSpeedMultiplier;
    final pColor = astroState.currentPeriod.uiColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: pColor.withValues(alpha: 0.65), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            speedMultiplier >= 1.0 ? LucideIcons.zap : LucideIcons.hourglass,
            color: pColor,
            size: 10,
          ),
          const SizedBox(width: 4),
          Text(
            '${speedMultiplier.toStringAsFixed(2)}x',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
