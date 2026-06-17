import 'package:flutter/material.dart';

import '../models/commerce_models.dart';
import '../models/auth_models.dart';
import '../services/commerce_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

enum _NotifType { payment, received, problem, info, order, shipping }

// Parses structured info from notification description text.
Map<String, String> _parseDetails(AppNotification n, {String role = ''}) {
  final type = _detectType(n, role: role);
  final desc = n.description;
  final details = <String, String>{};

  if (type == _NotifType.payment) {
    // Format: "Pembayaran PO-XXXXX melalui METHOD telah diterima."
    final poMatch = RegExp(r'(PO-[\w-]+)').firstMatch(desc);
    final methodMatch = RegExp(r'melalui (.+?) telah').firstMatch(desc);
    if (poMatch != null) details['Nomor PO'] = poMatch.group(1)!;
    if (methodMatch != null) details['Metode Pembayaran'] = methodMatch.group(1)!;
  } else if (type == _NotifType.received || type == _NotifType.problem) {
    // Format: "PO-XXXXX: catatan"
    final colonIdx = desc.indexOf(':');
    if (colonIdx != -1) {
      final candidate = desc.substring(0, colonIdx).trim();
      final notes = desc.substring(colonIdx + 1).trim();
      if (candidate.startsWith('PO-')) {
        details['Nomor PO'] = candidate;
        if (notes.isNotEmpty) details['Catatan'] = notes;
      }
    }
  } else if (type == _NotifType.order) {
    final poMatch = RegExp(r'(PO-[\w-]+)').firstMatch(desc);
    if (poMatch != null) details['Nomor PO'] = poMatch.group(1)!;
    final colonIdx = desc.indexOf(':');
    if (colonIdx != -1) {
      final notes = desc.substring(colonIdx + 1).trim();
      if (notes.isNotEmpty) details['Keterangan'] = notes;
    }
  } else if (type == _NotifType.shipping) {
    final sjMatch = RegExp(r'(SJ-[\w-]+)').firstMatch(desc);
    final poMatch = RegExp(r'(PO-[\w-]+)').firstMatch(desc);
    if (sjMatch != null) details['No. Surat Jalan'] = sjMatch.group(1)!;
    if (poMatch != null) details['Nomor PO'] = poMatch.group(1)!;
  }

  return details;
}

_NotifType _detectType(AppNotification n, {String role = ''}) {
  final t = n.title.toLowerCase();
  final d = n.description.toLowerCase();

  if (role == 'transportir') {
    if (t.contains('pesanan') || d.contains('pesanan') ||
        t.contains('order') || d.contains('order') ||
        t.contains('po-') || d.contains('po-')) { return _NotifType.order; }
    if (t.contains('pengiriman') || d.contains('pengiriman') ||
        t.contains('kirim') || d.contains('kirim') ||
        t.contains('muat') || d.contains('muat') ||
        t.contains('surat jalan') || d.contains('surat jalan')) { return _NotifType.shipping; }
    return _NotifType.info;
  }

  if (t.contains('bayar') || d.contains('bayar') || t.contains('payment')) { return _NotifType.payment; }
  if (t.contains('bermasalah') || d.contains('bermasalah')) { return _NotifType.problem; }
  if (t.contains('diterima') || d.contains('diterima')) { return _NotifType.received; }
  return _NotifType.info;
}

IconData _typeIcon(_NotifType type) => switch (type) {
      _NotifType.payment => Icons.credit_card_rounded,
      _NotifType.received => Icons.inventory_2_rounded,
      _NotifType.problem => Icons.warning_amber_rounded,
      _NotifType.order => Icons.assignment_rounded,
      _NotifType.shipping => Icons.local_shipping_rounded,
      _NotifType.info => Icons.notifications_rounded,
    };

Color _typeColor(_NotifType type, {bool dimmed = false}) {
  if (dimmed) return Colors.grey[400]!;
  return switch (type) {
    _NotifType.payment => const Color(0xFF2F6C3F),
    _NotifType.received => AppTheme.primary,
    _NotifType.problem => const Color(0xFFC62828),
    _NotifType.order => const Color(0xFF0F261F),
    _NotifType.shipping => const Color(0xFF2F6C3F),
    _NotifType.info => const Color(0xFF2F6C3F),
  };
}

Color _typeBgColor(_NotifType type, {bool dimmed = false}) {
  if (dimmed) return Colors.grey[100]!;
  return switch (type) {
    _NotifType.payment => const Color(0xFFDCEDE1),
    _NotifType.received => const Color(0xFFEAF2EC),
    _NotifType.problem => const Color(0xFFFFEBEE),
    _NotifType.order => const Color(0xFFDCEDE1),
    _NotifType.shipping => const Color(0xFFEAF2EC),
    _NotifType.info => const Color(0xFFDCEDE1),
  };
}

String _typeLabel(_NotifType type) => switch (type) {
      _NotifType.payment => 'Pembayaran',
      _NotifType.received => 'Penerimaan',
      _NotifType.problem => 'Masalah',
      _NotifType.order => 'Pesanan',
      _NotifType.shipping => 'Pengiriman',
      _NotifType.info => 'Info',
    };

String _relativeTime(DateTime dt) {
  final now = DateTime.now();
  final local = dt.toLocal();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays == 1) return 'Kemarin';
  return shortDateTime(dt);
}

