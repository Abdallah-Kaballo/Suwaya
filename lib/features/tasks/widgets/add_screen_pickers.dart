import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:hijri/hijri_calendar.dart';

// 🌟 العجلة السويعية الجديدة السلسة جداً (ساعات، دقائق، ليل/نهار)
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

    _hourController = FixedExtentScrollController(initialItem: 10000 * 12 + (selectedHour - 1));
    _minuteController = FixedExtentScrollController(initialItem: 10000 * 60 + selectedMinute);
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
    final headerStyle = TextStyle(color: widget.textColor.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold);
    
    final dayIcon = widget.iconMode == 'text' ? (isRTL ? 'ن' : 'D') : '☀️';
    final nightIcon = widget.iconMode == 'text' ? (isRTL ? 'ل' : 'N') : '🌑';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [
          Expanded(child: Center(child: Text('common.suwaya'.tr(), style: headerStyle))),
          const SizedBox(width: 14),
          Expanded(child: Center(child: Text('add_screen.minute'.tr(), style: headerStyle))),
          const SizedBox(width: 14),
        ]),
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
                      style: const TextStyle(color: Color(0xFFF2C94C), fontSize: 26, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                    ),
                  ),
                ),
              ),
              Container(
                width: 1.5,
                height: 12,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: widget.textColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(1)),
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
                      style: const TextStyle(color: Color(0xFFF2C94C), fontSize: 26, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // 🌟 زر التبديل البصري الجميل
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
                      color: isNight ? const Color(0xFF1A237E).withValues(alpha: 0.3) : const Color(0xFFFFF176).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isNight ? const Color(0xFF3949AB) : const Color(0xFFFFCA28), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        isNight ? nightIcon : dayIcon,
                        style: TextStyle(
                          fontSize: 28,
                          color: isNight ? const Color(0xFF64B5F6) : const Color(0xFFFFCA28),
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal'
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
    ]);
  }
}

class DoubleWheelPicker extends StatefulWidget {
  final String label1, label2;
  final int initialVal1, initialVal2, min1, max1, max2;
  final Function(int, int) onChanged;
  final Color textColor, surfaceColor;
  
  const DoubleWheelPicker({
    super.key, required this.label1, required this.label2,
    required this.initialVal1, required this.initialVal2,
    required this.min1, required this.max1, required this.max2,
    required this.onChanged, required this.textColor, required this.surfaceColor
  });

  @override
  State<DoubleWheelPicker> createState() => _DoubleWheelPickerState();
}

class _DoubleWheelPickerState extends State<DoubleWheelPicker> {
  late int val1, val2;
  late FixedExtentScrollController _controller1, _controller2;

  @override
  void initState() {
    super.initState();
    val1 = widget.initialVal1; val2 = widget.initialVal2;
    int range1 = widget.max1 - widget.min1 + 1;
    _controller1 = FixedExtentScrollController(initialItem: 10000 * range1 + (val1 - widget.min1));
    _controller2 = FixedExtentScrollController(initialItem: 10000 * (widget.max2 + 1) + val2); 
  }

  @override
  void dispose() {
    _controller1.dispose(); _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int range1 = widget.max1 - widget.min1 + 1;
    final headerStyle = TextStyle(color: widget.textColor.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [
          Expanded(child: Center(child: Text(widget.label1, style: headerStyle))),
          const SizedBox(width: 24),
          Expanded(child: Center(child: Text(widget.label2, style: headerStyle)))
        ])),
      const SizedBox(height: 8),
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          height: 140,
          child: Row(children: [
            Expanded(
              child: CupertinoPicker.builder(
                scrollController: _controller1, itemExtent: 40,
                onSelectedItemChanged: (i) {
                  HapticFeedback.selectionClick();
                  val1 = (i % range1) + widget.min1;
                  widget.onChanged(val1, val2);
                },
                itemBuilder: (ctx, idx) => Center(child: Text(((idx % range1) + widget.min1).toString().padLeft(2, '0'), style: TextStyle(color: widget.textColor, fontSize: 26, fontWeight: FontWeight.w600, fontFamily: 'Inter'))),
              )
            ),
            Text(':', style: TextStyle(color: widget.textColor.withValues(alpha: 0.3), fontSize: 24, fontWeight: FontWeight.bold)),
            Expanded(
              child: CupertinoPicker.builder(
                scrollController: _controller2, itemExtent: 40,
                onSelectedItemChanged: (i) {
                  HapticFeedback.selectionClick();
                  val2 = (i % (widget.max2 + 1));
                  widget.onChanged(val1, val2);
                },
                itemBuilder: (ctx, idx) => Center(child: Text((idx % (widget.max2 + 1)).toString().padLeft(2, '0'), style: TextStyle(color: widget.textColor, fontSize: 26, fontWeight: FontWeight.w600, fontFamily: 'Inter'))),
              )
            ),
          ])
        )
      )
    ]);
  }
}

class HijriWheelPicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onChanged;
  final Color textColor, surfaceColor;

  const HijriWheelPicker({super.key, required this.initialDate, required this.onChanged, required this.textColor, required this.surfaceColor});

  @override
  State<HijriWheelPicker> createState() => _HijriWheelPickerState();
}

class _HijriWheelPickerState extends State<HijriWheelPicker> {
  late int hDay, hMonth, hYear;
  late FixedExtentScrollController _dayController, _monthController, _yearController;
  final int minYearOffset = -1;
  final int maxYearOffset = 5;

  @override
  void initState() {
    super.initState();
    final hDate = HijriCalendar.fromDate(widget.initialDate);
    hYear = hDate.hYear; hMonth = hDate.hMonth; hDay = hDate.hDay;
    _dayController = FixedExtentScrollController(initialItem: 10000 * 30 + (hDay - 1));
    _monthController = FixedExtentScrollController(initialItem: 10000 * 12 + (hMonth - 1));
    int yearIndex = hYear - (HijriCalendar.now().hYear + minYearOffset);
    if (yearIndex < 0) yearIndex = 0;
    _yearController = FixedExtentScrollController(initialItem: yearIndex);
  }

  @override
  void dispose() {
    _dayController.dispose(); _monthController.dispose(); _yearController.dispose();
    super.dispose();
  }

  void _updateDate() {
    int maxDays = HijriCalendar().getDaysInMonth(hYear, hMonth);
    if (hDay > maxDays) hDay = maxDays;
    final updatedHijri = HijriCalendar()..hYear = hYear..hMonth = hMonth..hDay = hDay;
    widget.onChanged(updatedHijri.hijriToGregorian(hYear, hMonth, hDay));
  }

  @override
  Widget build(BuildContext context) {
    final headerStyle = TextStyle(color: widget.textColor.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold);
    int currentHijriYear = HijriCalendar.now().hYear;
    int yearRange = maxYearOffset - minYearOffset + 1;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Directionality(textDirection: TextDirection.ltr, child: Row(children: [
        Expanded(child: Center(child: Text('add_screen.year'.tr(), style: headerStyle))), const SizedBox(width: 8),
        Expanded(flex: 2, child: Center(child: Text('add_screen.month'.tr(), style: headerStyle))), const SizedBox(width: 8),
        Expanded(child: Center(child: Text('add_screen.day'.tr(), style: headerStyle)))
      ])),
      const SizedBox(height: 8),
      Directionality(textDirection: TextDirection.ltr, child: SizedBox(height: 140, child: Row(children: [
        Expanded(child: CupertinoPicker.builder(scrollController: _yearController, itemExtent: 40, onSelectedItemChanged: (i) { HapticFeedback.selectionClick(); hYear = currentHijriYear + minYearOffset + i; _updateDate(); }, childCount: yearRange, itemBuilder: (ctx, idx) => Center(child: Text('${currentHijriYear + minYearOffset + idx}', style: TextStyle(color: widget.textColor, fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Inter'))))),
        Text('/', style: TextStyle(color: widget.textColor.withValues(alpha: 0.3), fontSize: 24, fontWeight: FontWeight.bold)),
        Expanded(flex: 2, child: CupertinoPicker.builder(scrollController: _monthController, itemExtent: 40, onSelectedItemChanged: (i) { HapticFeedback.selectionClick(); hMonth = (i % 12) + 1; _updateDate(); }, itemBuilder: (ctx, idx) => Center(child: Text('hijri.m${(idx % 12) + 1}'.tr(), style: TextStyle(color: widget.textColor, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Tajawal'))))),
        Text('/', style: TextStyle(color: widget.textColor.withValues(alpha: 0.3), fontSize: 24, fontWeight: FontWeight.bold)),
        Expanded(child: CupertinoPicker.builder(scrollController: _dayController, itemExtent: 40, onSelectedItemChanged: (i) { HapticFeedback.selectionClick(); hDay = (i % 60) + 1; _updateDate(); }, itemBuilder: (ctx, idx) => Center(child: Text(((idx % 60) + 1).toString().padLeft(2, '0'), style: TextStyle(color: widget.textColor, fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Inter'))))),
      ])))
    ]);
  }
}