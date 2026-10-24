import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:suwaya_time/suwaya_time.dart';
import '../../core/utils/time_formatters.dart';
import '../../features/settings/settings_provider.dart';

class ClockTimeText extends ConsumerWidget {
  final CivilWallClock? civilClock;
  final int? globalSuwayaIndex;
  final int? virtualMinute;
  final String civilTimeFormat;
  final String locale;
  final TextStyle style;

  /// باني صريح يعتمد على CivilWallClock (Zero-Ambiguity Time Type)
  const ClockTimeText.civilClock({
    super.key,
    required CivilWallClock this.civilClock,
    required this.civilTimeFormat,
    required this.locale,
    required this.style,
  })  : globalSuwayaIndex = null,
        virtualMinute = null;

  /// باني متوافق يقبل DateTime أو يحوله داخلياً إلى CivilWallClock
  ClockTimeText.civil({
    super.key,
    required DateTime civilTime,
    required this.civilTimeFormat,
    required this.locale,
    required this.style,
  })  : civilClock = CivilWallClock.fromDateTime(civilTime),
        globalSuwayaIndex = null,
        virtualMinute = null;

  const ClockTimeText.suwaya({
    super.key,
    required this.globalSuwayaIndex,
    required this.virtualMinute,
    required this.style,
  })  : civilClock = null,
        civilTimeFormat = civilTimeFormatSystem,
        locale = 'en';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (civilClock != null) {
      final defaultCivilColor =
          isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
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
    final suwayaGoldColor =
        isDark ? const Color(0xFFF2C94C) : const Color(0xFF8A5A00);

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

    final iconWidget = Text(
      parts.icon,
      style: style.copyWith(fontFamily: 'Tajawal'),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: isRTL
          ? [iconWidget, const SizedBox(width: 4), numbersWidget]
          : [numbersWidget, const SizedBox(width: 4), iconWidget],
    );
  }
}