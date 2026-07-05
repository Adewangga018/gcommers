import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../models/commerce_models.dart';
import '../services/commerce_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/infographic_widgets.dart';
import 'settings_pages.dart';

class KiosDashboardPage extends StatefulWidget {
  const KiosDashboardPage({super.key});

  @override
  State<KiosDashboardPage> createState() => _KiosDashboardPageState();
}

class _KiosDashboardPageState extends State<KiosDashboardPage> {
  final _commerceService = CommerceService();
  late Future<DashboardSummary> _summaryFuture;
  AuthSession? _session;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummary();
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

  Future<DashboardSummary> _loadSummary() async {
    final session = await sessionManager.getSession();
    if (session == null || session.email.isEmpty) {
      throw Exception('Sesi berakhir, silakan login ulang.');
    }
    return _commerceService.getDashboardSummary(userEmail: session.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.paper,
      body: SafeArea(
        child: FutureBuilder<DashboardSummary>(
          future: _summaryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.ink));
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
                    decoration: const BoxDecoration(
                      color: AppTheme.ink,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, ${_session?.displayName ?? '...'}',
                                style: AppTheme.title(size: 21, color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                shortDateTime(DateTime.now()),
                                style: AppTheme.body(size: 13, color: Colors.white70),
                              ),
                            ],
                          ),
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
                          AppTheme.tertiaryGreen,
                          AppTheme.tertiaryGreenSoft,
                          onTap: () => Navigator.of(context).pushNamed('/orders'),
                        ),
                        _buildQuickActionCard(
                          context,
                          Icons.history_outlined,
                          'Riwayat',
                          AppTheme.tertiaryGold,
                          AppTheme.tertiaryGoldSoft,
                          onTap: () => Navigator.of(context).pushNamed('/history'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SectionKicker(label: 'Ringkasan Bulan Ini'),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: StatTile(
                              icon: Icons.shopping_bag_outlined,
                              label: 'Total Pesanan',
                              value: '${summary.totalOrderCount}',
                              caption: '${summary.ordersThisMonth} pesanan bulan ini',
                              accent: AppTheme.tertiaryGreen,
                              accentSoft: AppTheme.tertiaryGreenSoft,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: StatTile(
                              icon: Icons.payments_outlined,
                              label: 'Total Harga Produk',
                              value: formatCurrency(summary.totalSpent),
                              caption: '${formatCurrency(summary.monthlySales)} bulan ini',
                              accent: AppTheme.tertiaryGold,
                              accentSoft: AppTheme.tertiaryGoldSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SectionKicker(
                      label: 'Pesanan Terbaru',
                      action: TextButton(
                        onPressed: () => Navigator.of(context).pushNamed('/history'),
                        child: Text(
                          'Lihat Semua',
                          style: AppTheme.body(size: 13, color: AppTheme.tertiaryGreen, weight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        if (summary.recentOrders.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text('Belum ada pesanan.', style: AppTheme.body(size: 13, color: AppTheme.muted)),
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
      bottomNavigationBar: _buildBottomNavBar(context, 0),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String label,
    Color accent,
    Color accentSoft, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(height: 10),
              Text(label, style: AppTheme.subtitle(size: 14)),
            ],
          ),
        ),
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
          color: AppTheme.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
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
                      Text(order.poNumber, style: AppTheme.subtitle(size: 15)),
                      const SizedBox(height: 4),
                      Text(formatDateTime(order.createdAt), style: AppTheme.body(size: 12, color: AppTheme.muted)),
                    ],
                  ),
                ),
                StatusChip(label: order.statusLabel, color: statusColor),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppTheme.border.withValues(alpha: 0.5)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatCurrency(order.totalAmount),
                  style: AppTheme.title(size: 15, color: AppTheme.tertiaryGreen),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.border, size: 20),
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
    'pending_payment' => AppTheme.tertiaryGold,
    'paid' || 'shipping' => AppTheme.tertiaryGreen,
    'received' || 'completed' => const Color(0xFF059669),
    _ => AppTheme.muted,
  };
}

Widget _buildBottomNavBar(BuildContext context, int currentIndex) {
  return BottomNavigationBar(
    currentIndex: currentIndex,
    type: BottomNavigationBarType.fixed,
    backgroundColor: AppTheme.paper,
    selectedItemColor: AppTheme.ink,
    unselectedItemColor: AppTheme.muted,
    selectedLabelStyle: AppTheme.body(size: 12, weight: FontWeight.w700),
    unselectedLabelStyle: AppTheme.body(size: 12),
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
