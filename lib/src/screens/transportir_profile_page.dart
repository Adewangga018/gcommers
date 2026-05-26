import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../services/session_manager.dart';

class TransportirProfilePage extends StatelessWidget {
  const TransportirProfilePage({super.key, this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF4A3AFF);
    final companyName = (session?.companyName?.trim().isNotEmpty ?? false)
        ? session!.companyName!
        : ((session?.displayName.trim().isNotEmpty ?? false) ? session!.displayName : 'Nama Perusahaan Transportir');
    final transportirName = (session?.transportirName?.trim().isNotEmpty ?? false)
        ? session!.transportirName!
        : 'Nama Transportir';
    final policeNumber = (session?.policeNumber?.trim().isNotEmpty ?? false)
        ? session!.policeNumber!
        : 'Nomor polisi belum diisi';
    final vehicleType = (session?.vehicleType?.trim().isNotEmpty ?? false)
        ? session!.vehicleType!
        : 'Jenis kendaraan belum diisi';
    final email = session?.email ?? 'you@domain.tld';

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A3AFF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('GCommers', style: TextStyle(color: Color(0xFF4A3AFF), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 18),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    ),
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.grey[200],
                          child: Icon(Icons.person, size: 56, color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 12),
                        Text(companyName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFFEDE8FF), borderRadius: BorderRadius.circular(20)),
                              child: const Text('Transportir Mitra', style: TextStyle(color: Color(0xFF4A3AFF), fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                            const SizedBox(width: 10),
                            Text(transportirName, style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 48,
                      top: 54,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Color(0xFF4A3AFF), shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Stats cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                      child: Column(
                        children: const [
                          Icon(Icons.local_shipping_outlined, color: Color(0xFF154E96)),
                          SizedBox(height: 6),
                          Text('142', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                          SizedBox(height: 4),
                          Text('Total Trip', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
                      child: Column(
                        children: const [
                          Icon(Icons.monetization_on_outlined, color: Color(0xFF154E96)),
                          SizedBox(height: 6),
                          Text('1.2K', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                          SizedBox(height: 4),
                          Text('Est. Pendapatan', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data Transportir', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    _buildInfoRow('Nama transportir', transportirName),
                    const SizedBox(height: 10),
                    _buildInfoRow('Nama perusahaan', companyName),
                    const SizedBox(height: 10),
                    _buildInfoRow('Email', email),
                    const SizedBox(height: 10),
                    _buildInfoRow('Nomor polisi', policeNumber),
                    const SizedBox(height: 10),
                    _buildInfoRow('Jenis kendaraan', vehicleType),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Menu list
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
                child: Column(
                  children: [
                    _buildMenuTile(Icons.person_outline, 'Informasi Akun', () {}),
                    const Divider(height: 1, indent: 16),
                    _buildMenuTile(Icons.shield_outlined, 'Keamanan', () {}),
                    const Divider(height: 1, indent: 16),
                    _buildMenuTile(Icons.notifications_none_outlined, 'Notifikasi', () {}),
                    const Divider(height: 1, indent: 16),
                    _buildMenuTile(Icons.help_outline_rounded, 'Bantuan', () {}),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Logout button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await sessionManager.clearSession();
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil('/transportir-login', (_) => false);
                  },
                  icon: const Icon(Icons.logout, color: Color(0xFFB92B2B)),
                  label: const Text('Keluar', style: TextStyle(color: Color(0xFFB92B2B), fontWeight: FontWeight.bold, fontSize: 16)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFB92B2B)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Pesanan'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Pengiriman'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Laporan'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
        onTap: (index) {
          if (index == 0) Navigator.of(context).pushNamed('/transportir-home', arguments: session);
          if (index == 1) Navigator.of(context).pushNamed('/transportir-orders', arguments: session);
          if (index == 2) Navigator.of(context).pushNamed('/transportir-shipments', arguments: session);
          if (index == 3) Navigator.of(context).pushReplacementNamed('/transportir-reports', arguments: session);
        },
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF4A3AFF)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 128,
          child: Text(label, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
