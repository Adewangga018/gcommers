import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../widgets/transportir_bottom_nav.dart';
import 'settings_pages.dart';

class TransportirDashboardScreen extends StatelessWidget {
  const TransportirDashboardScreen({super.key, this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    final displayName = (session?.displayName.trim().isNotEmpty ?? false)
        ? session!.displayName
        : 'Sutrisno';

    return Scaffold(
      backgroundColor: const Color(0xFFF0EEF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF0EEF6),
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'GCommers',
          style: TextStyle(color: Color(0xFF3F3AA0), fontWeight: FontWeight.w800),
        ),
        actions: [
          const NotificationBadge(iconColor: Color(0xFF3F3AA0)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        children: [
          Text(
            'Halo, $displayName',
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF20202D)),
          ),
          const SizedBox(height: 2),
          const Text(
            'Beranda Transportir',
            style: TextStyle(fontSize: 16, color: Color(0xFF5D5B6A), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          const _TransportirStatsCard(),
          const SizedBox(height: 8),
          const _RouteCard(),
          const SizedBox(height: 12),
          _NewOrdersCard(onTapAll: () => Navigator.of(context).pushReplacementNamed('/transportir-orders', arguments: session)),
        ],
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 0, session: session),
    );
  }

}
class _TransportirStatsCard extends StatelessWidget {
  const _TransportirStatsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF4438A7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(color: Color(0xFFF3F2FF), fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Transportir',
                      style: TextStyle(color: Color(0xFFCAC5F0), fontSize: 16),
                    ),
                  ],
                ),
              ),
              Icon(Icons.local_shipping_outlined, color: Color(0xFFAAA3E8), size: 32),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(child: _MiniStatBox(label: 'Pengiriman', value: '12')),
              SizedBox(width: 14),
              Expanded(child: _MiniStatBox(label: 'Pemesanan', value: '4')),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF5449B6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6A5FC5)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Tagihan Bulan ini',
                  style: TextStyle(color: Color(0xFFCBC6F3), fontSize: 14, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Rp 1.200.000',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatBox extends StatelessWidget {
  const _MiniStatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF5449B6),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF665CC2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFCAC5F0), fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCFCADB)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                const Icon(Icons.route_rounded, color: Color(0xFF1C5AAA)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Rute Terkini',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF252335)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDAE3F5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'PERJALANAN',
                    style: TextStyle(color: Color(0xFF1C5DA7), fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: Container(
              height: 190,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF264454), Color(0xFF2E6B7A), Color(0xFF314C62)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RoutePainter(),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFEFFA),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFF66A4E8),
                            child: Icon(Icons.store_mall_directory_outlined, color: Color(0xFF154E96)),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tujuan Kiosk', style: TextStyle(fontSize: 12.5, color: Color(0xFF666475))),
                                Text(
                                  'TOKO PUPUK\nYELLOW',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF20202E)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('15m', style: TextStyle(fontSize: 17, color: Color(0xFF4441AA), fontWeight: FontWeight.w900)),
                              Text('Estimasi tiba', style: TextStyle(fontSize: 13, color: Color(0xFF666475))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFCC71F2), Color(0xFF84A0FF)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.45, size.height * 0.72, size.width * 0.62, size.height * 0.63)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.54, size.width * 0.88, size.height * 0.42);

    canvas.drawPath(path, routePaint);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.42), 4.5, Paint()..color = const Color(0xFF9DB3FF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NewOrdersCard extends StatelessWidget {
  const _NewOrdersCard({required this.onTapAll});

  final VoidCallback onTapAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCFCADB)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pemesanan Baru',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF252335)),
                  ),
                ),
                TextButton(
                  onPressed: onTapAll,
                  child: const Text(
                    'LIHAT SEMUA',
                    style: TextStyle(color: Color(0xFF1C5DA7), fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFD6D2E2)),
          const _OrderRow(),
          const _OrderRow(),
          const _OrderRow(),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.inventory_2_outlined, color: Color(0xFF686577), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Pengambilan: 5 Palet',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF20202E)),
                ),
                SizedBox(height: 3),
                Text('PT. Sumber Makmur', style: TextStyle(fontSize: 13, color: Color(0xFF525160))),
                SizedBox(height: 2),
                Text('Jadwal: 14.00 WIB', style: TextStyle(fontSize: 12, color: Color(0xFF7B7889))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

