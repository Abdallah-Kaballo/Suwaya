import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya_time/suwaya_time.dart';

import '../../../core/utils/time_formatters.dart';
import '../../../models/settings_model.dart';
import 'dial/dial_models.dart';
import 'dial/period_metrics.dart';

({int globalIndex, int minute}) _getDynamicOrFixedAstroTime(
  DialSelection selection,
  AstroState state,
  DateTime time,
  bool isEnd,
) {
  if (selection.type == DialSelectionType.prayer ||
      selection.type == DialSelectionType.period) {
    return getFixedAstroTime(selection.id, state, isEnd: isEnd);
  } else {
    final DateTime evalTime =
        isEnd ? time.subtract(const Duration(microseconds: 1)) : time;
    final mockState = SuwayaTimeEngine.calculateCurrentState(
      SuwayaDay(
        ibadatTimings: state.ibadatTimings,
        cycleAnchors: state.cycleAnchors,
        periods: state.periods,
      ),
      evalTime,
    );
    final int global = mockState.currentSuwayaTime.phase == SuwayaPhase.day
        ? 12 + mockState.currentSuwayaTime.phaseSlotNumber - 1
        : mockState.currentSuwayaTime.phaseSlotNumber - 1;
    return (
      globalIndex: global,
      minute: mockState.currentSuwayaTime.virtualMinute,
    );
  }
}

int? _getNightPartSuwayasCount(String id) {
  final sid = id.toLowerCase();
  if (sid.contains('half_2')) return 6;
  if (sid.contains('third_3')) return 4;
  if (sid.contains('sixth_4') ||
      sid.contains('sixth_5') ||
      sid.contains('sixth_6')) {
    return 2;
  }
  return null;
}

String _formatSuwayaDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes ${'details.minute'.tr()} $seconds ${'details.sec'.tr()}';
}

Future<void> showDialItemDetailsDialog({
  required BuildContext context,
  required DialSelection selection,
  required AstroState astroState,
  required SettingsModel settings,
}) async {
  final textColor = Theme.of(context).colorScheme.onSurface;
  final civilColor = textColor.withValues(alpha: 0.82);

  PeriodMetrics? periodMetrics;

  if (selection.type == DialSelectionType.period) {
    final periodId = int.tryParse(selection.id);
    for (final period in astroState.periods) {
      if (period.id == periodId) {
        periodMetrics = PeriodMetrics.fromPeriod(period);
        break;
      }
    }
  } else if (selection.endTime != null) {
    final nightSuwayas = _getNightPartSuwayasCount(selection.id);
    if (nightSuwayas != null && nightSuwayas > 0) {
      final tempPeriod = AstroPeriod(
        id: 3,
        periodKey: PeriodKey.nightMidnightFajr,
        nameKey: selection.id,
        startTime: selection.startTime,
        endTime: selection.endTime!,
        suwayasCount: nightSuwayas,
        colorValue: selection.color.toARGB32(),
      );
      periodMetrics = PeriodMetrics.fromPeriod(tempPeriod);
    }
  }

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(
        selection.title,
        textAlign: TextAlign.center,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDialTimeRow(
            context,
            'details.start'.tr(),
            selection.startTime,
            astroState,
            settings,
            civilColor,
            selection.color,
            selection,
            false,
          ),
          if (selection.endTime != null) ...[
            const SizedBox(height: 12),
            _buildDialTimeRow(
              context,
              'details.end'.tr(),
              selection.endTime!,
              astroState,
              settings,
              civilColor,
              selection.color,
              selection,
              true,
            ),
          ],
          if (periodMetrics != null) ...[
            const SizedBox(height: 16),
            _buildPeriodMetricRow(
              'home.suwayas_count'.tr(),
              '${periodMetrics.suwayaCount} ${'details.suwayas'.tr()}',
              civilColor,
              selection.color,
            ),
            const SizedBox(height: 10),
            _buildPeriodMetricRow(
              'details.suwaya_length'.tr(),
              _formatSuwayaDuration(periodMetrics.actualSuwayaDuration),
              civilColor,
              selection.color,
            ),
            const SizedBox(height: 10),
            _buildPeriodMetricRow(
              'details.flow_speed'.tr(),
              '${periodMetrics.flowSpeed.toStringAsFixed(2)}x',
              civilColor,
              selection.color,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text('common.done'.tr()),
        ),
      ],
    ),
  );
}

Widget _buildPeriodMetricRow(
  String label,
  String value,
  Color labelColor,
  Color valueColor,
) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Flexible(
        child: Text(label, style: TextStyle(color: labelColor, fontSize: 13)),
      ),
      const SizedBox(width: 12),
      Text(
        value,
        textAlign: TextAlign.end,
        style: TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

Widget _buildDialTimeRow(
  BuildContext context,
  String label,
  DateTime time,
  AstroState astroState,
  SettingsModel settings,
  Color civilColor,
  Color suwayaColor,
  DialSelection selection,
  bool isEnd,
) {
  final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
  const baseStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );

  final fixedTime =
      _getDynamicOrFixedAstroTime(selection, astroState, time, isEnd);
  final formattedSuwaya = formatSuwayaTime(
    fixedTime.globalIndex,
    fixedTime.minute,
    separator: '|',
    isRTL: isRTL,
    iconMode: settings.suwayaIconMode,
  );

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: civilColor, fontSize: 13)),
      const SizedBox(width: 10),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Text(
              formatCivilTime(
                time,
                format: settings.civilTimeFormat,
                locale: context.locale.languageCode,
                context: context,
              ),
              style: baseStyle.copyWith(color: civilColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '/',
              style: TextStyle(color: civilColor.withValues(alpha: 0.5)),
            ),
          ),
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Text(
              formattedSuwaya,
              style: baseStyle.copyWith(color: suwayaColor),
            ),
          ),
        ],
      ),
    ],
  );
}