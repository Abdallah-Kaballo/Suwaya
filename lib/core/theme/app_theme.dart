import 'package:flutter/material.dart';

enum AppColorTheme { gold, ocean, forest, desert }

class AppTheme {
  static const String fontFamily = 'Tajawal';

  // 🌟 درجات الألوان للوضع الفاتح
  static Color _getPrimaryLight(AppColorTheme theme) {
    switch (theme) {
      case AppColorTheme.gold:
        return const Color(0xFFB8860B);
      case AppColorTheme.ocean:
        return const Color(0xFF00897B);
      case AppColorTheme.forest:
        return const Color(0xFF2E7D32);
      case AppColorTheme.desert:
        return const Color(0xFFD84315);
    }
  }

  // 🌟 درجات الألوان للوضع الداكن الاحترافي
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

  // 🌙 الثيم الداكن القياسي المتدرج والمريح للعين (Multi-Tiered Dark Gray)
  static ThemeData getDarkTheme(AppColorTheme theme) {
    final primary = _getPrimaryDark(theme);
    const bgScaffold = Color(0xFF121316); // خلفية رمادية داكنة مريحة للعين
    const surfaceCard = Color(0xFF1C1E24); // طبقة البطاقات الأولى
    const surfaceElevated = Color(0xFF24272F); // طبقة النوافذ المنبثقة والحوارات
    const borderGray = Color(0xFF2C303A); // حدود وفواصل ناعمة
    const textPrimary = Color(0xFFF3F4F6); // أبيض دافئ مريح للقراءة
    const textSecondary = Color(0xFF9CA3AF); // رمادي متوازن للنصوص الفرعية

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgScaffold,
      primaryColor: primary,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: primary,
        surface: surfaceCard,
        surfaceContainerHighest: surfaceElevated,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: borderGray,
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
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          fontFamily: fontFamily,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
          fontFamily: fontFamily,
          height: 1.4,
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

  // ☀️ الثيم المضيء
  static ThemeData getLightTheme(AppColorTheme theme) {
    final primary = _getPrimaryLight(theme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      primaryColor: primary,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primary,
        surface: Colors.white,
        onSurface: const Color(0xFF111827),
        onSurfaceVariant: const Color(0xFF6B7280),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF111827), size: 22),
        titleTextStyle: TextStyle(
          color: Color(0xFF111827),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          fontFamily: fontFamily,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Colors.black45,
        elevation: 15,
        type: BottomNavigationBarType.fixed,
      ),
      cardColor: Colors.white,
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      dividerColor: const Color(0xFFE5E7EB),
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
        return ThemeMode.dark;
    }
  }
}