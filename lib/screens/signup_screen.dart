import 'package:flutter/material.dart';
import 'package:taexpense/utils/colors_util.dart';
import 'package:taexpense/widgets/app_icon.dart';
import 'package:taexpense/widgets/fina_widgets.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: kBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: kText, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FinaLogo(size: 96), // Sử dụng widget AppIcon đã tạo
                const SizedBox(height: 24),
                // Header Section
                const Text(
                  'Đăng ký tài khoản',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tham gia cùng chúng tôi để trải nghiệm dịch vụ tốt nhất',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
      
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
                      // Name Field
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Họ và tên',
                        icon: Icons.person_outline
                      ),
                      const SizedBox(height: 16),
      
                      // Email Field
                      _buildTextField(
                        controller: _emailController,
                        hint: 'Địa chỉ Email',
                        icon: Icons.mail_outline,
                      ),
                      const SizedBox(height: 16),
      
                      // Password Field
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Mật khẩu',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        isVisible: _isPasswordVisible,
                        onToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      const SizedBox(height: 16),
      
                      // Confirm Password Field
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: 'Xác nhận mật khẩu',
                        icon: Icons.lock_reset_outlined,
                        isPassword: true,
                        isVisible: _isConfirmVisible,
                        onToggle: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                      ),
                      const SizedBox(height: 24),
      
                      // Signup Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            // Xử lý logic đăng ký
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 4,
                            shadowColor: kPrimary.withOpacity(0.3),
                          ),
                          child: const Text(
                            'ĐĂNG KÝ NGAY',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
      
                // Terms and Conditions
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text.rich(
                    TextSpan(
                      text: 'Bằng cách đăng ký, bạn đồng ý với ',
                      style: TextStyle(color: kSubtext, fontSize: 12),
                      children: [
                        TextSpan(
                          text: 'Điều khoản sử dụng',
                          style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' và '),
                        TextSpan(
                          text: 'Chính sách bảo mật',
                          style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold),
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
    );
  }

  // Helper method to build text fields to keep code clean
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 16),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}