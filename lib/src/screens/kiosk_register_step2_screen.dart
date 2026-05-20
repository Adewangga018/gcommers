import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class KioskRegisterStep2Screen extends StatefulWidget {
  const KioskRegisterStep2Screen({
    super.key,
    required this.kioskName,
    required this.picName,
    required this.phone,
    required this.email,
    required this.password,
  });

  final String kioskName;
  final String picName;
  final String phone;
  final String email;
  final String password;

  @override
  State<KioskRegisterStep2Screen> createState() => _KioskRegisterStep2ScreenState();
}

class _KioskRegisterStep2ScreenState extends State<KioskRegisterStep2Screen> {
  final _addressController = TextEditingController();
  final _authService = AuthService();
  bool _accepted = false;
  bool _loading = false;
  String? _selectedRegion;
  XFile? _ktpImage;
  Uint8List? _ktpImageBytes;
  final _regions = ['Jawa Barat', 'Jawa Tengah', 'Jawa Timur', 'DKI Jakarta', 'Banten'];

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickKtpImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _ktpImage = image;
          _ktpImageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih foto: ${e.toString()}')),
      );
    }
  }

  Future<void> _submit() async {
    if (_ktpImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih foto KTP terlebih dahulu')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final draft = KioskRegistrationDraft(
        kioskName: widget.kioskName,
        picName: widget.picName,
        phone: widget.phone,
        email: widget.email,
        password: widget.password,
        address: _addressController.text,
        region: _selectedRegion ?? '',
        termsAccepted: _accepted,
        licenseImageName: _ktpImage!.name,
      );
      
      // Register kiosk - this includes the KTP filename
      final session = await _authService.registerKiosk(draft);
      
      await sessionManager.saveSession(session);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pendaftaran gagal: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
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
                stepLabel: 'Langkah 2 dari 2',
                rightLabel: 'Data Lokasi & Berkas',
                progress: 1,
              ),
              const SizedBox(height: 22),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthTextField(
                        controller: _addressController,
                        hintText: 'Masukkan alamat lengkap kios (Jalan, RT/RW, Patokan)',
                        labelText: 'Alamat Lengkap',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kode Wilayah', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedRegion,
                            items: _regions
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(() => _selectedRegion = value),
                            decoration: const InputDecoration(
                              hintText: 'Pilih Provinsi / Kota',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Upload Foto KTP Pemilik',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickKtpImage,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 26),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFB8B1D1),
                              style: BorderStyle.solid,
                              width: 1.4,
                            ),
                            color: Colors.transparent,
                          ),
                          child: _ktpImage != null
                              ? Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _ktpImageBytes != null
                                          ? Image.memory(
                                              _ktpImageBytes!,
                                              height: 120,
                                              width: 120,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              height: 120,
                                              width: 120,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: CircularProgressIndicator(),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _ktpImage!.name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Ketuk untuk ganti foto',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.muted,
                                      ),
                                    ),
                                  ],
                                )
                              : const Column(
                                  children: [
                                    Icon(Icons.camera_alt, color: AppTheme.primary, size: 32),
                                    SizedBox(height: 10),
                                    Text(
                                      'Ketuk untuk upload',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Format .JPG atau .PNG maks 5MB',
                                      style: TextStyle(color: AppTheme.muted, fontSize: 13),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _accepted,
                        onChanged: (value) => setState(() => _accepted = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: AppTheme.text, fontSize: 13),
                            children: [
                              TextSpan(text: 'Saya menyetujui '),
                              TextSpan(
                                text: 'Syarat & Ketentuan',
                                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: ' serta '),
                              TextSpan(
                                text: 'Kebijakan Privasi',
                                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: ' yang berlaku di GCommers.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Daftar',
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
