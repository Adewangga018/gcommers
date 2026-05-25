import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../models/commerce_models.dart';
import '../services/commerce_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class KiosDashboardPage extends StatefulWidget {
  const KiosDashboardPage({super.key});

  @override
  State<KiosDashboardPage> createState() => _KiosDashboardPageState();
}

class _KiosDashboardPageState extends State<KiosDashboardPage> {
  final _commerceService = CommerceService();
  late final Future<DashboardSummary> _summaryFuture;
  AuthSession? _session;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _commerceService.getDashboardSummary();
    _initData();
  }

  Future<void> _initData() async {
    await _loadSession();
    await _loadUnreadCount();
  }

  Future<void> _loadSession() async {
    final session = await sessionManager.getSession();
    if (!mounted) return;
    setState(() {
      _session = session;
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      debugPrint('KiosDashboardPage: Loading unread count for user: ${_session?.email}');
      final notifications = await _commerceService.getNotifications(userEmail: _session?.email);
      if (!mounted) return;
      setState(() {
        _unreadNotifications = notifications.where((item) => !item.isRead).length;
      });
      debugPrint('KiosDashboardPage: Unread notifications count: $_unreadNotifications');
    } catch (e) {
      // Ignore notification load error here; dashboard still works.
      debugPrint('KiosDashboardPage: Error loading unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryPurple = AppTheme.primary;
    const Color bgLight = Color(0xFFF9F9FF);

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(
        child: FutureBuilder<DashboardSummary>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ErrorState(message: snapshot.error.toString());
            }

            final summary = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF534AB7), Color(0xFF3C3489)],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${_session?.displayName ?? 'PT Kios Berkah'}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              shortDateTime(DateTime.now()),
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                await Navigator.of(context).pushNamed('/notifications');
                                _loadUnreadCount(); // Refresh jumlah saat kembali
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                                  if (_unreadNotifications > 0)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                        child: Text(
                                          '$_unreadNotifications',
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                ],
                              ),
                            ),
                            const SizedBox(width: 15),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pushNamed('/profile'),
                              child: const CircleAvatar(
                                backgroundColor: Colors.white24,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildQuickActionCard(
                          context,
                          Icons.shopping_cart_outlined,
                          'Pesanan',
                          primaryPurple,
                          onTap: () => Navigator.of(context).pushNamed('/orders'),
                        ),
                        _buildQuickActionCard(
                          context,
                          Icons.history_outlined,
                          'Riwayat',
                          primaryPurple,
                          onTap: () => Navigator.of(context).pushNamed('/history'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text('Ringkasan Bulan Ini', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.shopping_bag_outlined,
                            title: 'Pesanan Aktif',
                            value: '${summary.activeOrderCount}',
                            subWidget: Text(
                              '${summary.completedOrderCount} selesai',
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSummaryCard(
                            icon: Icons.payments_outlined,
                            title: 'Total Tagihan',
                            value: formatCurrency(summary.monthlySales),
                            subWidget: const Text('Bulan berjalan', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pesanan Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushNamed('/history'),
                          child: Text('Lihat Semua', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        if (summary.recentOrders.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('Belum ada pesanan.'),
                          )
                        else
                          ...summary.recentOrders.map(
                            (order) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildOrderCard(
                                context: context,
                                order: order,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 0, primaryPurple),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({required IconData icon, required String title, required String value, required Widget subWidget}) {
    return SizedBox(
      height: 115, // Memberikan tinggi tetap agar ukuran container sama
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title, 
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value, 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          subWidget,
        ],
      ),),
    );
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required OrderSummary order,
  }) {
    final statusColor = _statusColor(order.status);
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/history-detail', arguments: order.poNumber),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.poNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(formatDateTime(order.createdAt), style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${formatCurrency(order.totalAmount)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Gagal memuat dashboard: $message', textAlign: TextAlign.center),
      ),
    );
  }
}

Color _statusColor(String status) {
  return switch (status) {
    'pending_payment' => AppTheme.primary,
    'paid' => AppTheme.primaryDark,
    'shipping' => AppTheme.primaryDark,
    'received' || 'completed' => AppTheme.primaryDark,
    _ => Colors.grey,
  };
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
      switch (index) {
        case 1:
          Navigator.of(context).pushNamed('/orders');
          break;
        case 2:
          Navigator.of(context).pushNamed('/history');
          break;
        case 3:
          Navigator.of(context).pushNamed('/profile');
          break;
      }
    },
  );
}
