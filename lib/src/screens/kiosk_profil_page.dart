import 'package:flutter/material.dart';

class KiosProfilePage extends StatelessWidget {
  const KiosProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF4A3AFF);
    const Color bgLight = Color(0xFFF9F9FF);

    return Scaffold(

      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'GCommers',
          style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () {Navigator.of(context).pushNamed('/notifications');},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // --- AVATAR SECTION WITH EDIT BUTTON ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: Icon(Icons.person, size: 60, color: Colors.grey[400]),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: primaryPurple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- NAME & BADGE ---
              const Text(
                'Budi Santoso',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryPurple.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Kios Mitra',
                      style: TextStyle(color: primaryPurple, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#K-84920',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- STATS ROW ---
              Row(
                children: [
                  Expanded(child: _buildStatCard(Icons.assignment_outlined, '142', 'Total PO', primaryPurple)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard(Icons.account_balance_wallet_outlined, '1.2K', 'Total Transaksi', primaryPurple)),
                ],
              ),

              const SizedBox(height: 24),

              // --- MENU OPTIONS ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildMenuListTile(Icons.person_outline, 'Informasi Akun'),
                    const Divider(height: 1, indent: 50),
                    _buildMenuListTile(Icons.shield_outlined, 'Keamanan'),
                    const Divider(height: 1, indent: 50),
                    _buildMenuListTile(Icons.notifications_none_outlined, 'Notifikasi'),
                    const Divider(height: 1, indent: 50),
                    _buildMenuListTile(Icons.help_outline_rounded, 'Bantuan'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // --- OUTLINE LOGOUT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Keluar',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, 3, primaryPurple), // Index 3 aktif untuk Profil
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 28),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMenuListTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4A3AFF)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: () {},
    );
  }

  // Menggunakan fungsi _buildBottomNavBar yang sama dari file sebelumnya
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
        if (index == 0) {
          Navigator.of(context).pushNamed('/home');
        } else if (index == 1) {
          Navigator.of(context).pushNamed('/orders');
        } else if (index == 2) {
          Navigator.of(context).pushNamed('/history');
        }
      },
    );
  }
}

