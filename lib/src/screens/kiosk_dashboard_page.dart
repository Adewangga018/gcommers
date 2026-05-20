import 'package:flutter/material.dart';

class KiosDashboardPage extends StatelessWidget {
  const KiosDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF4A3AFF);
    const Color bgLight = Color(0xFFF9F9FF);

    return Scaffold(
      backgroundColor: bgLight,
      body: SafeArea(

        child: SingleChildScrollView(
          child: Column(

            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER SECTION ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: primaryPurple,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Halo, PT Kios Berkah',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Senin, 24 Mei 2026',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/notifications'),
                          child: Stack(
                            children: [
                              const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
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

              // --- QUICK ACTIONS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

              // --- RINGKASAN BULAN INI ---
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Ringkasan Bulan Ini',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                        title: 'Total Pesanan',
                        value: '124',
                        subWidget: Row(
                          children: const [
                            Icon(Icons.trending_up, color: Colors.orange, size: 16),
                            SizedBox(width: 4),
                            Text('+12%', style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        icon: Icons.payments_outlined,
                        title: 'Total Tagihan',
                        value: 'Rp 45.2M',
                        subWidget: const Text(
                          'Menunggu Pembayaran',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // --- PESANAN TERBARU ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pesanan Terbaru',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Lihat Semua', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildOrderCard(
                      poNumber: 'PO-20231024-001',
                      date: '24 Okt 2026, 09:30',
                      status: 'Menunggu',
                      statusBg: Colors.grey[200]!,
                      statusTextColor: Colors.grey[700]!,
                      total: 'Rp 12.500.000',
                    ),
                    const SizedBox(height: 12),
                    _buildOrderCard(
                      poNumber: 'PO-20231023-089',
                      date: '23 Okt 2026, 14:15',
                      status: 'Dikirim',
                      statusBg: Colors.blue[50]!,
                      statusTextColor: Colors.blue[700]!,
                      total: 'Rp 8.200.000',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
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
    return Container(
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
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          subWidget,
        ],
      ),
    );
  }

  Widget _buildOrderCard({
    required String poNumber,
    required String date,
    required String status,
    required Color statusBg,
    required Color statusTextColor,
    required String total,
  }) {
    return Container(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(poNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
                child: Text(
                  status,
                  style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 12),
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
              Text('Total: $total', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          )
        ],
      ),
    );
  }
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
        case 0:
          break;
        case 1:
          Navigator.of(context).pushNamed('/orders');
          break;
        case 2:
          Navigator.of(context).pushNamed('/history');
          break;
        case 3:
          Navigator.of(context).pushNamed('/profile');
          break;
        default:
          break;
      }
    },
  );
}
