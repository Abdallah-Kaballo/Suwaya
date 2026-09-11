import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';

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
        child: Image.asset('assets/icons/app_icon.png', width: 48, height: 48, errorBuilder: (c, e, s) => const Icon(LucideIcons.compass, size: 48)),
      ),
      applicationLegalese: '© ${DateTime.now().year} Abdallah Kaballo.\nAll rights reserved.',
    );
  }

  String _normalizeVersion(String value) {
    return value
        .trim()
        .replaceFirst(RegExp(r'^v', caseSensitive: false), '')
        .split('+')
        .first
        .trim();
  }

  int _compareVersions(String current, String latest) {
    final currentParts = _normalizeVersion(current)
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    final latestParts = _normalizeVersion(latest)
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();

    for (var index = 0; index < 3; index++) {
      final currentPart = index < currentParts.length ? currentParts[index] : 0;
      final latestPart = index < latestParts.length ? latestParts[index] : 0;

      if (currentPart != latestPart) {
        return currentPart.compareTo(latestPart);
      }
    }

    return 0;
  }

  Future<void> _checkForUpdates(BuildContext context, Color primaryColor) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        content: Row(
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(width: 24),
            Text('drawer.checking_updates'.tr(), style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = _normalizeVersion(packageInfo.version);

      final response = await http.get(Uri.parse('https://api.github.com/repos/Abdallah-Kaballo/Suwaya/releases/latest'));
      
      if (!context.mounted) return;
      Navigator.pop(context); 

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = _normalizeVersion(data['tag_name'].toString());
        final apkUrl = data['assets'] != null && data['assets'].isNotEmpty 
            ? data['assets'][0]['browser_download_url'] 
            : data['html_url']; 

        if (_compareVersions(currentVersion, latestVersion) < 0) {
          _showUpdateAvailableDialog(context, latestVersion, apkUrl, primaryColor, isDark);
        } else {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Row(
                children: [
                  const Icon(LucideIcons.circle_check, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('drawer.up_to_date'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Text('${'drawer.latest_version_msg'.tr()} (v$currentVersion)', style: TextStyle(color: textColor.withValues(alpha: 0.7), height: 1.5)),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('common.done'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception('فشل الاتصال بـ GitHub');
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('drawer.github_connection_failed'.tr()), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showUpdateAvailableDialog(BuildContext context, String newVersion, String url, Color primaryColor, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Row(
          children: [
            Icon(LucideIcons.cloud_download, color: primaryColor),
            const SizedBox(width: 8),
            Text('drawer.update_available'.tr(), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text('${'drawer.new_version_desc'.tr()} (v$newVersion)\n\n${'drawer.do_you_want_to_download'.tr()}', style: TextStyle(color: textColor.withValues(alpha: 0.7), height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr(), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () {
              Navigator.pop(ctx);
              _launchUrl(url);
            },
            child: Text('drawer.download'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: textColor.withValues(alpha: 0.05))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: Icon(LucideIcons.compass, color: primaryColor, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Suwaya', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        // 🌟 تم حذف جملة "هندسة الوقت" من هنا حسب طلبك
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
                  _buildDrawerItem(context, LucideIcons.settings, 'settings.title'.tr(), () {
                    Navigator.pop(context);
                    context.push('/settings'); 
                  }),
                  _buildDrawerItem(context, LucideIcons.book_open, 'drawer.faq'.tr(), () {_launchUrl('https://github.com/Abdallah-Kaballo/Suwaya/wiki');}),
                  _buildDrawerItem(context, LucideIcons.mail, 'drawer.contact'.tr(), () {
                    _launchUrl('mailto:suwaya2026@gmail.com');
                  }),
                  
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), child: Text('drawer.about_app'.tr(), style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold))),
                  
                  _buildDrawerItem(context, LucideIcons.refresh_cw, 'drawer.check_updates'.tr(), () => _checkForUpdates(context, primaryColor)),
                  
                  _buildDrawerItem(context, LucideIcons.code, 'drawer.develop_with_us'.tr(), () {
                    _launchUrl('https://github.com/Abdallah-Kaballo/Suwaya');
                  }),
                  _buildDrawerItem(context, LucideIcons.shield, 'settings.privacy_policy'.tr(), () {
                    _launchUrl('https://abdallah-kaballo.github.io/Suwaya/privacy.html');
                  }),
                  _buildDrawerItem(context, LucideIcons.info, 'settings.about'.tr(), () => _showAboutDialog(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, VoidCallback onTap, {Color? iconColor, Color? textColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white70 : Colors.black87;
    
    return ListTile(
      leading: Icon(icon, color: iconColor ?? defaultColor.withValues(alpha: 0.7), size: 22),
      title: Text(title, style: TextStyle(color: textColor ?? defaultColor, fontSize: 15, fontWeight: FontWeight.w600)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
    );
  }
}