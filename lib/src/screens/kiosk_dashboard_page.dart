import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../models/commerce_models.dart';
import '../services/commerce_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'settings_pages.dart';

class KiosDashboardPage extends StatefulWidget {
  const KiosDashboardPage({super.key});

  @override
  State<KiosDashboardPage> createState() => _KiosDashboardPageState();
}

class _KiosDashboardPageState extends State<KiosDashboardPage> {
  final _commerceService = CommerceService();
  late final Future<DashboardSummary> _summaryFuture;
  AuthSession? _session;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _commerceService.getDashboardSummary();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final session = await sessionManager.getSession();
    final avatar = await sessionManager.loadAvatarBytes(email: session?.email);
    if (!mounted) return;
    setState(() {
      _session = session;
      _avatarBytes = avatar;
    });
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
                            const NotificationBadge(iconColor: Colors.white),
                            GestureDetector(
                              onTap: () async {
                                await Navigator.of(context).pushNamed('/profile');
                                _loadSession();
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white24,
                                child: _avatarBytes != null
                                    ? ClipOval(
                                        child: Image.memory(
                                          _avatarBytes!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : const Icon(Icons.person_rounded, color: Colors.white, size: 22),
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
                    child: Text(
                      'Ringkasan Bulan Ini',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: 0.1),
                    ),
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
                        const Text(
                          'Pesanan Terbaru',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), letterSpacing: 0.1),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushNamed('/history'),
                          child: Text('Lihat Semua', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w600, fontSize: 13)),
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2DDF1)),
            boxShadow: const [
              BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({required IconData icon, required String title, required String value, required Widget subWidget}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2DDF1)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF6B7280), size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 6),
          subWidget,
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required BuildContext context,
    required OrderSummary order,
  }) {
    final statusColor = _statusColor(order.status);
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed('/history-detail', arguments: order.poNumber),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2DDF1)),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.poNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1E293B))),
                      const SizedBox(height: 4),
                      Text(formatDateTime(order.createdAt), style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    order.statusLabel,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFF1EEF9)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatCurrency(order.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF3B309E)),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBC8D8), size: 20),
              ],
            ),
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
    'pending_payment' => const Color(0xFFD97706),
    'paid' => const Color(0xFF2563EB),
    'shipping' => const Color(0xFF7C3AED),
    'received' || 'completed' => const Color(0xFF059669),
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
