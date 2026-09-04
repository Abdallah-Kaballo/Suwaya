import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:geolocator/geolocator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:suwaya/core/services/location_service.dart'; 

import 'package:suwaya/features/settings/settings_provider.dart';
import 'package:suwaya/features/settings/widgets/smart_location_picker.dart';
import 'package:suwaya/features/layout/main_layout.dart'; 
import 'package:suwaya/core/services/permissions_provider.dart';

class OnboardingLocationScreen extends ConsumerStatefulWidget {
  const OnboardingLocationScreen({super.key});

  @override
  ConsumerState<OnboardingLocationScreen> createState() => _OnboardingLocationScreenState();
}

class _OnboardingLocationScreenState extends ConsumerState<OnboardingLocationScreen> {
  bool _isFetchingGps = false; 

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isLocationSet = settings.activeLocation != null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: isLocationSet ? Colors.green.withValues(alpha: 0.1) : primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(isLocationSet ? LucideIcons.map_pin_check : LucideIcons.compass, color: isLocationSet ? Colors.green : primaryColor, size: 48),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('onboarding.set_location'.tr(), textAlign: TextAlign.center, style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    
                    Text('onboarding.location_desc'.tr(), textAlign: TextAlign.center, style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 14, height: 1.5)),
                    
                    const SizedBox(height: 48),

                    if (isLocationSet) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          children: [
                            Text('onboarding.location_success'.tr(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(settings.activeLocation!.name, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => _openLocationPicker(context, true),
                              icon: const Icon(LucideIcons.pencil, size: 16, color: Colors.green),
                              label: Text('onboarding.change_location'.tr(), style: const TextStyle(color: Colors.green)),
                            )
                          ],
                        ),
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        icon: _isFetchingGps 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(LucideIcons.crosshair, size: 20), 
                        label: Text(_isFetchingGps ? 'onboarding.fetching_gps'.tr() : 'onboarding.update_gps'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent, 
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _isFetchingGps ? null : () async {
                          setState(() => _isFetchingGps = true);
                          try { 
                            final langCode = Localizations.localeOf(context).languageCode;
                            final locData = await SmartGpsEngine.fetchOfflineLocation(langCode);
                            
                            await ref.read(settingsProvider.notifier).addAndSelectLocation(
                              locData['formattedName'], 
                              locData['lat'],
                              locData['lng'],
                              locData['countryCode'],
                              locationType: 'gps',             
                              nearestCity: locData['city'],    
                            );

                            await ref.read(settingsProvider.notifier).updateCalculationMethod(locData['method']);
                            await ref.read(settingsProvider.notifier).updateMadhab(locData['madhab']);

                            if (!context.mounted) return; 

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${'onboarding.gps_success'.tr()} ${locData['formattedName']}'), backgroundColor: Colors.green),
                            );
                            
                          } catch (e) {
                            if (!context.mounted) return;

                            final errorMsg = e.toString().toLowerCase();
                            
                            if (errorMsg.contains('gps_disabled') || errorMsg.contains('disabled') || errorMsg.contains('location services are disabled')) {
                              Geolocator.openLocationSettings();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('onboarding.gps_failed'.tr()),
                                  backgroundColor: Colors.redAccent.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _isFetchingGps = false);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      ElevatedButton.icon(
                        onPressed: () => _openLocationPicker(context, true), 
                        icon: const Icon(LucideIcons.map),
                        label: Text('onboarding.manual_select'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                          foregroundColor: textColor,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ],

                    const Spacer(),
                    const SizedBox(height: 24), 

                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: isLocationSet ? 1.0 : 0.4,
                      child: ElevatedButton(
                        onPressed: isLocationSet ? () async {
                          HapticFeedback.heavyImpact();
                          
                          await ref.read(permissionsProvider.notifier).requestInitialPermissions();
                          await ref.read(settingsProvider.notifier).completeOnboarding();
                          
                          if (!context.mounted) return;
                          
                          await Future.delayed(const Duration(milliseconds: 150));
                          
                          if (!context.mounted) return; 
                          Navigator.pushAndRemoveUntil(
                            context, 
                            MaterialPageRoute(builder: (_) => const MainLayout()), 
                            (route) => false
                          );
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: Text('onboarding.start_journey'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLocationPicker(BuildContext context, bool startManual) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (_) => SmartLocationPicker(startAtManualLists: startManual)
    );
  }
}