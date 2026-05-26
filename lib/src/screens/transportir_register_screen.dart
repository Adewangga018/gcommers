import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../widgets/auth_widgets.dart';
import 'role_selection_screen.dart';

class TransportirRegisterScreen extends StatefulWidget {
  const TransportirRegisterScreen({super.key});

  @override
  State<TransportirRegisterScreen> createState() => _TransportirRegisterScreenState();
}

class _TransportirRegisterScreenState extends State<TransportirRegisterScreen> {
  final _transportirNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _policeNumberController = TextEditingController();
  final _typeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _accepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _transportirNameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _policeNumberController.dispose();
    _typeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final draft = TransportirRegistrationDraft(
        transportirName: _transportirNameController.text,
        companyName: _companyNameController.text,
        phone: _phoneController.text,
        policeNumber: _policeNumberController.text,
        type: _typeController.text,
        email: _emailController.text,
        password: _passwordController.text,
        termsAccepted: _accepted,
      );

      final session = await _authService.registerTransportir(draft);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Transportir')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const StepHeader(
                stepLabel: 'Langkah 1 dari 1',
                rightLabel: 'Data Transportir',
                progress: 1,
              ),
              const SizedBox(height: 22),
              const SectionTitle(
                title: 'Daftar Akun Transportir',
                subtitle: 'Buat akun transportir untuk login ke sistem GCommers.',
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AuthTextField(
                        controller: _transportirNameController,
                        hintText: 'Nama transportir',
                        icon: Icons.local_shipping_outlined,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _companyNameController,
                        hintText: 'Nama perusahaan transportir',
                        icon: Icons.business_outlined,
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
                        controller: _policeNumberController,
                        hintText: 'Nomor polisi / plat kendaraan',
                        icon: Icons.confirmation_number_outlined,
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 14),
                      AuthTextField(
                        controller: _typeController,
                        hintText: 'Jenis kendaraan',
                        icon: Icons.two_wheeler_outlined,
                        textCapitalization: TextCapitalization.words,
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
                      const SizedBox(height: 14),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _accepted,
                        onChanged: (value) => setState(() => _accepted = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'Saya menyetujui syarat dan ketentuan serta kebijakan privasi.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'Daftar Transportir',
                icon: Icons.app_registration_rounded,
                isLoading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 14),
              TextActionLink(
                label: 'Kembali ke pemilihan role',
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(builder: (_) => const RoleSelectionScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}