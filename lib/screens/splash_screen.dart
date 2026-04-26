import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taexpense/models/user_model.dart';
import 'package:taexpense/screens/home_screen.dart';
import 'package:taexpense/screens/login_screen.dart';
import 'package:taexpense/screens/onboarding_screen.dart';
import 'package:taexpense/services/auth_service.dart';
import 'package:taexpense/services/auth_storage.dart';
import 'package:taexpense/services/master_data_store.dart';
import 'package:taexpense/session.dart';
import 'package:taexpense/widgets/fina_widgets.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  static String routeName = "/splash-screen";
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final UserModel? user = await loginWithToken();

    if (!mounted) return;

    if (user == null) {
      _goto(LoginScreen.routeName);
      return;
    }

    // Set session in memory
    final token = await AuthStorage.getToken();
    Session.setSession(jwt: token!, userData: user);

    // status=9 → đã onboard xong
    final isReady = (user.status == 9);

    final prefs = await SharedPreferences.getInstance();

    if (!isReady) {
      // Chưa onboard — xóa flag cũ nếu có
      await prefs.remove('user_initialized');
      _goto(OnboardingScreen.routeName);
      return;
    }

    // Đã ready — đảm bảo flag được lưu
    await prefs.setBool('user_initialized', true);

    // Load cache ngay để Home không trắng
    await MasterDataStore().loadFromCache();

    // Sync background — không await để không block navigation
    MasterDataStore().sync(token);

    _goto(HomeScreen.routeName);
  }

  void _goto(String route) {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: kBg,
    body: Center(
      child: FinaLogo(size: 120),
    ),
  );
}