import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/auth_models.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';

class KiosProfilePage extends StatefulWidget {
  const KiosProfilePage({super.key});

  @override
  State<KiosProfilePage> createState() => _KiosProfilePageState();
}

class _KiosProfilePageState extends State<KiosProfilePage> {
  AuthSession? _session;
  Uint8List? _avatarBytes;
  final _displayNameController = TextEditingController();
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final session = await sessionManager.getSession();
    if (!mounted) return;
    setState(() {
      _session = session;
      _displayNameController.text = session?.displayName ?? '';
    });
  }

  Future<void> _pickAvatarImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 800, maxHeight: 800);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _avatarBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah foto profil: ${e.toString()}')),
      );
    }
  }

  void _toggleEditName() {
    setState(() {
      _isEditingName = !_isEditingName;
      if (!_isEditingName) {
        _displayNameController.text = _session?.displayName ?? '';
      }
    });
  }

  void _saveName() {
    if (_displayNameController.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _session = _session?.copyWith(displayName: _displayNameController.text.trim());
      _isEditingName = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = AppTheme.primary;
    const Color bgLight = Color(0xFFF9F9FF);
    final session = _session;
    final displayName = session?.displayName ?? 'Nama Pengguna';
    final email = session?.email ?? 'user@contoh.com';

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GCommers',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.grey[200],
                      child: _avatarBytes != null
                          ? ClipOval(
                              child: Image.memory(
                                _avatarBytes!,
                                width: 112,
                                height: 112,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(Icons.person, size: 60, color: Colors.grey[400]),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAvatarImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_isEditingName)
                Column(
                  children: [
                    TextField(
                      controller: _displayNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        hintText: 'Nama Lengkap',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveName,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _toggleEditName,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 6),
                    Text(email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _toggleEditName,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, color: primaryColor, size: 18),
                            const SizedBox(width: 8),
                            Text('Edit Profil', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: _buildStatCard(Icons.assignment_outlined, '142', 'Total PO', primaryColor)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard(Icons.account_balance_wallet_outlined, '1.2K', 'Total Transaksi', primaryColor)),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildMenuListTile(Icons.person_outline, 'Informasi Akun', '/account-info', primaryColor),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildMenuListTile(Icons.shield_outlined, 'Keamanan', '/security', primaryColor),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildMenuListTile(Icons.notifications_none_outlined, 'Notifikasi', '/notification-settings', primaryColor),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _buildMenuListTile(Icons.help_outline_rounded, 'Bantuan', '/help', primaryColor),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await sessionManager.clearSession();
                    if (!mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 3, primaryColor),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withAlpha((0.1 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryColor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMenuListTile(IconData icon, String title, String route, Color primaryColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(icon, color: primaryColor, size: 24),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
      onTap: () => Navigator.of(context).pushNamed(route),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, int currentIndex, Color primaryColor) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Pesanan'),
        BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'Riwayat'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
      ],
      onTap: (index) {
        if (index == 0) {
          Navigator.of(context).pushNamed('/home');
        } else if (index == 1) {
          Navigator.of(context).pushNamed('/orders');
        } else if (index == 2) {
          Navigator.of(context).pushNamed('/history');
        }
      },
    );
  }
}

extension on AuthSession {
  AuthSession copyWith({String? displayName}) {
    return AuthSession(
      email: email,
      role: role,
      displayName: displayName ?? this.displayName,
      token: token,
    );
  }
}

