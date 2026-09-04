import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../../core/astro_engine/astro_provider.dart';
import '../../core/astro_engine/astro_models.dart';
import '../settings/settings_provider.dart';
import '../../core/services/permissions_provider.dart';

class IbadatScreen extends ConsumerWidget {
  const IbadatScreen({super.key});

  String _getDisplayTime(DateTime targetTime, AstroState astroState, bool useAstro) {
    // تم إضافة 'en' لإجبار مكتبة intl على استخدام الأرقام الإنجليزية (0-9) دائماً
    if (!useAstro) return DateFormat('HH:mm', 'en').format(targetTime);

    if (astroState.periods.isEmpty) return "00:00";
    double totalVirtualMinutes = 0.0;
    
    for (var p in astroState.periods) {
      if (targetTime.isAfter(p.endTime) || targetTime.isAtSameMomentAs(p.endTime)) {
        totalVirtualMinutes += p.suwayasCount * 30.0;
      } else if ((targetTime.isAfter(p.startTime) || targetTime.isAtSameMomentAs(p.startTime)) && targetTime.isBefore(p.endTime)) {
        final totalMicro = p.endTime.difference(p.startTime).inMicroseconds;
        final elapsedMicro = targetTime.difference(p.startTime).inMicroseconds;
        final progress = totalMicro > 0 ? (elapsedMicro / totalMicro) : 0.0;
        totalVirtualMinutes += progress * (p.suwayasCount * 30.0);
        break;
      }
    }
    
    int totalMins = totalVirtualMinutes.round();
    int s = totalMins ~/ 30; 
    int m = totalMins % 30;  
    
    if (s >= 48) { s = 0; m = 0; }
    return '${s.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final astroState = ref.watch(astroProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (astroState.periods.isEmpty) {
      return Scaffold(backgroundColor: scaffoldBgColor, body: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent, elevation: 0,
          title: Text('ibadat.title'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)), centerTitle: true,
          bottom: TabBar(
            indicatorColor: Theme.of(context).primaryColor, 
            labelColor: Theme.of(context).primaryColor, 
            unselectedLabelColor: isDark ? Colors.white70 : Colors.black54, 
            dividerColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
            tabs: [
              Tab(text: 'ibadat.prayers_tab'.tr(), icon: const Icon(LucideIcons.moon_star)),
              Tab(text: 'ibadat.qiyam_tab'.tr(), icon: const Icon(LucideIcons.sparkles)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPrayersTab(context, ref, astroState, isDark),
            _buildQiyamTab(context, ref, astroState, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayersTab(BuildContext context, WidgetRef ref, AstroState astroState, bool isDark) {
    final ibadat = astroState.ibadatTimings;
    final now = astroState.virtualTime;
    final settings = ref.watch(settingsProvider);

    final prayers = [
      {'name': 'periods.fajr'.tr(), 'time': ibadat.fajr},
      {'name': 'ibadat.sunrise'.tr(), 'time': ibadat.sunrise},
      {'name': 'periods.dhuhr'.tr(), 'time': ibadat.dhuhr},
      {'name': 'periods.asr'.tr(), 'time': ibadat.asr},
      {'name': 'periods.maghrib'.tr(), 'time': ibadat.maghrib},
      // تم تصحيح المفتاح هنا من periods.isha إلى prayers.isha
      {'name': 'prayers.isha'.tr(), 'time': ibadat.isha},
      {'name': 'ibadat.next_fajr'.tr(), 'time': ibadat.nextFajr},
    ];

    final nextPrayer = prayers.firstWhere((p) => (p['time'] as DateTime).isAfter(now), orElse: () => prayers.last);
    
    int sCount, mCount;
    String topLabel;
    
    if (settings.useAstroTimeForIbadat) {
      topLabel = 'ibadat.virtual_remaining'.tr();
      int nowVirtualMins = _getVirtualMinutesHelper(now, astroState);
      int nextVirtualMins = _getVirtualMinutesHelper(nextPrayer['time'] as DateTime, astroState);
      if (nextVirtualMins <= nowVirtualMins) nextVirtualMins = 1440; 
      int remainingMins = nextVirtualMins - nowVirtualMins;
      sCount = remainingMins ~/ 30;
      mCount = remainingMins % 30;
    } else {
      topLabel = 'ibadat.civil_remaining'.tr();
      int remainingMins = (nextPrayer['time'] as DateTime).difference(now).inMinutes;
      if (remainingMins < 0) remainingMins += 1440;
      sCount = remainingMins ~/ 60;
      mCount = remainingMins % 60;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20), margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark ? [const Color(0xFF1E2530), const Color(0xFF0B0F19)] : [Colors.white, const Color(0xFFE8ECEF)],
              begin: Alignment.topLeft, end: Alignment.bottomRight
            ), 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            boxShadow: [BoxShadow(color: isDark ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05), blurRadius: 20)]
          ),
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
                  Directionality(textDirection: ui.TextDirection.ltr, child: Text('- ${sCount.toString().padLeft(2, '0')}:${mCount.toString().padLeft(2, '0')}', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
                ],
              ),
            ],
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('ibadat.prayers_tab'.tr(), context),
            IconButton(
              icon: Icon(LucideIcons.settings_2, color: Theme.of(context).primaryColor, size: 20),
              onPressed: () => _showPrayerSettingsSheet(context, ref, isDark),
            )
          ],
        ),

