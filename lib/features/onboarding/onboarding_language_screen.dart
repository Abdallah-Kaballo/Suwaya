import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:suwaya/features/settings/settings_provider.dart';

import 'onboarding_location_screen.dart';

class OnboardingLanguageScreen extends ConsumerStatefulWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  ConsumerState<OnboardingLanguageScreen> createState() => _OnboardingLanguageScreenState();
}

class _OnboardingLanguageScreenState extends ConsumerState<OnboardingLanguageScreen> {
  late String _selectedLang;

  // 🌟 القائمة تحتوي على الاسم الأصلي فقط، أما الترجمة فستأتي من القاموس
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLang = context.locale.languageCode;
    if (!_appLanguages.containsKey(_selectedLang)) {
      _selectedLang = 'en'; 
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text('onboarding.welcome_sub'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _appLanguages.length,
                itemBuilder: (context, index) {
                  final code = _appLanguages.keys.elementAt(index);
                  final nativeName = _appLanguages[code]!;
                  return _buildLangCard(code, nativeName, primaryColor, textColor, isDark);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await ref.read(settingsProvider.notifier).updateLanguage(_selectedLang);
                  if (!context.mounted) return;
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingLocationScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Text('onboarding.continue_btn'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangCard(String code, String nativeName, Color primaryColor, Color textColor, bool isDark) {
    final isSelected = _selectedLang == code;
    return Column(
      children: [
        InkWell(
          onTap: () async {
            HapticFeedback.selectionClick();
            setState(() => _selectedLang = code);
            // 🌟 تحديث لغة التطبيق بالكامل فوراً عند الضغط
            await context.setLocale(Locale(code));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                Icon(isSelected ? LucideIcons.circle_dot : LucideIcons.circle, color: isSelected ? primaryColor : Colors.grey, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nativeName, style: TextStyle(color: textColor, fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      const SizedBox(height: 4),
                      // 🌟 الترجمة تأتي من القاموس وتتحدث فوراً (مثال: التركية -> Turkish)
                      Text('languages.$code'.tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12, indent: 50),
      ],
    );
  }
}