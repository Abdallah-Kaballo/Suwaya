import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:suwaya/core/location/location_service.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import 'settings_provider.dart';
import 'widgets/smart_location_picker.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<String, String> _appLanguages = {
    'tr': 'Türkçe', 'ru': 'Русский', 'ur': 'اردو', 'ar': 'العربية', 'hi': 'हिन्दी',
    'bn': 'বাংলা', 'th': 'ไทย', 'ja': '日本語', 'zh': '中文 (简体)', 'ug': 'ئۇيغۇرچە',
    'pt': 'Português', 'ff': 'Pulaar', 'az': 'Azərbaycanca', 'id': 'Bahasa Indonesia',
    'ms': 'Bahasa Melayu', 'da': 'Dansk', 'de': 'Deutsch', 'en': 'English',
    'es': 'Español', 'fr': 'Français', 'it': 'Italiano', 'nl': 'Nederlands',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    
    final currentLang = settingsState.languageCode;
    final currentLangName = _appLanguages[currentLang] ?? 'English';

    final activeLocation = settingsState.activeLocation;
    final cityName = activeLocation?.name ?? 'add_screen.not_set_mandatory'.tr();

    // 🌟 إصلاح الوضع الفاتح (Light Mode): الاعتماد على الثيم الفعلي للنظام
    final isDark = Theme.of(context).brightness == Brightness.dark; 
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final borderColor = Theme.of(context).dividerColor;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(context.locale.languageCode == 'ar' ? LucideIcons.arrow_right : LucideIcons.arrow_left, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text('settings.title'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: textColor, fontSize: 14),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'settings.search_hint'.tr(),
                  hintStyle: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3)),
                  prefixIcon: Icon(LucideIcons.search, color: isDark ? Colors.white54 : Colors.black54, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 60),
              children: [
                _buildSettingsGroup('settings.notifications_alerts'.tr(), [
                  _buildSettingRow(
                    context,
                    icon: LucideIcons.bell_ring, title: 'settings.notifications_alerts'.tr(), subtitle: 'settings.notifications_desc'.tr(), 
                    onTap: () => context.push('/settings/notifications'),
                    isDark: isDark, primaryColor: primaryColor, textColor: textColor
                  ),
                ], isDark, surfaceColor, borderColor, textColor, primaryColor),

                _buildSettingsGroup('settings.advanced_astro'.tr(), [
                  _buildSettingRow(
                    context,
                    icon: LucideIcons.telescope, title: 'settings.astro_settings'.tr(), subtitle: 'settings.astro_desc'.tr(),
                    onTap: () => context.push('/settings/astro'),
                    isDark: isDark, primaryColor: primaryColor, textColor: textColor
                  ),
                ], isDark, surfaceColor, borderColor, textColor, primaryColor),

                _buildSettingsGroup('settings.active_location'.tr(), [
                  _buildSettingRow(
                    context,
                    icon: LucideIcons.map_pin, title: 'settings.active_location'.tr(), subtitle: cityName, 
                    onTap: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => const SmartLocationPicker()),
                    isDark: isDark, primaryColor: primaryColor, textColor: textColor
                  ),
                  _buildGpsUpdateButton(context, ref, isDark, textColor), 
                ], isDark, surfaceColor, borderColor, textColor, primaryColor),

                _buildSettingsGroup('settings.dial_settings'.tr(), [
                  _buildSettingRow(
                    context,
                    icon: LucideIcons.moon_star, title: 'settings.golden_night_markers'.tr(), subtitle: 'settings.markers_desc'.tr(),
                    onTap: () => _showNightMarkersSheet(context, isDark, surfaceColor, textColor, primaryColor),
                    isDark: isDark, primaryColor: primaryColor, textColor: textColor
                  ),
                  _buildSettingRow(
                    context,
                    icon: LucideIcons.refresh_ccw, title: 'settings.auto_rotate'.tr(), subtitle: 'settings.auto_rotate_desc'.tr(), 
                    isToggle: true, toggleValue: settingsState.isDialAutoRotating, 
                    onToggle: (v) => notifier.updateDialAutoRotation(v),
                    isDark: isDark, primaryColor: primaryColor, textColor: textColor 
                  ),
                ], isDark, surfaceColor, borderColor, textColor, primaryColor),

                _buildSettingsGroup('settings.general'.tr(), [
                  _buildSettingRow(
                    context,
                    icon: LucideIcons.languages, title: 'settings.app_language'.tr(), subtitle: currentLangName,
                    onTap: () => _showSelectionSheet('settings.app_language'.tr(), _appLanguages, currentLang, (v){ notifier.updateLanguage(v); context.setLocale(Locale(v)); }, isDark, surfaceColor, textColor, primaryColor),
                    isDark: isDark, primaryColor: primaryColor, textColor: textColor
                  ),
                  _buildSettingRow(
                    context,
                    icon: LucideIcons.shield_alert, 
                    title: 'settings.permissions'.tr(), 
                    subtitle: 'settings.permissions_desc'.tr(),
                    onTap: () => context.push('/settings/permissions'),
                    isDark: isDark, primaryColor: primaryColor, textColor: textColor
                  ),
                ], isDark, surfaceColor, borderColor, textColor, primaryColor),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Text('Suwaya', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 6),
                      Text('settings.version'.tr(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsUpdateButton(BuildContext context, WidgetRef ref, bool isDark, Color textColor) {
    final Color mainColor = textColor;
    final Color iconBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);
    bool isUpdating = false; 

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
                child: const Icon(LucideIcons.crosshair, color: Colors.blueAccent, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('settings.update_gps'.tr(), style: TextStyle(color: mainColor, fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('settings.gps_desc'.tr(), style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.5), fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
              isUpdating 
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      minimumSize: const Size(60, 32),
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final langCode = Localizations.localeOf(context).languageCode;
                      setState(() => isUpdating = true);
                      try {
                        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                        if (!serviceEnabled) {
                          setState(() => isUpdating = false);
                          await Geolocator.openLocationSettings();
                          return; 
                        }
                        final locData = await LocationService.fetchOfflineLocation(langCode);
                        await ref.read(settingsProvider.notifier).addAndSelectLocation(locData['formattedName'], locData['lat'], locData['lng'], locData['countryCode']);
                        await ref.read(settingsProvider.notifier).updateCalculationMethod(locData['method']);
                        await ref.read(settingsProvider.notifier).updateMadhab(locData['madhab']);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${'settings.gps_success'.tr()} ${locData['formattedName']}'), backgroundColor: Colors.green));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('settings.gps_failed'.tr()), backgroundColor: Colors.redAccent));
                        }
                      } finally {
                        if (mounted) setState(() => isUpdating = false);
                      }
                    },
                    child: Text('settings.update'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildSettingsGroup(String label, List<Widget> rows, bool isDark, Color surfaceColor, Color borderColor, Color textColor, Color primaryColor) {
    // 🌟 إصلاح البحث: إخفاء المجموعة فقط إذا كان البحث لا يطابق العنوان
    if (_searchQuery.isNotEmpty && !label.toLowerCase().contains(_searchQuery)) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: Text(label, style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: rows.asMap().entries.map((entry) {
                final int idx = entry.key;
                final Widget row = entry.value;
                if (idx == rows.length - 1) return row;
                return Column(
                  children: [
                    row,
                    Divider(height: 1, thickness: 1, color: borderColor, indent: 56, endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(BuildContext context, {required IconData icon, required String title, String? subtitle, VoidCallback? onTap, bool isToggle = false, bool toggleValue = false, Function(bool)? onToggle, required bool isDark, required Color primaryColor, required Color textColor}) {
    return _SettingRow(context: context, icon: icon, title: title, subtitle: subtitle, onTap: onTap, isToggle: isToggle, toggleValue: toggleValue, onToggle: onToggle, isDark: isDark, primaryColor: primaryColor, textColor: textColor);
  }
  
  void _showNightMarkersSheet(BuildContext context, bool isDark, Color surfaceColor, Color textColor, Color primaryColor) {
    final markers = {
      'np_third_2': 'night_parts.third_2', 'np_sixth_3': 'night_parts.sixth_3',
      'np_half_2': 'night_parts.half_2', 'np_sixth_4': 'night_parts.sixth_4',
      'np_third_3': 'night_parts.third_3', 'np_sixth_5': 'night_parts.sixth_5',
      'np_sixth_6': 'night_parts.sixth_6',
    };
    showModalBottomSheet(
      context: context, backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final liveSettings = ref.watch(settingsProvider);
            final notifier = ref.read(settingsProvider.notifier);
            final active = liveSettings.activeNightMarkers;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text('settings.max_two_markers'.tr(), style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold))),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true, physics: const BouncingScrollPhysics(),
                        children: markers.entries.map((entry) {
                          final isSelected = active.contains(entry.key);
                          return CheckboxListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                            title: Text(entry.value.tr(), style: TextStyle(color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black87), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            value: isSelected,
                            activeColor: primaryColor,
                            checkColor: Colors.white,
                            onChanged: (val) { notifier.toggleNightMarker(entry.key); },
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
      },
    );
  }

  void _showSelectionSheet(String title, Map<String, String> items, String selectedValue, Function(String) onSelected, bool isDark, Color surfaceColor, Color textColor, Color primaryColor) {
    showModalBottomSheet(
      context: context, backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(title, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true, physics: const BouncingScrollPhysics(),
                  children: items.entries.map((entry) {
                    final isSelected = entry.key == selectedValue;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      title: Text(entry.value, style: TextStyle(color: isSelected ? primaryColor : (isDark ? Colors.white70 : Colors.black87), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
                      trailing: isSelected ? Icon(LucideIcons.circle_check, color: primaryColor, size: 20) : null,
                      onTap: () { onSelected(entry.key); Navigator.pop(context); },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isToggle;
  final bool toggleValue;
  final Function(bool)? onToggle;
  final bool isDark;
  final Color primaryColor;
  final Color textColor;

  const _SettingRow({required this.context, required this.icon, required this.title, this.subtitle, this.onTap, this.isToggle = false, this.toggleValue = false, this.onToggle, required this.isDark, required this.primaryColor, required this.textColor});

  @override
  Widget build(BuildContext _) {
    final Color mainColor = textColor;
    final Color baseIconColor = isDark ? Colors.white70 : Colors.black87;
    final Color iconBgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isToggle || onToggle == null && isToggle) ? null : () {
          if (onTap != null) { HapticFeedback.lightImpact(); onTap!(); }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: baseIconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: mainColor, fontSize: 15, fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.5), fontSize: 12, height: 1.4)),
                    ],
                  ],
                ),
              ),
              if (isToggle)
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: toggleValue,
                    onChanged: onToggle,
                    activeThumbColor: isDark ? Colors.black : Colors.white,
                    activeTrackColor: primaryColor,
                    inactiveTrackColor: isDark ? const Color(0xFF2E3745) : Colors.black12,
                    inactiveThumbColor: isDark ? Colors.white70 : Colors.black54,
                  ),
                )
              else 
                // 🌟 السهم ينعكس بناءً على اتجاه لغة التطبيق
                Icon(
                  context.locale.languageCode == 'ar' ? LucideIcons.chevron_left : LucideIcons.chevron_right, 
                  color: isDark ? Colors.white38 : Colors.black38, 
                  size: 18
                ),
            ],
          ),
        ),
      ),
    );
  }
}