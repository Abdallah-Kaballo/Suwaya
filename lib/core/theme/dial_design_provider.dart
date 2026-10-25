import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DialDesign { classic, minimal, geometric }

extension DialDesignExt on DialDesign {
  String get displayName {
    switch (this) {
      case DialDesign.classic:
        final tr = 'settings.design_classic'.tr();
        return tr != 'settings.design_classic' ? tr : 'Classic Astrolabe';
      case DialDesign.minimal:
        final tr = 'settings.design_minimal'.tr();
        return tr != 'settings.design_minimal' ? tr : 'Minimal';
      case DialDesign.geometric:
        final tr = 'settings.design_geometric'.tr();
        return tr != 'settings.design_geometric' ? tr : 'Islamic Geometric';
    }
  }
}

final dialDesignProvider =
    StateNotifierProvider<DialDesignNotifier, DialDesign>((ref) {
      return DialDesignNotifier();
    });

class DialDesignNotifier extends StateNotifier<DialDesign> {
  DialDesignNotifier() : super(DialDesign.classic) {
    _loadDesign();
  }

  Future<void> _loadDesign() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('selected_dial_design') ?? 0;
    state = DialDesign.values[index];
  }

  Future<void> changeDesign(DialDesign newDesign) async {
    state = newDesign;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_dial_design', newDesign.index);
  }
}