import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/l10n/app_localizations.dart';
import 'package:taexpense/services/master_data_store.dart';
import 'package:taexpense/services/parser_rules_manager.dart';
import 'package:taexpense/utils/app_config.dart';
import 'package:taexpense/screens/home_screen.dart';
import 'package:taexpense/screens/login_screen.dart';
import 'package:taexpense/screens/onboarding_screen.dart';
import 'package:taexpense/screens/splash_screen.dart';
import 'package:taexpense/screens/wallet_list_screen.dart';
import 'package:taexpense/theme/app_theme.dart';
import 'locale_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  await MasterDataStore().loadFromCache();

  ParserRulesStorage storage;
  if (kIsWeb) {
    storage = SharedPreferencesParserRulesStorage();
  } else {
    final supportDirectory = await getApplicationSupportDirectory();
    storage =
        FileParserRulesStorage('${supportDirectory.path}/parser_rules.json');
  }

  final categories = MasterDataStore().categories;
  final mgr = ParserRulesManager(
    bundledJson: await rootBundle.loadString('assets/parser_rules.json'),
    storage: storage,
    manifestUri:
        Uri.parse('${AppConstants.BASE_URL}/parser-rules/manifest.json'),
    validCategoryIds: categories.isNotEmpty ? categories : null,
  );
  await mgr.init(); // trước khi gọi LocalTransactionParser.parse
  unawaited(mgr.checkForUpdate()); // nền, không throw

  runApp(
    ChangeNotifierProvider(
      create: (_) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'FinA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,

        // Cấu hình giao diện chung cho tất cả TextField (EditText)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          // Viền mặc định khi không focus
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          // Viền khi focus (chọn vào)
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: const BorderSide(color: Colors.indigo, width: 2.0),
          ),
          // Viền khi có lỗi
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: const BorderSide(color: Colors.red, width: 1.0),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: const BorderSide(color: Colors.red, width: 2.0),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
        )),

        textTheme: ThemeData.light()
            .textTheme
            .copyWith(bodyMedium: const TextStyle(color: kText)),
      ),
      debugShowCheckedModeBanner: false,

      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,

      // home: const LoginScreen(),
      initialRoute: SplashScreen.routeName,
      routes: {
        SplashScreen.routeName: (context) => const SplashScreen(),
        OnboardingScreen.routeName: (context) => const OnboardingScreen(),
        LoginScreen.routeName: (context) => const LoginScreen(),
        HomeScreen.routeName: (context) => const HomeScreen(),
        WalletListScreen.routeName: (context) => const WalletListScreen(),
      },
    );
  }
}
