import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'kiosk_register_step1_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final session = await _authService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await sessionManager.saveSession(session);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Stack(
          children: [
            const SizedBox.expand(),
            const Positioned(
              top: 64,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  _LogoCircle(size: 96),
                  SizedBox(height: 16),
                  Text(
                    'GCommers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AuthSectionCard(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 4),
                      const Text(
                        'Selamat Datang',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Masuk ke akun GCommers',
                        style: TextStyle(color: AppTheme.muted, fontSize: 15),
                      ),
                      const SizedBox(height: 18),
                      AuthTextField(
                        controller: _emailController,
                        hintText: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscure,
                        suffixIcon: Icon(
                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppTheme.border,
                        ),
                        onSuffixTap: () => setState(() => _obscure = !_obscure),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextActionLink(
                          label: 'Lupa Password?',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      PrimaryButton(
                        label: 'Masuk',
                        isLoading: _loading,
                        onPressed: _submit,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppTheme.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Atau', style: TextStyle(color: Colors.grey.shade600)),
                          ),
                          Expanded(child: Divider(color: AppTheme.border)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextActionLink(
                          label: 'Daftar sebagai Kios →',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const KioskRegisterStep1Screen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoCircle extends StatelessWidget {
  const _LogoCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Icon(Icons.store_rounded, size: 46, color: AppTheme.primary),
    );
  }
}
