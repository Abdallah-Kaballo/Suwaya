import 'package:flutter/material.dart';

// 🌟 1. تعريف الثيمات المتاحة
enum AppColorTheme { gold, ocean, forest, desert }

class AppTheme {
  static const String fontFamily = 'Tajawal';

  // 🌟 2. درجات الألوان للوضع الفاتح
  static Color _getPrimaryLight(AppColorTheme theme) {
    switch (theme) {
      case AppColorTheme.gold: return const Color(0xFFB8860B);
      case AppColorTheme.ocean: return const Color(0xFF00897B); // تيل / محيطي
      case AppColorTheme.forest: return const Color(0xFF2E7D32); // أخضر غابة
      case AppColorTheme.desert: return const Color(0xFFD84315); // برتقالي صحراوي
    }
  }

  // 🌟 3. درجات الألوان للوضع الداكن (OLED)
  static Color _getPrimaryDark(AppColorTheme theme) {
    switch (theme) {
      case AppColorTheme.gold: return const Color(0xFFD4AF37);
      case AppColorTheme.ocean: return const Color(0xFF4DB6AC);
      case AppColorTheme.forest: return const Color(0xFF81C784);
      case AppColorTheme.desert: return const Color(0xFFFF8A65);
    }
  }

  // 🌙 الثيم الداكن المحدث
  static ThemeData getDarkTheme(AppColorTheme theme) {
    final primary = _getPrimaryDark(theme);
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      primaryColor: primary,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: const Color(0xFF0A0A0F),
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: fontFamily),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: primary,
        unselectedItemColor: Colors.white38,
        elevation: 10, type: BottomNavigationBarType.fixed,
      ),
      cardColor: const Color(0xFF0A0A0F),
      canvasColor: const Color(0xFF0A0A0F),
      dialogTheme: const DialogThemeData(backgroundColor: Color(0xFF0A0A0F)),
      dividerColor: Colors.white.withValues(alpha: 0.05),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF0A0A0F), surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
    );
  }

  // ☀️ الثيم المضيء المحدث
  static ThemeData getLightTheme(AppColorTheme theme) {
    final primary = _getPrimaryLight(theme);
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      primaryColor: primary,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: Colors.white,
        onSurface: const Color(0xFF0B0F19),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF0B0F19)),
        titleTextStyle: TextStyle(color: Color(0xFF0B0F19), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: fontFamily),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.black38,
        elevation: 15, type: BottomNavigationBarType.fixed,
      ),
      cardColor: Colors.white,
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      dividerColor: Colors.black12,
    );
  }

  static ThemeMode getThemeMode(String themeModeString, {required bool isDayTime}) {
    switch (themeModeString) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      case 'system': return ThemeMode.system;
      case 'mixed': return isDayTime ? ThemeMode.light : ThemeMode.dark;
      default: return ThemeMode.dark;
    }
  }
}