import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import 'settings_pages.dart';

class TransportirShipmentsPage extends StatelessWidget {
  const TransportirShipmentsPage({super.key, this.session});

  final AuthSession? session;

  static const List<TransportirShipmentCardData> _shipments = [
    TransportirShipmentCardData(
      shipmentNumber: 'SJ-20231024-001',
      statusLabel: 'Ready to Load',
      statusColor: Color(0xFF4D8FE8),
      statusBackground: Color(0xFFDDEBFF),
      scheduleLabel: 'Today, 09:00 AM',
      origin: 'Gudang Utama, Jakarta',
      destination: 'Pabrik Perakitan, Bekasi',
      destinationSubtitle: 'Pabrik Perakitan, Bekasi',
      actionPrimaryLabel: 'Load-In',
      actionSecondaryLabel: '',
      actionSecondaryKind: TransportirShipmentActionKind.none,
    ),
    TransportirShipmentCardData(
      shipmentNumber: 'SJ-20231024-002',
      statusLabel: 'In Transit',
      statusColor: Color(0xFFB86B22),
      statusBackground: Color(0xFFF4E0CB),
      scheduleLabel: 'Est. Arrival: 14:30 PM',
      origin: 'Gudang Utama, Jakarta',
      destination: 'Pabrik Perakitan, Bekasi',
      destinationSubtitle: 'Pabrik Perakitan, Bekasi',
      actionPrimaryLabel: 'Track',
      actionSecondaryLabel: 'Load-Out',
      actionSecondaryKind: TransportirShipmentActionKind.loadOut,
    ),
    TransportirShipmentCardData(
      shipmentNumber: 'SJ-20231023-089',
      statusLabel: 'Completed',
      statusColor: Color(0xFF6ABAB4),
      statusBackground: Color(0xFFDDF3F0),
      scheduleLabel: 'Delivered: Yesterday, 16:45 PM',
      origin: 'Gudang Utama, Jakarta',
      destination: 'Distributor Regional, Semarang',
      destinationSubtitle: 'Distributor Regional, Semarang',
      actionPrimaryLabel: 'View Proof',
      actionSecondaryLabel: '',
      actionSecondaryKind: TransportirShipmentActionKind.proof,
      completed: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4A3AFF)),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/transportir-home', arguments: session),
        ),
        title: const Text(
          'GCommers',
          style: TextStyle(color: Color(0xFF4A3AFF), fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          const Text(
            'Daftar Pengiriman',
            style: TextStyle(fontSize: 30 / 2, fontWeight: FontWeight.w900, color: Color(0xFF17203A)),
          ),
          const SizedBox(height: 14),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD3CFE2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Color(0xFF8D88A3)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cari No. Surat Jalan...',
                    style: TextStyle(color: Color(0xFFB0AAC4), fontSize: 15),
                  ),
                ),
                Icon(Icons.tune_rounded, color: Color(0xFF4A3AFF)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ..._shipments.map(
            (shipment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ShipmentSummaryCard(
                shipment: shipment,
                session: session,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _TransportirShippingBottomBar(currentIndex: 2, session: session),
    );
  }
}

class TransportirShipmentTrackingPage extends StatelessWidget {
  const TransportirShipmentTrackingPage({super.key, required this.shipment, this.session});

  final TransportirShipmentCardData shipment;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF3B309E);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primaryPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('GCommers', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD3CFE2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tracking Shipment', style: TextStyle(color: Color(0xFF6B6780), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(shipment.shipmentNumber, style: const TextStyle(fontSize: 24 / 2, fontWeight: FontWeight.w900, color: Color(0xFF20202D))),
                        ],
                      ),
                    ),
                    _StatusChip(label: shipment.statusLabel, foreground: shipment.statusColor, background: shipment.statusBackground),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                _KeyValue(label: 'Origin', value: shipment.origin),
                const SizedBox(height: 12),
                _KeyValue(label: 'Destination', value: shipment.destination),
                const SizedBox(height: 12),
                _KeyValue(label: 'Schedule', value: shipment.scheduleLabel),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD3CFE2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
                const SizedBox(height: 14),
                _TimelineStep(active: true, title: 'Loading Started', subtitle: 'Warehouse Alpha - Dock 4', icon: Icons.local_shipping_outlined),
                _TimelineStep(active: true, title: 'Departed', subtitle: 'Jakarta - Bekasi corridor', icon: Icons.route_rounded),
                _TimelineStep(active: false, title: 'Arrived', subtitle: 'Waiting for confirmation', icon: Icons.flag_outlined),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TransportirShipmentProofPage(shipment: shipment, session: session),
                ),
              ),
              icon: const Icon(Icons.qr_code_rounded),
              label: const Text('View Proof', style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _TransportirShippingBottomBar(currentIndex: 2, session: session),
    );
  }
}

