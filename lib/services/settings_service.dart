import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyLocale = 'locale';
  static const _keyCurrency = 'currency';
  static const _keyDateTimeFormat = 'date_time_format';
  static const _keyDateFormat = 'date_format';

  static Future<void> setLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, locale);
  }

  static Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLocale) ?? 'vi';
  }

  static Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrency, currency);
  }

  static Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrency) ?? 'VND';
  }

  static Future<void> setDateTimeFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDateTimeFormat, format);
  }

  static Future<String> getDateTimeFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDateTimeFormat) ?? 'dd-MM-yyyy HH:mm:ss';
  }

  static Future<void> setDateFormat(String format) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDateFormat, format);
  }

  static Future<String> getDateFormat() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDateFormat) ?? 'dd-MM-yyyy';
  }
}