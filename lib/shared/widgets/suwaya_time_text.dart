import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suwaya_time/suwaya_time.dart';
import '../../core/utils/time_formatters.dart';
import '../../features/settings/settings_provider.dart';

/// شارة دائرية مضغوطة عالية الدقة لصورتي الشمس والقمر بدلاً من الإيموجي النصي
class SuwayaPhaseBadge extends StatelessWidget {
  final bool isNight;
  final double size;
  final String iconMode;
  final bool isRTL;
  final TextStyle? textStyle;

  const SuwayaPhaseBadge({
    super.key,
    required this.isNight,
    this.size = 18.0,
    this.iconMode = 'emoji',
    this.isRTL = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (iconMode == 'text') {
      final label = isNight ? (isRTL ? 'ل' : 'N') : (isRTL ? 'ن' : 'D');
      return Text(
        label,
        style: (textStyle ?? const TextStyle()).copyWith(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final targetCacheSize = (size * dpr).round().clamp(24, 96);
    final assetPath = isNight
        ? 'assets/icons/moon.png'
        : 'assets/icons/sun.png';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isNight
              ? const Color(0xFF90CAF9).withValues(alpha: 0.45)
              : const Color(0xFFFFD54F).withValues(alpha: 0.65),
          width: 0.8,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          cacheWidth: targetCacheSize,
          cacheHeight: targetCacheSize,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

class ClockTimeText extends ConsumerWidget {
  final CivilWallClock? civilClock;
  final int? globalSuwayaIndex;
  final int? virtualMinute;
  final String civilTimeFormat;
  final String locale;
  final TextStyle style;

  const ClockTimeText.civilClock({
    super.key,
    required CivilWallClock this.civilClock,
    required this.civilTimeFormat,
    required this.locale,
    required this.style,
  }) : globalSuwayaIndex = null,
       virtualMinute = null;

  ClockTimeText.civil({
    super.key,
    required DateTime civilTime,
    required this.civilTimeFormat,
    required this.locale,
    required this.style,
  }) : civilClock = CivilWallClock.fromDateTime(civilTime),
       globalSuwayaIndex = null,
       virtualMinute = null;

  const ClockTimeText.suwaya({
    super.key,
    required this.globalSuwayaIndex,
    required this.virtualMinute,
    required this.style,
  }) : civilClock = null,
       civilTimeFormat = civilTimeFormatSystem,
       locale = 'en';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (civilClock != null) {
      final defaultCivilColor = isDark
          ? const Color(0xFFF3F4F6)
          : const Color(0xFF111827);
      return Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Text(
          formatCivilClock(
            civilClock!,
            format: civilTimeFormat,
            locale: locale,
            context: context,
          ),
          style: style.copyWith(color: style.color ?? defaultCivilColor),
        ),
      );
    }

    final settings = ref.watch(settingsProvider);
    final suwayaGoldColor = isDark
        ? const Color(0xFFF2C94C)
        : const Color(0xFF8A5A00);

    return SuwayaTimeText(
      globalSuwayaIndex: globalSuwayaIndex!,
      minute: virtualMinute!,
      style: style.copyWith(color: suwayaGoldColor),
      iconMode: settings.suwayaIconMode,
      isRTL: isRTL,
    );
  }
}

class SuwayaTimeText extends StatelessWidget {
  final int globalSuwayaIndex;
  final int minute;
  final TextStyle style;
  final String iconMode;
  final bool isRTL;

  const SuwayaTimeText({
    super.key,
    required this.globalSuwayaIndex,
    required this.minute,
    required this.style,
    required this.iconMode,
    required this.isRTL,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parts = getSuwayaTimeParts(
      globalSuwayaIndex,
      minute,
      isRTL,
      iconMode,
    );
    final isNight = globalSuwayaIndex.clamp(0, 23) < 12;
    final fontSize =
        style.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14;

    final separatorColor = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : const Color(0xFF111827).withValues(alpha: 0.65);

    final separator = Container(
      width: 1.5,
      height: fontSize * 0.58,
      margin: EdgeInsets.symmetric(horizontal: fontSize * 0.15),
      decoration: BoxDecoration(
        color: separatorColor,
        borderRadius: BorderRadius.circular(1.0),
      ),
    );

    final numbersWidget = Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(parts.suwayaStr, style: style),
          separator,
          Text(parts.minStr, style: style),
        ],
      ),
    );

    final badgeSize = (fontSize * 1.15).clamp(14.0, 24.0);
    final iconWidget = SuwayaPhaseBadge(
      isNight: isNight,
      size: badgeSize,
      iconMode: iconMode,
      isRTL: isRTL,
      textStyle: style,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: isRTL
          ? [iconWidget, const SizedBox(width: 5), numbersWidget]
          : [numbersWidget, const SizedBox(width: 5), iconWidget],
    );
  }
}