class TransportirShipmentProofPage extends StatelessWidget {
  const TransportirShipmentProofPage({super.key, required this.shipment, this.session});

  final TransportirShipmentCardData shipment;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF3B309E);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primaryPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Load-in Proof', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF2B2B36), Color(0xFF13141D)],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0.55, -0.4),
                          radius: 0.95,
                          colors: [Colors.white.withValues(alpha: 0.20), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 250,
                      height: 420,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(44),
                        border: Border.all(color: const Color(0xFF3D3D47), width: 7),
                        boxShadow: const [
                          BoxShadow(color: Color(0x55000000), blurRadius: 28, offset: Offset(0, 18)),
                        ],
                        color: const Color(0xFF0F111A),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFF4A4E5A), Color(0xFF1C1F2A)],
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(painter: _WarehousePainter()),
                                  ),
                                  Positioned(
                                    left: 18,
                                    right: 18,
                                    bottom: 18,
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xCC2A2736),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          _InfoLine(icon: Icons.location_on_outlined, label: 'LOCATION', value: 'Warehouse Alpha - Dock 4'),
                                          Divider(height: 18, color: Colors.white12),
                                          _InfoLine(icon: Icons.gps_fixed_outlined, label: 'GPS COORDINATES', value: '-6.2088° S, 106.8456° E'),
                                          Divider(height: 18, color: Colors.white12),
                                          _InfoLine(icon: Icons.access_time_rounded, label: 'TIMESTAMP', value: '24 Oct 2023, 14:32:05 WIB'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 34,
                            right: 34,
                            top: 118,
                            child: Container(
                              height: 112,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white70, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: const BoxDecoration(
                color: Color(0xFFF0EDF8),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  _ActionMiniButton(
                    icon: Icons.restore_rounded,
                    label: 'Retake',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retake sedang disiapkan.'))),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFD8D3EA),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFF6F3FD),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  _ActionMiniButton(
                    icon: Icons.check_circle_outline,
                    label: 'Confirm Order',
                    filled: true,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order confirmed.'))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _TransportirShippingBottomBar(currentIndex: 2, session: session),
    );
  }
}

class TransportirShipmentCardData {
  const TransportirShipmentCardData({
    required this.shipmentNumber,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.scheduleLabel,
    required this.origin,
    required this.destination,
    required this.destinationSubtitle,
    required this.actionPrimaryLabel,
    required this.actionSecondaryLabel,
    required this.actionSecondaryKind,
    this.completed = false,
  });

  final String shipmentNumber;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final String scheduleLabel;
  final String origin;
  final String destination;
  final String destinationSubtitle;
  final String actionPrimaryLabel;
  final String actionSecondaryLabel;
  final TransportirShipmentActionKind actionSecondaryKind;
  final bool completed;
}

enum TransportirShipmentActionKind { none, proof, loadOut }

class _ShipmentSummaryCard extends StatelessWidget {
  const _ShipmentSummaryCard({required this.shipment, required this.session});

  final TransportirShipmentCardData shipment;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    final faded = shipment.completed;
    final titleColor = faded ? Colors.grey.shade500 : const Color(0xFF20202D);
    final bodyColor = faded ? Colors.grey.shade400 : const Color(0xFF9A93AC);
    final subTitleColor = faded ? Colors.grey.shade500 : const Color(0xFF2A2740);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4D0E3)),
        boxShadow: const [
          BoxShadow(color: Color(0x0C000000), blurRadius: 14, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.description_outlined, color: faded ? Colors.grey.shade500 : const Color(0xFF2F77C4), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _StatusChip(label: shipment.statusLabel, foreground: shipment.statusColor, background: shipment.statusBackground),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              shipment.scheduleLabel,
                              style: TextStyle(color: faded ? Colors.grey.shade500 : const Color(0xFF7D768B), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        shipment.shipmentNumber,
                        style: TextStyle(fontSize: 20 / 2, fontWeight: FontWeight.w900, color: titleColor, decoration: faded ? TextDecoration.lineThrough : TextDecoration.none),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: bodyColor, size: 16),
                          const SizedBox(width: 6),
                          Expanded(child: Text(shipment.origin, style: TextStyle(color: bodyColor, fontSize: 13))),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('⋮', style: TextStyle(color: bodyColor, height: 1)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.flag_outlined, color: bodyColor, size: 16),
                          const SizedBox(width: 6),
                          Expanded(child: Text(shipment.destinationSubtitle, style: TextStyle(color: subTitleColor, fontSize: 14, fontWeight: FontWeight.w800))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: shipment.actionPrimaryLabel,
                    primary: true,
                    onTap: () => _handlePrimary(context),
                  ),
                ),
                if (shipment.actionSecondaryKind != TransportirShipmentActionKind.none) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: shipment.actionSecondaryLabel,
                      primary: false,
                      onTap: () => _handleSecondary(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handlePrimary(BuildContext context) {
    if (shipment.actionPrimaryLabel == 'Track') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => TransportirShipmentTrackingPage(shipment: shipment, session: session)),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => TransportirShipmentProofPage(shipment: shipment, session: session)),
    );
  }

  void _handleSecondary(BuildContext context) {
    switch (shipment.actionSecondaryKind) {
      case TransportirShipmentActionKind.loadOut:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => TransportirShipmentTrackingPage(shipment: shipment, session: session)),
        );
        break;
      case TransportirShipmentActionKind.proof:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => TransportirShipmentProofPage(shipment: shipment, session: session)),
        );
        break;
      case TransportirShipmentActionKind.none:
        break;
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.primary, required this.onTap});

  final String label;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = primary ? const Color(0xFF4535A8) : Colors.white;
    final foreground = primary ? Colors.white : const Color(0xFF4535A8);

    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          side: primary ? BorderSide.none : const BorderSide(color: Color(0xFF4535A8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.foreground, required this.background});

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w800)),
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
        Text(label, style: const TextStyle(color: Color(0xFF6A6780), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF20202D))),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.active, required this.title, required this.subtitle, required this.icon});

  final bool active;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final fg = active ? const Color(0xFF3B309E) : const Color(0xFFB6B1C6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: active ? const Color(0xFF3B309E) : const Color(0xFFE2DDF1), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: active ? Colors.white : fg),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: fg.withValues(alpha: 0.85), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11.5, letterSpacing: 0.6, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionMiniButton extends StatelessWidget {
  const _ActionMiniButton({required this.icon, required this.label, required this.onTap, this.filled = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : const Color(0xFF443C53);
    final bg = filled ? const Color(0xFF4A3AFF) : Colors.transparent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 90,
          height: 50,
          child: TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              foregroundColor: fg,
              backgroundColor: bg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Icon(icon, size: 24),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4B465B))),
      ],
    );
  }
}