        _buildTimingCard(context, ref, astroState, '1', 'periods.fajr'.tr(), ibadat.fajr, LucideIcons.sunrise, const Color(0xFF64B5F6), nextPrayer['time'] == ibadat.fajr, isDark),
        if (settings.showSunrise)
          _buildTimingCard(context, ref, astroState, 'sunrise', 'ibadat.sunrise'.tr(), ibadat.sunrise, LucideIcons.sun, Colors.orangeAccent, nextPrayer['time'] == ibadat.sunrise, isDark),
        _buildTimingCard(context, ref, astroState, '3', 'periods.dhuhr'.tr(), ibadat.dhuhr, LucideIcons.sun_dim, const Color(0xFFFFCA28), nextPrayer['time'] == ibadat.dhuhr, isDark),
        _buildTimingCard(context, ref, astroState, '4', 'periods.asr'.tr(), ibadat.asr, LucideIcons.cloud_sun, const Color(0xFFFF9800), nextPrayer['time'] == ibadat.asr, isDark),
        _buildTimingCard(context, ref, astroState, '5', 'periods.maghrib'.tr(), ibadat.maghrib, LucideIcons.sunset, const Color(0xFFE53935), nextPrayer['time'] == ibadat.maghrib, isDark),
        _buildTimingCard(context, ref, astroState, 'isha', 'prayers.isha'.tr(), ibadat.isha, LucideIcons.moon, const Color(0xFF1A237E), nextPrayer['time'] == ibadat.isha, isDark),
      ],
    );
  }

  Widget _buildQiyamTab(BuildContext context, WidgetRef ref, AstroState astroState, bool isDark) {
    final ibadat = astroState.ibadatTimings;
    final settings = ref.watch(settingsProvider);
    final visibleNightParts = settings.visibleNightParts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('ibadat.qiyam_tab'.tr(), context),
            IconButton(
              icon: Icon(LucideIcons.settings_2, color: Theme.of(context).primaryColor, size: 20),
              onPressed: () => _showNightPrefsSheet(context, ref, ibadat.nightParts, isDark),
            )
          ],
        ),
        
        if (visibleNightParts.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('ibadat.no_qiyam'.tr(), textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
            ),
          ),

        ...ibadat.nightParts.where((p) => visibleNightParts.contains(p.id)).map((part) {
          final isPeak = ['sixth_4', 'sixth_5', 'third_3'].contains(part.id);
          
          final alertLevel = settings.getPeriodAlertLevel(part.id);
          IconData bellIcon = LucideIcons.bell_off;
          Color bellColor = isDark ? Colors.white38 : Colors.black38;
          if (alertLevel == 1) { bellIcon = LucideIcons.bell; bellColor = Theme.of(context).primaryColor; }
          if (alertLevel == 2) { bellIcon = LucideIcons.bell_ring; bellColor = Theme.of(context).primaryColor; }
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: isPeak ? [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.05), blurRadius: 15, spreadRadius: 1)] : null,
              border: Border.all(color: isPeak ? Theme.of(context).primaryColor.withValues(alpha: 0.4) : (isDark ? Colors.white12 : Colors.black12), width: isPeak ? 1.5 : 1),
            ),
            child: Material(
              color: isPeak ? (isDark ? const Color(0xFF1E2530) : Colors.white) : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias, 
              child: Theme(
                data: ThemeData().copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: isPeak, 
                  iconColor: isPeak ? Theme.of(context).primaryColor : (isDark ? Colors.white70 : Colors.black54),
                  collapsedIconColor: isPeak ? Theme.of(context).primaryColor : (isDark ? Colors.white70 : Colors.black54),
                  title: Row(
                    children: [
                      Icon(isPeak ? LucideIcons.sparkles : LucideIcons.moon, color: isPeak ? Theme.of(context).primaryColor : Colors.purpleAccent, size: 18), 
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(('night_parts.${part.nameKey.replaceAll("np_", "")}').tr(), style: TextStyle(color: isPeak ? Theme.of(context).primaryColor : (isDark ? Colors.white : Colors.black87), fontSize: 16, fontWeight: isPeak ? FontWeight.bold : FontWeight.w600)),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _showAlarmChoiceSheet(context, ref, part.id, ('night_parts.${part.nameKey.replaceAll("np_", "")}').tr(), isDark);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Icon(bellIcon, color: bellColor, size: 20),
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFF9FAFB),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isPeak) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text('ibadat.peak_time'.tr(), style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ibadat.starts_at'.tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
                              Directionality(textDirection: ui.TextDirection.ltr, child: Text(_getDisplayTime(part.startTime, astroState, settings.useAstroTimeForIbadat), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'monospace'))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ibadat.ends_at'.tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
                              Directionality(textDirection: ui.TextDirection.ltr, child: Text(_getDisplayTime(part.endTime, astroState, settings.useAstroTimeForIbadat), style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontFamily: 'monospace'))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTimingCard(BuildContext context, WidgetRef ref, AstroState astroState, String periodId, String title, DateTime time, IconData icon, Color rawColor, bool isNext, bool isDark) {
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isNext ? adaptedColor.withValues(alpha: 0.5) : (isDark ? Colors.white12 : Colors.black12), width: 1)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: isNext ? adaptedColor : rawColor),
        title: Text(title, style: TextStyle(color: isNext ? activeTextColor : (isDark ? Colors.white : Colors.black87), fontSize: 16, fontWeight: isNext ? FontWeight.bold : FontWeight.normal)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(textDirection: ui.TextDirection.ltr, child: Text(_getDisplayTime(time, astroState, settings.useAstroTimeForIbadat), style: TextStyle(color: isNext ? activeTextColor : (isDark ? Colors.white : Colors.black87), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showAlarmChoiceSheet(context, ref, periodId, title, isDark);
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(bellIcon, color: bellColor, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 8, left: 8), 
      child: Text(title, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16, fontWeight: FontWeight.bold))
    );
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

  void _showPrayerSettingsSheet(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(settingsProvider);
            final notifier = ref.read(settingsProvider.notifier);
            final accentColor = Theme.of(context).primaryColor;
            
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ibadat.customize_prayers'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(value: true, label: Text('ibadat.astro_time'.tr()), icon: const Icon(LucideIcons.moon_star)),
                          ButtonSegment(value: false, label: Text('ibadat.civil_time'.tr()), icon: const Icon(LucideIcons.clock)),
                        ],
                        selected: {settings.useAstroTimeForIbadat},
                        onSelectionChanged: (set) => notifier.updateUseAstroTimeForIbadat(set.first),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor.withValues(alpha: 0.2) : Colors.transparent), 
                          foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor : (isDark ? Colors.white54 : Colors.black54)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: Text('ibadat.show_sunrise'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('ibadat.show_sunrise_desc'.tr()),
                      value: settings.showSunrise,
                      activeThumbColor: accentColor,
                      onChanged: (val) => notifier.updateShowSunrise(val),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  void _showNightPrefsSheet(BuildContext context, WidgetRef ref, List<NightPart> parts, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(settingsProvider);
            final notifier = ref.read(settingsProvider.notifier);
            final accentColor = Theme.of(context).primaryColor;
            
            return SafeArea(
              child: Container(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ibadat.customize_qiyam'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: [
                          ButtonSegment(value: true, label: Text('ibadat.astro_time'.tr()), icon: const Icon(LucideIcons.moon_star)),
                          ButtonSegment(value: false, label: Text('ibadat.civil_time'.tr()), icon: const Icon(LucideIcons.clock)),
                        ],
                        selected: {settings.useAstroTimeForIbadat},
                        onSelectionChanged: (set) => notifier.updateUseAstroTimeForIbadat(set.first),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor.withValues(alpha: 0.2) : Colors.transparent), 
                          foregroundColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accentColor : (isDark ? Colors.white54 : Colors.black54)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: parts.map((part) {
                          final isSelected = settings.visibleNightParts.contains(part.id);
                          return CheckboxListTile(
                            title: Text(('night_parts.${part.nameKey.replaceAll("np_", "")}').tr(), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            value: isSelected,
                            activeColor: accentColor,
                            onChanged: (val) => notifier.toggleVisibleNightPart(part.id),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  int _getVirtualMinutesHelper(DateTime targetTime, AstroState astroState) {
    if (astroState.periods.isEmpty) return 0;
    double totalVirtualMinutes = 0.0;
    for (var p in astroState.periods) {
      if (targetTime.isAfter(p.endTime) || targetTime.isAtSameMomentAs(p.endTime)) {
        totalVirtualMinutes += p.suwayasCount * 30.0;
      } else if ((targetTime.isAfter(p.startTime) || targetTime.isAtSameMomentAs(p.startTime)) && targetTime.isBefore(p.endTime)) {
        final totalMicro = p.endTime.difference(p.startTime).inMicroseconds;
        final elapsedMicro = targetTime.difference(p.startTime).inMicroseconds;
        final progress = totalMicro > 0 ? (elapsedMicro / totalMicro) : 0.0;
        totalVirtualMinutes += progress * (p.suwayasCount * 30.0);
        break;
      }
    }
    return totalVirtualMinutes.round();
  }
}