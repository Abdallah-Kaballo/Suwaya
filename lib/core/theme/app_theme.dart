import 'package:flutter/material.dart';

enum AppColorTheme { gold, ocean, forest, desert }

class AppTheme {
  static const String fontFamily = 'Tajawal';

  static Color _getPrimaryLight(AppColorTheme theme) {
    switch (theme) {
      case AppColorTheme.gold:
        return const Color(0xFF8A5A00);
      case AppColorTheme.ocean:
        return const Color(0xFF006B60);
      case AppColorTheme.forest:
        return const Color(0xFF246B2A);
      case AppColorTheme.desert:
        return const Color(0xFFB93815);
    }
  }

  static Color _getPrimaryDark(AppColorTheme theme) {
    switch (theme) {
      case AppColorTheme.gold:
        return const Color(0xFFE5C158);
      case AppColorTheme.ocean:
        return const Color(0xFF4DB6AC);
      case AppColorTheme.forest:
        return const Color(0xFF81C784);
      case AppColorTheme.desert:
        return const Color(0xFFFF8A65);
    }
  }

  static ThemeData getDarkTheme(AppColorTheme theme) {
    final primary = _getPrimaryDark(theme);
    const bgScaffold = Color(0xFF121316);
    const surfaceCard = Color(0xFF1C1E24);
    const surfaceElevated = Color(0xFF24272F);
    const borderGray = Color(0xFF2E3340);
    const textPrimary = Color(0xFFF3F4F6);
    const textSecondary = Color(0xFFA1A8B8);
    const onPrimaryDark = Color(0xFF0F172A); // تباين فائق (> 10:1) فوق الذهبي والألوان الفاتحة

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgScaffold,
      primaryColor: primary,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: onPrimaryDark,
        secondary: primary,
        onSecondary: onPrimaryDark,
        surface: surfaceCard,
        surfaceContainerHighest: surfaceElevated,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: borderGray,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimaryDark,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary, size: 22),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          fontFamily: fontFamily,
          letterSpacing: 0.2,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      cardColor: surfaceCard,
      canvasColor: surfaceCard,
      dividerColor: borderGray,
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  static ThemeData getLightTheme(AppColorTheme theme) {
    final primary = _getPrimaryLight(theme);
    const bgScaffold = Color(0xFFF4F6F9);
    const surfaceCard = Color(0xFFFFFFFF);
    const surfaceElevated = Color(0xFFF8FAFC);
    const borderGray = Color(0xFFE2E8F0);
    const textPrimary = Color(0xFF0F172A);
    const textSecondary = Color(0xFF475569);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgScaffold,
      primaryColor: primary,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        secondary: primary,
        onSecondary: Colors.white,
        surface: surfaceCard,
        surfaceContainerHighest: surfaceElevated,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: borderGray,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary, size: 22),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          fontFamily: fontFamily,
          letterSpacing: 0.2,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceCard,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      cardColor: surfaceCard,
      canvasColor: surfaceCard,
      dividerColor: borderGray,
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  static ThemeMode getThemeMode(
    String themeModeString, {
    required bool isDayTime,
  }) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'mixed':
        return isDayTime ? ThemeMode.light : ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}