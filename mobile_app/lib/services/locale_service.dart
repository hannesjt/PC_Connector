import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and exposes the user's language preference.
///
/// A `null` [locale] means "follow the system language" (automatic). Any other
/// value forces that locale regardless of the device setting.
class LocaleService {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  static const _prefsKey = 'app_locale';

  Locale? _locale;

  /// The forced locale, or `null` when following the system language.
  Locale? get locale => _locale;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == 'en' || code == 'de') {
      _locale = Locale(code!);
    } else {
      _locale = null;
    }
  }

  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
  }
}
