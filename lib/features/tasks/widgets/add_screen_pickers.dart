import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya_time/suwaya_time.dart';
import '../../../shared/widgets/suwaya_time_text.dart';

// 🌟 1. العجلة السويعية (سويعات 1-12، دقائق 0-59، وزر ليل/نهار)
class AstroTimePicker extends StatefulWidget {
  final int initialHour; // 1-12
  final int initialMinute; // 0-59
  final bool initialIsNight;
  final Function(int hour, int minute, bool isNight) onChanged;
  final Color textColor;
  final Color surfaceColor;
  final Color accentColor;
  final String iconMode;

  const AstroTimePicker({
    super.key,
    required this.initialHour,
    required this.initialMinute,
    required this.initialIsNight,
    required this.onChanged,
    required this.textColor,
    required this.surfaceColor,
    required this.accentColor,
    this.iconMode = 'emoji',
  });

  @override
  State<AstroTimePicker> createState() => _AstroTimePickerState();
}

class _AstroTimePickerState extends State<AstroTimePicker> {
  late int selectedHour, selectedMinute;
  late bool isNight;
  late FixedExtentScrollController _hourController, _minuteController;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialHour.clamp(1, 12);
    selectedMinute = widget.initialMinute.clamp(0, 59);
    isNight = widget.initialIsNight;

