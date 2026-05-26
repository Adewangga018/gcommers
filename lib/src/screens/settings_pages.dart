import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../services/commerce_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';

class AccountInfoPage extends StatefulWidget {
  const AccountInfoPage({super.key});

  @override
  State<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends State<AccountInfoPage> {
  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await sessionManager.getSession();
    if (mounted) setState(() => _session = session);
  }

  @override
  Widget build(BuildContext context) {
    const Color bgLight = Color(0xFFF9F9FF);
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppTheme.primary),
        title: const Text('Informasi Akun', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          const NotificationBadge(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Akun Anda', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Kelola informasi akun dan detail verifikasi kios Anda.', style: TextStyle(color: Colors.grey[600], height: 1.5)),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _InfoTile(label: 'Nama Akun', value: _session?.displayName ?? '-'),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _InfoTile(label: 'Email', value: _session?.email ?? '-'),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _InfoTile(label: 'Jenis Akun', value: _session?.role == 'kiosk' ? 'Kios Mitra' : 'Administrator'),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _InfoTile(label: 'PIC', value: _session?.picName ?? '-'),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _InfoTile(label: 'Nomor Telepon', value: _session?.phone ?? '-'),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _InfoTile(label: 'Alamat Kios', value: _session?.address ?? '-'),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    const _InfoTile(label: 'Status Verifikasi', value: 'Terverifikasi'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await sessionManager.getSession();
    if (mounted) setState(() => _session = session);
  }

  @override
  Widget build(BuildContext context) {
    const Color bgLight = Color(0xFFF9F9FF);
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppTheme.primary),
        title: const Text('Keamanan', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          const NotificationBadge(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Keamanan Akun', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Kelola login Anda, ganti password, dan aktifkan keamanan tambahan.', style: TextStyle(color: Colors.grey[600], height: 1.5)),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    const _InfoTile(label: 'Password', value: '••••••••'),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    const _InfoTile(label: 'Otentikasi 2 Langkah', value: 'Nonaktif'),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    _InfoTile(label: 'Pemulihan Akun', value: _session?.email ?? 'Email terdaftar'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Ubah Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgLight = Color(0xFFF9F9FF);
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppTheme.primary),
        title: const Text('Notifikasi', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          const NotificationBadge(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pengaturan Notifikasi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Pilih jenis notifikasi yang ingin Anda terima dari GCommers.', style: TextStyle(color: Colors.grey[600], height: 1.5)),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Column(
                  children: [
                    _ToggleTile(label: 'Notifikasi Pesanan'),
                    Divider(height: 1, indent: 20, endIndent: 20),
                    _ToggleTile(label: 'Notifikasi Pembayaran'),
                    Divider(height: 1, indent: 20, endIndent: 20),
                    _ToggleTile(label: 'Notifikasi Pengiriman'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgLight = Color(0xFFF9F9FF);
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppTheme.primary),
        title: const Text('Bantuan', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          const NotificationBadge(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bantuan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Jika Anda membutuhkan bantuan, lihat petunjuk atau hubungi tim dukungan kami.', style: TextStyle(color: Colors.grey[600], height: 1.5)),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: const Column(
                  children: [
                    _InfoTile(label: 'Pusat Bantuan', value: 'Panduan penggunaan aplikasi'),
                    Divider(height: 1, indent: 20, endIndent: 20),
                    _InfoTile(label: 'Kontak Dukungan', value: 'support@gcommers.id'),
                    Divider(height: 1, indent: 20, endIndent: 20),
                    _InfoTile(label: 'FAQ', value: 'Pertanyaan umum'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 15),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationBadge extends StatefulWidget {
  final Color iconColor;
  const NotificationBadge({super.key, this.iconColor = AppTheme.primary});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final _commerceService = CommerceService();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      debugPrint('NotificationBadge: Loading unread count.');
      final session = await sessionManager.getSession();
      debugPrint('NotificationBadge: Session email: ${session?.email}');
      final notifications = await _commerceService.getNotifications(userEmail: session?.email);
      if (!mounted) return;
      setState(() {
        _unreadCount = notifications.where((item) => !item.isRead).length;
      });
      debugPrint('NotificationBadge: Unread count: $_unreadCount');
    } catch (e) { debugPrint('NotificationBadge: Error loading unread count: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).pushNamed('/notifications');
        _loadUnreadCount();
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_none, color: widget.iconColor, size: 28),
            if (_unreadCount > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$_unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatefulWidget {
  const _ToggleTile({required this.label});

  final String label;

  @override
  State<_ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<_ToggleTile> {
  bool _isEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(widget.label, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          Switch(
            value: _isEnabled,
            activeColor: AppTheme.primary,
            onChanged: (value) {
              setState(() {
                _isEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
