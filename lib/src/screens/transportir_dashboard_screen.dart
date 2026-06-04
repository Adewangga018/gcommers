import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/auth_models.dart';
import '../widgets/transportir_bottom_nav.dart';
import 'settings_pages.dart';
import 'transportir_shipping_flow.dart';

class TransportirDashboardScreen extends StatefulWidget {
  const TransportirDashboardScreen({super.key, this.session});
  final AuthSession? session;

  @override
  State<TransportirDashboardScreen> createState() => _TransportirDashboardScreenState();
}

class _TransportirDashboardScreenState extends State<TransportirDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final displayName = (widget.session?.displayName.trim().isNotEmpty ?? false)
        ? widget.session!.displayName
        : 'Pengemudi';

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
            'Halo, $displayName 👋',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF20202D)),
          ),
          const SizedBox(height: 2),
          const Text(
            'Beranda Transportir',
            style: TextStyle(
                fontSize: 14, color: Color(0xFF6B6780), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          _TransportirStatsCard(session: widget.session),
          const SizedBox(height: 10),
          _RouteCard(session: widget.session),
          const SizedBox(height: 12),
          _NewOrdersCard(
            session: widget.session,
            onTapAll: () => Navigator.of(context).pushReplacementNamed(
              '/transportir-orders',
              arguments: widget.session,
            ),
            onTapOrder: () => Navigator.of(context).pushReplacementNamed(
              '/transportir-orders',
              arguments: widget.session,
            ),
          ),
        ],
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 0, session: widget.session),
    );
  }
}

// ── Stats Card ─────────────────────────────────────────────────────────────

class _TransportirStatsCard extends StatelessWidget {
  const _TransportirStatsCard({required this.session});
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    final companyName = (session?.companyName?.trim().isNotEmpty ?? false)
        ? session!.companyName!
        : 'Transportir';
    final vehicleLabel = (session?.vehicleType?.trim().isNotEmpty ?? false)
        ? session!.vehicleType!
        : 'Kendaraan';
    final policeNumber = (session?.policeNumber?.trim().isNotEmpty ?? false)
        ? session!.policeNumber!
        : '—';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B309E), Color(0xFF4A3AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x334A3AFF), blurRadius: 18, offset: Offset(0, 8)),
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
                    Text(
                      companyName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicleLabel,
                      style: const TextStyle(color: Color(0xFFCDC8F5), fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  policeNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Total Pengiriman',
                  value: '—',
                  icon: Icons.local_shipping_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'Pemesanan Aktif',
                  value: '—',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: const [
                Icon(Icons.account_balance_wallet_outlined, color: Color(0xFFCDC8F5), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Total Tagihan Bulan Ini',
                    style: TextStyle(color: Color(0xFFCDC8F5), fontSize: 13),
                  ),
                ),
                Text(
                  '—',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFCDC8F5), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Color(0xFFCDC8F5), fontSize: 11)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Route Card (tracks the active shipment) ───────────────────────────────

class _RouteCard extends StatefulWidget {
  const _RouteCard({required this.session});
  final AuthSession? session;

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  TransportirShipmentCardData? _activeShipment;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadActiveShipment();
  }

  /// Finds the first shipment that is currently in-progress (muat masuk done,
  /// muat keluar not yet done).  Falls back to the first unstarted shipment,
  /// then to the very first entry in the list.
  Future<void> _loadActiveShipment() async {
    final shipments = TransportirShipmentsPage.shipments;
    TransportirShipmentCardData? inProgress;
    TransportirShipmentCardData? pending;

    for (final s in shipments) {
      final p = await loadShipmentProgress(s.shipmentNumber);
      if (p.muatMasukCompleted && !p.muatKeluarCompleted) {
        inProgress = s;
        break;
      }
      if (!p.muatMasukCompleted && pending == null) pending = s;
    }

    if (!mounted) return;
    setState(() {
      _activeShipment = inProgress ?? pending ?? (shipments.isNotEmpty ? shipments.first : null);
      _loaded = true;
    });
  }

  void _navigate(BuildContext context) {
    final shipment = _activeShipment;
    if (shipment != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TransportirMapTrackingPage(
            shipment: shipment,
            session: widget.session,
          ),
        ),
      );
    } else {
      Navigator.of(context)
          .pushReplacementNamed('/transportir-shipments', arguments: widget.session);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipment = _activeShipment;

    // Use shipment lat/lng if available, otherwise fall back to GCS coordinates
    final origin = shipment?.originLatLng ?? const LatLng(-7.1553, 112.6547);
    final dest = shipment?.destinationLatLng ?? const LatLng(-7.3130, 112.7963);

    // 3 intermediate checkpoint positions
    LatLng lerp(double t) => LatLng(
          origin.latitude + (dest.latitude - origin.latitude) * t,
          origin.longitude + (dest.longitude - origin.longitude) * t,
        );
    final checkpointPositions = [lerp(0.25), lerp(0.50), lerp(0.75)];
    final allRoutePoints = [origin, ...checkpointPositions, dest];

    final midPoint = LatLng(
      (origin.latitude + dest.latitude) / 2,
      (origin.longitude + dest.longitude) / 2,
    );

    final distKm = const Distance().as(LengthUnit.Kilometer, origin, dest);

    // Short display label for the destination (before the dash separator)
    final destLabel = shipment != null
        ? (shipment.destinationSubtitle.isNotEmpty
            ? shipment.destinationSubtitle
            : shipment.destination)
        : 'Belum ada pengiriman';

    final statusLabel = shipment != null ? shipment.statusLabel : '—';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _navigate(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD3CFE2)),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4EFFF),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.route_rounded,
                          color: Color(0xFF1C5AAA), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rute Terkini',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF252335))),
                          Text(
                            shipment != null
                                ? '${shipment.shipmentNumber} · 3 checkpoint'
                                : 'Tidak ada pengiriman aktif',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF7A7490)),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: shipment != null
                            ? const Color(0xFFDFF6EC)
                            : const Color(0xFFF4F1FD),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: shipment != null
                                  ? const Color(0xFF16C38A)
                                  : const Color(0xFF9A93AC),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel.toUpperCase(),
                            style: TextStyle(
                                color: shipment != null
                                    ? const Color(0xFF0E8F61)
                                    : const Color(0xFF9A93AC),
                                fontSize: 11,
                                fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    // Tap-to-track chevron
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF9A93AC), size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // ── Map ─────────────────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: SizedBox(
                  height: 210,
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: midPoint,
                          initialZoom: 10.0,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a', 'b', 'c', 'd'],
                            userAgentPackageName: 'com.gcommers.app',
                            maxNativeZoom: 19,
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: allRoutePoints,
                                color: const Color(0xFF4438A7),
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              // Checkpoint dots
                              ...checkpointPositions.map((pos) => Marker(
                                    point: pos,
                                    width: 20,
                                    height: 20,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFA000),
                                        shape: BoxShape.circle,
                                        border:
                                            Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  )),
                              // Origin (Gudang)
                              Marker(
                                point: origin,
                                width: 36,
                                height: 36,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16C38A),
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x5516C38A), blurRadius: 8),
                                    ],
                                  ),
                                  child: const Icon(Icons.warehouse,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                              // Destination (Kios)
                              Marker(
                                point: dest,
                                width: 36,
                                height: 36,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5050),
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Color(0x55FF5050), blurRadius: 8),
                                    ],
                                  ),
                                  child: const Icon(Icons.store,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Loading shimmer
                      if (!_loaded)
                        Container(
                          color: Colors.white.withValues(alpha: 0.6),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      // Bottom info overlay
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE4EFFF),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                    Icons.store_mall_directory_outlined,
                                    color: Color(0xFF154E96),
                                    size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tujuan Kios',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF7A7490))),
                                    Text(
                                      destLabel,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF20202E)),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${distKm.toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF4441AA),
                                        fontWeight: FontWeight.w900),
                                  ),
                                  const Text('Jarak total',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF7A7490))),
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
        ),
      ),
    );
  }
}

