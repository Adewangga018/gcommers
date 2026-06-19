import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/transportir_bottom_nav.dart';
import 'settings_pages.dart';

class TransportirProfilePage extends StatefulWidget {
  const TransportirProfilePage({super.key, this.session});

  final AuthSession? session;

  @override
  State<TransportirProfilePage> createState() => _TransportirProfilePageState();
}

class _TransportirProfilePageState extends State<TransportirProfilePage> {
  AuthSession? _session;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await sessionManager.getSession();
    final activeSession = session ?? widget.session;
    final avatar = await sessionManager.loadAvatarBytes(email: activeSession?.email);
    if (!mounted) return;
    setState(() {
      _session = activeSession;
      _avatarBytes = avatar;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _session ?? widget.session;
    final companyName = _companyName(session);
    final email = session?.email ?? '-';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('GCommers', style: AppTheme.title(size: 18)),
        centerTitle: true,
        actions: const [NotificationBadge()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 28),
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
                        : Icon(Icons.local_shipping_rounded, size: 58, color: Colors.grey[400]),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Column(
                children: [
                  Text(
                    companyName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.navy),
                  ),
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
                        color: AppTheme.primary.withAlpha(18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primary.withAlpha(40)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_rounded, color: AppTheme.primary, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Edit Profil',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Row(
                children: const [
                  Expanded(child: _StatCard(icon: Icons.local_shipping_outlined, value: '142', label: 'Total Trip')),
                  SizedBox(width: 14),
                  Expanded(child: _StatCard(icon: Icons.payments_outlined, value: '1.2K', label: 'Transaksi')),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    await sessionManager.clearSession();
                    if (!mounted) return;
                    nav.pushNamedAndRemoveUntil('/transportir-login', (_) => false);
                  },
                  icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
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
      bottomNavigationBar: TransportirBottomNav(currentIndex: 3, session: session),
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1, thickness: 0.5, color: Color(0xFFF5F5F5)),
      );

  String _companyName(AuthSession? session) {
    if (session?.companyName?.trim().isNotEmpty ?? false) return session!.companyName!;
    if (session?.displayName.trim().isNotEmpty ?? false) return session!.displayName;
    return 'Nama Perusahaan Transportir';
  }

}

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
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.primary.withAlpha(18), shape: BoxShape.circle),
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
