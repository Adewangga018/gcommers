import 'package:flutter/material.dart';

class OrderHistoryDetailPage extends StatelessWidget {
  const OrderHistoryDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2F77C4);
    const Color primaryPurple = Color(0xFF4A3AFF);
    const Color bgLight = Color(0xFFF9F9FF);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD1CBE4)),
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
                            children: const [
                              Text(
                                'PURCHASE ORDER',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'PO-2026-10-9842',
                                style: TextStyle(
                                  color: primaryPurple,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '24 Oct 2026, 14:30 WIB',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'DALAM PERJALANAN',
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Expanded(
                          child: _KeyValue(label: 'Vendor', value: 'PT Global Logistik Nusantara'),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _KeyValue(label: 'Metode Pembayaran', value: 'Bank Transfer (Mandiri)'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD1CBE4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status Pengiriman',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    const _StatusTimeline(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD1CBE4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Barang',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EEF7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '3 Items',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    const _ItemRow(
                      icon: Icons.water_drop_outlined,
                      iconBg: Color(0xFFF0EEF7),
                      title: 'Pupuk Urea Prill 50kg',
                      subtitle: '100 Sak x Rp 55.000',
                      price: 'Rp 5.500.000',
                    ),
                    const SizedBox(height: 12),
                    const _ItemRow(
                      icon: Icons.eco_outlined,
                      iconBg: Color(0xFFF0EEF7),
                      title: 'NPK Phonska 15-15-15',
                      subtitle: '50 Btg x Rp 85.000',
                      price: 'Rp 4.250.000',
                    ),
                    const SizedBox(height: 12),
                    const _ItemRow(
                      icon: Icons.spa_outlined,
                      iconBg: Color(0xFFF0EEF7),
                      title: 'Benih Padi Inpari 32',
                      subtitle: '20 Btg x Rp 120.000',
                      price: 'Rp 2.400.000',
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    const _SummaryLine(label: 'Subtotal', value: 'Rp 12.150.000'),
                    const SizedBox(height: 8),
                    const _SummaryLine(label: 'PPN (11%)', value: 'Rp 1.336.500'),
                    const SizedBox(height: 8),
                    const _SummaryLine(label: 'Ongkos Kirim', value: 'Rp 250.000'),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Total Pembayaran',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Rp 13.736.500',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E9AA7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text(
                    'SCAN QR KONFIRMASI',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyValue extends StatelessWidget {
  const _KeyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline();

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF4A3AFF);
    const mutedColor = Color(0xFFC8C1DE);

    return Column(
      children: [
        _StatusStep(
          icon: Icons.receipt_long_outlined,
          iconColor: mutedColor,
          title: 'Diterima',
          subtitle: 'Menunggu konfirmasi',
          subtitleColor: Colors.black54,
          connectorColor: mutedColor,
        ),
        _StatusStep(
          icon: Icons.local_shipping_outlined,
          iconColor: activeColor,
          title: 'Dalam Perjalanan',
          subtitle: '25 Oct 2026, 08:15 WIB',
          subtitleColor: Colors.black54,
          connectorColor: activeColor,
          card: Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EFFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD9D1EF)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kurir: Budi Santoso (B 1234 CD)',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                SizedBox(height: 4),
                Text(
                  'Lacak Posisi',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2F77C4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        _StatusStep(
          icon: Icons.check_circle,
          iconColor: const Color(0xFF2F77C4),
          title: 'Pembayaran Berhasil',
          subtitle: '24 Oct 2026, 16:00 WIB',
          subtitleColor: Colors.black54,
          connectorColor: const Color(0xFF2F77C4),
        ),
        _StatusStep(
          icon: Icons.check_circle,
          iconColor: const Color(0xFF2F77C4),
          title: 'Pesanan Disetujui',
          subtitle: '24 Oct 2026, 15:10 WIB',
          subtitleColor: Colors.black54,
          connectorColor: const Color(0xFF2F77C4),
        ),
        _StatusStep(
          icon: Icons.check_circle,
          iconColor: const Color(0xFF2F77C4),
          title: 'Pesanan Dibuat',
          subtitle: '24 Oct 2026, 14:30 WIB',
          subtitleColor: Colors.black54,
          connectorColor: const Color(0xFF2F77C4),
          showConnector: false,
        ),
      ],
    );
  }
}

class _StatusStep extends StatelessWidget {
  const _StatusStep({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.connectorColor,
    this.card,
    this.showConnector = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final Color connectorColor;
  final Widget? card;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              if (showConnector)
                Container(
                  width: 2,
                  height: card == null ? 36 : 46,
                  color: connectorColor.withOpacity(0.35),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: subtitleColor, fontSize: 12),
                ),
                if (card != null) card!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.price,
  });

  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF7B768E), size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          price,
          style: const TextStyle(
            color: Color(0xFF4A3AFF),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.black87, fontSize: 14)),
      ],
    );
  }
}
