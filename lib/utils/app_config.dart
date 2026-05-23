import 'package:taexpense/services/settings_service.dart';

class AppConfig {
  static String currentLocale = 'vi';
  static String currentCurrency = 'VND';
  static String dateTimeFormat = 'dd-MM-yyyy HH:mm:ss';
  static String dateFormat = 'dd-MM-yyyy';

  static Future<void> load() async {
    currentLocale = await SettingsService.getLocale();
    currentCurrency = await SettingsService.getCurrency();
    dateTimeFormat = await SettingsService.getDateTimeFormat();
    dateFormat = await SettingsService.getDateFormat();
  }
}