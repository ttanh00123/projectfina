// lib/screens/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taexpense/screens/home_screen.dart';
import 'package:taexpense/services/auth_storage.dart';
import 'package:taexpense/services/master_data_service.dart';
import 'package:taexpense/services/master_data_store.dart';
import 'package:taexpense/session.dart';
import 'package:taexpense/widgets/fina_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  static String routeName = "/onboarding-screen";
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _locale   = 'vi';
  String _currency = 'VND';
  bool   _loading  = false;

  static const _locales = [
    {'code': 'vi', 'label': 'Tiếng Việt'},
    {'code': 'en', 'label': 'English'},
  ];

  static const _currencies = ['VND', 'USD', 'EUR', 'SGD'];

  // OnboardingScreen._confirm() — thay toàn bộ phần lấy token

// OnboardingScreen._confirm() — thay toàn bộ phần lấy token

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      // Dùng AuthStorage thay vì prefs.getString('auth_token')
      final token = await AuthStorage.getToken() ?? Session.token;

      if (token == null) {
        throw Exception('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại');
      }

      await MasterDataService.initialize(
        authToken: token,
        locale:    _locale,
        currency:  _currency,
      );

      await MasterDataStore().sync(token, locale: _locale);

      // Lưu flag initialized — dùng AuthStorage's prefs instance
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('user_initialized', true);

      if (mounted) Navigator.pushReplacementNamed(context, HomeScreen.routeName);
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const FinaLogo(),
            const SizedBox(height: 40),
            const SectionHeader(title: 'Thiết lập ban đầu'),
            const SizedBox(height: 24),

            // Ngôn ngữ
            FinaDropdown<String>(
              label: 'Ngôn ngữ',
              value: _locale,
              items: _locales.map((l) => DropdownMenuItem(
                value: l['code'],
                child: Text(l['label']!),
              )).toList(),
              onChanged: (v) => setState(() => _locale = v!),
            ),
            const SizedBox(height: 16),

            // Tiền tệ mặc định
            FinaDropdown<String>(
              label: 'Tiền tệ mặc định',
              value: _currency,
              items: _currencies.map((c) => DropdownMenuItem(
                value: c, child: Text(c),
              )).toList(),
              onChanged: (v) => setState(() => _currency = v!),
            ),

            const Spacer(),

            // Note
            Text(
              'Danh mục chi tiêu sẽ được tạo tự động theo ngôn ngữ bạn chọn. '
              'Bạn có thể đổi tên sau.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),

            FinaButton(
              label: 'Bắt đầu',
              isLoading: _loading,
              onPressed: _confirm,
            ),
          ],
        ),
      ),
    ),
  );
}