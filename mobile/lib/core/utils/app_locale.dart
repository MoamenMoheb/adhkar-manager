import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocale extends ChangeNotifier {
  static final AppLocale instance = AppLocale._internal();
  AppLocale._internal();

  static const String _prefLang = 'app_language_code';
  String _code = 'ar';

  String get code => _code;
  bool get isAr => _code == 'ar';
  Locale get locale => Locale(_code);

  String tr(String ar, String en) => isAr ? ar : en;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefLang);
      if (saved == 'ar' || saved == 'en') {
        _code = saved!;
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String code) async {
    if (code != 'ar' && code != 'en') return;
    if (_code == code) return;
    _code = code;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefLang, code);
    } catch (_) {}
  }
}
