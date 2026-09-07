import 'package:flutter/material.dart';

class AppLocales {
  static const List<Locale> supported = [
    Locale('ar'), Locale('en'), Locale('tr'), Locale('ru'), Locale('ur'),
    Locale('hi'), Locale('bn'), Locale('th'), Locale('ja'), Locale('zh'),
    Locale('ug'), Locale('pt'), Locale('ff'), Locale('az'), Locale('id'),
    Locale('ms'), Locale('da'), Locale('de'), Locale('es'), Locale('fr'),
    Locale('it'), Locale('nl'),
  ];

  static const String path = 'assets/translations';
  static const Locale fallback = Locale('ar');
}