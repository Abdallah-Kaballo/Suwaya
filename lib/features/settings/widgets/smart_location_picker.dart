import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/geo_search_service.dart';
import '../../../core/services/location_service.dart'; 
import '../settings_provider.dart';

enum LocationStep { method, manualChoice, dropdowns, coordinates, savedLocations }

Future<void> _applySmartSettings(String countryCode, String countryName, WidgetRef ref) async {
  final c = countryName.toLowerCase();
  
  String method = 'muslim_world_league';
  if (countryCode == 'EG' || c.contains('مصر') || c.contains('سودان')) {
    method = 'egyptian';
  } else if (countryCode == 'SA' || c.contains('سعودية')) {
    method = 'umm_al_qura';
  } else if (countryCode == 'PK' || countryCode == 'IN' || c.contains('باكستان') || c.contains('هند')) {
    method = 'karachi';
  } else if (countryCode == 'TR' || c.contains('تركيا')) {
    method = 'turkey';
  } else if (countryCode == 'KW' || c.contains('كويت')) {
    method = 'kuwait';
  } else if (countryCode == 'QA' || c.contains('قطر')) {
    method = 'qatar';
  } else if (countryCode == 'AE' || c.contains('إمارات')) {
    method = 'dubai';
  } else if (countryCode == 'US' || countryCode == 'CA' || c.contains('أمريكا') || c.contains('كندا')) {
    method = 'north_america';
  } else if (countryCode == 'IR' || c.contains('إيران')) {
    method = 'tehran';
  }

  String madhab = 'shafi';
  if (['PK', 'IN', 'TR', 'BD', 'AF'].contains(countryCode.toUpperCase())) {
    madhab = 'hanafi';
  }

  await ref.read(settingsProvider.notifier).updateCalculationMethod(method);
  await ref.read(settingsProvider.notifier).updateMadhab(madhab);
}

class SmartLocationPicker extends ConsumerStatefulWidget {
  final bool startAtManualLists;
  const SmartLocationPicker({super.key, this.startAtManualLists = false});
  
  @override
  ConsumerState<SmartLocationPicker> createState() => _SmartLocationPickerState();
}

