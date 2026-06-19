import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'reset_password_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.email, this.initialOtp});

  final String email;
  final String? initialOtp;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _authService = AuthService();
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  int _secondsLeft = 45;
  Timer? _timer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
    if ((widget.initialOtp ?? '').length == 6) {
      for (var index = 0; index < 6; index++) {
        _controllers[index].text = widget.initialOtp![index];
      }
    }
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      await _authService.verifyOtp(email: widget.email, otp: _otp);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => ResetPasswordScreen(email: widget.email)),
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
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              const Text(
                'Masukkan Kode OTP',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Kode dikirim ke ${widget.email}',
                style: const TextStyle(color: AppTheme.muted, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              OtpBoxes(controllers: _controllers, focusNodes: _focusNodes),
              const SizedBox(height: 24),
              Text(
                _secondsLeft == 0
                    ? 'Kirim ulang sekarang'
                    : 'Kirim ulang dalam 00:${_secondsLeft.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Verifikasi',
                isLoading: _loading,
                onPressed: _submit,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
