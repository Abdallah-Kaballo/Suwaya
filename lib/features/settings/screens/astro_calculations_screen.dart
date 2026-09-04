import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

import '../settings_provider.dart';

class AstroCalculationsScreen extends ConsumerWidget {
  const AstroCalculationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = isDark ? Colors.white54 : Colors.black54;
    final borderColor = Theme.of(context).dividerColor;
    final primaryColor = Theme.of(context).primaryColor;

    final isCustomMethod = settings.calculationMethod == 'custom';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: Icon(LucideIcons.arrow_right, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text('astro_calc.title'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: primaryColor.withValues(alpha: 0.3))),
            child: Row(
              children: [
                Icon(LucideIcons.info, color: primaryColor),
                const SizedBox(width: 12),
                Expanded(child: Text('astro_calc.warning'.tr(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 12, height: 1.5))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildGroupTitle('astro_calc.calc_method'.tr(), primaryColor),
          _buildCard(surfaceColor, borderColor, [
            _buildRadioItem('muslim_world_league', 'astro_calc.mwl'.tr(), 'astro_calc.mwl_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
            _buildRadioItem('egyptian', 'astro_calc.egypt'.tr(), 'astro_calc.egypt_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
            _buildRadioItem('umm_al_qura', 'astro_calc.makkah'.tr(), 'astro_calc.makkah_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
            _buildRadioItem('dubai', 'astro_calc.dubai'.tr(), 'astro_calc.dubai_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
            _buildRadioItem('qatar', 'astro_calc.qatar'.tr(), 'astro_calc.qatar_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
            _buildRadioItem('kuwait', 'astro_calc.kuwait'.tr(), 'astro_calc.kuwait_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
            _buildRadioItem('karachi', 'astro_calc.karachi'.tr(), 'astro_calc.karachi_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
            _buildRadioItem('north_america', 'astro_calc.isna'.tr(), 'astro_calc.isna_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
            _buildRadioItem('turkey', 'astro_calc.turkey'.tr(), 'astro_calc.turkey_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
            _buildRadioItem('tehran', 'astro_calc.tehran'.tr(), 'astro_calc.tehran_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
            _buildRadioItem('france_uoif', 'astro_calc.uoif'.tr(), 'astro_calc.uoif_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
            _buildRadioItem('russia', 'astro_calc.russia'.tr(), 'astro_calc.russia_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
            _buildRadioItem('singapore', 'astro_calc.singapore'.tr(), 'astro_calc.singapore_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
            _buildRadioItem('custom', 'astro_calc.custom'.tr(), 'astro_calc.custom_desc'.tr(), settings.calculationMethod, (v) => notifier.updateAstroSettings(method: v), textColor, isDark, primaryColor),
          ]),

          if (isCustomMethod) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: primaryColor.withValues(alpha: 0.5))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.settings_2, color: primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text('astro_calc.custom_angles'.tr(), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  _buildAngleSlider(
                    title: 'astro_calc.fajr_angle'.tr(), 
                    value: settings.customFajrAngle, 
                    isDark: isDark, textColor: textColor, primaryColor: primaryColor, hintColor: hintColor,
                    onChanged: (v) => notifier.updateAstroSettings(fajrAngle: v, ishaAngle: settings.customIshaAngle)
                  ),
                  
                  const SizedBox(height: 16),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 16),

                  _buildAngleSlider(
                    title: 'astro_calc.isha_angle'.tr(), 
                    value: settings.customIshaAngle, 
                    isDark: isDark, textColor: textColor, primaryColor: primaryColor, hintColor: hintColor,
                    onChanged: (v) => notifier.updateAstroSettings(fajrAngle: settings.customFajrAngle, ishaAngle: v)
                  ),
                ],
              ),
             ),
          ],

          const SizedBox(height: 24),
          _buildGroupTitle('astro_calc.asr_madhab'.tr(), primaryColor),
          _buildCard(surfaceColor, borderColor, [
            _buildRadioItem('shafi', 'astro_calc.shafi'.tr(), 'astro_calc.shafi_desc'.tr(), settings.madhab, (v) => notifier.updateAstroSettings(madhab: v), textColor, isDark, primaryColor),
            _buildRadioItem('hanafi', 'astro_calc.hanafi'.tr(), 'astro_calc.hanafi_desc'.tr(), settings.madhab, (v) => notifier.updateAstroSettings(madhab: v), textColor, isDark, primaryColor),
          ]),

          const SizedBox(height: 24),
          _buildGroupTitle('astro_calc.high_lat'.tr(), primaryColor),
          _buildCard(surfaceColor, borderColor, [
            _buildRadioItem('middle_of_the_night', 'astro_calc.midnight'.tr(), 'astro_calc.midnight_desc'.tr(), settings.highLatitudeRule, (v) => notifier.updateAstroSettings(highLatRule: v), textColor, isDark, primaryColor),
            _buildRadioItem('seventh_of_the_night', 'astro_calc.seventh'.tr(), 'astro_calc.seventh_desc'.tr(), settings.highLatitudeRule, (v) => notifier.updateAstroSettings(highLatRule: v), textColor, isDark, primaryColor),
            _buildRadioItem('twilight_angle', 'astro_calc.twilight'.tr(), 'astro_calc.twilight_desc'.tr(), settings.highLatitudeRule, (v) => notifier.updateAstroSettings(highLatRule: v), textColor, isDark, primaryColor),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAngleSlider({
    required String title, required double value, required bool isDark,
    required Color textColor, required Color primaryColor, required Color hintColor,
    required Function(double) onChanged
  }) {
    final displayValue = value.toStringAsFixed(1);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$displayValue°', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 16)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              icon: Icon(LucideIcons.minus, size: 20, color: value > 10.0 ? textColor : hintColor.withValues(alpha: 0.3)),
              onPressed: value > 10.0 ? () {
                HapticFeedback.lightImpact();
                onChanged(double.parse((value - 0.1).toStringAsFixed(1)));
              } : null,
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: primaryColor,
                  inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                  thumbColor: primaryColor,
                  overlayColor: primaryColor.withValues(alpha: 0.2),
                  valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                child: Slider(
                  value: value,
                  min: 10.0,
                  max: 20.0,
                  divisions: 100, 
                  label: displayValue,
                  onChanged: (val) {
                    onChanged(double.parse(val.toStringAsFixed(1)));
                  },
                  onChangeEnd: (_) => HapticFeedback.selectionClick(),
                ),
              ),
            ),
            IconButton(
              icon: Icon(LucideIcons.plus, size: 20, color: value < 20.0 ? textColor : hintColor.withValues(alpha: 0.3)),
              onPressed: value < 20.0 ? () {
                HapticFeedback.lightImpact();
                onChanged(double.parse((value + 0.1).toStringAsFixed(1)));
              } : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroupTitle(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 8),
      child: Text(title, style: TextStyle(color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCard(Color surfaceColor, Color borderColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor)),
      clipBehavior: Clip.antiAlias, 
      child: Column(children: children),
    );
  }

  Widget _buildRadioItem(String value, String title, String subtitle, String? groupValue, Function(String) onChanged, Color textColor, bool isDark, Color primaryColor) {
    final isSelected = value == groupValue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(value);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: isSelected ? primaryColor : textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? primaryColor : (isDark ? Colors.white38 : Colors.black38), width: 2),
                ),
                child: isSelected 
                    ? Center(
                        child: Container(
                          width: 12, height: 12, 
                          decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                        ),
                      ) 
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}