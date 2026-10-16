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

/// 🌟 نافذة موحدة للتحكم في إظهار الشروق وأوقات الليل الخمسة (تُفتح من شاشة العبادات ومن الزر أعلى القرص)
void showDialAndIbadatMarkersSheet(BuildContext context, AstroState astroState) {
  HapticFeedback.selectionClick();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  const allowedOrder = ['half_2', 'third_3', 'sixth_4', 'sixth_5', 'sixth_6'];
  final availableNightParts = <NightPart>[];
  for (final id in allowedOrder) {
    final match = astroState.ibadatTimings.nightParts.where((p) => p.id == id);
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
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

                  // 🌟 1. زر إظهار الشروق
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    title: Text(
                      'ibadat.show_sunrise'.tr(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
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

                  // 🌟 2. أوقات الليل الخمسة بنفس تصميم زر الشروق تماماً (SwitchListTile)
                  ...availableNightParts.map((part) {
                    final isSelected =
                        settings.visibleNightParts.contains(part.id);
                    final partTitle =
                        ('night_parts.${part.nameKey.replaceAll("np_", "")}')
                            .tr();

                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        partTitle,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
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

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
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
        style: style.copyWith(color: const Color(0xFFF2C94C)),
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
        style: style.copyWith(color: const Color(0xFFF2C94C)),
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
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(LucideIcons.menu, color: textColor),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          'ibadat.title'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          // 🌟 زر التحويل العالمي بين التوقيت السويعي والتوقيت المدني
          Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(settingsProvider);
              return IconButton(
                icon: Icon(
                  settings.useAstroTimeForIbadat
                      ? LucideIcons.clock
                      : LucideIcons.moon_star,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref
                      .read(settingsProvider.notifier)
                      .updateUseAstroTimeForIbadat(
                        !settings.useAstroTimeForIbadat,
                      );
                },
              );
            },
          ),
          // 🌟 زر فتح النافذة الموحدة للشروق وأوقات الليل
          IconButton(
            icon: Icon(
              LucideIcons.settings_2,
              color: Theme.of(context).primaryColor,
            ),
            onPressed: () =>
                showDialAndIbadatMarkersSheet(context, astroState),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: _buildDashboardBody(context, ref, astroState, isDark),
      ),
    );
  }

  /// 🌟 واجهة متكاملة تعرض جميع العناصر في شاشة واحدة دون الحاجة للتمرير (Scroll)
  Widget _buildDashboardBody(
    BuildContext context,
    WidgetRef ref,
    AstroState astroState,
    bool isDark,
  ) {
    final ibadat = astroState.ibadatTimings;
    final now = astroState.virtualTime;
    final settings = ref.watch(settingsProvider);

    final mandatoryPrayers = [
      {'name': 'periods.fajr'.tr(), 'time': ibadat.fajr},
      {'name': 'periods.dhuhr'.tr(), 'time': ibadat.dhuhr},
      {'name': 'periods.asr'.tr(), 'time': ibadat.asr},
      {'name': 'periods.maghrib'.tr(), 'time': ibadat.maghrib},
      {'name': 'prayers.isha'.tr(), 'time': ibadat.isha},
    ];

    Map<String, dynamic> nextPrayer = mandatoryPrayers.first;
    int minDiff = 1440;
    for (var p in mandatoryPrayers) {
      final DateTime pTime = p['time'] as DateTime;
      int diff = (pTime.hour * 60 + pTime.minute) - (now.hour * 60 + now.minute);
      if (diff <= 0) diff += 1440;
      if (diff < minDiff) {
        minDiff = diff;
        nextPrayer = p;
      }
    }

    final int remainingMins = minDiff;
    int sCount, mCount;
    String topLabel;

    if (settings.useAstroTimeForIbadat) {
      topLabel = 'ibadat.virtual_remaining'.tr();
      final int virtualRemaining =
          (remainingMins * astroState.timeSpeedMultiplier).round();
      sCount = virtualRemaining ~/ 60;
      mCount = virtualRemaining % 60;
    } else {
      topLabel = 'ibadat.civil_remaining'.tr();
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
        'isNext': nextPrayer['time'] == ibadat.fajr,
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
        'isNext': nextPrayer['time'] == ibadat.dhuhr,
      },
      {
        'id': 'asr',
        'title': 'periods.asr'.tr(),
        'time': ibadat.asr,
        'icon': LucideIcons.cloud_sun,
        'color': const Color(0xFFFF9800),
        'isNext': nextPrayer['time'] == ibadat.asr,
      },
      {
        'id': 'maghrib',
        'title': 'periods.maghrib'.tr(),
        'time': ibadat.maghrib,
        'icon': LucideIcons.sunset,
        'color': const Color(0xFFE53935),
        'isNext': nextPrayer['time'] == ibadat.maghrib,
      },
      {
        'id': 'isha',
        'title': 'prayers.isha'.tr(),
        'time': ibadat.isha,
        'icon': LucideIcons.moon,
        'color': const Color(0xFF1A237E),
        'isNext': nextPrayer['time'] == ibadat.isha,
      },
    ];

    final visibleNightParts = ibadat.nightParts
        .where((p) => settings.visibleNightParts.contains(p.id))
        .toList();

    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return LayoutBuilder(
      builder: (context, constraints) {
        // حساب الكثافة الرأسية لضمان ظهور كل البطاقات في شاشة واحدة بدون تمرير
        final int totalCards =
            prayerRowsData.length + visibleNightParts.length;
        final bool isCompact =
            constraints.maxHeight < 680 || totalCards >= 8;

        final double cardGap = isCompact ? 5.0 : 7.0;
        final double prayerTitleFontSize = isCompact ? 15.0 : 16.5;
        final double prayerClockFontSize = isCompact ? 14.5 : 16.0;
        final double qiyamTitleFontSize = isCompact ? 13.5 : 15.0;
        final double qiyamClockFontSize = isCompact ? 13.0 : 14.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, bottomSafe + 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🌟 1. بطاقة الصلاة القادمة المدمجة
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isCompact ? 10 : 13,
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
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nextPrayer['name'] as String,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: isCompact ? 18 : 20,
                            fontWeight: FontWeight.bold,
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
                            fontSize: 10.5,
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
                                    fontSize: isCompact ? 17 : 19,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                    letterSpacing: 1.0,
                                  ),
                                )
                              : Text(
                                  '- ${sCount.toString().padLeft(2, '0')}:${mCount.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                    fontSize: isCompact ? 17 : 19,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: isCompact ? 6 : 10),
              _buildSectionTitle('ibadat.prayers_tab'.tr(), context),
              SizedBox(height: isCompact ? 4 : 6),

              // 🌟 2. قائمة الصلوات (تتمدد بتوازن داخل المساحة المتاحة)
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

              // 🌟 3. قسم قيام الليل (يظهر في نفس الشاشة دون الحاجة للتمرير)
              if (visibleNightParts.isNotEmpty) ...[
                SizedBox(height: isCompact ? 2 : 6),
                _buildSectionTitle('ibadat.qiyam_tab'.tr(), context),
                SizedBox(height: isCompact ? 4 : 6),
                ...visibleNightParts.map(
                  (part) => Expanded(
                    flex: 11,
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
  }

  /// 🌟 بطاقة الصلوات بحجم خطوط متناسق ومريح للعين
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
          Icon(icon, color: isNext ? adaptedColor : rawColor, size: 20),
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
                fontWeight: FontWeight.w800,
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
              child: Icon(bellIcon, color: bellColor, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  /// 🌟 بطاقة أوقات القيام مع مراعاة اتجاه اللغة (RTL: البداية يمين <- النهاية يسار | LTR: البداية يسار -> النهاية يمين)
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
          Icon(LucideIcons.sparkles, color: pColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              partTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 🌟 نطاق الوقت يحترم اتجاه اللغة تلقائياً:
          // في RTL (العربية): [وقت البداية (يمين)]  ←  [وقت النهاية (يسار)]
          // في LTR (الإنجليزية): [Start Time (left)]  →  [End Time (right)]
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
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(
                        isRTL
                            ? LucideIcons.arrow_left
                            : LucideIcons.arrow_right,
                        size: 13,
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
              child: Icon(bellIcon, color: bellColor, size: 18),
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
          fontSize: 13,
          fontWeight: FontWeight.bold,
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
                title: Text('ibadat.silent'.tr()),
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
                title: Text('ibadat.notification'.tr()),
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