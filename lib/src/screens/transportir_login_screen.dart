import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'role_selection_screen.dart';
import 'transportir_register_screen.dart';

class TransportirLoginScreen extends StatefulWidget {
  const TransportirLoginScreen({super.key});

  @override
  State<TransportirLoginScreen> createState() => _TransportirLoginScreenState();
}

class _TransportirLoginScreenState extends State<TransportirLoginScreen> {
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

      final role = session.role.toLowerCase();
      if (role != 'transportir') {
        throw Exception('Akun ini bukan role transportir. Gunakan login transportir.');
      }

      await sessionManager.saveSession(session);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/transportir-home',
        (_) => false,
        arguments: session,
      );
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
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Stack(
                clipBehavior: Clip.none,
                children: const [
                  Positioned(
                    top: -40,
                    left: -50,
                    child: _DecoDot(220, Color(0x2638804B)),
                  ),
                  Positioned(
                    bottom: 10,
                    right: -60,
                    child: _DecoDot(180, Color(0x1A38804B)),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LogoCircle(size: 96),
                        SizedBox(height: 18),
                        Text(
                          'GCommers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Platform Logistik Digital',
                          style: TextStyle(
                            color: Color(0x8CFFFFFF),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(24, 24, 24, 28 + bottomPad),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Masuk Transportir',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Masuk ke akun GCommers untuk role transportir',
                    style: TextStyle(color: AppTheme.muted, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Masuk',
                    isLoading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: TextActionLink(
                      label: 'Belum punya akun? Daftar Transportir',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const TransportirRegisterScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextActionLink(
                      label: 'Pilih Role Lain',
                      onTap: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x4D38804B),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.local_shipping_rounded, size: 44, color: AppTheme.primary),
    );
  }
}

class _DecoDot extends StatelessWidget {
  const _DecoDot(this.size, this.color);

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
