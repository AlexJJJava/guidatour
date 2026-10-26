import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const supportedLocales = [Locale('it'), Locale('en'), Locale('es')];

const _localeNames = {'it': 'Italiano', 'en': 'English', 'es': 'Español'};

String localeDisplayName(Locale locale) =>
    _localeNames[locale.languageCode] ?? locale.languageCode;

class LocaleController extends ValueNotifier<Locale> {
  LocaleController() : super(const Locale('it')) {
    _restore();
  }

  static const _prefKey = 'locale';

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && supportedLocales.any((l) => l.languageCode == saved)) {
      value = Locale(saved);
    }
  }

  Future<void> setLocale(Locale locale) async {
    value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, locale.languageCode);
  }
}

final localeController = LocaleController();
