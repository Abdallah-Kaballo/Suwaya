import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

final themeColorProvider = StateNotifierProvider<ThemeColorNotifier, AppColorTheme>((ref) {
  return ThemeColorNotifier();
});

class ThemeColorNotifier extends StateNotifier<AppColorTheme> {
  ThemeColorNotifier() : super(AppColorTheme.gold) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('selected_color_theme') ?? 0;
    state = AppColorTheme.values[index];
  }

  Future<void> changeTheme(AppColorTheme newTheme) async {
    state = newTheme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_color_theme', newTheme.index);
  }
}