String _groupLabel(DateTime dt) {
  final now = DateTime.now();
  final local = dt.toLocal();
  final diffDays = DateTime(now.year, now.month, now.day)
      .difference(DateTime(local.year, local.month, local.day))
      .inDays;
  if (diffDays == 0) return 'Hari ini';
  if (diffDays == 1) return 'Kemarin';
  return shortDateTime(dt);
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _commerceService = CommerceService();
  bool _isLoading = true;
  String? _errorMessage;
  List<AppNotification> _notifications = [];
  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    _session = await sessionManager.getSession();
    await _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _commerceService.getNotifications(userEmail: _session?.email);
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<AppNotification> get _visibleNotifications {
    final role = _session?.role ?? '';
    return _notifications.where((n) {
      final type = _detectType(n, role: role);
      if (role == 'transportir') {
        return type == _NotifType.order || type == _NotifType.shipping || type == _NotifType.info;
      }
      // kiosk and others: payment, received, problem, info
      return type == _NotifType.payment || type == _NotifType.received ||
          type == _NotifType.problem || type == _NotifType.info;
    }).toList();
  }

  int get _unreadCount => _visibleNotifications.where((n) => !n.isRead).length;

  Future<void> _markAllRead() async {
    setState(() {
      _notifications = _notifications.map((n) => n.isRead ? n : n.copyWith(isRead: true)).toList();
    });
    try {
      await _commerceService.markAllNotificationsRead(userEmail: _session?.email);
    } catch (e) {
      debugPrint('Gagal update status read: $e');
    }
  }

  Future<void> _openDetail(AppNotification item) async {
    if (!item.isRead) {
      setState(() {
        _notifications = _notifications.map((n) => n.id == item.id ? n.copyWith(isRead: true) : n).toList();
      });
      try {
        await _commerceService.markNotificationRead(item.id);
      } catch (e) {
        debugPrint('Gagal update status read: $e');
      }
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationDetailPage(
          notification: item.copyWith(isRead: true),
          role: _session?.role ?? '',
        ),
      ),
    );
    _loadNotifications();
  }

  Map<String, List<AppNotification>> get _grouped {
    final map = <String, List<AppNotification>>{};
    for (final n in _visibleNotifications) {
      map.putIfAbsent(_groupLabel(n.createdAt), () => []).add(n);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(color: AppTheme.navy, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Baca Semua',
                style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _ErrorState(onRetry: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadNotifications();
                })
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppTheme.primary,
                  child: _visibleNotifications.isEmpty ? _EmptyState(role: _session?.role ?? '') : _buildList(),
                ),
    );
  }

  Widget _buildList() {
    final grouped = _grouped;
    final groups = grouped.keys.toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Text(
                  '${_visibleNotifications.length} notifikasi',
                  style: const TextStyle(fontSize: 13, color: AppTheme.muted, fontWeight: FontWeight.w500),
                ),
                if (_unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_unreadCount belum dibaca',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        for (final group in groups) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
              child: Text(
                group.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final item = grouped[group]![i];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _NotificationCard(item: item, onTap: () => _openDetail(item), role: _session?.role ?? ''),
                );
              },
              childCount: grouped[group]!.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.role = ''});

  final String role;

  @override
  Widget build(BuildContext context) {
    final subtitle = role == 'transportir'
        ? 'Notifikasi pesanan masuk dan pengiriman\nakan muncul di sini.'
        : 'Notifikasi pesanan dan pembayaran\nakan muncul di sini.';

    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_none_rounded,
                  size: 56,
                  color: AppTheme.primary.withAlpha(140),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Belum ada notifikasi',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.navy),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.muted, height: 1.6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 52, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat notifikasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy),
            ),
            const SizedBox(height: 8),
            const Text(
              'Periksa koneksi internet Anda dan coba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap, this.role = ''});

  final AppNotification item;
  final VoidCallback onTap;
  final String role;

  @override
  Widget build(BuildContext context) {
    final type = _detectType(item, role: role);
    final iconColor = _typeColor(type, dimmed: item.isRead);
    final bgColor = _typeBgColor(type, dimmed: item.isRead);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: item.isRead ? Colors.transparent : iconColor,
              width: 3.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(item.isRead ? 5 : 10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_typeIcon(type), color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withAlpha(item.isRead ? 18 : 28),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _typeLabel(type),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: iconColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _relativeTime(item.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                        color: item.isRead ? AppTheme.muted : AppTheme.navy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.45),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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

class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage({required this.notification, this.role = '', super.key});

  final AppNotification notification;
  final String role;

  @override
  Widget build(BuildContext context) {
    final type = _detectType(notification, role: role);
    final iconColor = _typeColor(type);
    final bgColor = _typeBgColor(type);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.primary,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.navy),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon + type label + title
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
                    child: Icon(_typeIcon(type), color: iconColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: iconColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _typeLabel(type),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: iconColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.navy,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Metadata + parsed detail section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Builder(builder: (context) {
                final details = _parseDetails(notification, role: role);
                final rows = <Widget>[
                  _DetailRow(
                    icon: Icons.access_time_filled_rounded,
                    label: 'Waktu',
                    value: formatDateTime(notification.createdAt),
                    iconColor: AppTheme.primary,
                  ),
                ];
                details.forEach((label, value) {
                  rows.add(const _Divider());
                  final icon = switch (label) {
                    'Nomor PO' => Icons.receipt_long_rounded,
                    'Metode Pembayaran' => Icons.payment_rounded,
                    'Catatan' => Icons.notes_rounded,
                    _ => Icons.info_outline_rounded,
                  };
                  rows.add(_DetailRow(icon: icon, label: label, value: value, iconColor: iconColor));
                });
                return Column(children: rows);
              }),
            ),

            const SizedBox(height: 14),

            // Full message section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description_rounded, size: 15, color: AppTheme.muted),
                      const SizedBox(width: 6),
                      const Text(
                        'PESAN',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.muted, letterSpacing: 0.8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notification.description,
                    style: const TextStyle(fontSize: 15, height: 1.7, color: AppTheme.navy),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Kembali', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.navy),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