class _SmartLocationPickerState extends ConsumerState<SmartLocationPicker> {
  late LocationStep _step;
  List<Map<String, String>> _countries = [];
  Map<String, String>? _selectedCountry;
  List<Map<String, dynamic>> _cities = [];
  bool _isLoadingData = true;
  bool _isLoadingCities = false;
  bool _isFetchingGps = false; 

  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _step = widget.startAtManualLists ? LocationStep.dropdowns : LocationStep.method;
    Future.microtask(() => _initData());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!mounted) return;
    final langCode = context.locale.languageCode;
    
    await GeoSearchService.loadDatabase();
    
    if (!mounted) return;
    final countries = await GeoSearchService.getCountries(langCode);
    
    if (!mounted) return;
    setState(() {
      _countries = countries; 
      _isLoadingData = false; 
    });
  }

  Future<void> _loadCitiesForCountry(String countryCode) async {
    setState(() => _isLoadingCities = true);
    try {
      final langCode = context.locale.languageCode;
      final rawCities = await GeoSearchService.getCitiesByCountry(countryCode);
      final mutableCities = List<Map<String, dynamic>>.from(rawCities);
      
      mutableCities.sort((a, b) {
        String nameA = (langCode == 'ar' ? (a['name'] ?? a['nameEn']) : (a['nameEn'] ?? a['name']))?.toString().trim() ?? '';
        String nameB = (langCode == 'ar' ? (b['name'] ?? b['nameEn']) : (b['nameEn'] ?? b['name']))?.toString().trim() ?? '';
        return nameA.compareTo(nameB);
      });
      if (!mounted) return;
      setState(() {
        _cities = mutableCities;
        _isLoadingCities = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCities = false);
    }
  }

  void _goBack() {
    setState(() {
      if (_step == LocationStep.coordinates || _step == LocationStep.dropdowns) {
        _step = LocationStep.manualChoice;
      } else if (_step == LocationStep.manualChoice || _step == LocationStep.savedLocations) {
        _step = LocationStep.method;
      }
    });
  }

  void _saveCustomCoordinates() async {
    final name = _nameController.text.trim();
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('location_picker.location_name_required'.tr(), style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white)), backgroundColor: Colors.redAccent));
      return;
    }

    if (lat == null || lat < -90 || lat > 90) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('location_picker.lat_validation_error'.tr(), style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white)), backgroundColor: Colors.redAccent));
      return;
    }

    if (lng == null || lng < -180 || lng > 180) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('location_picker.lng_validation_error'.tr(), style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white)), backgroundColor: Colors.redAccent));
      return;
    }

    final notifier = ref.read(settingsProvider.notifier);
    final langCode = context.locale.languageCode;

    final localData = await GeoSearchService.getNearestLocationData(lat, lng, langCode);
    String countryCode = 'CUSTOM';
    String countryName = 'غير معروف';

    if (localData != null) {
      countryCode = localData['countryCode'] ?? 'CUSTOM';
      countryName = GeoSearchService.getLocalizedCountryName(countryCode, langCode);
    }

    await notifier.addAndSelectLocation(name, lat, lng, countryCode);
    await _applySmartSettings(countryCode, countryName, ref);

    if (!mounted) return;
    
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('location_picker.location_updated'.tr(), style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white)), 
      backgroundColor: Colors.green.shade800
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = isDark ? Colors.white54 : Colors.black54;
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(color: surfaceColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 20), decoration: BoxDecoration(color: hintColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (_step != LocationStep.method)
                  IconButton(icon: Icon(context.locale.languageCode == 'ar' ? LucideIcons.arrow_right : LucideIcons.arrow_left, color: textColor), onPressed: _goBack)
                else
                  const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    _step == LocationStep.method ? 'location_picker.locate_accurately'.tr() :
                    _step == LocationStep.manualChoice ? 'location_picker.manual_choice'.tr() :
                    _step == LocationStep.dropdowns ? 'location_picker.choose_region'.tr() : 
                    _step == LocationStep.savedLocations ? 'location_picker.saved_locations'.tr() : 'location_picker.custom_coordinates'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoadingData 
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _buildCurrentStepView(isDark, surfaceColor, textColor, hintColor, primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepView(bool isDark, Color surfaceColor, Color textColor, Color hintColor, Color primaryColor) {
    switch (_step) {
      case LocationStep.method: return _buildMethodStep(isDark, textColor, primaryColor);
      case LocationStep.manualChoice: return _buildManualChoiceStep(isDark, textColor);
      case LocationStep.dropdowns: return _buildDropdownsStep(isDark, surfaceColor, textColor, hintColor, primaryColor);
      case LocationStep.coordinates: return _buildCoordinatesStep(isDark, textColor, hintColor, primaryColor);
      case LocationStep.savedLocations: return _buildSavedLocationsStep(isDark, textColor, hintColor, primaryColor);
    }
  }

  Widget _buildMethodStep(bool isDark, Color textColor, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: _isFetchingGps 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.crosshair, size: 20), 
            label: Text(_isFetchingGps ? 'onboarding.fetching_gps'.tr() : 'onboarding.update_gps'.tr(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

                if (!mounted) return; 

                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${'onboarding.gps_success'.tr()} ${locData['formattedName']}'), backgroundColor: Colors.green),
                );
                
              } catch (e) {
                if (!mounted) return;

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
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.map, size: 20), label: Text('onboarding.manual_select'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), foregroundColor: textColor,
              minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
            ),
            onPressed: () => setState(() => _step = LocationStep.manualChoice),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            icon: const Icon(LucideIcons.bookmark, size: 20), label: Text('location_picker.saved_locations'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), foregroundColor: textColor,
              minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0,
            ),
            onPressed: () => setState(() => _step = LocationStep.savedLocations),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedLocationsStep(bool isDark, Color textColor, Color hintColor, Color primaryColor) {
    final savedLocs = ref.watch(settingsProvider).savedLocations.reversed.toList();
    if (savedLocs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.map_pin_off, size: 48, color: hintColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('location_picker.no_saved_locations'.tr(), style: TextStyle(color: hintColor, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: savedLocs.length,
      itemBuilder: (context, index) {
        final loc = savedLocs[index];
        final bool isCustom = loc.countryCode == 'CUSTOM';
        
        return Card(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
          elevation: 0, margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              child: Icon(isCustom ? LucideIcons.navigation : LucideIcons.map_pin, color: primaryColor, size: 18),
            ),
            title: Text(loc.name, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            subtitle: Text(
              isCustom ? '${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}' : '${loc.name}، ${loc.countryCode}',
              style: TextStyle(color: hintColor, fontSize: 12),
            ),
            onTap: () {
              ref.read(settingsProvider.notifier).selectSavedLocation(loc);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  Widget _buildManualChoiceStep(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.list, size: 20), label: Text('location_picker.choose_from_lists'.tr()),
            style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), foregroundColor: textColor, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            onPressed: () => setState(() => _step = LocationStep.dropdowns),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.map_pin, size: 20), label: Text('location_picker.enter_coordinates_manually'.tr()),
            style: ElevatedButton.styleFrom(backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), foregroundColor: textColor, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
            onPressed: () => setState(() => _step = LocationStep.coordinates),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownsStep(bool isDark, Color surfaceColor, Color textColor, Color hintColor, Color primaryColor) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Material(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03), 
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                showModalBottomSheet(
                  context: context, isScrollControlled: true, backgroundColor: surfaceColor,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (_) => _CountrySearchSheet(
                    countries: _countries,
                    onSelected: (country) {
                      setState(() { _selectedCountry = country; _cities.clear(); });
                      _loadCitiesForCountry(country['code']!);
                    },
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.white12 : Colors.black12), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(LucideIcons.globe, color: _selectedCountry != null ? primaryColor : hintColor, size: 20), 
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCountry != null ? '${GeoSearchService.getFlagEmoji(_selectedCountry!['code']!)} ${_selectedCountry!['name']}' : 'location_picker.select_country'.tr(),
                        style: TextStyle(color: _selectedCountry != null ? textColor : hintColor, fontSize: 16, fontWeight: _selectedCountry != null ? FontWeight.bold : FontWeight.normal),
                      )
                    ),
                    Icon(LucideIcons.chevron_down, color: hintColor, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Opacity(
          opacity: _selectedCountry != null ? 1.0 : 0.4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Material(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03), 
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _selectedCountry != null && !_isLoadingCities ? () {
                  showModalBottomSheet(
                    context: context, isScrollControlled: true, backgroundColor: surfaceColor,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (_) => _CitySearchSheet(
                      cities: _cities,
                      onSelected: (city) async {
                        final notifier = ref.read(settingsProvider.notifier);
                        final langCode = context.locale.languageCode;
                        
                        final cityName = langCode == 'ar' ? (city['name'] ?? city['nameEn']) : (city['nameEn'] ?? city['name']);
                        final countryCode = city['countryCode'];
                        final countryName = GeoSearchService.getLocalizedCountryName(countryCode, langCode);

                        await notifier.addAndSelectLocation(
                          cityName, 
                          (city['lat'] as num).toDouble(), 
                          (city['lng'] as num).toDouble(), 
                          countryCode,
                          timezone: city['timezone'], 
                          locationType: 'list',       
                          nearestCity: cityName,     
                        );
                        
                        await _applySmartSettings(countryCode, countryName, ref);
                        
                        if (!mounted) return;
                        
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('location_picker.location_updated'.tr()), 
                          backgroundColor: Colors.green.shade800
                        ));
                      },
                    ),
                  );
                } : null,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.white12 : Colors.black12), borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Icon(LucideIcons.map_pin, color: _selectedCountry != null ? primaryColor : hintColor, size: 20), 
                      const SizedBox(width: 12),
                      Expanded(child: Text(_isLoadingCities ? 'location_picker.loading'.tr() : 'location_picker.select_city'.tr(), style: TextStyle(color: hintColor, fontSize: 16))),
                      if (_isLoadingCities) 
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor))
                      else 
                        Icon(LucideIcons.chevron_down, color: hintColor, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoordinatesStep(bool isDark, Color textColor, Color hintColor, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          TextField(
            controller: _nameController, style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'location_picker.location_name_example'.tr(), labelStyle: TextStyle(color: hintColor),
              filled: true, fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _latController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(labelText: 'location_picker.latitude'.tr(), labelStyle: TextStyle(color: hintColor), filled: true, fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _lngController, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(labelText: 'location_picker.longitude'.tr(), labelStyle: TextStyle(color: hintColor), filled: true, fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(LucideIcons.save, size: 18), label: Text('location_picker.save_use'.tr()),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: isDark ? Colors.black87 : Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            onPressed: _saveCustomCoordinates,
          ),
        ],
      ),
    );
  }
}

