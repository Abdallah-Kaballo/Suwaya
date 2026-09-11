import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya_time/suwaya_time.dart';
import 'package:hijri/hijri_calendar.dart';

class TripleWheelPicker extends StatefulWidget {
  final List<AstroPeriod> periods; 
  final int initialPeriodId; 
  final int initialSuwaya; 
  final int initialMinute;
  final Function(int pId, int sNum, int min) onChanged; 
  final Color textColor; 
  final Color surfaceColor;
  
  const TripleWheelPicker({
    super.key, required this.periods, required this.initialPeriodId, required this.initialSuwaya, 
    required this.initialMinute, required this.onChanged, required this.textColor, 
    required this.surfaceColor
  });
  
  @override 
  State<TripleWheelPicker> createState() => _TripleWheelPickerState();
}

class _TripleWheelPickerState extends State<TripleWheelPicker> {
  late int selectedPeriodIndex, selectedSuwaya, selectedMinute;
  late FixedExtentScrollController _periodController, _suwayaController, _minuteController;
  
  @override 
  void initState() {
    super.initState();
    selectedPeriodIndex = widget.periods.indexWhere((p) => p.id == widget.initialPeriodId);
    if (selectedPeriodIndex == -1) { selectedPeriodIndex = 0; }
    selectedSuwaya = widget.initialSuwaya; 
    selectedMinute = widget.initialMinute;
    _periodController = FixedExtentScrollController(initialItem: selectedPeriodIndex);
    _suwayaController = FixedExtentScrollController(initialItem: selectedSuwaya - 1);
    _minuteController = FixedExtentScrollController(initialItem: 10000 * 30 + selectedMinute);
  }
  
  @override 
  void dispose() { 
    _periodController.dispose(); _suwayaController.dispose(); _minuteController.dispose(); super.dispose(); 
  }

  String _getCustomPeriodName(int idx) {
    switch (idx) {
      case 0: return 'periods.fajr'.tr();
      case 1: return 'periods.duha'.tr();
      case 2: return 'periods.dhuhr'.tr();
      case 3: return 'periods.asr'.tr();
      case 4: return 'periods.maghrib'.tr();
      case 5: return 'periods.middle_third'.tr();
      case 6: return 'periods.last_third'.tr();
      default: return '${'common.period'.tr()} ${idx + 1}';
    }
  }

  @override 
  Widget build(BuildContext context) {
    if (widget.periods.isEmpty) return const SizedBox.shrink();
    AstroPeriod currentPeriod = widget.periods[selectedPeriodIndex];
    int maxSuwayas = currentPeriod.suwayasCount > 0 ? currentPeriod.suwayasCount : 1;
    final headerStyle = TextStyle(color: widget.textColor.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Expanded(flex: 3, child: Center(child: Text('common.period'.tr(), style: headerStyle))),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: Center(child: Text('common.suwaya'.tr(), style: headerStyle))),
            const SizedBox(width: 14),
            Expanded(flex: 2, child: Center(child: Text('add_screen.minute'.tr(), style: headerStyle))),
          ]
        ),
      ),
      const SizedBox(height: 8),
      Directionality(
        textDirection: TextDirection.ltr, 
        child: SizedBox(height: 140, child: Row(children: [
          Expanded(
            flex: 3, 
            child: CupertinoPicker.builder(
              scrollController: _periodController, itemExtent: 40, 
              onSelectedItemChanged: (i) { 
                HapticFeedback.selectionClick(); 
                setState(() { 
                  selectedPeriodIndex = i; 
                  if (selectedSuwaya > widget.periods[i].suwayasCount) { 
                    selectedSuwaya = widget.periods[i].suwayasCount; 
                    _suwayaController.jumpToItem(selectedSuwaya - 1); 
                  } 
                }); 
                widget.onChanged(widget.periods[i].id, selectedSuwaya, selectedMinute); 
              }, 
              childCount: widget.periods.length, 
              itemBuilder: (ctx, idx) => Center(child: Text(_getCustomPeriodName(idx), style: TextStyle(color: widget.textColor, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')))
            )
          ),
          Text(':', style: TextStyle(color: widget.textColor.withValues(alpha: 0.3), fontSize: 24, fontWeight: FontWeight.bold)),
          
          Expanded(
            flex: 2, 
            child: CupertinoPicker.builder(
              scrollController: _suwayaController, itemExtent: 40, 
              onSelectedItemChanged: (i) { 
                HapticFeedback.selectionClick(); 
                selectedSuwaya = i + 1; 
                widget.onChanged(widget.periods[selectedPeriodIndex].id, selectedSuwaya, selectedMinute); 
              }, 
              childCount: maxSuwayas, 
              itemBuilder: (ctx, idx) => Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text((idx).toString().padLeft(2, '0'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal, fontFamily: 'Playfair Display', foreground: Paint()..style=PaintingStyle.stroke..strokeWidth=1.1..color=Colors.white)),
                    Text((idx).toString().padLeft(2, '0'), style: const TextStyle(color: Color(0xFFF2C94C), fontSize: 24, fontWeight: FontWeight.normal, fontFamily: 'Playfair Display')),
                  ],
                ),
              )
            )
          ),
          Text(':', style: TextStyle(color: widget.textColor.withValues(alpha: 0.3), fontSize: 24, fontWeight: FontWeight.bold)),
          
          Expanded(
            flex: 2, 
            child: CupertinoPicker.builder(
              scrollController: _minuteController, itemExtent: 40, 
              onSelectedItemChanged: (i) { 
                HapticFeedback.selectionClick(); 
                selectedMinute = i % 30; 
                widget.onChanged(widget.periods[selectedPeriodIndex].id, selectedSuwaya, selectedMinute); 
              }, 
              itemBuilder: (ctx, idx) => Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text((idx % 30).toString().padLeft(2, '0'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal, fontFamily: 'Playfair Display', foreground: Paint()..style=PaintingStyle.stroke..strokeWidth=1.1..color=Colors.white)),
                    Text((idx % 30).toString().padLeft(2, '0'), style: const TextStyle(color: Color(0xFFF2C94C), fontSize: 24, fontWeight: FontWeight.normal, fontFamily: 'Playfair Display')),
                  ],
                ),
              )
            )
          ),
        ]))
      )
    ]);
  }
}

