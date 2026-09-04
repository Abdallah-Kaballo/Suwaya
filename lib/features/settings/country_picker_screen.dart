import 'package:flutter/material.dart';
import '../../core/services/geo_search_service.dart';
import 'package:easy_localization/easy_localization.dart';

class CountryPickerScreen extends StatefulWidget {
  const CountryPickerScreen({super.key});
  @override
  State<CountryPickerScreen> createState() => _CountryPickerScreenState();
}

class _CountryPickerScreenState extends State<CountryPickerScreen> {
  List<Map<String, dynamic>> _countries = [];
  bool _loading = true;

  final Map<String, String> _countryNames = {
    'SA': 'السعودية', 'EG': 'مصر', 'AE': 'الإمارات', 'KW': 'الكويت',
    'QA': 'قطر', 'BH': 'البحرين', 'OM': 'عُمان', 'YE': 'اليمن',
    'IQ': 'العراق', 'SY': 'سوريا', 'JO': 'الأردن', 'LB': 'لبنان',
    'PS': 'فلسطين', 'DZ': 'الجزائر', 'MA': 'المغرب', 'TN': 'تونس',
    'LY': 'ليبيا', 'SD': 'السودان', 'TR': 'تركيا', 'US': 'الولايات المتحدة',
    'GB': 'بريطانيا', 'FR': 'فرنسا', 'DE': 'ألمانيا',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await GeoSearchService.getCountries(context.locale.languageCode);
    setState(() {
      _countries = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('اختر الدولة', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : ListView.builder(
              itemCount: _countries.length,
              itemBuilder: (context, index) {
                final code = _countries[index]['code'] as String;
                final displayName = _countryNames[code] ?? code;
                return ListTile(
                  leading: Text(GeoSearchService.getFlagEmoji(code),
                      style: const TextStyle(fontSize: 24)),
                  title: Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: Text(code, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  onTap: () => Navigator.pop(context, code),
                );
              },
            ),
    );
  }
}