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

class IbadatScreen extends ConsumerWidget {
  const IbadatScreen({super.key});

  Widget _buildClockTime(BuildContext context, DateTime targetTime,
      AstroState astroState, SettingsModel settings, bool isDark, String identifier,
      {double fontSize = 16, Color? civilColor, bool isEnd = false}) {
    final useAstro = settings.useAstroTimeForIbadat;
    final style = TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, fontFamily: 'Inter');
    final isRTL = Directionality.of(context) == ui.TextDirection.rtl;

    if (!useAstro) {
      return Directionality(
        textDirection: ui.TextDirection.ltr,
        child: Text(
          formatCivilTime(targetTime, format: settings.civilTimeFormat, locale: context.locale.languageCode, context: context),
          style: style.copyWith(color: civilColor ?? (isDark ? Colors.white : Colors.black87)),
        ),
      );
    }

    if (astroState.periods.isEmpty) return Text('00|00', style: style.copyWith(color: const Color(0xFFF2C94C)));

    final fixedTime = getFixedAstroTime(identifier, astroState, isEnd: isEnd);
    final formattedTime = formatSuwayaTime(fixedTime.globalIndex, fixedTime.minute, separator: '|', isRTL: isRTL, iconMode: settings.suwayaIconMode);

    return Directionality(textDirection: ui.TextDirection.ltr, child: Text(formattedTime, style: style.copyWith(color: const Color(0xFFF2C94C))));
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
                onPressed: () => ref.read(astroProvider.notifier).resetToRealTime(),
                icon: const Icon(Icons.refresh),
                label: Text('common.retry'.tr()),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
              )
            ],
          )));
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      // 🌟 تفعيل إيماءة السحب بوضوح
      drawerEnableOpenDragGesture: true,
      // 🌟 زيادة مساحة استشعار السحب من الحافة لتكون 15% من عرض الشاشة
      drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.15,
      
      drawer: const AppDrawer(),
      onDrawerChanged: (isOpen) => ref.read(isDrawerOpenProvider.notifier).state = isOpen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(icon: Icon(LucideIcons.menu, color: textColor), onPressed: () => Scaffold.of(ctx).openDrawer()),
        ),
        title: Text('ibadat.title'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
        centerTitle: true,
        actions: [
          // 🌟 زر التحويل العالمي بين السويعي والمدني
          Consumer(builder: (context, ref, _) {
            final settings = ref.watch(settingsProvider);
            return IconButton(
              icon: Icon(
                settings.useAstroTimeForIbadat ? LucideIcons.clock : LucideIcons.moon_star,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(settingsProvider.notifier).updateUseAstroTimeForIbadat(!settings.useAstroTimeForIbadat);
              },
            );
          }),
          // زر الإعدادات الموجود مسبقاً
          IconButton(
            icon: Icon(LucideIcons.settings_2, color: Theme.of(context).primaryColor),
            onPressed: () => _showCombinedSettingsSheet(context, ref, astroState, isDark),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildCombinedList(context, ref, astroState, isDark),
    );
  }

  Widget _buildCombinedList(BuildContext context, WidgetRef ref, AstroState astroState, bool isDark) {
    final ibadat = astroState.ibadatTimings;
    final now = astroState.virtualTime;
    final settings = ref.watch(settingsProvider);

    final prayers = [
      {'name': 'periods.fajr'.tr(), 'time': ibadat.fajr},
      {'name': 'periods.dhuhr'.tr(), 'time': ibadat.dhuhr},
      {'name': 'periods.asr'.tr(), 'time': ibadat.asr},
      {'name': 'periods.maghrib'.tr(), 'time': ibadat.maghrib},
      {'name': 'prayers.isha'.tr(), 'time': ibadat.isha},
    ];

    Map<String, dynamic> nextPrayer = prayers.first;
    int minDiff = 1440; 
    for (var p in prayers) {
      DateTime pTime = p['time'] as DateTime;
      int diff = (pTime.hour * 60 + pTime.minute) - (now.hour * 60 + now.minute);
      if (diff <= 0) diff += 1440; 
      if (diff < minDiff) {
        minDiff = diff;
        nextPrayer = p;
      }
    }

    int remainingMins = minDiff; 
    int sCount, mCount;
    String topLabel;
 
    if (settings.useAstroTimeForIbadat) {
      topLabel = 'ibadat.virtual_remaining'.tr();
      int virtualRemaining = (remainingMins * astroState.timeSpeedMultiplier).round();
      sCount = virtualRemaining ~/ 60;
      mCount = virtualRemaining % 60;
    } else {
      topLabel = 'ibadat.civil_remaining'.tr();
      sCount = remainingMins ~/ 60;
      mCount = remainingMins % 60;
    }

    // جلب أجزاء الليل المفعلة فقط
    final visibleNightParts = ibadat.nightParts.where((p) => settings.visibleNightParts.contains(p.id)).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // 🌟 كارت الصلاة القادمة
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: isDark ? [const Color(0xFF1E2530), const Color(0xFF0B0F19)] : [Colors.white, const Color(0xFFE8ECEF)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              boxShadow: [BoxShadow(color: isDark ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05), blurRadius: 20)]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ibadat.next_prayer'.tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(nextPrayer['name'] as String, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(topLabel, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 11)),
                  const SizedBox(height: 4),
                  Directionality(
                    textDirection: ui.TextDirection.ltr,
                    child: settings.useAstroTimeForIbadat
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('- ', style: TextStyle(color: Color(0xFFF2C94C), fontSize: 22, fontFamily: 'Playfair Display')),
                              Text('${sCount.toString().padLeft(2, '0')}|${mCount.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: Color(0xFFF2C94C), fontSize: 22, fontWeight: FontWeight.normal, fontFamily: 'Playfair Display', letterSpacing: 1.5)),
                            ],
                          )
                        : Text('- ${sCount.toString().padLeft(2, '0')}:${mCount.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.normal, fontFamily: 'Inter')),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        _buildSectionTitle('ibadat.prayers_tab'.tr(), context),
        _buildTimingCard(context, ref, astroState, 'fajr', 'periods.fajr'.tr(), ibadat.fajr, LucideIcons.sunrise, const Color(0xFF64B5F6), nextPrayer['time'] == ibadat.fajr, isDark),
        if (settings.showSunrise)
          _buildTimingCard(context, ref, astroState, 'sunrise', 'ibadat.sunrise'.tr(), ibadat.sunrise, LucideIcons.sun, Colors.orangeAccent, nextPrayer['time'] == ibadat.sunrise, isDark),
        _buildTimingCard(context, ref, astroState, 'dhuhr', 'periods.dhuhr'.tr(), ibadat.dhuhr, LucideIcons.sun_dim, const Color(0xFFFFCA28), nextPrayer['time'] == ibadat.dhuhr, isDark),
        _buildTimingCard(context, ref, astroState, 'asr', 'periods.asr'.tr(), ibadat.asr, LucideIcons.cloud_sun, const Color(0xFFFF9800), nextPrayer['time'] == ibadat.asr, isDark),
        _buildTimingCard(context, ref, astroState, 'maghrib', 'periods.maghrib'.tr(), ibadat.maghrib, LucideIcons.sunset, const Color(0xFFE53935), nextPrayer['time'] == ibadat.maghrib, isDark),
        _buildTimingCard(context, ref, astroState, 'isha', 'prayers.isha'.tr(), ibadat.isha, LucideIcons.moon, const Color(0xFF1A237E), nextPrayer['time'] == ibadat.isha, isDark),

        // 🌟 إضافة قسم القيام بتصميمه الجديد المبسط
        if (visibleNightParts.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionTitle('ibadat.qiyam_tab'.tr(), context),
          ...visibleNightParts.map((part) => _buildSimpleNightPartRow(context, ref, part, astroState, settings, isDark))
        ],
      ],
    );
  }

  // 🌟 التصميم الأنيق والبسيط لفترات الليل
  Widget _buildSimpleNightPartRow(BuildContext context, WidgetRef ref, NightPart part, AstroState astroState, SettingsModel settings, bool isDark) {
    final alertLevel = settings.getPeriodAlertLevel(part.id);
    IconData bellIcon = LucideIcons.bell_off;
    Color bellColor = isDark ? Colors.white38 : Colors.black38;
    if (alertLevel == 1) { bellIcon = LucideIcons.bell; bellColor = Theme.of(context).primaryColor; }
    if (alertLevel == 2) { bellIcon = LucideIcons.bell_ring; bellColor = Theme.of(context).primaryColor; }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1D24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.sparkles, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(('night_parts.${part.nameKey.replaceAll("np_", "")}').tr(),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Row(
                    children: [
                      _buildClockTime(context, part.startTime, astroState, settings, isDark, part.id, fontSize: 14, isEnd: false),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                      ),
                      _buildClockTime(context, part.endTime, astroState, settings, isDark, part.id, fontSize: 14, isEnd: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(bellIcon, color: bellColor, size: 22),
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showAlarmChoiceSheet(context, ref, part.id, ('night_parts.${part.nameKey.replaceAll("np_", "")}').tr(), isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimingCard(
      BuildContext context, WidgetRef ref, AstroState astroState, String periodId, String title, DateTime time, IconData icon, Color rawColor, bool isNext, bool isDark) {
    final settings = ref.watch(settingsProvider);
    final alertLevel = settings.getPeriodAlertLevel(periodId);
    final adaptedColor = rawColor.adapt(context);
    final activeTextColor = isDark ? adaptedColor : adaptedColor;

    IconData bellIcon = LucideIcons.bell_off;
    Color bellColor = isDark ? Colors.white38 : Colors.black38;
    if (alertLevel == 1) { bellIcon = LucideIcons.bell; bellColor = adaptedColor; }
    if (alertLevel == 2) { bellIcon = LucideIcons.bell_ring; bellColor = adaptedColor; }

    return Card(
      elevation: 0,
      color: isNext ? rawColor.withValues(alpha: isDark ? 0.15 : 0.08) : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isNext ? adaptedColor.withValues(alpha: 0.5) : (isDark ? Colors.white12 : Colors.black12), width: 1)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: isNext ? adaptedColor : rawColor, size: 30), 
        title: Text(title,
            style: TextStyle(color: isNext ? activeTextColor : (isDark ? Colors.white : Colors.black87), fontSize: 22, fontWeight: FontWeight.w900)), 
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildClockTime(context, time, astroState, settings, isDark, periodId, fontSize: 20, civilColor: isNext ? activeTextColor : null),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showAlarmChoiceSheet(context, ref, periodId, title, isDark);
              },
              child: Padding(padding: const EdgeInsets.all(8.0), child: Icon(bellIcon, color: bellColor, size: 20)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 8, left: 8, top: 8),
        child: Text(title, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16, fontWeight: FontWeight.bold)));
  }

  // 🌟 النافذة المنبثقة المحدثة والشاملة (بدون زر التبديل مدني/سويعي)
  void _showCombinedSettingsSheet(BuildContext context, WidgetRef ref, AstroState astroState, bool isDark) {
    final availableNightParts = [
      if (astroState.ibadatTimings.nightParts.any((p) => p.id == 'half_2')) astroState.ibadatTimings.nightParts.firstWhere((p) => p.id == 'half_2'),
      if (astroState.ibadatTimings.nightParts.any((p) => p.id == 'third_3')) astroState.ibadatTimings.nightParts.firstWhere((p) => p.id == 'third_3'),
      if (astroState.ibadatTimings.nightParts.any((p) => p.id == 'sixth_4')) astroState.ibadatTimings.nightParts.firstWhere((p) => p.id == 'sixth_4'),
      if (astroState.ibadatTimings.nightParts.any((p) => p.id == 'sixth_5')) astroState.ibadatTimings.nightParts.firstWhere((p) => p.id == 'sixth_5'),
      if (astroState.ibadatTimings.nightParts.any((p) => p.id == 'sixth_6')) astroState.ibadatTimings.nightParts.firstWhere((p) => p.id == 'sixth_6'),
    ];

    showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).cardColor,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return Consumer(builder: (context, ref, _) {
            final settings = ref.watch(settingsProvider);
            final notifier = ref.read(settingsProvider.notifier);
            final pColor = Theme.of(context).primaryColor;

            return SafeArea(
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Text('home.dial_markers_settings'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
                    const SizedBox(height: 24),
                    
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('ibadat.show_sunrise'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      value: settings.showSunrise,
                      activeThumbColor: pColor,
                      secondary: const Icon(LucideIcons.sun, color: Colors.orangeAccent),
                      onChanged: (val) => notifier.updateShowSunrise(val),
                    ),
                    const Divider(height: 24),
                    
                    Text('ibadat.qiyam_tab'.tr(), style: TextStyle(color: pColor, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: availableNightParts.map((part) {
                          final isSelected = settings.visibleNightParts.contains(part.id);
                          return CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(('night_parts.${part.nameKey.replaceAll("np_", "")}').tr(),
                                style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            value: isSelected,
                            activeColor: pColor,
                            secondary: Icon(LucideIcons.sparkles, color: isSelected ? pColor : Colors.grey),
                            onChanged: (val) => notifier.toggleVisibleNightPart(part.id), // الدالة في المزود تعالج التعارض بذكاء
                          );
                        }).toList(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: pColor),
                        onPressed: () => Navigator.pop(context),
                        child: Text('common.done'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }

  void _showAlarmChoiceSheet(BuildContext context, WidgetRef ref, String periodId, String title, bool isDark) {
    final settings = ref.read(settingsProvider);
    final currentLevel = settings.getPeriodAlertLevel(periodId);
    final currentSound = settings.getPeriodSound(periodId, 'assets/audio/adhan.mp3');
    final currentVolume = settings.getPeriodVolume(periodId, 1.0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${'ibadat.alert_for'.tr()} $title', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(LucideIcons.bell_off, color: Colors.grey),
                title: Text('ibadat.silent'.tr()),
                trailing: currentLevel == 0 ? Icon(LucideIcons.circle_check, color: Theme.of(context).primaryColor) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).updatePeriodNotificationSettings(periodId: periodId, isEnabled: false, alertLevel: 0, soundPath: currentSound, volume: currentVolume);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.bell, color: Colors.blueAccent),
                title: Text('ibadat.notification'.tr()),
                trailing: currentLevel == 1 ? Icon(LucideIcons.circle_check, color: Theme.of(context).primaryColor) : null,
                onTap: () async {
                  final isNotifGranted = await ref.read(permissionsProvider.notifier).ensureNotificationPermission();
                  if (isNotifGranted) {
                    ref.read(settingsProvider.notifier).updatePeriodNotificationSettings(periodId: periodId, isEnabled: true, alertLevel: 1, soundPath: currentSound, volume: currentVolume);
                  }
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.bell_ring, color: Colors.orangeAccent),
                title: Text('ibadat.alarm'.tr()),
                trailing: currentLevel == 2 ? Icon(LucideIcons.circle_check, color: Theme.of(context).primaryColor) : null,
                onTap: () async {
                  final isNotifGranted = await ref.read(permissionsProvider.notifier).ensureNotificationPermission();
                  final isAlarmGranted = await ref.read(permissionsProvider.notifier).ensureExactAlarmPermission();
                  if (isNotifGranted && isAlarmGranted) {
                    ref.read(settingsProvider.notifier).updatePeriodNotificationSettings(periodId: periodId, isEnabled: true, alertLevel: 2, soundPath: currentSound, volume: currentVolume);
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