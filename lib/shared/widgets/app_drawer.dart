import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_update/in_app_update.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('${'settings.cannot_open_link'.tr()}: $urlString');
    }
  }

  Future<void> _showAboutDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'Suwaya',
      applicationVersion: packageInfo.version,
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/icons/app_icon.png',
            width: 48,
            height: 48,
            errorBuilder: (c, e, s) =>
                const Icon(LucideIcons.compass, size: 48)),
      ),
      applicationLegalese:
          '© ${DateTime.now().year} Abdallah Kaballo.\nAll rights reserved.',
    );
  }

  Future<void> _checkForUpdates(BuildContext context, Color primaryColor) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;

    final rootNav = Navigator.of(context, rootNavigator: true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // إغلاق القائمة الجانبية بطريقة آمنة
    Navigator.pop(context);

    if (!Platform.isAndroid) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
            content: const Text('التحديثات متاحة عبر متجر التطبيقات الخاص بنظامك.'),
            backgroundColor: primaryColor),
      );
      return;
    }

    BuildContext? loadingDialogContext;
    showDialog(
      context: rootNav.context, 
      barrierDismissible: false,
      builder: (ctx) {
        loadingDialogContext = ctx;
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: scaffoldBgColor,
            content: Row(
              children: [
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(width: 24),
                Text('drawer.checking_updates'.tr(),
                    style: TextStyle(color: textColor)),
              ],
            ),
          ),
        );
      },
    );

    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (loadingDialogContext != null && loadingDialogContext!.mounted) {
        Navigator.pop(loadingDialogContext!);
      }

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      } else {
        // 🌟 إرضاء المحلل: تخزين الـ context في متغير محلي وفحصه
        final navContext = rootNav.context;
        if (!navContext.mounted) return;

        showDialog(
          context: navContext,
          builder: (ctx) => AlertDialog(
            backgroundColor: scaffoldBgColor,
            title: Row(
              children: [
                const Icon(LucideIcons.circle_check, color: Colors.green),
                const SizedBox(width: 8),
                Text('drawer.up_to_date'.tr(),
                    style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ],
            ),
            content: Text('drawer.latest_version_msg'.tr(),
                style: TextStyle(
                    color: textColor.withValues(alpha: 0.7), height: 1.5)),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                onPressed: () => Navigator.pop(ctx),
                child: Text('common.done'.tr(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (loadingDialogContext != null && loadingDialogContext!.mounted) {
        Navigator.pop(loadingDialogContext!);
      }

      scaffoldMessenger.showSnackBar(
        const SnackBar(
            content: Text('فشل الاتصال بمتجر Google Play. يرجى المحاولة لاحقاً.'),
            backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final brandName = context.locale.languageCode == 'ar' ? 'سٌويعة' : 'Suwaya';

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                    bottom:
                        BorderSide(color: textColor.withValues(alpha: 0.05))),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(brandName,
                            style: TextStyle(
                                color: textColor,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                      context, LucideIcons.settings, 'settings.title'.tr(), () {
                    Navigator.pop(context);
                    context.push('/settings');
                  }),
                  _buildDrawerItem(
                      context, LucideIcons.book_open, 'drawer.faq'.tr(), () {
                    Navigator.pop(context);
                    context.push('/faq');
                  }),
                  _buildDrawerItem(
                      context, LucideIcons.mail, 'drawer.contact'.tr(), () {
                    _launchUrl('mailto:suwaya2026@gmail.com');
                  }),
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Text('drawer.about_app'.tr(),
                          style: TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold))),
                  _buildDrawerItem(
                      context,
                      LucideIcons.refresh_cw,
                      'drawer.check_updates'.tr(),
                      () => _checkForUpdates(context, primaryColor)),
                  _buildDrawerItem(
                      context, LucideIcons.code, 'drawer.develop_with_us'.tr(),
                      () {
                    _launchUrl('https://github.com/Abdallah-Kaballo/Suwaya');
                  }),
                  _buildDrawerItem(context, LucideIcons.shield,
                      'settings.privacy_policy'.tr(), () {
                    Navigator.pop(context);
                    context.push('/privacy');
                  }),
                  _buildDrawerItem(context, LucideIcons.info,
                      'settings.about'.tr(), () => _showAboutDialog(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap,
      {Color? iconColor, Color? textColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white70 : Colors.black87;

    return ListTile(
      leading: Icon(icon,
          color: iconColor ?? defaultColor.withValues(alpha: 0.7), size: 22),
      title: Text(title,
          style: TextStyle(
              color: textColor ?? defaultColor,
              fontSize: 15,
              fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}