class DoubleWheelPicker extends StatefulWidget {
  final bool isAstro; 
  final String label1, label2; final int initialVal1, initialVal2, min1, max1, max2;
  final Function(int, int) onChanged; final Color textColor, surfaceColor;
  const DoubleWheelPicker({super.key, required this.isAstro, required this.label1, required this.label2, required this.initialVal1, required this.initialVal2, required this.min1, required this.max1, required this.max2, required this.onChanged, required this.textColor, required this.surfaceColor});
  @override State<DoubleWheelPicker> createState() => _DoubleWheelPickerState();
}

class _DoubleWheelPickerState extends State<DoubleWheelPicker> {
  late int val1, val2; late FixedExtentScrollController _controller1, _controller2;
  
  @override 
  void initState() {
    super.initState();
    val1 = widget.initialVal1; val2 = widget.initialVal2;
    int range1 = widget.max1 - widget.min1 + 1;
    _controller1 = FixedExtentScrollController(initialItem: 10000 * range1 + (val1 - widget.min1));
    _controller2 = FixedExtentScrollController(initialItem: 10000 * (widget.max2 + 1) + val2); // إصلاح قسمة المودولو
  }
  
  @override 
  void dispose() { _controller1.dispose(); _controller2.dispose(); super.dispose(); }
  
