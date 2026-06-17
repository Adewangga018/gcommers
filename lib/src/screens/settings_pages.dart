import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../services/commerce_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';

// ─── Account Info ─────────────────────────────────────────────────────────────

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
    final s = _session;
    final roleLabel = switch (s?.role) {
      'kiosk' => 'Kios Mitra',
      'transportir' => 'Transportir',
      _ => 'Administrator',
    };
    final isTransportir = s?.role == 'transportir';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar('Informasi Akun'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(isTransportir ? 'Profil Transportir' : 'Profil Kios'),
            _InfoCard(
              children: isTransportir
                  ? [
                      _InfoRow(label: 'Nama Perusahaan', value: s?.companyName ?? s?.displayName),
                      _InfoRow(label: 'Nama Transportir', value: s?.transportirName),
                      _InfoRow(label: 'Nomor Telepon', value: s?.phone),
                      _InfoRow(label: 'Nomor Polisi', value: s?.policeNumber),
                      _InfoRow(label: 'Jenis Kendaraan', value: s?.vehicleType, isLast: true),
                    ]
                  : [
                      _InfoRow(label: 'Nama Kios', value: s?.displayName),
                      _InfoRow(label: 'Penanggung Jawab', value: s?.picName),
                      _InfoRow(label: 'Nomor Telepon', value: s?.phone),
                      _InfoRow(label: 'Alamat', value: s?.address),
                      _InfoRow(label: 'Wilayah', value: s?.region, isLast: true),
                    ],
            ),
            const SizedBox(height: 20),
            _SectionLabel('Akun'),
            _InfoCard(children: [
              _InfoRow(label: 'Email', value: s?.email),
              _InfoRow(label: 'Jenis Akun', value: roleLabel),
              _InfoRow(
                label: 'Status Verifikasi',
                value: 'Terverifikasi',
                valueColor: const Color(0xFF2E7D32),
                isLast: true,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Security ─────────────────────────────────────────────────────────────────

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  AuthSession? _session;
  bool _twoFactorEnabled = false;

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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar('Keamanan'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Kata Sandi'),
            _InfoCard(children: [
              _InfoRow(label: 'Password', value: '••••••••'),
              _InfoRow(label: 'Pemulihan Akun', value: _session?.email, isLast: true),
            ]),
            const SizedBox(height: 20),
            _SectionLabel('Keamanan Tambahan'),
            Container(
              decoration: _cardDecoration(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Otentikasi 2 Langkah',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.navy)),
                          const SizedBox(height: 2),
                          Text(
                            _twoFactorEnabled ? 'Aktif' : 'Nonaktif',
                            style: TextStyle(
                              fontSize: 12,
                              color: _twoFactorEnabled ? const Color(0xFF2E7D32) : AppTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _twoFactorEnabled,
                      thumbColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected) ? AppTheme.primary : null,
                      ),
                      onChanged: (v) => setState(() => _twoFactorEnabled = v),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notification Settings ────────────────────────────────────────────────────

class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar('Notifikasi'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Preferensi Notifikasi'),
            Container(
              decoration: _cardDecoration(),
              child: const Column(
                children: [
                  _ToggleRow(label: 'Notifikasi Pesanan', subtitle: 'Pesanan baru dan perubahan status'),
                  _RowDivider(),
                  _ToggleRow(label: 'Notifikasi Pembayaran', subtitle: 'Konfirmasi dan pengingat pembayaran'),
                  _RowDivider(),
                  _ToggleRow(label: 'Notifikasi Pengiriman', subtitle: 'Status pengiriman dan estimasi tiba', isLast: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Help ─────────────────────────────────────────────────────────────────────

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar('Bantuan'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel('Panduan'),
            Container(
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _HelpRow(
                    label: 'Panduan Penggunaan',
                    subtitle: 'Cara menggunakan fitur GCommers',
                    onTap: () => _openHelpDetail(context, _HelpDetailKind.guide),
                  ),
                  _HelpRow(
                    label: 'FAQ',
                    subtitle: 'Pertanyaan yang sering diajukan',
                    onTap: () => _openHelpDetail(context, _HelpDetailKind.faq),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Hubungi Kami'),
            Container(
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  _HelpRow(
                    label: 'Email Dukungan',
                    subtitle: 'support@gcommers.id',
                    onTap: () => _openHelpDetail(context, _HelpDetailKind.email),
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionLabel('Tentang Aplikasi'),
            _InfoCard(children: [
              const _InfoRow(label: 'Versi Aplikasi', value: '1.0.0'),
              const _InfoRow(label: 'Nama Aplikasi', value: 'GCommers', isLast: true),
            ]),
          ],
        ),
      ),
    );
  }

  void _openHelpDetail(BuildContext context, _HelpDetailKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _HelpDetailPage(kind: kind)),
    );
  }
}

enum _HelpDetailKind { guide, faq, email }

class _HelpDetailPage extends StatelessWidget {
  const _HelpDetailPage({required this.kind});

  final _HelpDetailKind kind;

  @override
  Widget build(BuildContext context) {
    final title = switch (kind) {
      _HelpDetailKind.guide => 'Panduan Penggunaan',
      _HelpDetailKind.faq => 'FAQ',
      _HelpDetailKind.email => 'Email Dukungan',
    };

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kind == _HelpDetailKind.guide) ..._guideContent(),
            if (kind == _HelpDetailKind.faq) ..._faqContent(),
            if (kind == _HelpDetailKind.email) ..._emailContent(),
          ],
        ),
      ),
    );
  }

  List<Widget> _guideContent() => const [
        _SectionLabel('Mulai Menggunakan'),
        _DetailCard(
          children: [
            _BulletText('Pilih role sesuai akun: Kios untuk pembelian, Transportir untuk pengiriman.'),
            _BulletText('Masuk menggunakan email dan password yang sudah terdaftar.'),
            _BulletText('Gunakan menu Profil untuk melihat informasi akun, keamanan, notifikasi, dan bantuan.'),
          ],
        ),
        SizedBox(height: 20),
        _SectionLabel('Kios'),
        _DetailCard(
          children: [
            _BulletText('Buka Pesanan untuk memilih produk dari database.'),
            _BulletText('Gunakan pencarian berdasarkan nama atau kode produk.'),
            _BulletText('Lanjutkan pembayaran setelah pesanan dibuat.'),
          ],
        ),
        SizedBox(height: 20),
        _SectionLabel('Transportir'),
        _DetailCard(
          children: [
            _BulletText('Pantau pesanan, pengiriman, dan laporan dari navigasi bawah.'),
            _BulletText('Buka detail pesanan untuk melihat surat jalan dan status pengiriman.'),
            _BulletText('Gunakan halaman laporan untuk klaim atau riwayat laporan.'),
          ],
        ),
      ];

  List<Widget> _faqContent() => const [
        _SectionLabel('Pertanyaan Umum'),
        _DetailCard(
          children: [
            _QuestionAnswer(
              question: 'Bagaimana jika produk tidak muncul?',
              answer: 'Pastikan backend berjalan dan koneksi database aktif, lalu muat ulang halaman pesanan.',
            ),
            _RowDivider(),
            _QuestionAnswer(
              question: 'Kenapa notifikasi saya kosong?',
              answer: 'Notifikasi akan muncul setelah ada aktivitas pesanan, pembayaran, atau pengiriman untuk akun Anda.',
            ),
            _RowDivider(),
            _QuestionAnswer(
              question: 'Bagaimana cara mengubah foto profil?',
              answer: 'Buka Profil, pilih Edit Profil, unggah foto baru, lalu tekan Simpan Profil.',
            ),
          ],
        ),
      ];

  List<Widget> _emailContent() => const [
        _SectionLabel('Kontak Dukungan'),
        _DetailCard(
          children: [
            _InfoRow(label: 'Email', value: 'support@gcommers.id'),
            _InfoRow(label: 'Jam Layanan', value: 'Senin-Jumat, 08.00-17.00 WIB'),
            _InfoRow(label: 'Prioritas', value: 'Sertakan email akun, role, dan ringkasan kendala.', isLast: true),
          ],
        ),
        SizedBox(height: 20),
        _SectionLabel('Format Pesan'),
        _DetailCard(
          children: [
            _BulletText('Subjek: Kendala GCommers - nama fitur.'),
            _BulletText('Tuliskan langkah yang dilakukan sebelum masalah muncul.'),
            _BulletText('Lampirkan tangkapan layar jika ada pesan error.'),
          ],
        ),
      ];
}

// ─── NotificationBadge ────────────────────────────────────────────────────────

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
      final session = await sessionManager.getSession();
      final notifications = await _commerceService.getNotifications(userEmail: session?.email);
      if (!mounted) return;
      setState(() => _unreadCount = notifications.where((n) => !n.isRead).length);
    } catch (e) {
      debugPrint('NotificationBadge error: $e');
    }
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
            Icon(Icons.notifications_rounded, color: widget.iconColor, size: 26),
            if (_unreadCount > 0)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                  child: Text(
                    _unreadCount > 99 ? '99+' : '$_unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

AppBar _buildAppBar(String title) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    shadowColor: Colors.black12,
    iconTheme: const IconThemeData(color: AppTheme.primary),
    title: Text(title, style: const TextStyle(color: AppTheme.navy, fontWeight: FontWeight.bold, fontSize: 18)),
    centerTitle: true,
  );
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 8, offset: const Offset(0, 2))],
    );

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(decoration: _cardDecoration(), child: Column(children: children));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.valueColor, this.isLast = false});

  final String label;
  final String? value;
  final Color? valueColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(label,
                    style: const TextStyle(fontSize: 13, color: AppTheme.muted, fontWeight: FontWeight.w500)),
              ),
              Expanded(
                child: Text(
                  (value == null || value!.isEmpty) ? '-' : value!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppTheme.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const _RowDivider(),
      ],
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
    );
  }
}

class _ToggleRow extends StatefulWidget {
  const _ToggleRow({required this.label, this.subtitle, this.isLast = false});

  final String label;
  final String? subtitle;
  final bool isLast;

  @override
  State<_ToggleRow> createState() => _ToggleRowState();
}

class _ToggleRowState extends State<_ToggleRow> {
  bool _enabled = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.label,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.navy)),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(widget.subtitle!,
                          style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                    ],
                  ],
                ),
              ),
              Switch(
                value: _enabled,
                thumbColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected) ? AppTheme.primary : null,
                ),
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ],
          ),
        ),
        if (!widget.isLast) const _RowDivider(),
      ],
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.label, required this.subtitle, required this.onTap, this.isLast = false});

  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: isLast
              ? const BorderRadius.only(bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14))
              : BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.navy)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
        if (!isLast) const _RowDivider(),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7, right: 10),
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.45, color: AppTheme.navy)),
          ),
        ],
      ),
    );
  }
}

class _QuestionAnswer extends StatelessWidget {
  const _QuestionAnswer({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const SizedBox(height: 6),
          Text(answer, style: const TextStyle(fontSize: 13, height: 1.45, color: AppTheme.muted)),
        ],
      ),
    );
  }
}
