import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/auth_models.dart';
import '../models/commerce_models.dart';
import '../services/commerce_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/infographic_widgets.dart';
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
    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        backgroundColor: AppTheme.paper,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('GCommers', style: AppTheme.title(size: 18)),
        actions: [
          const NotificationBadge(iconColor: AppTheme.ink),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        children: [
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

class _TransportirStatsCard extends StatefulWidget {
  const _TransportirStatsCard({required this.session});
  final AuthSession? session;

  @override
  State<_TransportirStatsCard> createState() => _TransportirStatsCardState();
}

class _TransportirStatsCardState extends State<_TransportirStatsCard> {
  final _service = CommerceService();

  int _totalPengiriman = 0;
  int _pemesananAktif = 0;
  double _tagihanBulanIni = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  String _fmtRupiah(double v) {
    if (v == 0) return 'Rp 0';
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(v % 1000000 == 0 ? 0 : 1)}jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${v.toStringAsFixed(0)}';
  }

  Future<void> _loadStats() async {
    try {
      final email = widget.session?.email;
      if (email == null || email.isEmpty) {
        throw Exception('Sesi berakhir, silakan login ulang.');
      }
      final summary = await _service.getTransportirDashboardSummary(transportirEmail: email);
      final orders = await _service.getOrders(userEmail: email);
      if (!mounted) return;

      final now = DateTime.now();
      final thisMonth = orders.where(
        (o) => o.createdAt.year == now.year && o.createdAt.month == now.month,
      );

      setState(() {
        _totalPengiriman = summary.totalShipments;
        _pemesananAktif = summary.activeShipments;
        _tagihanBulanIni = thisMonth.fold(0.0, (s, o) => s + o.totalAmount);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyName =
        (widget.session?.companyName?.trim().isNotEmpty ?? false)
            ? widget.session!.companyName!
            : 'Transportir';
    final vehicleLabel =
        (widget.session?.vehicleType?.trim().isNotEmpty ?? false)
            ? widget.session!.vehicleType!
            : 'Kendaraan';
    final policeNumber =
        (widget.session?.policeNumber?.trim().isNotEmpty ?? false)
            ? widget.session!.policeNumber!
            : '—';

    final totalVal = _loading ? '…' : '$_totalPengiriman';
    final aktifVal = _loading ? '…' : '$_pemesananAktif';
    final tagihanVal = _loading ? '…' : _fmtRupiah(_tagihanBulanIni);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.all(Radius.circular(16)),
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
                      style: AppTheme.title(size: 16, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicleLabel,
                      style: AppTheme.body(size: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  policeNumber,
                  style: AppTheme.subtitle(size: 13, color: AppTheme.ink).copyWith(letterSpacing: 1),
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
                  value: totalVal,
                  icon: Icons.local_shipping_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  label: 'Pemesanan Aktif',
                  value: aktifVal,
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
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppTheme.tertiaryGold, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Total Tagihan Bulan Ini',
                    style: AppTheme.body(size: 13, color: Colors.white70),
                  ),
                ),
                Text(
                  tagihanVal,
                  style: AppTheme.title(size: 17, color: AppTheme.tertiaryGold),
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
          Icon(icon, color: AppTheme.tertiaryGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.body(size: 11, color: Colors.white70)),
                const SizedBox(height: 3),
                Text(value, style: AppTheme.title(size: 18, color: Colors.white)),
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
  final _service = CommerceService();
  TransportirShipmentCardData? _activeShipment;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadActiveShipment();
  }

  Future<void> _loadActiveShipment() async {
    try {
      final email = widget.session?.email;
      if (email == null || email.isEmpty) {
        throw Exception('Sesi berakhir, silakan login ulang.');
      }
      final summary = await _service.getTransportirDashboardSummary(transportirEmail: email);
      if (!mounted) return;
      setState(() {
        _activeShipment = summary.activeShipment == null ? null : _toCardData(summary.activeShipment!);
        _loaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loaded = true);
    }
  }

  TransportirShipmentCardData _toCardData(ShipmentSummary shipment) {
    return TransportirShipmentCardData(shipment: shipment);
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
            border: Border.all(color: const Color(0xFFB5D4BC)),
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
                        color: AppTheme.tertiaryGreenSoft,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(Icons.route_rounded,
                          color: AppTheme.tertiaryGreen, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rute Terkini', style: AppTheme.subtitle(size: 15)),
                          Text(
                            shipment != null
                                ? '${shipment.shipmentNumber} · 3 checkpoint'
                                : 'Tidak ada pengiriman aktif',
                            style: AppTheme.body(size: 12, color: AppTheme.muted),
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
                            : const Color(0xFFEAF2EC),
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
                                  : const Color(0xFF6B8C73),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel.toUpperCase(),
                            style: TextStyle(
                                color: shipment != null
                                    ? const Color(0xFF0E8F61)
                                    : const Color(0xFF6B8C73),
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
                          color: Color(0xFF6B8C73), size: 20),
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
                        key: ValueKey(shipment?.shipmentNumber ?? 'none'),
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
                                color: const Color(0xFF0F261F),
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
                                  color: const Color(0xFFDCEDE1),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(
                                    Icons.store_mall_directory_outlined,
                                    color: Color(0xFF2F6C3F),
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
                                            color: Color(0xFF6B8C73))),
                                    Text(
                                      destLabel,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF0F261F)),
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
                                        color: Color(0xFF0F261F),
                                        fontWeight: FontWeight.w900),
                                  ),
                                  const Text('Jarak total',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF6B8C73))),
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

class _NewOrdersCard extends StatefulWidget {
  const _NewOrdersCard({
    required this.onTapAll,
    required this.onTapOrder,
    required this.session,
  });
  final VoidCallback onTapAll;
  final VoidCallback onTapOrder;
  final AuthSession? session;

  @override
  State<_NewOrdersCard> createState() => _NewOrdersCardState();
}

class _NewOrdersCardState extends State<_NewOrdersCard> {
  final _service = CommerceService();
  List<OrderSummary>? _orders;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final email = widget.session?.email;
      if (email == null || email.isEmpty) {
        throw Exception('Sesi berakhir, silakan login ulang.');
      }
      final orders = await _service.getOrders(userEmail: email);
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() => _orders = orders.take(5).toList());
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
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
                    color: AppTheme.tertiaryGreenSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: AppTheme.ink, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Pemesanan Terbaru', style: AppTheme.subtitle(size: 15)),
                ),
                TextButton(
                  onPressed: widget.onTapAll,
                  style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                  child: Text(
                    'LIHAT SEMUA',
                    style: AppTheme.body(size: 12, color: AppTheme.tertiaryGreen, weight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          // Order rows
          if (_orders == null && !_failed)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_failed)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Gagal memuat pesanan.', style: AppTheme.body(size: 13, color: AppTheme.muted)),
            )
          else if (_orders!.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Belum ada pesanan.', style: AppTheme.body(size: 13, color: AppTheme.muted)),
            )
          else
            ..._orders!.map(
              (o) => _OrderRow(order: o, onTap: widget.onTapOrder),
            ),
          // Footer button
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: widget.onTapAll,
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                label: Text('Lihat Semua Pemesanan', style: AppTheme.body(size: 14, weight: FontWeight.w800)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.ink,
                  side: const BorderSide(color: AppTheme.border),
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
  const _OrderRow({required this.order, required this.onTap});

  final OrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);
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
                color: AppTheme.tertiaryGreenSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  color: AppTheme.tertiaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(order.poNumber, style: AppTheme.subtitle(size: 13)),
                      ),
                      StatusChip(label: order.statusLabel, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(formatCurrency(order.totalAmount),
                      style: AppTheme.body(size: 12, color: AppTheme.muted)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 12, color: AppTheme.muted),
                      const SizedBox(width: 4),
                      Text('${order.itemCount} item',
                          style: AppTheme.body(size: 11, color: AppTheme.muted)),
                      const Spacer(),
                      Text(formatDateTime(order.createdAt),
                          style: AppTheme.body(size: 11, color: AppTheme.muted)),
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

Color _statusColor(String status) {
  return switch (status) {
    'pending_payment' => AppTheme.tertiaryGold,
    'paid' || 'shipping' => AppTheme.tertiaryGreen,
    'received' || 'completed' || 'delivered' => const Color(0xFF059669),
    _ => AppTheme.muted,
  };
}
