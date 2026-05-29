import 'package:flutter/material.dart';

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
  bool _isFormValid = false;

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
    final kioskName = _kioskNameController.text.trim();
    final picName = _picNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (kioskName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama Kios tidak boleh kosong')),
      );
      return;
    }

    if (picName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama PIC tidak boleh kosong')),
      );
      return;
    }

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No. HP tidak boleh kosong')),
      );
      return;
    }

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak boleh kosong')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak boleh kosong')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => KioskRegisterStep2Screen(
          kioskName: kioskName,
          picName: picName,
          phone: phone,
          email: email,
          password: password,
        ),
      ),
    );
  }

  void _validateForm() {
    final kioskName = _kioskNameController.text.trim();
    final picName = _picNameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    _isFormValid = kioskName.isNotEmpty && picName.isNotEmpty && phone.isNotEmpty && email.isNotEmpty && password.isNotEmpty && password == confirmPassword;
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
                        onChanged: (_) => setState(_validateForm),
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _picNameController,
                        hintText: 'Nama PIC',
                        icon: Icons.person_outline,
                        onChanged: (_) => setState(_validateForm),
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _phoneController,
                        hintText: 'No. HP',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        onChanged: (_) => setState(_validateForm),
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setState(_validateForm),
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
                        onChanged: (_) => setState(_validateForm),
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
                        onChanged: (_) => setState(_validateForm),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Lanjut',
                icon: Icons.arrow_forward_rounded,
                onPressed: _isFormValid ? _next : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
