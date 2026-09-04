import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../settings/settings_provider.dart';
import '../../../core/services/geo_search_service.dart';
import '../../settings/settings_screen.dart';


final nearestCityProvider = FutureProvider.family.autoDispose<String?, String>((ref, langCode) async {
  final loc = ref.watch(settingsProvider).activeLocation;
  if (loc == null) return null;
  
  if (loc.isAutoLocation || loc.countryCode == 'CUSTOM') {
    final data = await GeoSearchService.getNearestLocationData(loc.latitude, loc.longitude, langCode);
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

    if (loc == null) {
      return InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: _buildSmartHeaderContent(loc, isDark, textColor, accentColor),
      ),
    );
  }

  Widget _buildSmartHeaderContent(dynamic loc, bool isDark, Color textColor, Color accentColor) {
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

    final latStr = loc.latitude.toStringAsFixed(4);
    final lngStr = loc.longitude.toStringAsFixed(4);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type == 'gps' ? LucideIcons.satellite : LucideIcons.navigation, size: 14, color: isDark ? Colors.white54 : Colors.black54),
            const SizedBox(width: 6),
            Text('header.current_location'.tr(), style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        if (type == 'gps')
          Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Text(
              '$latStr°N, $lngStr°E',
              style: TextStyle(color: textColor, fontSize: 14, fontFamily: 'monospace', letterSpacing: 1.0, fontWeight: FontWeight.bold),
            ),
          )
        else
          Text(
            loc.name, 
            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.map_pin, size: 14, color: accentColor),
            const SizedBox(width: 4),
            Text(
              '${'header.nearest_city'.tr()} $city',
              style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}