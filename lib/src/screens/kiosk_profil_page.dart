import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import 'settings_pages.dart';

class KiosProfilePage extends StatefulWidget {
  const KiosProfilePage({super.key});

  @override
  State<KiosProfilePage> createState() => _KiosProfilePageState();
}

class _KiosProfilePageState extends State<KiosProfilePage> {
  AuthSession? _session;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await sessionManager.getSession();
    final avatar = await sessionManager.loadAvatarBytes();
    if (!mounted) return;
    setState(() {
      _session = session;
      _avatarBytes = avatar;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppTheme.primary;
    final session = _session;
    final displayName = session?.displayName ?? 'Nama Pengguna';
    final email = session?.email ?? 'user@contoh.com';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('GCommers', style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        actions: const [NotificationBadge()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 28),

              // ── Avatar ────────────────────────────────────────────────────
              Center(
                child: Container(
                  width: 116,
                  height: 116,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary.withAlpha(60), width: 3),
                    color: Colors.grey[100],
                  ),
                  child: ClipOval(
                    child: _avatarBytes != null
                        ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                        : Icon(Icons.person_rounded, size: 62, color: Colors.grey[400]),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── Nama & Edit ───────────────────────────────────────────────
              Column(
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navy)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: AppTheme.muted, fontSize: 14)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.of(context).pushNamed('/edit-profile');
                      _loadSession();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryColor.withAlpha(40)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, color: primaryColor, size: 16),
                          SizedBox(width: 6),
                          Text('Edit Profil', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Statistik ─────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _StatCard(icon: Icons.assignment_outlined, value: '142', label: 'Total PO')),
                  const SizedBox(width: 14),
                  Expanded(child: _StatCard(icon: Icons.account_balance_wallet_outlined, value: '1.2K', label: 'Transaksi')),
                ],
              ),

              const SizedBox(height: 28),

              // ── Menu ──────────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: [
                    _MenuTile(icon: Icons.person_outline_rounded, title: 'Informasi Akun', route: '/account-info'),
                    _divider(),
                    _MenuTile(icon: Icons.shield_outlined, title: 'Keamanan', route: '/security'),
                    _divider(),
                    _MenuTile(icon: Icons.notifications_outlined, title: 'Notifikasi', route: '/notification-settings'),
                    _divider(),
                    _MenuTile(icon: Icons.help_outline_rounded, title: 'Bantuan', route: '/help'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Logout ────────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    await sessionManager.clearSession();
                    if (!mounted) return;
                    nav.pushNamedAndRemoveUntil('/login', (_) => false);
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  label: const Text('Keluar', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 3),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
      );
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primary, size: 26),
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.navy)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, required this.route});

  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: AppTheme.primary.withAlpha(18), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.navy)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
      onTap: () => Navigator.of(context).pushNamed(route),
    );
  }
}

Widget _buildBottomNavBar(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    type: BottomNavigationBarType.fixed,
    selectedItemColor: AppTheme.primary,
    unselectedItemColor: Colors.grey,
    showUnselectedLabels: true,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
      BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Pesanan'),
      BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'Riwayat'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
    ],
    onTap: (index) {
      if (index == 0) Navigator.of(context).pushNamed('/home');
      if (index == 1) Navigator.of(context).pushNamed('/orders');
      if (index == 2) Navigator.of(context).pushNamed('/history');
    },
  );
}
