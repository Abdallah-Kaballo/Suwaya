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

import '../../features/auth/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('لا يمكن فتح الرابط: $urlString');
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Suwaya',
      applicationVersion: '1.0.0',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/icons/app_icon.png', width: 48, height: 48, errorBuilder: (c, e, s) => const Icon(LucideIcons.compass, size: 48)),
      ),
      applicationLegalese: '© ${DateTime.now().year} Abdallah Kaballo.\nAll rights reserved.',
    );
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
      final currentVersion = packageInfo.version.trim();

      final response = await http.get(Uri.parse('https://api.github.com/repos/Abdallah-Kaballo/Suwaya/releases/latest'));
      
      if (!context.mounted) return;
      Navigator.pop(context); // إغلاق نافذة التحميل

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['tag_name'].toString().replaceAll('v', '').trim();
        final apkUrl = data['assets'] != null && data['assets'].isNotEmpty 
            ? data['assets'][0]['browser_download_url'] 
            : data['html_url']; 

        if (latestVersion != currentVersion) {
          _showUpdateAvailableDialog(context, latestVersion, apkUrl, primaryColor, isDark);
        } else {
          // 🌟 التعديل الأول: عرض نافذة أنيقة تؤكد أن التطبيق محدث بدلاً من SnackBar
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
              content: Text('أنت تستخدم أحدث إصدار متاح من التطبيق (v$currentVersion). لا توجد تحديثات جديدة حالياً.', style: TextStyle(color: textColor.withValues(alpha: 0.7), height: 1.5)),
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
        SnackBar(content: Text('drawer.update_check_failed'.tr()), backgroundColor: Colors.redAccent),
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

  // 🌟 التعديل الثاني: شاشة المصادقة (Auth Sheet) المنبثقة من الأسفل
  void _showAuthSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final user = ref.watch(currentUserProvider);
            final isAnon = user == null;
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : Colors.black87;
            final primaryColor = Theme.of(context).primaryColor;
            final authService = ref.read(authServiceProvider);

            final userMeta = user?.userMetadata;
            final userName = userMeta?['full_name'] ?? userMeta?['name'] ?? 'مستخدم سويعة';
            final userEmail = user?.email ?? '';
            final userAvatar = userMeta?['avatar_url'];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // حالة المستخدم الزائر (تسجيل الدخول)
                    if (isAnon) ...[
                      Icon(LucideIcons.cloud, size: 64, color: primaryColor),
                      const SizedBox(height: 16),
                      Text('تسجيل الدخول', style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        'قم بتسجيل الدخول لحفظ مهامك وإعداداتك، ومزامنتها عبر جميع أجهزتك بأمان عبر السحابة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.white : Colors.black,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            try {
                              await authService.signInWithGoogle();
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل تسجيل الدخول: $e'), backgroundColor: Colors.redAccent));
                              }
                            }
                          },
                          icon: const Icon(LucideIcons.globe), // أيقونة بديلة معبرة عن جوجل/الويب
                          label: const Text('المتابعة بواسطة Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ] 
                    // حالة المستخدم المسجل (تسجيل الخروج)
                    else ...[
                      Container(
                        padding: userAvatar == null ? const EdgeInsets.all(24) : EdgeInsets.zero,
                        decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: userAvatar != null 
                            ? ClipOval(child: Image.network(userAvatar, width: 96, height: 96, fit: BoxFit.cover))
                            : Icon(LucideIcons.user, color: primaryColor, size: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(userName, style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(userEmail, style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 14)),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                            foregroundColor: Colors.redAccent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Colors.redAccent)),
                          ),
                          onPressed: () async {
                            HapticFeedback.heavyImpact();
                            await authService.signOut();
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(LucideIcons.log_out),
                          label: const Text('تسجيل الخروج', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    final user = ref.watch(currentUserProvider);
    final isAnon = user == null;
    final userMeta = user?.userMetadata;
    final userName = userMeta?['full_name'] ?? userMeta?['name'] ?? user?.email ?? 'drawer.guest_user'.tr();
    final userAvatar = userMeta?['avatar_url'];

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // 🌟 الترويسة تفتح الآن شاشة المصادقة (Auth Sheet)
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                _showAuthSheet(context, ref);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Row(
                  children: [
                    Container(
                      padding: userAvatar == null ? const EdgeInsets.all(12) : EdgeInsets.zero,
                      decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: userAvatar != null 
                          ? ClipOval(child: Image.network(userAvatar, width: 48, height: 48, fit: BoxFit.cover))
                          : Icon(LucideIcons.user, color: primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(isAnon ? 'اضغط لتسجيل الدخول' : 'اضغط لعرض الحساب', style: TextStyle(color: isAnon ? primaryColor : textColor.withValues(alpha: 0.5), fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Icon(
                      isAnon ? LucideIcons.chevron_left : LucideIcons.chevron_left,
                      color: textColor.withValues(alpha: 0.3),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: textColor.withValues(alpha: 0.05), height: 1),
            
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(context, LucideIcons.settings, 'settings.title'.tr(), () {
                    Navigator.pop(context);
                    context.push('/settings'); 
                  }),
                  _buildDrawerItem(context, LucideIcons.book_open, 'drawer.faq'.tr(), () {}),
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