class _CountrySearchSheet extends StatefulWidget {
  final List<Map<String, String>> countries;
  final Function(Map<String, String>) onSelected;
  const _CountrySearchSheet({required this.countries, required this.onSelected});
  @override
  State<_CountrySearchSheet> createState() => _CountrySearchSheetState();
}

class _CountrySearchSheetState extends State<_CountrySearchSheet> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = isDark ? Colors.white54 : Colors.black54;

    final filtered = widget.countries.where((c) => c['name']!.toLowerCase().contains(_query.toLowerCase())).toList();
    return Container(
      height: MediaQuery.of(context).size.height * 0.8, padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: hintColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
          TextField(
            autofocus: true, onChanged: (val) => setState(() => _query = val), style: TextStyle(color: textColor),
            decoration: InputDecoration(hintText: 'location_picker.search_country'.tr(), hintStyle: TextStyle(color: hintColor), prefixIcon: Icon(LucideIcons.search, color: hintColor), filled: true, fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final country = filtered[index];
                return ListTile(
                  leading: Text(GeoSearchService.getFlagEmoji(country['code']!), style: const TextStyle(fontSize: 24)),
                  title: Text(country['name']!, style: TextStyle(color: textColor)),
                  onTap: () { Navigator.pop(context); widget.onSelected(country); },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CitySearchSheet extends StatefulWidget {
  final List<Map<String, dynamic>> cities;
  final Function(Map<String, dynamic>) onSelected;
  const _CitySearchSheet({required this.cities, required this.onSelected});
  @override
  State<_CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<_CitySearchSheet> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final hintColor = isDark ? Colors.white54 : Colors.black54;
    final primaryColor = Theme.of(context).primaryColor;

    final langCode = context.locale.languageCode;
    final filtered = widget.cities.where((c) {
      final nameAr = (c['name'] ?? '').toString().toLowerCase();
      final nameEn = (c['nameEn'] ?? '').toString().toLowerCase();
      final q = _query.toLowerCase();
      return nameAr.contains(q) || nameEn.contains(q);
    }).toList();
    return Container(
      height: MediaQuery.of(context).size.height * 0.8, padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: hintColor.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4))),
          TextField(
            autofocus: true, onChanged: (val) => setState(() => _query = val), style: TextStyle(color: textColor),
            decoration: InputDecoration(hintText: 'location_picker.search_city_hint'.tr(), hintStyle: TextStyle(color: hintColor), prefixIcon: Icon(LucideIcons.search, color: hintColor), filled: true, fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('location_picker.try_english_name'.tr(), style: TextStyle(color: hintColor)))
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final city = filtered[index];
                      final cityName = langCode == 'ar' ? (city['name'] ?? city['nameEn']) : (city['nameEn'] ?? city['name']);
                      return ListTile(
                        leading: Icon(LucideIcons.map_pin, color: primaryColor),
                        title: Text(cityName, style: TextStyle(color: textColor)),
                        subtitle: langCode == 'ar' && city['nameEn'] != null ? Text(city['nameEn'], style: TextStyle(color: hintColor, fontSize: 12)) : null,
                        onTap: () { Navigator.pop(context); widget.onSelected(city); },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}