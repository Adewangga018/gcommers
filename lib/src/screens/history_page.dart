import 'package:flutter/material.dart';

import 'order_history_detail_page.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

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
          'Status Pesanan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: primaryPurple),
            onPressed: () {Navigator.of(context).pushNamed('/orders');},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: const [
                  Expanded(child: _FilterChip(label: 'Semua', selected: true)),
                  SizedBox(width: 10),
                  Expanded(child: _FilterChip(label: 'Pending', selected: false)),
                  SizedBox(width: 10),
                  Expanded(child: _FilterChip(label: 'Diproses', selected: false)),
                  SizedBox(width: 10),
                  Expanded(child: _FilterChip(label: 'Selesai', selected: false)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  _HistoryCard(
                    poNumber: 'PO-2026-10-9842',
                    date: '24 Okt 2026 • 14:30',
                    total: 'Rp 13.736.500',
                    status: 'DIPROSES',
                    statusColor: const Color(0xFF4A3AFF),
                    timeline: const [
                      _TimelineItem(
                        title: 'Pesanan Dibuat',
                        subtitle: '24 Okt, 14:30',
                        icon: Icons.check_circle,
                        active: true,
                      ),
                      _TimelineItem(
                        title: 'Pembayaran Berhasil',
                        subtitle: '24 Okt, 15:10 - Bank Transfer',
                        icon: Icons.check_circle,
                        active: true,
                      ),
                      _TimelineItem(
                        title: 'Dalam Perjalanan',
                        subtitle: 'Estimasi kirim: 25 Okt',
                        icon: Icons.local_shipping,
                        active: true,
                      ),
                    ],
                    actionLabel: 'Lihat Detail',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const OrderHistoryDetailPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PendingCard(
                    poNumber: 'PO-2310-090B',
                    date: '25 Okt 2026 • 09:15',
                    total: 'Rp 12.000.000',
                    onPay: () {},
                  ),
                  const SizedBox(height: 14),
                  _CompletedCard(
                    poNumber: 'PO-2310-075C',
                    date: '20 Okt 2026 • 11:00',
                    total: 'Rp 8.750.000',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _HistoryBottomBar(currentIndex: 2),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF4A3AFF);

    return Container(
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? primaryPurple : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: selected ? primaryPurple : const Color(0xFFD1CBE4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black54,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.poNumber,
    required this.date,
    required this.total,
    required this.status,
    required this.statusColor,
    required this.timeline,
    required this.actionLabel,
    required this.onTap,
  });

  final String poNumber;
  final String date;
  final String total;
  final String status;
  final Color statusColor;
  final List<_TimelineItem> timeline;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
                    children: [
                      Text(
                        poNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              total,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3F35A6),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...timeline.map((item) => _TimelineTile(item: item)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Color(0xFF9F97C8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({
    required this.poNumber,
    required this.date,
    required this.total,
    required this.onPay,
  });

  final String poNumber;
  final String date;
  final String total;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1CBE4)),
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
                  Text(poNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E3FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    color: Color(0xFF4A3AFF),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            total,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2B2A3A)),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Menunggu Pembayaran', style: TextStyle(color: Colors.black54)),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: onPay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A3AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Bayar', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.poNumber, required this.date, required this.total});

  final String poNumber;
  final String date;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1CBE4)),
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
                  Text(poNumber, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(date, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF0E7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'SELESAI',
                  style: TextStyle(
                    color: Color(0xFF2C9C78),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            total,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF2B2A3A)),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem {
  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.item});

  final _TimelineItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.active ? const Color(0xFF4A3AFF) : const Color(0xFFB8B1D1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: Colors.white, size: 16),
              ),
              if (item != item) const SizedBox.shrink(),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(color: item.active ? Colors.black54 : Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBottomBar extends StatelessWidget {
  const _HistoryBottomBar({required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF4A3AFF);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryPurple,
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
        } else if (index == 3) {
          Navigator.of(context).pushNamed('/profile');
        }
      },
    );
  }
}
