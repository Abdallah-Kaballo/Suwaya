import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:suwaya/core/location/location_service.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:suwaya/core/notification/notification_service.dart';
import 'package:suwaya/core/theme/app_theme.dart';
import 'package:suwaya/core/theme/dial_design_provider.dart';
import 'package:suwaya/core/theme/theme_color_provider.dart';

import 'settings_provider.dart';
import 'widgets/smart_location_picker.dart';
import '../../core/utils/time_formatters.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final Map<String, String> _appLanguages = {
    'tr': 'Türkçe',
    'ru': 'Русский',
    'ur': 'اردو',
    'ar': 'العربية',
    'hi': 'हिन्दी',
    'bn': 'বাংলা',
    'th': 'ไทย',
    'ja': '日本語',
    'zh': '中文 (简体)',
    'ug': 'ئۇيغۇرچە',
    'pt': 'Português',
    'ff': 'Pulaar',
    'az': 'Azərbaycanca',
    'id': 'Bahasa Indonesia',
    'ms': 'Bahasa Melayu',
    'da': 'Dansk',
    'de': 'Deutsch',
    'en': 'English',
    'es': 'Español',
    'fr': 'Français',
    'it': 'Italiano',
    'nl': 'Nederlands',
  };

  String _fontSettingsTitle(BuildContext context) {
    final tr = 'settings.fonts_and_size'.tr();
    if (tr != 'settings.fonts_and_size') return tr;
    return context.locale.languageCode == 'ar'
        ? 'الخطوط وحجم النص'
        : 'Fonts & Text Size';
  }

  String _fontFamilyLabel(BuildContext context, String fontKey) {
    final isAr = context.locale.languageCode == 'ar';
    switch (fontKey.toLowerCase()) {
      case 'tajawal':
        return isAr ? 'خط تجوال (Tajawal)' : 'Tajawal Font';
      case 'system':
        return isAr ? 'خط النظام (System)' : 'System Font';
      case 'inter':
      default:
        return isAr ? 'خط إنتر (Inter - الافتراضي)' : 'Inter Font (Default)';
    }
  }

  void _showFontCustomizationSheet(
    BuildContext context,
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return Consumer(
          builder: (context, ref, _) {
            final currentSettings = ref.watch(settingsProvider);
            final notifier = ref.read(settingsProvider.notifier);
            final selectedFont = currentSettings.appFontFamily;
            final currentScale = currentSettings.appFontScale;
            final selectedNumStyle = currentSettings.suwayaNumberStyle;
            final isAr = context.locale.languageCode == 'ar';

            final fontOptions = <String, String>{
              'inter': _fontFamilyLabel(context, 'inter'),
              'tajawal': _fontFamilyLabel(context, 'tajawal'),
              'system': _fontFamilyLabel(context, 'system'),
            };

            final scalePresets = <double, String>{
              0.85: isAr ? 'صغير (85%)' : 'Small (85%)',
              0.92: isAr ? 'متوسط (92%)' : 'Medium (92%)',
              1.00: isAr ? 'افتراضي (100%)' : 'Default (100%)',
              1.10: isAr ? 'كبير (110%)' : 'Large (110%)',
              1.20: isAr ? 'كبير جداً (120%)' : 'Extra Large (120%)',
            };

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: textColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        _fontSettingsTitle(context),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAr
                                ? 'معاينة الخط والأرقام'
                                : 'Live Font & Numerals Preview',
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 14 * currentScale,
                              fontWeight: FontWeight.bold,
                              fontFamily: AppTheme.resolveFontFamily(
                                selectedFont,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatDigitsForStyle(
                              isAr
                                  ? 'سُويعَة يربط يومك ومهامك بالإيقاع الفلكي الطبيعي (04|30 🌑).'
                                  : 'Suwaya aligns your daily rhythm with astronomical time (04|30 🌑).',
                              numberStyle: selectedNumStyle,
                              locale: context.locale.languageCode,
                            ),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14.5 * currentScale,
                              height: 1.4,
                              fontFamily: AppTheme.resolveFontFamily(
                                selectedFont,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      isAr ? 'نوع الخط' : 'Font Family',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...fontOptions.entries.map((entry) {
                      final isSelected = selectedFont == entry.key;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected ? primaryColor : textColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 15,
                            fontFamily: AppTheme.resolveFontFamily(entry.key),
                          ),
                        ),
                        trailing: Icon(
                          isSelected
                              ? LucideIcons.circle_check
                              : LucideIcons.circle,
                          color: isSelected
                              ? primaryColor
                              : textColor.withValues(alpha: 0.3),
                          size: 20,
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.updateAppFontFamily(entry.key);
                        },
                      );
                    }),
                    const Divider(height: 20),
                    Text(
                      isAr ? 'نمط الأرقام' : 'Numerals Style',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: Text(
                              isAr
                                  ? 'إنجليزية (0-9 · الافتراضي)'
                                  : 'English (0-9 · Default)',
                            ),
                            selected: selectedNumStyle != 'localized',
                            selectedColor: primaryColor.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: selectedNumStyle != 'localized'
                                  ? primaryColor
                                  : textColor,
                              fontWeight: selectedNumStyle != 'localized'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12.5,
                              fontFamily: 'Inter',
                            ),
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              notifier.updateSuwayaNumberStyle('english');
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: Text(
                              isAr ? 'محلية (٠-٩)' : 'Localized Numerals',
                            ),
                            selected: selectedNumStyle == 'localized',
                            selectedColor: primaryColor.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: selectedNumStyle == 'localized'
                                  ? primaryColor
                                  : textColor,
                              fontWeight: selectedNumStyle == 'localized'
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12.5,
                            ),
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              notifier.updateSuwayaNumberStyle('localized');
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAr ? 'حجم الخط' : 'Text Size',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${(currentScale * 100).round()}%',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.a_large_small,
                          size: 16,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        Expanded(
                          child: Slider(
                            value: currentScale,
                            min: 0.85,
                            max: 1.25,
                            divisions: 8,
                            activeColor: primaryColor,
                            onChanged: (val) {
                              notifier.updateAppFontScale(
                                double.parse(val.toStringAsFixed(2)),
                              );
                            },
                          ),
                        ),
                        Icon(
                          LucideIcons.a_large_small,
                          size: 24,
                          color: textColor,
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: scalePresets.entries.map((entry) {
                        final isSelected =
                            (currentScale - entry.key).abs() < 0.02;
                        return ChoiceChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          selectedColor: primaryColor.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? primaryColor : textColor,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            notifier.updateAppFontScale(entry.key);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: Text(
                          'common.done'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
    final cityName =
        activeLocation?.name ?? 'add_screen.not_set_mandatory'.tr();

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
          icon: Icon(
            context.locale.languageCode == 'ar'
                ? LucideIcons.arrow_right
                : LucideIcons.arrow_left,
            color: textColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'settings.title'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 18,
          ),
        ),
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
                onChanged: (val) =>
                    setState(() => _searchQuery = val.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'settings.search_hint'.tr(),
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.3),
                  ),
                  prefixIcon: Icon(
                    LucideIcons.search,
                    color: isDark ? Colors.white54 : Colors.black54,
                    size: 18,
                  ),
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
                // 1. الموقع النشط
                _buildSettingsGroup(
                  'settings.active_location'.tr(),
                  [
                    _buildSettingRow(
                      context,
                      icon: LucideIcons.map_pin,
                      title: 'settings.active_location'.tr(),
                      subtitle: cityName,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const SmartLocationPicker(),
                      ),
                      isDark: isDark,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                    _buildGpsUpdateButton(context, ref, isDark, textColor),
                  ],
                  isDark,
                  surfaceColor,
                  borderColor,
                  textColor,
                  primaryColor,
                ),

                // 2. المظهر وإمكانية الوصول (المظهر + اللون + تصميم القرص)
                _buildSettingsGroup(
                  'settings.appearance_accessibility'.tr(),
                  [
                    _buildSettingRow(
                      context,
                      icon: isDark ? LucideIcons.moon : LucideIcons.sun,
                      title: 'settings.app_appearance'.tr(),
                      subtitle: _themeModeLabel(
                        context,
                        settingsState.themeMode,
                      ),
                      onTap: () => _showSelectionSheet(
                        'settings.app_appearance'.tr(),
                        {
                          'dark': _themeModeLabel(context, 'dark'),
                          'light': _themeModeLabel(context, 'light'),
                          'mixed': _themeModeLabel(context, 'mixed'),
                          'system': _themeModeLabel(context, 'system'),
                        },
                        settingsState.themeMode,
                        notifier.updateThemeMode,
                        isDark,
                        surfaceColor,
                        textColor,
                        primaryColor,
                      ),
                      isDark: isDark,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                    _buildSettingRow(
                      context,
                      icon: LucideIcons.palette,
                      title: 'settings.app_color'.tr(),
                      subtitle: switch (ref.watch(themeColorProvider)) {
                        AppColorTheme.gold => 'settings.color_gold'.tr(),
                        AppColorTheme.ocean => 'settings.color_ocean'.tr(),
                        AppColorTheme.forest => 'settings.color_forest'.tr(),
                        AppColorTheme.desert => 'settings.color_desert'.tr(),
                      },
                      onTap: () => _showSelectionSheet(
                        'settings.choose_app_color'.tr(),
                        {
                          'gold': 'settings.color_gold'.tr(),
                          'ocean': 'settings.color_ocean'.tr(),
                          'forest': 'settings.color_forest'.tr(),
                          'desert': 'settings.color_desert'.tr(),
                        },
                        ref.read(themeColorProvider).name,
                        (val) {
                          final selected = AppColorTheme.values.firstWhere(
                            (e) => e.name == val,
                            orElse: () => AppColorTheme.gold,
                          );
                          ref
                              .read(themeColorProvider.notifier)
                              .changeTheme(selected);
                        },
                        isDark,
                        surfaceColor,
                        textColor,
                        primaryColor,
                      ),
                      isDark: isDark,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                    _buildSettingRow(
                      context,
                      icon: LucideIcons.compass,
                      title: 'settings.dial_design'.tr(),
                      subtitle: switch (ref.watch(dialDesignProvider)) {
                        DialDesign.classic => 'settings.design_classic'.tr(),
                        DialDesign.minimal => 'settings.design_minimal'.tr(),
                        DialDesign.geometric =>
                          'settings.design_geometric'.tr(),
                      },
                      onTap: () => _showSelectionSheet(
                        'settings.choose_dial_design'.tr(),
                        {
                          'classic': 'settings.design_classic'.tr(),
                          'minimal': 'settings.design_minimal'.tr(),
                          'geometric': 'settings.design_geometric'.tr(),
                        },
                        ref.read(dialDesignProvider).name,
                        (val) {
                          final selected = DialDesign.values.firstWhere(
                            (e) => e.name == val,
                            orElse: () => DialDesign.classic,
                          );
                          ref
                              .read(dialDesignProvider.notifier)
                              .changeDesign(selected);
                        },
                        isDark,
                        surfaceColor,
                        textColor,
                        primaryColor,
                      ),
                      isDark: isDark,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),

                    _buildSettingRow(
                      context,
                      icon: LucideIcons.type,
                      title: _fontSettingsTitle(context),
                      subtitle:
                          '${_fontFamilyLabel(context, settingsState.appFontFamily)} · ${(settingsState.appFontScale * 100).round()}%',
                      onTap: () => _showFontCustomizationSheet(
                        context,
                        isDark,
                        surfaceColor,
                        textColor,
                        primaryColor,
                      ),
                      isDark: isDark,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                  ],
                  isDark,
                  surfaceColor,
                  borderColor,
                  textColor,
                  primaryColor,
                ),

                // 3. الإشعارات والتنبيهات
                _buildSettingsGroup(
                  'settings.notifications_alerts'.tr(),
                  [
                    _buildSettingRow(
                      context,
                      icon: LucideIcons.bell_ring,
                      title: 'settings.notifications_alerts'.tr(),
                      subtitle: 'settings.notifications_desc'.tr(),
                      onTap: () => context.push('/settings/notifications'),
                      isDark: isDark,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                  ],
                  isDark,
                  surfaceColor,
                  borderColor,
                  textColor,
                  primaryColor,
                ),

                // 4. إعدادات فلكية متقدمة
                _buildSettingsGroup(
                  'settings.advanced_astro'.tr(),
                  [
                    _buildSettingRow(
                      context,
                      icon: LucideIcons.telescope,
                      title: 'settings.astro_settings'.tr(),
                      subtitle: 'settings.astro_desc'.tr(),
                      onTap: () => context.push('/settings/astro'),
                      isDark: isDark,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                  ],
                  isDark,
                  surfaceColor,
                  borderColor,
                  textColor,
                  primaryColor,
                ),

                // 5. عام
                _buildSettingsGroup(
                  'settings.general'.tr(),
                  [
                    _buildSettingRow(
                      context,
                      icon: LucideIcons.languages,
                      title: 'settings.app_language'.tr(),
                      subtitle: currentLangName,
                      onTap: () => _showSelectionSheet(
                        'settings.app_language'.tr(),
                        _appLanguages,
                        currentLang,
                        (v) async {
                          await notifier.updateLanguage(v);
                          if (context.mounted) {
                            await context.setLocale(Locale(v));
                          }
                          await NotificationService()
                              .refreshLocalizedChannels();
                        },
                        isDark,
                        surfaceColor,
                        textColor,
                        primaryColor,
                      ),
                      isDark: isDark,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                    _buildSettingRow(
                      context,
                      icon: LucideIcons.clock_3,
                      title: 'home.civil_time'.tr(),
                      subtitle: _civilTimeFormatLabel(
                        context,
                        settingsState.civilTimeFormat,
                      ),
                      onTap: () => _showSelectionSheet(
                        'home.civil_time'.tr(),
                        {
                          civilTimeFormatSystem: 'settings.theme_system'.tr(),
                          civilTimeFormat12Hour: _civilTimeFormatLabel(
                            context,
                            civilTimeFormat12Hour,
                          ),
                          civilTimeFormat24Hour: _civilTimeFormatLabel(
                            context,
                            civilTimeFormat24Hour,
                          ),
                        },
                        settingsState.civilTimeFormat,
                        notifier.updateCivilTimeFormat,
                        isDark,
                        surfaceColor,
                        textColor,
                        primaryColor,
                      ),
                      isDark: isDark,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                    _buildSettingRow(
                      context,
                      icon: LucideIcons.calendar,
                      title: context.locale.languageCode == 'ar'
                          ? 'تصحيح التاريخ الهجري'
                          : 'Hijri Date Adjustment',
                      subtitle: _hijriOffsetLabel(
                        context,
                        settingsState.hijriOffsetDays,
                      ),
                      onTap: () => _showSelectionSheet(
                        context.locale.languageCode == 'ar'
                            ? 'تصحيح التاريخ الهجري'
                            : 'Hijri Date Adjustment',
                        {
                          '-2': context.locale.languageCode == 'ar'
                              ? '- يومان (-2)'
                              : '-2 Days',
                          '-1': context.locale.languageCode == 'ar'
                              ? '- يوم واحد (-1)'
                              : '-1 Day',
                          '0': context.locale.languageCode == 'ar'
                              ? 'تلقائي (0)'
                              : 'Default (0)',
                          '1': context.locale.languageCode == 'ar'
                              ? '+ يوم واحد (+1)'
                              : '+1 Day',
                          '2': context.locale.languageCode == 'ar'
                              ? '+ يومان (+2)'
                              : '+2 Days',
                        },
                        settingsState.hijriOffsetDays.toString(),
                        (String val) {
                          notifier.updateHijriOffsetDays(
                            int.tryParse(val) ?? 0,
                          );
                        },
                        isDark,
                        surfaceColor,
                        textColor,
                        primaryColor,
                      ),
                      isDark: isDark,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                    _buildSettingRow(
                      context,
                      icon: LucideIcons.shield_alert,
                      title: 'settings.permissions'.tr(),
                      subtitle: 'settings.permissions_desc'.tr(),
                      onTap: () => context.push('/settings/permissions'),
                      isDark: isDark,
                      primaryColor: primaryColor,
                      textColor: textColor,
                    ),
                  ],
                  isDark,
                  surfaceColor,
                  borderColor,
                  textColor,
                  primaryColor,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Column(
                    children: [
                      Text(
                        'app_name'.tr(),
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          final versionText = snapshot.hasData
                              ? 'v${snapshot.data!.version} (${snapshot.data!.buildNumber})'
                              : 'settings.version'.tr();
                          return Text(
                            versionText,
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 11,
                              fontFamily: 'Inter',
                            ),
                          );
                        },
                      ),
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

  String _hijriOffsetLabel(BuildContext context, int offset) {
    final isAr = context.locale.languageCode == 'ar';
    if (offset == 0) {
      return isAr ? 'تلقائي (بدون تعديل)' : 'Auto (0 days)';
    }
    final sign = offset > 0 ? '+$offset' : '$offset';
    return isAr ? '$sign يوم' : '$sign days';
  }

  /// 🌟 التعديل 8: عرض "12 ساعة" و "24 ساعة" وما يوازيها في اللغات الأخرى مع الإبقاء على خيار النظام كما هو
  String _civilTimeFormatLabel(BuildContext context, String format) {
    if (format == civilTimeFormat12Hour) {
      final tr12 = 'settings.format_12h'.tr();
      if (tr12 != 'settings.format_12h') return tr12;
      return _localizedHourLabel(context.locale.languageCode, 12);
    }
    if (format == civilTimeFormat24Hour) {
      final tr24 = 'settings.format_24h'.tr();
      if (tr24 != 'settings.format_24h') return tr24;
      return _localizedHourLabel(context.locale.languageCode, 24);
    }
    return 'settings.theme_system'.tr();
  }

  String _localizedHourLabel(String lang, int hours) {
    return switch (lang) {
      'ar' => '$hours ساعة',
      'ur' => '$hours گھنٹے',
      'ug' => '$hours سائەت',
      'tr' || 'az' => '$hours Saat',
      'id' || 'ms' => '$hours Jam',
      'fr' => '$hours heures',
      'de' => '$hours Stunden',
      'es' || 'pt' => '$hours horas',
      'it' => '$hours ore',
      'nl' => '$hours uur',
      'da' => '$hours timer',
      'ru' => '$hours часов',
      'hi' => '$hours घंटे',
      'bn' => '$hours ঘণ্টা',
      'th' => '$hours ชั่วโมง',
      'ja' => '$hours時間制',
      'zh' => '$hours 小时制',
      'ff' => 'Waktuuji $hours',
      _ => '$hours Hours',
    };
  }

  Widget _buildGpsUpdateButton(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    Color textColor,
  ) {
    final Color mainColor = textColor;
    final Color iconBgColor = Theme.of(context).scaffoldBackgroundColor;

    bool isUpdating = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.crosshair,
                  color: Colors.blueAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'settings.update_gps'.tr(),
                      style: TextStyle(
                        color: mainColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'settings.gps_desc'.tr(),
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.5),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              isUpdating
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        minimumSize: const Size(60, 32),
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final langCode = Localizations.localeOf(
                          context,
                        ).languageCode;
                        setState(() => isUpdating = true);
                        try {
                          bool serviceEnabled =
                              await Geolocator.isLocationServiceEnabled();
                          if (!serviceEnabled) {
                            setState(() => isUpdating = false);
                            await Geolocator.openLocationSettings();
                            return;
                          }
                          final locData =
                              await LocationService.fetchOfflineLocation(
                                langCode,
                              );
                          await ref
                              .read(settingsProvider.notifier)
                              .addAndSelectLocation(
                                locData['formattedName'],
                                locData['lat'],
                                locData['lng'],
                                locData['countryCode'],
                                timezone: locData['timezone'],
                                locationType: 'gps',
                                nearestCity: locData['city'],
                              );
                          await ref
                              .read(settingsProvider.notifier)
                              .updateCalculationMethod(locData['method']);
                          await ref
                              .read(settingsProvider.notifier)
                              .updateMadhab(locData['madhab']);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${'settings.gps_success'.tr()} ${locData['formattedName']}',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('settings.gps_failed'.tr()),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => isUpdating = false);
                        }
                      },
                      child: Text(
                        'settings.update'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsGroup(
    String label,
    List<Widget> rows,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color primaryColor,
  ) {
    final filteredRows = _searchQuery.isEmpty
        ? rows
        : rows.where((w) {
            if (label.toLowerCase().contains(_searchQuery)) return true;
            if (w is _SettingRow) {
              return w.title.toLowerCase().contains(_searchQuery) ||
                  (w.subtitle?.toLowerCase().contains(_searchQuery) ?? false);
            }
            return true;
          }).toList();

    if (filteredRows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                color: primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: filteredRows.asMap().entries.map((entry) {
                final int idx = entry.key;
                final Widget row = entry.value;
                if (idx == filteredRows.length - 1) return row;
                return Column(
                  children: [
                    row,
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: borderColor,
                      indent: 56,
                      endIndent: 16,
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool isToggle = false,
    bool toggleValue = false,
    Function(bool)? onToggle,
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
  }) {
    return _SettingRow(
      context: context,
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      isToggle: isToggle,
      toggleValue: toggleValue,
      onToggle: onToggle,
      isDark: isDark,
      primaryColor: primaryColor,
      textColor: textColor,
    );
  }

  void _showSelectionSheet(
    String title,
    Map<String, String> items,
    String selectedValue,
    Function(String) onSelected,
    bool isDark,
    Color surfaceColor,
    Color textColor,
    Color primaryColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  children: items.entries.map((entry) {
                    final isSelected = entry.key == selectedValue;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                      ),
                      title: Text(
                        entry.value,
                        style: TextStyle(
                          color: isSelected
                              ? primaryColor
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              LucideIcons.circle_check,
                              color: primaryColor,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        onSelected(entry.key);
                        Navigator.pop(context);
                      },
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

String _themeModeLabel(BuildContext context, String mode) {
  final isAr = context.locale.languageCode == 'ar';
  switch (mode) {
    case 'light':
      final tr = 'settings.theme_light'.tr();
      return tr != 'settings.theme_light'
          ? tr
          : (isAr ? 'الوضع الفاتح' : 'Light Mode');
    case 'dark':
      final tr = 'settings.theme_dark'.tr();
      return tr != 'settings.theme_dark'
          ? tr
          : (isAr ? 'الوضع الداكن' : 'Dark Mode');
    case 'mixed':
      final tr = 'settings.theme_mixed'.tr();
      return tr != 'settings.theme_mixed'
          ? tr
          : (isAr
                ? 'فلكي مختلط (فاتح نهاراً / داكن ليلاً)'
                : 'Astro Mixed (Day Light / Night Dark)');
    case 'system':
    default:
      return 'settings.theme_system'.tr();
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

  const _SettingRow({
    required this.context,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isToggle = false,
    this.toggleValue = false,
    this.onToggle,
    required this.isDark,
    required this.primaryColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext _) {
    final Color mainColor = textColor;
    final Color baseIconColor = isDark ? Colors.white70 : Colors.black87;
    final Color iconBgColor = Theme.of(context).scaffoldBackgroundColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (isToggle || onToggle == null && isToggle)
            ? null
            : () {
                if (onTap != null) {
                  HapticFeedback.lightImpact();
                  onTap!();
                }
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: baseIconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: mainColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.5),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
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
                    inactiveTrackColor: isDark
                        ? const Color(0xFF2E3745)
                        : Colors.black12,
                    inactiveThumbColor: isDark
                        ? Colors.white70
                        : Colors.black54,
                  ),
                )
              else
                Icon(
                  context.locale.languageCode == 'ar'
                      ? LucideIcons.chevron_left
                      : LucideIcons.chevron_right,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
