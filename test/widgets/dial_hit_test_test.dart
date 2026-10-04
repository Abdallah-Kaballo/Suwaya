import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:suwaya/core/theme/dial_design_provider.dart';
import 'package:suwaya/features/home/widgets/dial/dial_constants.dart';
import 'package:suwaya/features/home/widgets/dial/dial_models.dart';
import 'package:suwaya/features/home/widgets/dial/painters/dynamic_elements_painters.dart';
import 'package:suwaya/models/task_model.dart';
import 'package:suwaya_time/suwaya_time.dart';

void main() {
  test('needle at 22|25 is closer to the 23 boundary than 22', () {
    final dayStart = DateTime.utc(2026, 10, 4);
    final dayEnd = dayStart.add(const Duration(hours: 24));
    final suwayaStart = dayStart.add(const Duration(hours: 11));
    final liveTime = suwayaStart.add(const Duration(minutes: 12, seconds: 30));
    final needle = DynamicNeedlePainter(
      currentTime: liveTime,
      dayStart: dayStart,
      dayEnd: dayEnd,
      isDark: true,
      design: DialDesign.classic,
    );
    final angle22 = timeToAngle(suwayaStart, dayStart, dayEnd);
    final angle23 = timeToAngle(
        suwayaStart.add(const Duration(minutes: 15)), dayStart, dayEnd);

    expect((needle.angle - angle23).abs(),
        lessThan((needle.angle - angle22).abs()));
  });

  test('needle painter requests repaint as its live timestamp advances', () {
    final dayStart = DateTime.utc(2026, 10, 4);
    final dayEnd = dayStart.add(const Duration(hours: 24));
    final first = DynamicNeedlePainter(
      currentTime: dayStart.add(const Duration(hours: 11)),
      dayStart: dayStart,
      dayEnd: dayEnd,
      isDark: true,
      design: DialDesign.classic,
    );
    final next = DynamicNeedlePainter(
      currentTime: dayStart.add(const Duration(hours: 11, minutes: 12)),
      dayStart: dayStart,
      dayEnd: dayEnd,
      isDark: true,
      design: DialDesign.classic,
    );

    expect(next.shouldRepaint(first), isTrue);
  });

  test('dial marker hit testing follows the painted task track after rotation',
      () {
    final dayStart = DateTime.utc(2026, 10, 4);
    final dayEnd = dayStart.add(const Duration(hours: 24));
    final ibadat = IbadatTimings(
      fajr: dayStart.add(const Duration(hours: 1)),
      sunrise: dayStart.add(const Duration(hours: 2)),
      dhuhr: dayStart.add(const Duration(hours: 6)),
      asr: dayStart.add(const Duration(hours: 10)),
      maghrib: dayStart.add(const Duration(hours: 14)),
      isha: dayStart.add(const Duration(hours: 18)),
      nextFajr: dayEnd,
      nightParts: const [],
    );
    final task = TaskModel()..id = 42;
    final layouts = layoutDialMarkers(
      size: const Size(400, 400),
      ibadat: ibadat,
      nightMarkers: const [],
      tasks: [
        DialTask(
          taskModel: task,
          shortName: 'Study',
          time: dayStart.add(const Duration(hours: 22)),
          color: Colors.green,
        ),
      ],
      design: DialDesign.classic,
      dayStart: dayStart,
      dayEnd: dayEnd,
    );
    final taskMarker =
        layouts.singleWhere((layout) => layout.item.id == 'task:42');
    const rotation = math.pi / 3;
    const center = Offset(200, 200);
    final point = Offset(
      center.dx + taskMarker.radius * math.cos(taskMarker.angle + rotation),
      center.dy + taskMarker.radius * math.sin(taskMarker.angle + rotation),
    );

    expect(
      hitTestDialMarker(
        position: point,
        size: const Size(400, 400),
        totalRotation: rotation,
        layouts: layouts,
      )?.item.id,
      'task:42',
    );
    expect(
      hitTestDialMarker(
        position: const Offset(200, 200),
        size: const Size(400, 400),
        totalRotation: rotation,
        layouts: layouts,
      ),
      isNull,
    );

    final prayerMarker = layouts.firstWhere(
        (layout) => layout.item.id == 'prayer:fajr' && !layout.isBadge);
    final prayerPoint = Offset(
      center.dx + prayerMarker.radius * math.cos(prayerMarker.angle + rotation),
      center.dy + prayerMarker.radius * math.sin(prayerMarker.angle + rotation),
    );
    expect(
      hitTestDialMarker(
        position: prayerPoint,
        size: const Size(400, 400),
        totalRotation: rotation,
        layouts: layouts,
      )?.item.id,
      'prayer:fajr',
    );

    final minimalLayouts = layoutDialMarkers(
      size: const Size(400, 400),
      ibadat: ibadat,
      nightMarkers: const [],
      tasks: const [],
      design: DialDesign.minimal,
      dayStart: dayStart,
      dayEnd: dayEnd,
    );
    expect(minimalLayouts.where((layout) => layout.isBadge), isEmpty);
  });
}
