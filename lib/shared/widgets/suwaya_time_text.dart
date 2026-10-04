import 'package:flutter/material.dart';

import '../../core/utils/time_formatters.dart';

class ClockTimeText extends StatelessWidget {
  final DateTime? civilTime;
  final int? globalSuwayaIndex;
  final int? virtualMinute;
  final String civilTimeFormat;
  final String locale;
  final TextStyle style;
  final Color? separatorColor;
  final double separatorHeightFactor;
  final double separatorWidth;

  const ClockTimeText.civil({
    super.key,
    required DateTime this.civilTime,
    required this.civilTimeFormat,
    required this.locale,
    required this.style,
  })  : globalSuwayaIndex = null,
        virtualMinute = null,
        separatorColor = null,
        separatorHeightFactor = 0.48,
        separatorWidth = 1.5;

  const ClockTimeText.suwaya({
    super.key,
    required int this.globalSuwayaIndex,
    required int this.virtualMinute,
    required this.style,
    this.separatorColor,
    this.separatorHeightFactor = 0.48,
    this.separatorWidth = 1.5,
  })  : civilTime = null,
        civilTimeFormat = civilTimeFormatSystem,
        locale = 'en';

  @override
  Widget build(BuildContext context) {
    if (civilTime != null) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          formatCivilTime(
            civilTime!,
            format: civilTimeFormat,
            locale: locale,
            context: context,
          ),
          style: style,
        ),
      );
    }

    return SuwayaTimeText(
      globalSuwayaIndex: globalSuwayaIndex!,
      minute: virtualMinute!,
      style: style,
      separatorColor: separatorColor,
      separatorHeightFactor: separatorHeightFactor,
      separatorWidth: separatorWidth,
    );
  }
}

class SuwayaTimeText extends StatelessWidget {
  final int globalSuwayaIndex;
  final int minute;
  final TextStyle style;
  final Color? separatorColor;
  final double separatorHeightFactor;
  final double separatorWidth;

  const SuwayaTimeText({
    super.key,
    required this.globalSuwayaIndex,
    required this.minute,
    required this.style,
    this.separatorColor,
    this.separatorHeightFactor = 0.48,
    this.separatorWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize =
        style.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
    final separator = Container(
      width: separatorWidth,
      height: fontSize * separatorHeightFactor,
      margin: EdgeInsets.symmetric(horizontal: fontSize * 0.08),
      decoration: BoxDecoration(
        color: separatorColor ?? Colors.white,
        borderRadius: BorderRadius.circular(separatorWidth / 2),
      ),
    );
    final formattedTime = formatSuwayaTime(globalSuwayaIndex, minute);
    final separatorIndex = formattedTime.indexOf(':');

    return Semantics(
      label: formatSuwayaTime(globalSuwayaIndex, minute, separator: '|'),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: RichText(
          text: TextSpan(
            style: style,
            children: [
              TextSpan(text: formattedTime.substring(0, separatorIndex)),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: separator,
              ),
              TextSpan(text: formattedTime.substring(separatorIndex + 1)),
            ],
          ),
        ),
      ),
    );
  }
}
