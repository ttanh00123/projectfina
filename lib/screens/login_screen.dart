import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taexpense/models/user_model.dart';
import 'package:taexpense/screens/home_screen.dart';
import 'package:taexpense/screens/signup_screen.dart';
import 'package:taexpense/services/auth_service.dart';
import 'package:taexpense/services/auth_storage.dart';
import 'package:taexpense/services/master_data_store.dart';
import 'package:taexpense/services/settings_service.dart';
import 'package:taexpense/utils/colors_util.dart';
import 'package:taexpense/widgets/app_icon.dart';
import 'package:taexpense/widgets/fina_widgets.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  static String routeName = "/login-screen";
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String message = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _emailController.text = "trantrung22@gmail.com";
    _passwordController.text = "12345678";
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kBg,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FinaLogo(size: 96), // Sử dụng widget AppIcon đã tạo
                const SizedBox(height: 24),
                // Header Text
                const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 24),
      
                // Form Container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Email Field
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Địa chỉ Email',
                          prefixIcon: const Icon(Icons.mail_outline_rounded, size: 14),
                          filled: true,
                          fillColor: Colors.grey[50],
                          
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
      
                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 16,),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordVisible
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded, size: 16),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kError, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text(
                            'Quên mật khẩu?',
                            style: TextStyle(color: kPrimary),
                          ),
                        ),
                      ),
                      
                      FinaButton(
                        label: 'Đăng nhập',
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                      
                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Bạn chưa có tài khoản? ',
                          style: TextStyle(color: kSubtext),
                        ),
                      ),
                      FinaButton(
                        label: 'Đăng ký ngay',
                        color: Colors.redAccent,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                      ),
                      // Login Button
                      
                    ],
                  ),
                ),
                const SizedBox(height: 32),
      
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleLogin() async {
    // setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        message = 'Vui lòng nhập đầy đủ email và mật khẩu';  
      });
      setState(() => _isLoading = false);
      return;
    }

    await doLogin(context, email, password);
  }  

  doLogin(BuildContext context, String email, String password) async {
    setState(() => _isLoading = true);

    try {
      UserModel? loginUser = await loginWithPassword(context, email, password)
          .timeout(const Duration(seconds: 10));  // explicit timeout

      if (loginUser != null) {
        if (context.mounted) {
          //Sync Master Data với locale mới
          await MasterDataStore().sync(await AuthStorage.getToken() ?? '', locale: await SettingsService.getLocale());
          
          Navigator.pushReplacementNamed(context, HomeScreen.routeName);
        }
      } else {
        _showError('Đăng nhập không thành công. Vui lòng kiểm tra lại.');
      }
    } on TimeoutException {
      _showError('Kết nối quá chậm, thử lại sau.');
    } on SocketException {
      _showError('Không thể kết nối server. Kiểm tra mạng.');
    } catch (e) {
      _showError('Lỗi: $e');   // in ra lỗi thật sự
      debugPrint('doLogin error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thông báo'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
