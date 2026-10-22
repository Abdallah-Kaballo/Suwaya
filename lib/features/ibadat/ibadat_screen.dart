import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya/core/location/permissions_provider.dart';
import 'package:suwaya/core/utils/time_formatters.dart';
import 'package:suwaya/models/settings_model.dart';
import 'package:suwaya_time/suwaya_time.dart';

import '../../core/astro_engine/astro_provider.dart';
import '../settings/settings_provider.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../core/theme/astro_ui_extensions.dart';
import '../../core/providers/ui_providers.dart';

/// 🌟 نافذة موحدة للتحكم في التدوير التلقائي للقرص، الشروق، وأوقات الليل الخمسة
/// تُفتح من زر تعديل القرص في الشاشة الرئيسية ومن زر الإعدادات في شاشة العبادات
void showDialAndIbadatMarkersSheet(
  BuildContext context,
  AstroState astroState,
) {
  HapticFeedback.selectionClick();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  const allowedOrder = ['half_2', 'third_3', 'sixth_4', 'sixth_5', 'sixth_6'];
  final sourceNightParts = astroState.activeOrUpcomingNightParts;
  final availableNightParts = <NightPart>[];
  for (final id in allowedOrder) {
    final match = sourceNightParts.where((p) => p.id == id);
    if (match.isNotEmpty) {
      availableNightParts.add(match.first);
    }
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(settingsProvider);
          final notifier = ref.read(settingsProvider.notifier);
          final pColor = Theme.of(context).primaryColor;
          final textColor = isDark ? Colors.white : Colors.black87;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'home.dial_markers_settings'.tr(),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 🌟 1. التدوير التلقائي للقرص (منقول من شاشة الإعدادات)
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    dense: true,
                    title: Text(
                      'settings.auto_rotate'.tr(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14.5,
                        fontWeight: settings.isDialAutoRotating
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'settings.auto_rotate_desc'.tr(),
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.55),
                        fontSize: 11.5,
                      ),
                    ),
                    value: settings.isDialAutoRotating,
                    activeThumbColor: pColor,
                    secondary: Icon(
                      LucideIcons.refresh_ccw,
                      color: settings.isDialAutoRotating ? pColor : Colors.grey,
                      size: 20,
                    ),
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      notifier.updateDialAutoRotation(val);
                    },
                  ),
                  Divider(
                    height: 8,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),

                  // 🌟 2. إظهار الشروق
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    dense: true,
                    title: Text(
                      'ibadat.show_sunrise'.tr(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14.5,
                        fontWeight: settings.showSunrise
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    value: settings.showSunrise,
                    activeThumbColor: pColor,
                    secondary: Icon(
                      LucideIcons.sun,
                      color: settings.showSunrise
                          ? Colors.orangeAccent
                          : Colors.grey,
                      size: 20,
                    ),
                    onChanged: (val) {
                      HapticFeedback.lightImpact();
                      notifier.updateShowSunrise(val);
                    },
                  ),
                  Divider(
                    height: 8,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),

                  // 🌟 3. أوقات الليل الخمسة بنفس تصميم زر الشروق (SwitchListTile)
                  ...availableNightParts.map((part) {
                    final isSelected =
                        settings.visibleNightParts.contains(part.id);
                    final partTitle =
                        ('night_parts.${part.nameKey.replaceAll("np_", "")}')
                            .tr();

                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      dense: true,
                      title: Text(
                        partTitle,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14.5,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      value: isSelected,
                      activeThumbColor: pColor,
                      secondary: Icon(
                        LucideIcons.sparkles,
                        color: isSelected ? pColor : Colors.grey,
                        size: 20,
                      ),
                      onChanged: (_) {
                        HapticFeedback.lightImpact();
                        notifier.toggleVisibleNightPart(part.id);
                      },
                    );
                  }),

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                      child: Text(
                        'common.done'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class IbadatScreen extends ConsumerWidget {
  const IbadatScreen({super.key});

  Widget _buildClockTime(
    BuildContext context,
    DateTime targetTime,
    AstroState astroState,
    SettingsModel settings,
    bool isDark,
    String identifier, {
    double fontSize = 15,
    Color? civilColor,
    bool isEnd = false,
  }) {
    final useAstro = settings.useAstroTimeForIbadat;
    final suwayaColor = suwayaTimeContrastColor(context);
    final style = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      fontFamily: 'Inter',
    );
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    if (!useAstro) {
      return Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Text(
          formatCivilTime(
            targetTime,
            format: settings.civilTimeFormat,
            locale: context.locale.languageCode,
            context: context,
          ),
          style: style.copyWith(
            color: civilColor ?? (isDark ? Colors.white : Colors.black87),
          ),
        ),
      );
    }

    if (astroState.periods.isEmpty) {
      return Text(
        '00|00',
        style: style.copyWith(color: suwayaColor),
      );
    }

    final fixedTime = getFixedAstroTime(identifier, astroState, isEnd: isEnd);
    final formattedTime = formatSuwayaTime(
      fixedTime.globalIndex,
      fixedTime.minute,
      separator: '|',
      isRTL: isRTL,
      iconMode: settings.suwayaIconMode,
    );

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Text(
        formattedTime,
        style: style.copyWith(color: civilColor ?? suwayaColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final astroState = ref.watch(astroProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (astroState.periods.isEmpty) {
      return Scaffold(
        backgroundColor: scaffoldBgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(astroProvider.notifier).resetToRealTime(),
                icon: const Icon(Icons.refresh),
                label: Text('common.retry'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      drawerEnableOpenDragGesture: true,
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.15,
      drawer: const AppDrawer(),
      onDrawerChanged: (isOpen) =>
          ref.read(isDrawerOpenProvider.notifier).state = isOpen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        titleSpacing: 4,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(LucideIcons.menu, color: textColor),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'ibadat.title'.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16.5,
          ),
        ),
        actions: [
          // 🌟 مفتاح التبديل (Switch) للوقت السُويعي وبجانبه عبارة "الوقت السُويعي"
          Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(settingsProvider);
              final primaryColor = Theme.of(context).primaryColor;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'common.suwaya_time'.tr(),
                    style: TextStyle(
                      color: settings.useAstroTimeForIbadat
                          ? primaryColor
                          : (isDark ? Colors.white70 : Colors.black54),
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.72,
                    child: Switch(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: settings.useAstroTimeForIbadat,
                      activeThumbColor: isDark ? Colors.black : Colors.white,
                      activeTrackColor: primaryColor,
                      onChanged: (val) {
                        HapticFeedback.lightImpact();
                        ref
                            .read(settingsProvider.notifier)
                            .updateUseAstroTimeForIbadat(val);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          // 🌟 زر فتح النافذة الموحدة لإعدادات القرص وأوقات الليل
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(
              LucideIcons.settings_2,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            onPressed: () =>
                showDialAndIbadatMarkersSheet(context, astroState),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: _buildDashboardBody(context, ref, astroState, isDark),
      ),
    );
  }

  Widget _buildDashboardBody(
    BuildContext context,
    WidgetRef ref,
    AstroState astroState,
    bool isDark,
  ) {
    // مواقيت اليوم المدني الحالي لعرض الصلوات الخمس والشروق لتاريخ اليوم الصحيح
    final ibadat = astroState.civilDayIbadat;
    final settings = ref.watch(settingsProvider);
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return ValueListenableBuilder<DateTime>(
      valueListenable: virtualDateTimeNotifier,
      builder: (context, liveNow, _) {
        final anchors = astroState.cycleAnchors;
        final mandatoryPrayers = [
          {
            'id': 'fajr',
            'name': 'periods.fajr'.tr(),
            'time': ibadat.fajr,
          },
          {
            'id': 'dhuhr',
            'name': 'periods.dhuhr'.tr(),
            'time': ibadat.dhuhr,
          },
          {
            'id': 'asr',
            'name': 'periods.asr'.tr(),
            'time': ibadat.asr,
          },
          {
            'id': 'maghrib',
            'name': 'periods.maghrib'.tr(),
            'time': ibadat.maghrib,
          },
          {
            'id': 'isha',
            'name': 'prayers.isha'.tr(),
            'time': ibadat.isha,
          },
        ];

        final candidatePrayers = [
          ...mandatoryPrayers,
          {
            'id': 'fajr',
            'name': 'periods.fajr'.tr(),
            'time': ibadat.nextFajr,
          },
          {
            'id': 'isha',
            'name': 'prayers.isha'.tr(),
            'time': anchors.cycleIsha,
          },
          {
            'id': 'fajr',
            'name': 'periods.fajr'.tr(),
            'time': anchors.cycleFajr,
          },
          {
            'id': 'dhuhr',
            'name': 'periods.dhuhr'.tr(),
            'time': anchors.cycleDhuhr,
          },
          {
            'id': 'asr',
            'name': 'periods.asr'.tr(),
            'time': anchors.cycleAsr,
          },
          {
            'id': 'maghrib',
            'name': 'periods.maghrib'.tr(),
            'time': anchors.cycleEndMaghrib,
          },
        ];

        Map<String, dynamic> nextPrayer = mandatoryPrayers.first;
        int minDiffSecs = 86400 * 2;

        for (final p in candidatePrayers) {
          final DateTime pTime = p['time'] as DateTime;
          final int diffSecs = pTime.difference(liveNow).inSeconds;
          if (diffSecs > 0 && diffSecs < minDiffSecs) {
            minDiffSecs = diffSecs;
            nextPrayer = p;
          }
        }

        int sCount, mCount;
        String topLabel;

        if (settings.useAstroTimeForIbadat) {
          topLabel = 'ibadat.virtual_remaining'.tr();

          final liveAstroState = SuwayaTimeEngine.calculateCurrentState(
            SuwayaDay(
              ibadatTimings: astroState.ibadatTimings,
              civilDayIbadat: astroState.civilDayIbadat,
              cycleAnchors: astroState.cycleAnchors,
              periods: astroState.periods,
            ),
            liveNow,
            nowUtc: DateTime.now().toUtc(),
          );
          final ct = liveAstroState.currentSuwayaTime;
          final int currentGlobalIndex = ct.phase.isNight
              ? (ct.phaseSlotNumber - 1)
              : (12 + ct.phaseSlotNumber - 1);
          final int currentVirtualTotalMins =
              (currentGlobalIndex * 60) + ct.virtualMinute;

          final targetAstro = getFixedAstroTime(
            nextPrayer['id'] as String,
            astroState,
            isEnd: false,
          );
          final int targetVirtualTotalMins =
              (targetAstro.globalIndex * 60) + targetAstro.minute;

          int virtualRemainingMins =
              targetVirtualTotalMins - currentVirtualTotalMins;
          if (virtualRemainingMins <= 0) {
            virtualRemainingMins += 1440;
          }

          sCount = virtualRemainingMins ~/ 60;
          mCount = virtualRemainingMins % 60;
        } else {
          topLabel = 'ibadat.civil_remaining'.tr();
          final int remainingMins = (minDiffSecs / 60).ceil();
          sCount = remainingMins ~/ 60;
          mCount = remainingMins % 60;
        }

        final prayerRowsData = <Map<String, dynamic>>[
          {
            'id': 'fajr',
            'title': 'periods.fajr'.tr(),
            'time': ibadat.fajr,
            'icon': LucideIcons.sunrise,
            'color': const Color(0xFF64B5F6),
            'isNext': nextPrayer['id'] == 'fajr',
          },
          if (settings.showSunrise)
            {
              'id': 'sunrise',
              'title': 'ibadat.sunrise'.tr(),
              'time': ibadat.sunrise,
              'icon': LucideIcons.sun,
              'color': Colors.orangeAccent,
              'isNext': false,
            },
          {
            'id': 'dhuhr',
            'title': 'periods.dhuhr'.tr(),
            'time': ibadat.dhuhr,
            'icon': LucideIcons.sun_dim,
            'color': const Color(0xFFFFCA28),
            'isNext': nextPrayer['id'] == 'dhuhr',
          },
          {
            'id': 'asr',
            'title': 'periods.asr'.tr(),
            'time': ibadat.asr,
            'icon': LucideIcons.cloud_sun,
            'color': const Color(0xFFFF9800),
            'isNext': nextPrayer['id'] == 'asr',
          },
          {
            'id': 'maghrib',
            'title': 'periods.maghrib'.tr(),
            'time': ibadat.maghrib,
            'icon': LucideIcons.sunset,
            'color': const Color(0xFFE53935),
            'isNext': nextPrayer['id'] == 'maghrib',
          },
          {
            'id': 'isha',
            'title': 'prayers.isha'.tr(),
            'time': ibadat.isha,
            'icon': LucideIcons.moon,
            'color': const Color(0xFF1A237E),
            'isNext': nextPrayer['id'] == 'isha',
          },
        ];

        final visibleNightParts = astroState.activeOrUpcomingNightParts
            .where((p) => settings.visibleNightParts.contains(p.id))
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final int totalCards =
                prayerRowsData.length + visibleNightParts.length;
            final bool isCompact =
                constraints.maxHeight < 680 || totalCards >= 8;

            final double cardGap = isCompact ? 4.5 : 6.5;
            final double prayerTitleFontSize = isCompact ? 18.0 : 20.5;
            final double prayerClockFontSize = isCompact ? 17.5 : 19.5;
            final double qiyamTitleFontSize = isCompact ? 16.5 : 18.0;
            final double qiyamClockFontSize = isCompact ? 15.5 : 17.0;

            return Padding(
              padding: EdgeInsets.fromLTRB(16, 2, 16, bottomSafe + 86),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: isCompact ? 10 : 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF1E2530), const Color(0xFF0B0F19)]
                            : [Colors.white, const Color(0xFFE8ECEF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ibadat.next_prayer'.tr(),
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nextPrayer['name'] as String,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: isCompact ? 21.0 : 24.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              topLabel,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Directionality(
                              textDirection: ui.TextDirection.ltr,
                              child: settings.useAstroTimeForIbadat
                                  ? Text(
                                      '- ${sCount.toString().padLeft(2, '0')}|${mCount.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: const Color(0xFFF2C94C),
                                        fontSize: isCompact ? 20.0 : 23.0,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Inter',
                                        letterSpacing: 1.2,
                                      ),
                                    )
                                  : Text(
                                      '- ${sCount.toString().padLeft(2, '0')}:${mCount.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: isCompact ? 20.0 : 23.0,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isCompact ? 5 : 8),
                  _buildSectionTitle('ibadat.prayers_tab'.tr(), context),
                  SizedBox(height: isCompact ? 3 : 5),
                  ...prayerRowsData.map(
                    (p) => Expanded(
                      flex: 10,
                      child: Padding(
                        padding: EdgeInsets.only(bottom: cardGap),
                        child: _buildTimingCard(
                          context: context,
                          ref: ref,
                          astroState: astroState,
                          periodId: p['id'] as String,
                          title: p['title'] as String,
                          time: p['time'] as DateTime,
                          icon: p['icon'] as IconData,
                          rawColor: p['color'] as Color,
                          isNext: p['isNext'] as bool,
                          isDark: isDark,
                          titleFontSize: prayerTitleFontSize,
                          clockFontSize: prayerClockFontSize,
                        ),
                      ),
                    ),
                  ),
                  if (visibleNightParts.isNotEmpty) ...[
                    SizedBox(height: isCompact ? 2 : 5),
                    _buildSectionTitle('ibadat.qiyam_tab'.tr(), context),
                    SizedBox(height: isCompact ? 3 : 5),
                    ...visibleNightParts.map(
                      (part) => Expanded(
                        flex: 10,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: cardGap),
                          child: _buildNightPartCard(
                            context: context,
                            ref: ref,
                            part: part,
                            astroState: astroState,
                            settings: settings,
                            isDark: isDark,
                            titleFontSize: qiyamTitleFontSize,
                            clockFontSize: qiyamClockFontSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimingCard({
    required BuildContext context,
    required WidgetRef ref,
    required AstroState astroState,
    required String periodId,
    required String title,
    required DateTime time,
    required IconData icon,
    required Color rawColor,
    required bool isNext,
    required bool isDark,
    required double titleFontSize,
    required double clockFontSize,
  }) {
    final settings = ref.watch(settingsProvider);
    final alertLevel = settings.getPeriodAlertLevel(periodId);
    final adaptedColor = rawColor.adapt(context);

    IconData bellIcon = LucideIcons.bell_off;
    Color bellColor = isDark ? Colors.white38 : Colors.black38;
    if (alertLevel == 1) {
      bellIcon = LucideIcons.bell;
      bellColor = adaptedColor;
    } else if (alertLevel == 2) {
      bellIcon = LucideIcons.bell_ring;
      bellColor = adaptedColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isNext
            ? rawColor.withValues(alpha: isDark ? 0.15 : 0.08)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNext
              ? adaptedColor.withValues(alpha: 0.55)
              : (isDark ? Colors.white12 : Colors.black12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: isNext ? adaptedColor : rawColor, size: 23),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isNext
                    ? adaptedColor
                    : (isDark ? Colors.white : Colors.black87),
                fontSize: titleFontSize,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _buildClockTime(
            context,
            time,
            astroState,
            settings,
            isDark,
            periodId,
            fontSize: clockFontSize,
            civilColor: isNext ? adaptedColor : null,
          ),
          const SizedBox(width: 10),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              HapticFeedback.mediumImpact();
              _showAlarmChoiceSheet(context, ref, periodId, title, isDark);
            },
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(bellIcon, color: bellColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// 🌟 بطاقة أوقات القيام بخطوط وساعات مكبّرة مع مراعاة اتجاه اللغة (RTL / LTR)
  Widget _buildNightPartCard({
    required BuildContext context,
    required WidgetRef ref,
    required NightPart part,
    required AstroState astroState,
    required SettingsModel settings,
    required bool isDark,
    required double titleFontSize,
    required double clockFontSize,
  }) {
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;
    final pColor = Theme.of(context).primaryColor;
    final alertLevel = settings.getPeriodAlertLevel(part.id);

    IconData bellIcon = LucideIcons.bell_off;
    Color bellColor = isDark ? Colors.white38 : Colors.black38;
    if (alertLevel == 1) {
      bellIcon = LucideIcons.bell;
      bellColor = pColor;
    } else if (alertLevel == 2) {
      bellIcon = LucideIcons.bell_ring;
      bellColor = pColor;
    }

    final partTitle =
        ('night_parts.${part.nameKey.replaceAll("np_", "")}').tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.sparkles, color: pColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              partTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: titleFontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 0,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Directionality(
                textDirection:
                    isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildClockTime(
                      context,
                      part.startTime,
                      astroState,
                      settings,
                      isDark,
                      part.id,
                      fontSize: clockFontSize,
                      isEnd: false,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        isRTL
                            ? LucideIcons.arrow_left
                            : LucideIcons.arrow_right,
                        size: 15,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                    _buildClockTime(
                      context,
                      part.endTime,
                      astroState,
                      settings,
                      isDark,
                      part.id,
                      fontSize: clockFontSize,
                      isEnd: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              HapticFeedback.mediumImpact();
              _showAlarmChoiceSheet(context, ref, part.id, partTitle, isDark);
            },
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Icon(bellIcon, color: bellColor, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 15.0,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  void _showAlarmChoiceSheet(
    BuildContext context,
    WidgetRef ref,
    String periodId,
    String title,
    bool isDark,
  ) {
    final settings = ref.read(settingsProvider);
    final currentLevel = settings.getPeriodAlertLevel(periodId);
    final currentSound =
        settings.getPeriodSound(periodId, 'assets/audio/adhan.mp3');
    final currentVolume = settings.getPeriodVolume(periodId, 1.0);
    final isAr = context.locale.languageCode == 'ar';

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${'ibadat.alert_for'.tr()} $title',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(LucideIcons.bell_off, color: Colors.grey),
                title: Text(isAr ? 'بدون إشعار' : 'No Notification'),
                trailing: currentLevel == 0
                    ? Icon(
                        LucideIcons.circle_check,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
                onTap: () {
                  ref
                      .read(settingsProvider.notifier)
                      .updatePeriodNotificationSettings(
                        periodId: periodId,
                        isEnabled: false,
                        alertLevel: 0,
                        soundPath: currentSound,
                        volume: currentVolume,
                      );
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.bell, color: Colors.blueAccent),
                title: Text(
                  isAr ? 'إشعار على الستارة' : 'Curtain Notification',
                ),
                trailing: currentLevel == 1
                    ? Icon(
                        LucideIcons.circle_check,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
                onTap: () async {
                  final isNotifGranted = await ref
                      .read(permissionsProvider.notifier)
                      .ensureNotificationPermission();
                  await ref
                      .read(permissionsProvider.notifier)
                      .ensureExactAlarmPermission();
                  if (isNotifGranted) {
                    ref
                        .read(settingsProvider.notifier)
                        .updatePeriodNotificationSettings(
                          periodId: periodId,
                          isEnabled: true,
                          alertLevel: 1,
                          soundPath: currentSound,
                          volume: currentVolume,
                        );
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  LucideIcons.bell_ring,
                  color: Colors.orangeAccent,
                ),
                title: Text('ibadat.alarm'.tr()),
                trailing: currentLevel == 2
                    ? Icon(
                        LucideIcons.circle_check,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
                onTap: () async {
                  final isNotifGranted = await ref
                      .read(permissionsProvider.notifier)
                      .ensureNotificationPermission();
                  final isAlarmGranted = await ref
                      .read(permissionsProvider.notifier)
                      .ensureExactAlarmPermission();
                  if (isNotifGranted && isAlarmGranted) {
                    ref
                        .read(settingsProvider.notifier)
                        .updatePeriodNotificationSettings(
                          periodId: periodId,
                          isEnabled: true,
                          alertLevel: 2,
                          soundPath: currentSound,
                          volume: currentVolume,
                        );
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}