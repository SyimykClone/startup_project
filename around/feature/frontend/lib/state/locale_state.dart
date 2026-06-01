import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleState extends ChangeNotifier {
  static const _prefsKey = 'app_locale_code';

  Locale _locale = const Locale('ru');

  Locale get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == 'en' || code == 'ru') {
      _locale = Locale(code!);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['ru', 'en'].contains(locale.languageCode)) return;
    if (_locale.languageCode == locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
