import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});

  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _authService.resetPassword(
        email: widget.email,
        password: _passwordController.text,
        confirmPassword: _confirmController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diperbarui')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
        (route) => false,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'Buat Password Baru',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Password baru Anda harus berbeda dari password\nyang digunakan sebelumnya.',
                style: TextStyle(color: AppTheme.muted, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              AuthTextField(
                controller: _passwordController,
                hintText: 'Masukkan password baru',
                labelText: 'Password Baru',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF6B8C73),
                ),
                onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 14),
              const _StrengthBar(level: 0.7, label: 'Sedang'),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _confirmController,
                hintText: 'Ulangi password baru',
                labelText: 'Konfirmasi Password Baru',
                icon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                suffixIcon: Icon(
                  _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: const Color(0xFF6B8C73),
                ),
                onSuffixTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Simpan Password',
                isLoading: _loading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  const _StrengthBar({required this.level, required this.label});

  final double level;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.primary)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: level,
            minHeight: 6,
            backgroundColor: const Color(0xFFC5DECC),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Minimal 8 karakter, kombinasi huruf dan angka.',
          style: TextStyle(color: AppTheme.muted, fontSize: 13),
        ),
      ],
    );
  }
}