class _TransportirShippingBottomBar extends StatelessWidget {
  const _TransportirShippingBottomBar({required this.currentIndex, this.session});

  final int currentIndex;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF4F2F9),
        border: Border(top: BorderSide(color: Color(0xFFD2CDDF))),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'Beranda', active: currentIndex == 0, onTap: () => Navigator.of(context).pushReplacementNamed('/transportir-home', arguments: session)),
          _NavItem(icon: Icons.inventory_2_outlined, label: 'Pesanan', active: currentIndex == 1, onTap: () => Navigator.of(context).pushReplacementNamed('/transportir-orders', arguments: session)),
          _NavItem(icon: Icons.local_shipping_outlined, label: 'Pengiriman', active: currentIndex == 2, onTap: () => Navigator.of(context).pushReplacementNamed('/transportir-shipments', arguments: session)),
          _NavItem(icon: Icons.bar_chart_outlined, label: 'Laporan', active: currentIndex == 3, onTap: () => Navigator.of(context).pushReplacementNamed('/transportir-reports', arguments: session)),
          _NavItem(icon: Icons.person_outline, label: 'Profil', active: currentIndex == 4, onTap: () => Navigator.of(context).pushReplacementNamed('/transportir-profile', arguments: session)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = active ? const Color(0xFF4A469E) : const Color(0xFF4D4A5C);
    final bg = active ? const Color(0xFFD7D2EC) : Colors.transparent;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(22)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 20),
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _WarehousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = const Color(0xFF2F3342);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45), basePaint);

    final lightPaint = Paint()..color = const Color(0xFF4B4F60);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.08, size.height * 0.18, size.width * 0.84, size.height * 0.46), lightPaint);

    final doorPaint = Paint()..color = const Color(0xFFB7B1A2);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.18, size.height * 0.44, size.width * 0.64, size.height * 0.18), doorPaint);

    final boxPaint = Paint()..color = const Color(0xFFD9B27B);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.20, size.height * 0.40, size.width * 0.16, size.height * 0.10), const Radius.circular(4)), boxPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.36, size.height * 0.36, size.width * 0.18, size.height * 0.14), const Radius.circular(4)), boxPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.54, size.height * 0.39, size.width * 0.16, size.height * 0.11), const Radius.circular(4)), boxPaint);

    final highlight = Paint()..color = const Color(0x22FFFFFF);
    canvas.drawLine(Offset(size.width * 0.12, size.height * 0.16), Offset(size.width * 0.88, size.height * 0.16), highlight..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
