import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../models/wilayah_models.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../services/wilayah_service.dart';
import '../theme/app_theme.dart';
import '../utils/ktp_picker_helper.dart';
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
  final _wilayahService = WilayahService();

  bool _accepted = false;
  bool _loading = false;
  bool _uploading = false;
  String? _selectedRegion;

  KtpPickResult? _ktpFile;
  String? _uploadedFileName;

  static const _regions = [
    'Jawa Timur',
    'Jawa Tengah Selatan',
    'Jawa Tengah Utara',
    'Makassar',
    'Medan',
    'Lampung',
  ];

  List<Provinsi> _provinsiList = [];
  List<Kabupaten> _kabupatenList = [];
  List<Kecamatan> _kecamatanList = [];
  Provinsi? _selectedProvinsi;
  Kabupaten? _selectedKabupaten;
  Kecamatan? _selectedKecamatan;
  bool _loadingProvinsi = false;
  bool _loadingKabupaten = false;
  bool _loadingKecamatan = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _addressController.text.trim().isNotEmpty &&
      _selectedRegion != null &&
      _selectedProvinsi != null &&
      _selectedKabupaten != null &&
      _selectedKecamatan != null &&
      _uploadedFileName != null &&
      _accepted &&
      !_loading &&
      !_uploading;

  Future<void> _loadProvinsiList() async {
    setState(() => _loadingProvinsi = true);
    try {
      final list = await _wilayahService.getProvinsiList(region: _selectedRegion);
      if (!mounted) return;
      setState(() {
        _provinsiList = list;
        _loadingProvinsi = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProvinsi = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar provinsi: ${e.toString()}')),
      );
    }
  }

  Future<void> _onProvinsiChanged(Provinsi? provinsi) async {
    setState(() {
      _selectedProvinsi = provinsi;
      _selectedKabupaten = null;
      _selectedKecamatan = null;
      _kabupatenList = [];
      _kecamatanList = [];
    });

    if (provinsi == null) return;

    setState(() => _loadingKabupaten = true);
    try {
      final list = await _wilayahService.getKabupatenList(provinsi.id);
      if (!mounted) return;
      setState(() {
        _kabupatenList = list;
        _loadingKabupaten = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingKabupaten = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar kabupaten: ${e.toString()}')),
      );
    }
  }

  Future<void> _onKabupatenChanged(Kabupaten? kabupaten) async {
    setState(() {
      _selectedKabupaten = kabupaten;
      _selectedKecamatan = null;
      _kecamatanList = [];
    });

    if (kabupaten == null) return;

    setState(() => _loadingKecamatan = true);
    try {
      final list = await _wilayahService.getKecamatanList(kabupaten.id);
      if (!mounted) return;
      setState(() {
        _kecamatanList = list;
        _loadingKecamatan = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingKecamatan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar kecamatan: ${e.toString()}')),
      );
    }
  }

  void _onKtpPicked(KtpPickResult result) async {
    setState(() {
      _ktpFile = result;
      _uploadedFileName = null;
      _uploading = true;
    });

    try {
      final fileName = await _authService.uploadKtp(
        fileName: result.name,
        bytes: result.bytes,
      );
      if (!mounted) return;
      setState(() {
        _uploadedFileName = fileName;
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ktpFile = null;
        _uploadedFileName = null;
        _uploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal upload KTP: ${e.toString()}')),
      );
    }
  }

  void _onKtpError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _pickKtp() {
    pickKtpFile(_onKtpPicked, _onKtpError);
  }

  Future<void> _submit() async {
    if (_uploadedFileName == null) return;

    setState(() => _loading = true);
    try {
      final session = await _authService.registerKiosk(
        KioskRegistrationDraft(
          kioskName: widget.kioskName,
          picName: widget.picName,
          phone: widget.phone,
          email: widget.email,
          password: widget.password,
          address: _addressController.text.trim(),
          region: _selectedRegion ?? '',
          provinsiId: _selectedProvinsi!.id,
          kabupatenId: _selectedKabupaten!.id,
          kecamatanId: _selectedKecamatan!.id,
          termsAccepted: _accepted,
          licenseImageName: _uploadedFileName,
        ),
      );

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
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      const Text('Region Kios', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedRegion,
                        items: _regions
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _selectedRegion = v;
                            _selectedProvinsi = null;
                            _selectedKabupaten = null;
                            _selectedKecamatan = null;
                            _provinsiList = [];
                            _kabupatenList = [];
                            _kecamatanList = [];
                          });
                          _loadProvinsiList();
                        },
                        decoration: const InputDecoration(hintText: 'Pilih region kios'),
                      ),
                      const SizedBox(height: 14),
                      const Text('Provinsi', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Provinsi>(
                        value: _selectedProvinsi,
                        items: _provinsiList
                            .map((p) => DropdownMenuItem(value: p, child: Text(p.nama)))
                            .toList(),
                        onChanged: (_selectedRegion == null || _loadingProvinsi) ? null : _onProvinsiChanged,
                        decoration: InputDecoration(
                          hintText: _selectedRegion == null
                              ? 'Pilih region kios terlebih dahulu'
                              : _loadingProvinsi
                                  ? 'Memuat provinsi...'
                                  : 'Pilih provinsi',
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Kabupaten/Kota', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Kabupaten>(
                        value: _selectedKabupaten,
                        items: _kabupatenList
                            .map((k) => DropdownMenuItem(value: k, child: Text(k.nama)))
                            .toList(),
                        onChanged: (_selectedProvinsi == null || _loadingKabupaten)
                            ? null
                            : _onKabupatenChanged,
                        decoration: InputDecoration(
                          hintText: _selectedProvinsi == null
                              ? 'Pilih provinsi terlebih dahulu'
                              : _loadingKabupaten
                                  ? 'Memuat kabupaten/kota...'
                                  : 'Pilih kabupaten/kota',
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Kecamatan', style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<Kecamatan>(
                        value: _selectedKecamatan,
                        items: _kecamatanList
                            .map((k) => DropdownMenuItem(value: k, child: Text(k.nama)))
                            .toList(),
                        onChanged: (_selectedKabupaten == null || _loadingKecamatan)
                            ? null
                            : (v) => setState(() => _selectedKecamatan = v),
                        decoration: InputDecoration(
                          hintText: _selectedKabupaten == null
                              ? 'Pilih kabupaten/kota terlebih dahulu'
                              : _loadingKecamatan
                                  ? 'Memuat kecamatan...'
                                  : 'Pilih kecamatan',
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Upload KTP Pemilik',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _uploading ? null : _pickKtp,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _uploadedFileName != null
                                  ? AppTheme.primary
                                  : AppTheme.border,
                              width: 1.4,
                            ),
                          ),
                          child: _buildKtpPreview(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _accepted,
                        onChanged: (v) => setState(() => _accepted = v ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: AppTheme.text, fontSize: 13),
                            children: [
                              TextSpan(text: 'Saya menyetujui '),
                              TextSpan(
                                text: 'Syarat & Ketentuan',
                                style: TextStyle(
                                    color: AppTheme.primary, fontWeight: FontWeight.w700),
                              ),
                              TextSpan(text: ' serta '),
                              TextSpan(
                                text: 'Kebijakan Privasi',
                                style: TextStyle(
                                    color: AppTheme.primary, fontWeight: FontWeight.w700),
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
                onPressed: _canSubmit ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKtpPreview() {
    if (_uploading) {
      return const Column(
        children: [
          SizedBox(
            height: 36,
            width: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: 12),
          Text('Mengupload KTP...', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
    }

    if (_ktpFile == null) {
      return const Column(
        children: [
          Icon(Icons.upload_file_outlined, color: AppTheme.primary, size: 36),
          SizedBox(height: 10),
          Text(
            'Ketuk untuk upload KTP',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4),
          Text(
            'Format .JPG, .PNG, atau .PDF · maks 5 MB',
            style: TextStyle(color: AppTheme.muted, fontSize: 13),
          ),
        ],
      );
    }

    if (_ktpFile!.isPdf) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.picture_as_pdf_outlined,
                color: AppTheme.primary, size: 44),
          ),
          const SizedBox(height: 12),
          Text(
            _ktpFile!.name,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          _uploadedFileName != null
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text('Berhasil diupload',
                        style: TextStyle(color: Colors.green, fontSize: 12)),
                  ],
                )
              : const SizedBox.shrink(),
          const SizedBox(height: 4),
          const Text('Ketuk untuk ganti file',
              style: TextStyle(fontSize: 12, color: AppTheme.muted)),
        ],
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _ktpFile!.bytes,
            height: 130,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _ktpFile!.name,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (_uploadedFileName != null)
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 14),
              SizedBox(width: 4),
              Text('Berhasil diupload',
                  style: TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ),
        const SizedBox(height: 4),
        const Text('Ketuk untuk ganti foto',
            style: TextStyle(fontSize: 12, color: AppTheme.muted)),
      ],
    );
  }
}