  @override 
  Widget build(BuildContext context) {
    int range1 = widget.max1 - widget.min1 + 1;
    final headerStyle = TextStyle(color: widget.textColor.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.bold);
    Color valColor = widget.isAstro ? const Color(0xFFF2C94C) : widget.textColor;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [Expanded(child: Center(child: Text(widget.label1, style: headerStyle))), const SizedBox(width: 24), Expanded(child: Center(child: Text(widget.label2, style: headerStyle)))])
      ),
      const SizedBox(height: 8),
      Directionality(
        textDirection: TextDirection.ltr, 
        child: SizedBox(height: 140, child: Row(children: [
          Expanded(child: CupertinoPicker.builder(scrollController: _controller1, itemExtent: 40, onSelectedItemChanged: (i) { HapticFeedback.selectionClick(); val1 = (i % range1) + widget.min1; widget.onChanged(val1, val2); }, itemBuilder: (ctx, idx) => Center(
            child: widget.isAstro ? Stack(
              alignment: Alignment.center,
              children: [
                Text(((idx % range1) + widget.min1).toString().padLeft(2, '0'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal, fontFamily: 'Playfair Display', foreground: Paint()..style=PaintingStyle.stroke..strokeWidth=1.1..color=Colors.white)),
                Text(((idx % range1) + widget.min1).toString().padLeft(2, '0'), style: TextStyle(color: valColor, fontSize: 24, fontWeight: FontWeight.normal, fontFamily: 'Playfair Display')),
              ],
            ) : Text(((idx % range1) + widget.min1).toString().padLeft(2, '0'), style: TextStyle(color: valColor, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
          ))),
          Text(':', style: TextStyle(color: widget.textColor.withValues(alpha: 0.3), fontSize: 24, fontWeight: FontWeight.bold)),
          Expanded(child: CupertinoPicker.builder(scrollController: _controller2, itemExtent: 40, onSelectedItemChanged: (i) { HapticFeedback.selectionClick(); val2 = (i % (widget.max2 + 1)); widget.onChanged(val1, val2); }, itemBuilder: (ctx, idx) => Center(
            child: widget.isAstro ? Stack(
              alignment: Alignment.center,
              children: [
                Text((idx % (widget.max2 + 1)).toString().padLeft(2, '0'), style: TextStyle(fontSize: 24, fontWeight: FontWeight.normal, fontFamily: 'Playfair Display', foreground: Paint()..style=PaintingStyle.stroke..strokeWidth=1.1..color=Colors.white)),
                Text((idx % (widget.max2 + 1)).toString().padLeft(2, '0'), style: TextStyle(color: valColor, fontSize: 24, fontWeight: FontWeight.normal, fontFamily: 'Playfair Display')),
              ],
            ) : Text((idx % (widget.max2 + 1)).toString().padLeft(2, '0'), style: TextStyle(color: valColor, fontSize: 24, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
          ))),
        ]))
      )
    ]);
  }
}

class HijriWheelPicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onChanged;
  final Color textColor;
  final Color surfaceColor;

  const HijriWheelPicker({
    super.key, required this.initialDate, required this.onChanged, required this.textColor, required this.surfaceColor,
  });

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
    _dayController.dispose(); _monthController.dispose(); _yearController.dispose(); super.dispose();
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
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [
          Expanded(child: Center(child: Text('add_screen.year'.tr(), style: headerStyle))), 
          const SizedBox(width: 8), 
          Expanded(flex: 2, child: Center(child: Text('add_screen.month'.tr(), style: headerStyle))),
          const SizedBox(width: 8), 
          Expanded(child: Center(child: Text('add_screen.day'.tr(), style: headerStyle)))
        ])
      ),
      const SizedBox(height: 8),
      Directionality(
        textDirection: TextDirection.ltr, 
        child: SizedBox(height: 140, child: Row(children: [
          Expanded(child: CupertinoPicker.builder(
            scrollController: _yearController, itemExtent: 40, 
            onSelectedItemChanged: (i) { HapticFeedback.selectionClick(); hYear = currentHijriYear + minYearOffset + i; _updateDate(); }, 
            childCount: yearRange,
            itemBuilder: (ctx, idx) => Center(child: Text('${currentHijriYear + minYearOffset + idx}', style: TextStyle(color: widget.textColor, fontSize: 20, fontWeight: FontWeight.w600, fontFamily: 'Inter'))))),
          Text('/', style: TextStyle(color: widget.textColor.withValues(alpha: 0.3), fontSize: 24, fontWeight: FontWeight.bold)),
          Expanded(flex: 2, child: CupertinoPicker.builder(
            scrollController: _monthController, itemExtent: 40, 
            onSelectedItemChanged: (i) { HapticFeedback.selectionClick(); hMonth = (i % 12) + 1; _updateDate(); }, 
            itemBuilder: (ctx, idx) => Center(child: Text('hijri.m${(idx % 12) + 1}'.tr(), style: TextStyle(color: widget.textColor, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Tajawal'))))),
          Text('/', style: TextStyle(color: widget.textColor.withValues(alpha: 0.3), fontSize: 24, fontWeight: FontWeight.bold)),
          Expanded(child: CupertinoPicker.builder(
            scrollController: _dayController, itemExtent: 40, 
            onSelectedItemChanged: (i) { HapticFeedback.selectionClick(); hDay = (i % 30) + 1; _updateDate(); }, 
            itemBuilder: (ctx, idx) => Center(child: Text(((idx % 30) + 1).toString().padLeft(2, '0'), style: TextStyle(color: widget.textColor, fontSize: 22, fontWeight: FontWeight.w600, fontFamily: 'Inter'))))),
        ]))
      )
    ]);
  }
}