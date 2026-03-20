import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:taexpense/models/user_model.dart';
import 'package:taexpense/screens/home_screen.dart';
import 'package:taexpense/screens/signup_screen.dart';
import 'package:taexpense/services/auth_service.dart';
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide.none,
                          ),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                            borderSide: BorderSide.none,
                          ),
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
                      // const SizedBox(height: 24),
      
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                  message = '';  
                              });
      
                              final email = _emailController.text.trim();
                              final password = _passwordController.text.trim();
      
                              if (email.isEmpty || password.isEmpty) {
                                // ScaffoldMessenger.of(context).showSnackBar(
                                //   const SnackBar(
                                //       content: Text(
                                //           'Vui lòng nhập đầy đủ email và mật khẩu')),
                                // );
                                setState(() {
                                  message = 'Vui lòng nhập đầy đủ email và mật khẩu';  
                                });
                                
                                return;
                              }
      
                              await doLogin(context, email, password);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 5,
                              shadowColor: kPrimary.withOpacity(0.4),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'ĐĂNG NHẬP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
      
                // Signup Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Chưa có tài khoản? ',
                      style: TextStyle(color: kSubtext),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Chuyển hướng trang đăng ký
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Đăng ký ngay',
                        style: TextStyle(
                          color: kPrimary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  doLogin(BuildContext context, String email, String password) async{
    // Hiển thị trạng thái loading
      setState(() => _isLoading = true);

      UserModel? loginUser = await loginWithPassword(context, email, password);
      if (loginUser != null) {
        if (context.mounted) {
          Navigator.pushReplacementNamed(
              context, HomeScreen.routeName);
        }
      } else {
        if (context.mounted) {
          showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Thông báo"),
                content: const Text("Đăng nhập không thành công. Vui lòng kiểm tra lại email và mật khẩu."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  ),
                ],
              ),
            );
        }

        // Hiển thị trạng thái loading
        setState(() => _isLoading = false);
        
      }
  }
}
