// lib/app_settings.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_l10n.dart';

class AppSettings extends ChangeNotifier {
  Locale _locale = const Locale('fr');
  ThemeMode _themeMode = ThemeMode.light;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  AppL10n get l10n => AppL10n(isAr: _locale.languageCode == 'ar');

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _locale = (p.getString('language') ?? 'FR') == 'AR'
        ? const Locale('ar')
        : const Locale('fr');
    _themeMode = switch (p.getString('theme') ?? 'Clair') {
      'Sombre' => ThemeMode.dark,
      'Système' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('language', lang);
    _locale = lang == 'AR' ? const Locale('ar') : const Locale('fr');
    notifyListeners();
  }

  Future<void> setTheme(String theme) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('theme', theme);
    _themeMode = switch (theme) {
      'Sombre' => ThemeMode.dark,
      'Système' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    notifyListeners();
  }
}