    _hourController = FixedExtentScrollController(
      initialItem: 10000 * 12 + (selectedHour - 1),
    );
    _minuteController = FixedExtentScrollController(
      initialItem: 10000 * 60 + selectedMinute,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged(selectedHour, selectedMinute, isNight);
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final headerStyle = TextStyle(
      color: widget.textColor.withValues(alpha: 0.6),
      fontSize: 13,
      fontWeight: FontWeight.bold,
    );

    final nightDayLabel = 'add_screen.night_day'.tr() != 'add_screen.night_day'
        ? 'add_screen.night_day'.tr()
        : (isRTL ? 'ليل / نهار' : 'Night / Day');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Text('common.suwaya'.tr(), style: headerStyle),
                ),
              ),
              const SizedBox(width: 17.5),
              Expanded(
                child: Center(
                  child: Text('add_screen.minute'.tr(), style: headerStyle),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Center(child: Text(nightDayLabel, style: headerStyle)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            height: 140,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker.builder(
                    scrollController: _hourController,
                    itemExtent: 40,
                    onSelectedItemChanged: (i) {
                      HapticFeedback.selectionClick();
                      selectedHour = (i % 12) + 1;
                      _notifyChange();
                    },
                    itemBuilder: (ctx, idx) => Center(
                      child: Text(
                        ((idx % 12) + 1).toString().padLeft(2, '0'),
                        style: const TextStyle(
                          color: Color(0xFFF2C94C),
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1.5,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: widget.textColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker.builder(
                    scrollController: _minuteController,
                    itemExtent: 40,
                    onSelectedItemChanged: (i) {
                      HapticFeedback.selectionClick();
                      selectedMinute = i % 60;
                      _notifyChange();
                    },
                    itemBuilder: (ctx, idx) => Center(
                      child: Text(
                        (idx % 60).toString().padLeft(2, '0'),
                        style: const TextStyle(
                          color: Color(0xFFF2C94C),
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      setState(() => isNight = !isNight);
                      _notifyChange();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 80,
                      decoration: BoxDecoration(
                        color: isNight
                            ? const Color(0xFF1A237E).withValues(alpha: 0.3)
                            : const Color(0xFFFFF176).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isNight
                              ? const Color(0xFF3949AB)
                              : const Color(0xFFFFCA28),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: SuwayaPhaseBadge(
                          isNight: isNight,
                          size: 38,
                          iconMode: widget.iconMode,
                          isRTL: isRTL,
                          textStyle: TextStyle(
                            fontSize: 26,
                            color: isNight
                                ? const Color(0xFF64B5F6)
                                : const Color(0xFFFFCA28),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// 🌟 2. عجلة الوقت المدني (تدعم نظام 24 ساعة 0..23، ونظام 12 ساعة 1..12 مع زر ص/م - AM/PM)
class DoubleWheelPicker extends StatefulWidget {
  final String label1, label2;
  final int initialVal1, initialVal2, min1, max1, max2;
  final Function(int, int) onChanged;
  final Color textColor, surfaceColor;
  final bool is12HourMode;

  const DoubleWheelPicker({
    super.key,
    required this.label1,
    required this.label2,
    required this.initialVal1,
    required this.initialVal2,
    required this.min1,
    required this.max1,
    required this.max2,
    required this.onChanged,
    required this.textColor,
    required this.surfaceColor,
    this.is12HourMode = false,
  });

  @override
  State<DoubleWheelPicker> createState() => _DoubleWheelPickerState();
}

class _DoubleWheelPickerState extends State<DoubleWheelPicker> {
  late int val1;
  late int val2;
  late bool isPm;
  late FixedExtentScrollController _controller1, _controller2;

  @override
  void initState() {
    super.initState();
    val2 = widget.initialVal2.clamp(0, widget.max2);

    if (widget.is12HourMode) {
      final rawHour24 = widget.initialVal1.clamp(0, 23);
      isPm = rawHour24 >= 12;
      int h12 = rawHour24 % 12;
      if (h12 == 0) h12 = 12;
      val1 = h12;
      _controller1 = FixedExtentScrollController(
        initialItem: 10000 * 12 + (val1 - 1),
      );
    } else {
      isPm = false;
      val1 = widget.initialVal1.clamp(widget.min1, widget.max1);
      final int range1 = widget.max1 - widget.min1 + 1;
      _controller1 = FixedExtentScrollController(
        initialItem: 10000 * range1 + (val1 - widget.min1),
      );
    }

    _controller2 = FixedExtentScrollController(
      initialItem: 10000 * (widget.max2 + 1) + val2,
    );
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  void _notifyChange() {
    if (widget.is12HourMode) {
      int hour24;
      if (isPm) {
        hour24 = val1 == 12 ? 12 : val1 + 12;
      } else {
        hour24 = val1 == 12 ? 0 : val1;
      }
      widget.onChanged(hour24, val2);
    } else {
      widget.onChanged(val1, val2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(
      color: widget.textColor.withValues(alpha: 0.6),
      fontSize: 13,
      fontWeight: FontWeight.bold,
    );

    if (widget.is12HourMode) {
      final isAr = context.locale.languageCode == 'ar';
      final amLabel = isAr ? 'ص' : 'AM';
      final pmLabel = isAr ? 'م' : 'PM';
      final periodHeader = isAr ? 'ص / م' : 'AM / PM';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Expanded(
                  child: Center(child: Text(widget.label1, style: headerStyle)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Center(child: Text(widget.label2, style: headerStyle)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Center(child: Text(periodHeader, style: headerStyle)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              height: 140,
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker.builder(
                      scrollController: _controller1,
                      itemExtent: 40,
                      onSelectedItemChanged: (i) {
                        HapticFeedback.selectionClick();
                        val1 = (i % 12) + 1;
                        _notifyChange();
                      },
                      itemBuilder: (ctx, idx) => Center(
                        child: Text(
                          ((idx % 12) + 1).toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    ':',
                    style: TextStyle(
                      color: widget.textColor.withValues(alpha: 0.3),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker.builder(
                      scrollController: _controller2,
                      itemExtent: 40,
                      onSelectedItemChanged: (i) {
                        HapticFeedback.selectionClick();
                        val2 = i % (widget.max2 + 1);
                        _notifyChange();
                      },
                      itemBuilder: (ctx, idx) => Center(
                        child: Text(
                          (idx % (widget.max2 + 1)).toString().padLeft(2, '0'),
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        setState(() => isPm = !isPm);
                        _notifyChange();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 80,
                        decoration: BoxDecoration(
                          color: isPm
                              ? const Color(0xFF1A237E).withValues(alpha: 0.3)
                              : const Color(0xFFFFF176).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isPm
                                ? const Color(0xFF3949AB)
                                : const Color(0xFFFFCA28),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            isPm ? pmLabel : amLabel,
                            style: TextStyle(
                              fontSize: 24,
                              color: isPm
                                  ? const Color(0xFF64B5F6)
                                  : const Color(0xFFFFCA28),
                              fontWeight: FontWeight.w900,
                              fontFamily: isAr ? 'Tajawal' : 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final int range1 = widget.max1 - widget.min1 + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Expanded(
                child: Center(child: Text(widget.label1, style: headerStyle)),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Center(child: Text(widget.label2, style: headerStyle)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            height: 140,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker.builder(
                    scrollController: _controller1,
                    itemExtent: 40,
                    onSelectedItemChanged: (i) {
                      HapticFeedback.selectionClick();
                      val1 = (i % range1) + widget.min1;
                      _notifyChange();
                    },
                    itemBuilder: (ctx, idx) => Center(
                      child: Text(
                        ((idx % range1) + widget.min1).toString().padLeft(
                          2,
                          '0',
                        ),
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  ':',
                  style: TextStyle(
                    color: widget.textColor.withValues(alpha: 0.3),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Expanded(
                  child: CupertinoPicker.builder(
                    scrollController: _controller2,
                    itemExtent: 40,
                    onSelectedItemChanged: (i) {
                      HapticFeedback.selectionClick();
                      val2 = i % (widget.max2 + 1);
                      _notifyChange();
                    },
                    itemBuilder: (ctx, idx) => Center(
                      child: Text(
                        (idx % (widget.max2 + 1)).toString().padLeft(2, '0'),
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class HijriCalendarDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;
  final Color textColor;
  final Color accentColor;
  final int hijriOffsetDays;

  const HijriCalendarDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
    required this.textColor,
    required this.accentColor,
    this.hijriOffsetDays = 0,
  });

  @override
  State<HijriCalendarDatePicker> createState() =>
      _HijriCalendarDatePickerState();
}

class _HijriCalendarDatePickerState extends State<HijriCalendarDatePicker> {
  static const UmmAlQuraHijriProvider _hijriProvider = UmmAlQuraHijriProvider();

  late DateTime _selectedDate;
  late DateTime _minDate;
  late DateTime _maxDate;
  late int _displayedHijriYear;
  late int _displayedHijriMonth;

  HijriDate _toAdjustedHijri(DateTime gregorianDate) {
    final offset = widget.hijriOffsetDays.clamp(-2, 2);
    return _hijriProvider.dateForGregorianDate(
      date: CivilDate(
        gregorianDate.year,
        gregorianDate.month,
        gregorianDate.day,
      ),
      adjustmentDays: offset,
    );
  }

  DateTime _fromAdjustedHijri(int hYear, int hMonth, int hDay) {
    final offset = widget.hijriOffsetDays.clamp(-2, 2);
    final civil = _hijriProvider.gregorianForHijriDate(
      hYear: hYear,
      hMonth: hMonth,
      hDay: hDay,
      adjustmentDays: offset,
    );
    return DateTime(civil.year, civil.month, civil.day);
  }

  @override
  void initState() {
    super.initState();
    _minDate = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
      widget.firstDate.day,
    );
    _maxDate = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
    );

    final cleanInit = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _selectedDate = cleanInit.isBefore(_minDate) ? _minDate : cleanInit;

    final hInit = _toAdjustedHijri(_selectedDate);
    _displayedHijriYear = hInit.year;
    _displayedHijriMonth = hInit.month;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _canGoPrevMonth {
    int prevM = _displayedHijriMonth - 1;
    int prevY = _displayedHijriYear;
    if (prevM < 1) {
      prevM = 12;
      prevY--;
    }
    final daysInPrev = _hijriProvider.daysInHijriMonth(prevY, prevM);
    final cleanLast = _fromAdjustedHijri(prevY, prevM, daysInPrev);
    return !cleanLast.isBefore(_minDate);
  }

  bool get _canGoNextMonth {
    int nextM = _displayedHijriMonth + 1;
    int nextY = _displayedHijriYear;
    if (nextM > 12) {
      nextM = 1;
      nextY++;
    }
    final cleanFirst = _fromAdjustedHijri(nextY, nextM, 1);
    return !cleanFirst.isAfter(_maxDate);
  }

  void _changeMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() {
      int m = _displayedHijriMonth + delta;
      int y = _displayedHijriYear;
      if (m > 12) {
        m = 1;
        y++;
      } else if (m < 1) {
        m = 12;
        y--;
      }
      _displayedHijriMonth = m;
      _displayedHijriYear = y;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = _hijriProvider.daysInHijriMonth(
      _displayedHijriYear,
      _displayedHijriMonth,
    );
    final DateTime firstGreg = _fromAdjustedHijri(
      _displayedHijriYear,
      _displayedHijriMonth,
      1,
    );
    final int leadingEmpty = firstGreg.weekday % 7;
    final int totalCells = leadingEmpty + daysInMonth;

    final langCode = context.locale.languageCode;
    final safeLocale = (langCode == 'ff' || langCode == 'ug') ? 'en' : langCode;
    final isRTL = Directionality.of(context) == TextDirection.rtl;
    final baseSunday = DateTime(2026, 10, 18);

    final monthTitle =
        '${'hijri.m$_displayedHijriMonth'.tr()} $_displayedHijriYear ${'common.ah'.tr()}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: _canGoPrevMonth ? () => _changeMonth(-1) : null,
              icon: Icon(
                isRTL ? LucideIcons.chevron_right : LucideIcons.chevron_left,
                color: _canGoPrevMonth
                    ? widget.textColor
                    : widget.textColor.withValues(alpha: 0.2),
                size: 20,
              ),
            ),
            Text(
              monthTitle,
              style: TextStyle(
                color: widget.textColor,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: _canGoNextMonth ? () => _changeMonth(1) : null,
              icon: Icon(
                isRTL ? LucideIcons.chevron_left : LucideIcons.chevron_right,
                color: _canGoNextMonth
                    ? widget.textColor
                    : widget.textColor.withValues(alpha: 0.2),
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(7, (index) {
            final d = baseSunday.add(Duration(days: index));
            final label = DateFormat('E', safeLocale).format(d);
            return Expanded(
              child: Center(
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: widget.textColor.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.05,
          ),
          itemBuilder: (context, index) {
            if (index < leadingEmpty) {
              return const SizedBox.shrink();
            }

            final int hDay = index - leadingEmpty + 1;
            final DateTime cellDate = _fromAdjustedHijri(
              _displayedHijriYear,
              _displayedHijriMonth,
              hDay,
            );

            final bool isDisabled =
                cellDate.isBefore(_minDate) || cellDate.isAfter(_maxDate);
            final bool isSelected = _isSameDay(cellDate, _selectedDate);
            final bool isToday = _isSameDay(cellDate, _minDate);

            return GestureDetector(
              onTap: isDisabled
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDate = cellDate);
                      widget.onDateChanged(cellDate);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? widget.accentColor
                      : (isDisabled
                            ? widget.textColor.withValues(alpha: 0.04)
                            : Colors.transparent),
                  border: isToday && !isSelected
                      ? Border.all(color: widget.accentColor, width: 1.5)
                      : null,
                ),
                child: Text(
                  '$hDay',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDisabled
                              ? widget.textColor.withValues(alpha: 0.24)
                              : (isToday
                                    ? widget.accentColor
                                    : widget.textColor)),
                    fontSize: 14,
                    fontWeight: (isSelected || isToday)
                        ? FontWeight.w900
                        : FontWeight.w600,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
