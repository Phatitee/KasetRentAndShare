import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';
import 'email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('รีเซ็ตรหัสผ่าน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('กรอกอีเมล @ku.th เพื่อรับลิงก์รีเซ็ตรหัสผ่าน'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'example@ku.th',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(context);
              try {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.resetPassword(email);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('ส่งลิงก์รีเซ็ตรหัสผ่านไปที่อีเมลของคุณแล้ว'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString().replaceAll('Exception: ', '')),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('ส่งลิงก์'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        // Check email verification for email/password login
        if (authService.currentUser != null &&
            !authService.currentUser!.emailVerified) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => const EmailVerificationScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final result = await authService.signInWithGoogle();
      if (result != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/logo.png',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 60),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Title
                  Text(
                    'เข้าสู่ระบบ',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'เริ่มต้นใช้งาน',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'example@ku.th',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกอีเมล';
                      }
                      if (!value.endsWith('@ku.th')) {
                        return 'กรุณาใช้อีเมล @ku.th';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      hintText: 'รหัสผ่าน',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกรหัสผ่าน';
                      }
                      if (value.length < 6) {
                        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => _showForgotPasswordDialog(),
                      child: Text(
                        'ลืมรหัสผ่าน?',
                        style: TextStyle(
                          color: AppTheme.primaryTeal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('เข้าสู่ระบบ'),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'หรือ',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Google Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: Image.network(
                        'https://www.google.com/favicon.ico',
                        width: 22,
                        height: 22,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.g_mobiledata, size: 24),
                      ),
                      label: const Text(
                        'เข้าสู่ระบบด้วย Google (@ku.th)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.primaryTeal),
                        foregroundColor: AppTheme.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'คุณยังไม่มีบัญชีใช่ไหม?',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'สมัครสมาชิกเลย',
                          style: TextStyle(
                            color: AppTheme.primaryTeal,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
