import 'package:taexpense/services/settings_service.dart';

class AppSettings {
  static String locale = 'vi';
  static String currency = 'VND';

  static Future<void> load() async {
    locale = await SettingsService.getLocale();
    currency = await SettingsService.getCurrency();
  }
}