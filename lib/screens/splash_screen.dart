import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taexpense/models/user_model.dart';
import 'package:taexpense/screens/home_screen.dart';
import 'package:taexpense/screens/login_screen.dart';
import 'package:taexpense/services/auth_service.dart';
import 'package:taexpense/utils/colors_util.dart';
import 'package:taexpense/widgets/app_icon.dart';
import 'package:taexpense/widgets/fina_widgets.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  static String routeName = "/splash-screen";

  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void getInitialRoute() async {
    
    // Try login with local token
    UserModel? user = await loginWithToken();

    if (!mounted) return;
    if (user != null) {
      // Login Success
      Navigator.of(context).pushNamedAndRemoveUntil(
        HomeScreen.routeName,
        (route) => false,
      );
      return;
    } else {
      // Login Failed
      Navigator.pushReplacementNamed(context, LoginScreen.routeName);
    }
  }

  @override
  void initState() {
    super.initState();

    getInitialRoute();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: FinaLogo(
            size: 120
          ),
        ));
  }
}
