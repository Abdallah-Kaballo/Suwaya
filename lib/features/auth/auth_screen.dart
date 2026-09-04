import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 
import 'package:easy_localization/easy_localization.dart';

import '../../core/sync/auth_service.dart';

final authScreenStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false; 

  @override
  Widget build(BuildContext context) {
    ref.watch(authScreenStateProvider); 
    final authService = ref.read(authServiceProvider);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).primaryColor;
    final borderColor = Theme.of(context).dividerColor;

    final isAnon = authService.isAnonymous;
    final user = authService.currentUser;

    final userMetadata = user?.userMetadata;
    final userName = userMetadata?['full_name'] ?? userMetadata?['name'] ?? 'مستخدم سُويعة';
    final userAvatar = userMetadata?['avatar_url'] ?? userMetadata?['picture'];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(context.locale.languageCode == 'ar' ? LucideIcons.arrow_right : LucideIcons.arrow_left, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Icon(isAnon ? LucideIcons.cloud_upload : LucideIcons.cloud_check, color: primaryColor, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                isAnon ? 'auth.secure_data'.tr() : 'auth.cloud_account'.tr(), 
                style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.w900)
              ),
              const SizedBox(height: 12),
              Text(
                isAnon ? 'auth.secure_desc'.tr() : 'auth.connected_desc'.tr(),
                style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 40),

              if (!isAnon) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.4), width: 2),
                    boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: primaryColor, width: 2),
                          image: userAvatar != null ? DecorationImage(image: NetworkImage(userAvatar), fit: BoxFit.cover) : null,
                        ),
                        child: userAvatar == null ? Icon(LucideIcons.user, color: primaryColor, size: 30) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userName, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 18), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(user?.email ?? '', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.circle_check, color: Colors.green, size: 12),
                                  const SizedBox(width: 4),
                                  Text('auth.synced'.tr(), style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    HapticFeedback.heavyImpact();
                    await authService.signOut();
                  },
                  icon: const Icon(LucideIcons.log_out, color: Colors.redAccent),
                  label: Text('auth.logout'.tr(), style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ] 
              else ...[
                _isLoading 
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : _buildAuthButton(
                      context: context,
                      title: 'auth.continue_google'.tr(),
                      iconWidget: Container(
                        width: 28, height: 28,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Text('G', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'sans-serif')),
                      ),
                      bgColor: surfaceColor,
                      textColor: textColor,
                      borderColor: borderColor,
                      onTap: () async {
                        HapticFeedback.mediumImpact();
                        setState(() => _isLoading = true);
                        
                        final errorMessage = await authService.signInWithGoogle();
                        
                        if (!context.mounted) return; 
                        
                        setState(() => _isLoading = false);
                        
                        if (errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)), 
                              backgroundColor: Colors.redAccent,
                              duration: const Duration(seconds: 10), 
                            )
                          );
                        }
                      },
                    ),
                
                const Spacer(),
                Text(
                  'auth.terms_agree'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required BuildContext context, required String title, required Widget iconWidget,
    required Color bgColor, required Color textColor, required Color borderColor, required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: borderColor, width: 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 16),
              Expanded(child: Text(title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold))),
              Icon(context.locale.languageCode == 'ar' ? LucideIcons.chevron_left : LucideIcons.chevron_right, color: textColor.withValues(alpha: 0.3), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}