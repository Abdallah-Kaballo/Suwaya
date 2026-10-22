import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:suwaya/core/location/geo_database_service.dart';
import 'package:suwaya/features/settings/widgets/smart_location_picker.dart';
import 'package:suwaya/models/settings_model.dart';

import '../../settings/settings_provider.dart';


final nearestCityProvider = FutureProvider.family.autoDispose<String?, String>((ref, langCode) async {
  final loc = ref.watch(settingsProvider).activeLocation;
  if (loc == null) return null;
  
  if (loc.isAutoLocation || loc.countryCode == 'CUSTOM') {
    final data = await GeoDatabaseService.getNearestLocationData(loc.latitude, loc.longitude, langCode);
    return data?['cityName'] as String?;
  }
  return null; 
});

class LocationHeader extends ConsumerWidget {
  const LocationHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final loc = settings.activeLocation;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white70 : Colors.black87;

    void openPicker() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SmartLocationPicker(),
      );
    }

    if (loc == null) {
      return InkWell(
        onTap: openPicker,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.map_pin_off, color: textColor, size: 20),
            const SizedBox(width: 8),
            Text('header.set_location'.tr(), style: TextStyle(color: textColor, fontSize: 16)),
          ],
        ),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: openPicker,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: _buildSmartHeaderContent(loc, isDark, textColor, accentColor),
      ),
    );
  }

  Widget _buildSmartHeaderContent(
    SavedLocation loc, // 🌟 نوع صريح بدلاً من dynamic
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final String type = loc.locationType.isEmpty ? 'list' : loc.locationType;
    final String city = loc.nearestCity.isEmpty ? loc.name : loc.nearestCity;

    if (type == 'list') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.map_pin, size: 18, color: accentColor),
          const SizedBox(width: 6),
          Text(
            '${'header.current_city'.tr()} $city',
            style: TextStyle(color: accentColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    final latStr = loc.latitude.toStringAsFixed(3); // تقليل الأرقام العشرية لتوفير المساحة
    final lngStr = loc.longitude.toStringAsFixed(3);
    
    // 🌟 تصميم مدمج وأنيق يمنع القص ويتسع داخل الـ AppBar
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center, // توسيط رأسي
      children: [
        // السطر الأول: الأيقونة + الإحداثيات (أو الاسم) في سطر واحد
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(type == 'gps' ? LucideIcons.satellite : LucideIcons.navigation, size: 14, color: textColor),
            const SizedBox(width: 6),
            if (type == 'gps')
              Directionality(
                textDirection: ui.TextDirection.ltr,
                child: Text(
                  '$latStr°N, $lngStr°E',
                  style: TextStyle(color: textColor, fontSize: 13, fontFamily: 'monospace', letterSpacing: 0.5, fontWeight: FontWeight.bold),
                ),
              )
            else
              Text(
                loc.name, 
                style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        
        const SizedBox(height: 2), // مسافة صغيرة جداً
        
        // السطر الثاني: أقرب مدينة
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(LucideIcons.map_pin, size: 12, color: accentColor),
            const SizedBox(width: 4),
            Text(
              '${'header.nearest_city'.tr()} $city',
              style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}