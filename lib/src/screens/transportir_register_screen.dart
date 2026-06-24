import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../models/wilayah_models.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../services/wilayah_service.dart';
import '../widgets/auth_widgets.dart';
import 'role_selection_screen.dart';

class TransportirRegisterScreen extends StatefulWidget {
  const TransportirRegisterScreen({super.key});

  @override
  State<TransportirRegisterScreen> createState() => _TransportirRegisterScreenState();
}

class _TransportirRegisterScreenState extends State<TransportirRegisterScreen> {
  final _transportirNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _policeNumberController = TextEditingController();
  final _typeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _wilayahService = WilayahService();
  bool _accepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;

  List<Region> _regionList = [];
  Region? _selectedRegion;
  bool _loadingRegions = false;

  List<String> _companyNames = [];
  String? _selectedCompanyName;
  bool _loadingCompanies = false;

  @override
  void initState() {
    super.initState();
    _loadRegionList();
  }

  @override
  void dispose() {
    _transportirNameController.dispose();
    _phoneController.dispose();
    _policeNumberController.dispose();
    _typeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadRegionList() async {
    setState(() => _loadingRegions = true);
    try {
      final list = await _wilayahService.getRegionList();
      if (!mounted) return;
      setState(() {
        _regionList = list;
        _loadingRegions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRegions = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar region: ${e.toString()}')),
      );
    }
  }

  Future<void> _onRegionChanged(Region? region) async {
    setState(() {
      _selectedRegion = region;
      _selectedCompanyName = null;
      _companyNames = [];
    });

    if (region == null) return;

    setState(() => _loadingCompanies = true);
    try {
      final list = await _authService.getTransportirCompanyNames(region: region.namaReg);
      if (!mounted) return;
      setState(() {
        _companyNames = list;
        _loadingCompanies = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingCompanies = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar perusahaan: ${e.toString()}')),
      );
    }
  }

  Future<void> _submit() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok')),
      );
      return;
    }

    if (_selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih region terlebih dahulu')),
      );
      return;
    }

    if (_selectedCompanyName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih nama perusahaan transportir')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final draft = TransportirRegistrationDraft(
        transportirName: _transportirNameController.text,
        companyName: _selectedCompanyName!,
        phone: _phoneController.text,
        policeNumber: _policeNumberController.text,
        type: _typeController.text,
        email: _emailController.text,
        password: _passwordController.text,
        region: _selectedRegion!.namaReg,
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
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Region', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Region>(
                        value: _selectedRegion,
                        items: _regionList
                            .map((r) => DropdownMenuItem(value: r, child: Text(r.namaReg)))
                            .toList(),
                        onChanged: _loadingRegions ? null : _onRegionChanged,
                        decoration: InputDecoration(
                          hintText: _loadingRegions ? 'Memuat region...' : 'Pilih region',
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Nama Perusahaan Transportir',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedCompanyName,
                        items: _companyNames
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (_selectedRegion == null || _loadingCompanies)
                            ? null
                            : (v) => setState(() => _selectedCompanyName = v),
                        decoration: InputDecoration(
                          hintText: _selectedRegion == null
                              ? 'Pilih region terlebih dahulu'
                              : _loadingCompanies
                                  ? 'Memuat perusahaan...'
                                  : _companyNames.isEmpty
                                      ? 'Belum ada perusahaan terdaftar di region ini'
                                      : 'Pilih perusahaan',
                        ),
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
                        icon: Icons.local_shipping_outlined,
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
                          color: const Color(0xFF6B8C73),
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
                          color: const Color(0xFF6B8C73),
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