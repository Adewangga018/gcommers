import 'package:flutter/material.dart';

import '../models/commerce_models.dart';
import '../models/auth_models.dart';
import '../services/commerce_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

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
    debugPrint('NotificationPage: Loading notifications for user: ${_session?.email}');
    try {
      final notifications = await _commerceService.getNotifications(userEmail: _session?.email);
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _errorMessage = null;
      });
      debugPrint('NotificationPage: Loaded ${notifications.length} notifications. Unread: $_unreadCount');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      debugPrint('NotificationPage: Error loading notifications: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  int get _unreadCount {
    return _notifications.where((item) => !item.isRead).length;
  }

  Future<void> _markAllRead() async {
    debugPrint('NotificationPage: Marking all notifications as read for user: ${_session?.email}');
    setState(() {
      _notifications = _notifications.map((item) => item.isRead ? item : item.copyWith(isRead: true)).toList();
    });
    try {
      await _commerceService.markAllNotificationsRead(userEmail: _session?.email);
      debugPrint('NotificationPage: Successfully marked all as read in backend.');
    } catch (e) {
      debugPrint('Gagal update status read: $e');
    }
  }

  Future<void> _openDetail(AppNotification item) async {
    if (!item.isRead) {
      setState(() {
        _notifications = _notifications.map((notification) {
          return notification.id == item.id ? notification.copyWith(isRead: true) : notification;
        }).toList();
      });
      debugPrint('NotificationPage: Marking notification ${item.id} as read for user: ${_session?.email}');
      try {
        await _commerceService.markNotificationRead(item.id);
        debugPrint('NotificationPage: Successfully marked notification ${item.id} as read in backend.');
      } catch (e) {
        debugPrint('Gagal update status read: $e');
      }
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationDetailPage(notification: item.copyWith(isRead: true)),
      ),
    );
    // Setelah kembali dari NotificationDetailPage, muat ulang notifikasi untuk memastikan status terbaru
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = AppTheme.primary;
    const Color bgLight = Color(0xFFF9F9FF);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifikasi', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Gagal memuat notifikasi: $_errorMessage'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Notifikasi', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            if (_unreadCount > 0)
                              TextButton(
                                onPressed: _markAllRead,
                                child: Text(
                                  'Tandai semua dibaca',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_notifications.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: Text('Belum ada notifikasi.')),
                          )
                        else
                          ..._notifications.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _NotificationCard(item: item, onTap: () => _openDetail(item)),
                            ),
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = item.title.toLowerCase().contains('bayar')
        ? Icons.credit_card_outlined
        : item.title.toLowerCase().contains('jalan')
            ? Icons.local_shipping_outlined
            : Icons.assignment_outlined;
    final color = item.isRead ? Colors.grey[500]! : AppTheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isRead ? Colors.white : Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: item.isRead ? Colors.grey[200]! : Colors.blue[100]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha((0.1 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              shortDateTime(item.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationDetailPage extends StatelessWidget {
  const NotificationDetailPage({required this.notification, super.key});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = AppTheme.primary;
    const Color bgLight = Color(0xFFF9F9FF);
    final icon = notification.title.toLowerCase().contains('bayar')
        ? Icons.credit_card_outlined
        : notification.title.toLowerCase().contains('jalan')
            ? Icons.local_shipping_outlined
            : Icons.assignment_outlined;

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha((0.1 * 255).round()),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            shortDateTime(notification.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deskripsi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    const SizedBox(height: 12),
                    Text(
                      notification.description,
                      style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kembali', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
