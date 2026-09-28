import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kSupportedLocales = [
  Locale('en'),
  Locale('si'),
  Locale('ta'),
];

const Map<String, String> kLanguageNames = {
  'en': 'English',
  'si': 'සිංහල',
  'ta': 'தமிழ்',
};

class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'app_locale';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && kSupportedLocales.any((l) => l.languageCode == code)) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
