import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_status_code/http_status_code.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taexpense/app_constants.dart';
import 'package:taexpense/models/user_model.dart';
import 'package:taexpense/screens/onboarding_screen.dart';
import 'package:taexpense/services/auth_storage.dart';
import 'package:taexpense/session.dart';
import 'package:taexpense/widgets/fina_widgets.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── API call ───────────────────────────────────────────────────────────────

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final res = await http.post(
        Uri.parse(AppConstants.SIGNUP_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name':             _nameController.text.trim(),
          'email':            _emailController.text.trim(),
          'password':         _passwordController.text,
          'confirm_password': _confirmController.text,
        }),
      );

      final body = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == StatusCode.CREATED) {
        // Tạo UserModel từ response
        final user = UserModel(
          id:          body['user_id'] as int,
          email:       _emailController.text.trim(),
          displayName: _nameController.text.trim(),
          status:      0,
        );
        final token = body['access_token'] as String;

        // Dùng AuthStorage — đúng key, nhất quán với login flow
        await AuthStorage.saveSession(token, user);
        Session.setSession(jwt: token, userData: user);

        if (mounted) {
          Navigator.pushReplacementNamed(context, OnboardingScreen.routeName);
        }
      } else {
        setState(() => _error = body['detail'] as String? ?? 'Đăng ký thất bại');
      }
    } catch (e) {
      setState(() => _error = 'Không thể kết nối server: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon:
                  const Icon(Icons.arrow_back_ios_new, color: kText, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FinaLogo(size: 96),
                    const SizedBox(height: 24),

                    const Text('Đăng ký tài khoản',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Tham gia cùng chúng tôi để trải nghiệm dịch vụ tốt nhất',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // Form card
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
                          // Error banner
                          if (_error != null) ...[
                            ErrorBanner(message: _error!),
                            const SizedBox(height: 16),
                          ],

                          _Field(
                            controller: _nameController,
                            hint: 'Họ và tên',
                            icon: Icons.person_outline,
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Vui lòng nhập họ tên'
                                : null,
                          ),

                          const SizedBox(height: 16),

                          _Field(
                            controller: _emailController,
                            hint: 'Địa chỉ Email',
                            icon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Vui lòng nhập email';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                                return 'Email không hợp lệ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _Field(
                            controller: _passwordController,
                            hint: 'Mật khẩu',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            isVisible: _isPasswordVisible,
                            onToggle: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Mật khẩu tối thiểu 6 ký tự'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          _Field(
                            controller: _confirmController,
                            hint: 'Xác nhận mật khẩu',
                            icon: Icons.lock_reset_outlined,
                            isPassword: true,
                            isVisible: _isConfirmVisible,
                            onToggle: () => setState(
                                () => _isConfirmVisible = !_isConfirmVisible),
                            validator: (v) => v != _passwordController.text
                                ? 'Mật khẩu không khớp'
                                : null,
                          ),
                          const SizedBox(height: 24),

                          FinaButton(
                            label: 'Đăng ký ngay',
                            isLoading: _loading,
                            onPressed: _handleRegister,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text.rich(
                        TextSpan(
                          text: 'Bằng cách đăng ký, bạn đồng ý với ',
                          style: TextStyle(color: kSubtext, fontSize: 12),
                          children: [
                            TextSpan(
                              text: 'Điều khoản sử dụng',
                              style: TextStyle(
                                  color: kPrimary, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: ' và '),
                            TextSpan(
                              text: 'Chính sách bảo mật',
                              style: TextStyle(
                                  color: kPrimary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// ── Reusable field widget ──────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final bool isVisible;
  final VoidCallback? onToggle;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.isVisible = false,
    this.onToggle,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: isPassword && !isVisible,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 16),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 16,
                  ),
                  onPressed: onToggle,
                )
              : null,
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      );
}
