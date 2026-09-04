import 'package:flutter/material.dart';

class AppTheme {
  static const String fontFamily = 'Tajawal';
  static const Color goldAccent = Color(0xFFD4AF37); // الذهبي المضيء (لليل)
  static const Color darkGoldAccent = Color(0xFFB8860B); // الذهبي الداكن (للنهار للوضوح)

  // 🌙 1. الثيم الداكن (OLED Black الموفر للبطارية)
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black, // 🌟 أسود مطلق للخلفيات
      primaryColor: goldAccent,
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: goldAccent,
        secondary: goldAccent,
        surface: Color(0xFF0A0A0F), // 🌟 رمادي كحلي داكن جداً للأسطح
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: fontFamily),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.black, // 🌟 شريط تنقل أسود ليدمج مع الشاشة
        selectedItemColor: goldAccent,
        unselectedItemColor: Colors.white38,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),
      cardColor: const Color(0xFF0A0A0F), // 🌟 لون الكروت
      canvasColor: const Color(0xFF0A0A0F), // 🌟 لون النوافذ المنبثقة
      
      // 🌟 تم تصحيح الكلاس إلى DialogThemeData
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF0A0A0F),
      ),
      
      dividerColor: Colors.white.withValues(alpha: 0.05), // 🌟 خطوط فصل خفيفة جداً
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF0A0A0F),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }

  // ☀️ 2. الثيم المضيء (النهاري المريح للعين)
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F6F9), // رمادي فاتح مريح
      primaryColor: darkGoldAccent, 
      fontFamily: fontFamily,
      colorScheme: const ColorScheme.light(
        primary: darkGoldAccent,
        secondary: darkGoldAccent,
        surface: Colors.white,
        onSurface: Color(0xFF0B0F19),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF0B0F19)),
        titleTextStyle: TextStyle(color: Color(0xFF0B0F19), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: fontFamily),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: darkGoldAccent,
        unselectedItemColor: Colors.black38,
        elevation: 15,
        type: BottomNavigationBarType.fixed,
      ),
      cardColor: Colors.white,
      
      // 🌟 تم تصحيح الكلاس إلى DialogThemeData للثيم النهاري أيضاً
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
      ),
      
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