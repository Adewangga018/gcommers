import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import 'settings_pages.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _authService = AuthService();

  AuthSession? _session;
  Uint8List? _avatarBytes;

  final _displayNameCtrl = TextEditingController();
  final _picNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _savingProfile = false;
  bool _savingPassword = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _picNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = await sessionManager.getSession();
    final avatar = await sessionManager.loadAvatarBytes();
    if (!mounted) return;
    setState(() {
      _session = session;
      _avatarBytes = avatar;
      _displayNameCtrl.text = session?.displayName ?? '';
      _picNameCtrl.text = session?.picName ?? '';
      _phoneCtrl.text = session?.phone ?? '';
      _addressCtrl.text = session?.address ?? '';
    });
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80, maxWidth: 800, maxHeight: 800);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      await sessionManager.saveAvatarBytes(bytes);
      if (!mounted) return;
      setState(() => _avatarBytes = bytes);
    } catch (e) {
      if (!mounted) return;
      _showError('Gagal mengunggah foto: $e');
    }
  }

  Future<void> _saveProfile() async {
    final session = _session;
    if (session == null) return;

    final name = _displayNameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Nama Kios tidak boleh kosong.');
      return;
    }

    setState(() => _savingProfile = true);
    try {
      final updated = await _authService.updateProfile(
        email: session.email,
        displayName: name,
        picName: _picNameCtrl.text.trim().isEmpty ? null : _picNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      );
      await sessionManager.saveSession(updated);
      if (!mounted) return;
      setState(() => _session = updated);
      _showSuccess('Profil berhasil disimpan.');
    } catch (e) {
      if (!mounted) return;
      _showError('$e');
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    final session = _session;
    if (session == null) return;

    final current = _currentPassCtrl.text;
    final next = _newPassCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      _showError('Semua field password wajib diisi.');
      return;
    }
    if (next.length < 8) {
      _showError('Password baru minimal 8 karakter.');
      return;
    }
    if (next != confirm) {
      _showError('Konfirmasi password tidak cocok.');
      return;
    }

    setState(() => _savingPassword = true);
    try {
      await _authService.changePassword(
        email: session.email,
        currentPassword: current,
        newPassword: next,
        confirmNewPassword: confirm,
      );
      if (!mounted) return;
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      _showSuccess('Password berhasil diubah.');
    } catch (e) {
      if (!mounted) return;
      _showError('$e');
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green[700]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: AppTheme.primary),
        title: const Text('Edit Profil',
            style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: const [NotificationBadge()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar ───────────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primary.withAlpha(60), width: 3),
                      color: Colors.grey[100],
                    ),
                    child: ClipOval(
                      child: _avatarBytes != null
                          ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                          : Icon(Icons.person_rounded, size: 58, color: Colors.grey[400]),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(_session?.email ?? '',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
            ),
            const SizedBox(height: 28),

            // ── Profil Info ───────────────────────────────────────────────
            _sectionLabel('PROFIL KIOS'),
            _card(children: [
              _field(
                controller: _displayNameCtrl,
                label: 'Nama Kios',
                hint: 'Nama kios Anda',
              ),
              _divider(),
              _field(
                controller: _picNameCtrl,
                label: 'Penanggung Jawab',
                hint: 'Nama penanggung jawab',
              ),
              _divider(),
              _field(
                controller: _phoneCtrl,
                label: 'Nomor Telepon',
                hint: 'Nomor telepon',
                keyboardType: TextInputType.phone,
              ),
              _divider(),
              _field(
                controller: _addressCtrl,
                label: 'Alamat',
                hint: 'Alamat lengkap kios',
                maxLines: 2,
              ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingProfile ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _savingProfile
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan Profil',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),

            const SizedBox(height: 32),

            // ── Ubah Password ─────────────────────────────────────────────
            _sectionLabel('UBAH PASSWORD'),
            _card(children: [
              _passwordField(
                controller: _currentPassCtrl,
                label: 'Password Lama',
                obscure: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              _divider(),
              _passwordField(
                controller: _newPassCtrl,
                label: 'Password Baru',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              _divider(),
              _passwordField(
                controller: _confirmPassCtrl,
                label: 'Konfirmasi Password',
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                isLast: true,
              ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _savingPassword ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _savingPassword
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Ubah Password',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
      );

  Widget _card({required List<Widget> children}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: children),
      );

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
      );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: AppTheme.navy),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
              filled: true,
              fillColor: AppTheme.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    bool isLast = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppTheme.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(fontSize: 14, color: AppTheme.navy),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
              filled: true,
              fillColor: AppTheme.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 20, color: AppTheme.muted),
                onPressed: onToggle,
              ),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.border)),
            ),
          ),
        ],
      ),
    );
  }
}
