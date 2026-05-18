import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'kiosk_register_step2_screen.dart';

class KioskRegisterStep1Screen extends StatefulWidget {
  const KioskRegisterStep1Screen({super.key});

  @override
  State<KioskRegisterStep1Screen> createState() => _KioskRegisterStep1ScreenState();
}

class _KioskRegisterStep1ScreenState extends State<KioskRegisterStep1Screen> {
  final _kioskNameController = TextEditingController();
  final _picNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _kioskNameController.dispose();
    _picNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _next() {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KioskRegisterStep2Screen(
          kioskName: _kioskNameController.text,
          picName: _picNameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          password: _passwordController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Kios')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const StepHeader(
                stepLabel: 'Langkah 1 dari 2',
                rightLabel: 'Data Kios',
                progress: 0.5,
              ),
              const SizedBox(height: 22),
              const SectionTitle(
                title: 'Daftar Akun Kios',
                subtitle: 'Lengkapi data kios Anda untuk memulai.',
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AuthTextField(
                        controller: _kioskNameController,
                        hintText: 'Nama Kios',
                        icon: Icons.store_outlined,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _picNameController,
                        hintText: 'Nama PIC',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _phoneController,
                        hintText: 'No. HP',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _passwordController,
                        hintText: 'Masukkan password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF938DA8),
                        ),
                        onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _confirmPasswordController,
                        hintText: 'Konfirmasi password',
                        icon: Icons.lock_outline,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF938DA8),
                        ),
                        onSuffixTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Lanjut',
                icon: Icons.arrow_forward_rounded,
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
