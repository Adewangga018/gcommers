import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF4A3AFF);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'GCommers',
          style: TextStyle(
            color: primaryPurple,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: primaryPurple),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifikasi',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Tandai semua dibaca',
                      style: TextStyle(
                        color: primaryPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // --- HARI INI ---
              const Text(
                'Hari Ini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildNotificationCard(
                icon: Icons.assignment_outlined,
                iconBgColor: Colors.blue[50]!,
                iconColor: Colors.blue,
                title: 'PO Baru #PO-2026-10-9842',
                description: 'Telah menerima Purchase Order baru\nsehilai Rp...',
                time: '10:30',
              ),
              const SizedBox(height: 12),
              _buildNotificationCard(
                icon: Icons.credit_card_outlined,
                iconBgColor: Colors.purple[50]!,
                iconColor: Colors.purple,
                title: 'Pembayaran Diterima',
                description: 'Pembayaran untuk Invoice #INV-992\ntelah berhasil diverifikasi oleh sistem...',
                time: '08:15',
              ),
              const SizedBox(height: 28),
              // --- SEBELUMNYA ---
              const Text(
                'Sebelumnya',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildNotificationCard(
                icon: Icons.local_shipping_outlined,
                iconBgColor: Colors.orange[50]!,
                iconColor: Colors.orange,
                title: 'Status Pengiriman Diperbarui',
                description: 'SPB #SPB-881 sedang dalam perjalanan\nmenuju gudang logistik pusat.',
                time: 'Kemarin',
                isRead: true,
              ),
              const SizedBox(height: 12),
              _buildNotificationCard(
                icon: Icons.inventory_2_outlined,
                iconBgColor: Colors.amber[50]!,
                iconColor: Colors.amber,
                title: 'Stok Menipis',
                description: 'Peringatan: Stok SKU-1049 (Baja Ringan\n0.75mm) di bawah batas minimum.',
                time: 'Kemarin',
                isRead: true,
              ),
              const SizedBox(height: 12),
              _buildNotificationCard(
                icon: Icons.settings_outlined,
                iconBgColor: Colors.grey[200]!,
                iconColor: Colors.grey[700]!,
                title: 'Update Sistem v1.2.0',
                description: 'Pembaruan sistem telah selesai. Fitur\npelaporan finansial baru kini tersedia di...',
                time: '2 Hari lalu',
                isRead: true,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
    bool isRead = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey[200]! : Colors.blue[100]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
