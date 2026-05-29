import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final challenge = await _authService.requestPasswordReset(email: _emailController.text);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OtpScreen(
            email: challenge.email,
            initialOtp: challenge.otp,
          ),
        ),
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
              const Spacer(),
              const CircleAvatar(
                radius: 34,
                backgroundColor: AppTheme.primary,
                child: Icon(Icons.mail_outline, color: Colors.white, size: 34),
              ),
              const SizedBox(height: 24),
              const Text(
                'Lupa Password',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan email terdaftar Anda',
                style: TextStyle(color: AppTheme.muted, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              AuthTextField(
                controller: _emailController,
                hintText: 'Email Anda',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Kirim Kode OTP',
                isLoading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 24),
              TextActionLink(
                label: '← Kembali ke Login',
                onTap: () => Navigator.of(context).pop(),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
