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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (astroState.periods.isEmpty) return const SizedBox.shrink();

    final speedMultiplier = astroState.timeSpeedMultiplier;
    final pColor = astroState.currentPeriod.uiColor.adapt(context);
    final strokeColor = isDark ? Colors.black : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: pColor.withValues(alpha: 0.15), 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: pColor.withValues(alpha: 0.5), width: 1.0)
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(speedMultiplier >= 1.0 ? LucideIcons.zap : LucideIcons.hourglass, color: pColor, size: 10),
          const SizedBox(width: 4),
          Stack(
            children: [
              Text(
                '${speedMultiplier.toStringAsFixed(1)}x', 
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal, fontFamily: 'Playfair Display', foreground: Paint()..style=PaintingStyle.stroke..strokeWidth=2..color=strokeColor)
              ),
              Text(
                '${speedMultiplier.toStringAsFixed(1)}x', 
                style: TextStyle(color: pColor, fontSize: 11, fontWeight: FontWeight.normal, fontFamily: 'Playfair Display')
              ),
            ],
          ),
        ],
      ),
    );
  }
}