// ── New Orders Card ─────────────────────────────────────────────────────────

class _NewOrdersCard extends StatelessWidget {
  const _NewOrdersCard({
    required this.onTapAll,
    required this.onTapOrder,
    required this.session,
  });
  final VoidCallback onTapAll;
  final VoidCallback onTapOrder;
  final AuthSession? session;

  // Latest orders sourced from the static transport order data
  static const _orders = [
    (
      invoice: 'INV-2023-1102',
      client: 'PT. Pembangunan Jaya Perkasa',
      items: '35 TON · 3 Jenis Pupuk',
      date: '24 Okt 2023',
      statusLabel: 'Proses Bank',
      statusColor: Color(0xFF8A5A12),
      statusBg: Color(0xFFF7E9D2),
    ),
    (
      invoice: 'INV-2023-1184',
      client: 'PT. Cahaya Agro Mandiri',
      items: '21 TON · 2 Jenis Pupuk',
      date: '19 Okt 2023',
      statusLabel: 'Terkirim',
      statusColor: Color(0xFF1F6CBF),
      statusBg: Color(0xFFE2EEFF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3CFE2)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0EDFF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: Color(0xFF4535A8), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Pemesanan Terbaru',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF252335)),
                  ),
                ),
                TextButton(
                  onPressed: onTapAll,
                  style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                  child: const Text(
                    'LIHAT SEMUA',
                    style: TextStyle(
                        color: Color(0xFF1C5DA7),
                        fontWeight: FontWeight.w800,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFECE9F3)),
          // Order rows
          ..._orders.map(
            (o) => _OrderRow(
              invoice: o.invoice,
              client: o.client,
              items: o.items,
              date: o.date,
              statusLabel: o.statusLabel,
              statusColor: o.statusColor,
              statusBg: o.statusBg,
              onTap: onTapOrder,
            ),
          ),
          // Footer button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: onTapAll,
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                label: const Text('Lihat Semua Pemesanan',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4535A8),
                  side: const BorderSide(color: Color(0xFFB9B5E4)),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.invoice,
    required this.client,
    required this.items,
    required this.date,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
    required this.onTap,
  });

  final String invoice;
  final String client;
  final String items;
  final String date;
  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFEAE8FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: Color(0xFF4A3AFF), size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          invoice,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF20202D)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(client,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6A6780))),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 12, color: Color(0xFF9A93AC)),
                      const SizedBox(width: 4),
                      Text(items,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9A93AC))),
                      const Spacer(),
                      Text(date,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFB0AAC4))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
