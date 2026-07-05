import 'dart:async';

import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../models/commerce_models.dart';
import '../services/commerce_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/infographic_widgets.dart';
import '../widgets/transportir_bottom_nav.dart';
import 'settings_pages.dart';

class TransportirOrdersPage extends StatefulWidget {
  const TransportirOrdersPage({super.key, this.session});

  final AuthSession? session;

  @override
  State<TransportirOrdersPage> createState() => _TransportirOrdersPageState();
}

class _TransportirOrdersPageState extends State<TransportirOrdersPage> {
  final _service = CommerceService();
  late Future<List<TransportirAssignedOrder>> _ordersFuture;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _load();
    // Polling ringan agar pesanan baru/perubahan status dari admin transport & sesama
    // sopir terlihat tanpa menunggu pull-to-refresh manual (lihat ORDER_FLOW_CONTRACT.md §1.5).
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh().catchError((_) {}));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<List<TransportirAssignedOrder>> _load() async {
    final email = widget.session?.email;
    if (email == null || email.isEmpty) {
      throw Exception('Sesi berakhir, silakan login ulang.');
    }
    final shipments = await _service.getShipments(transportirEmail: email);

    // Group surat jalan that share the same PO under one order card (covers split/partial delivery).
    final byPo = <String, List<ShipmentSummary>>{};
    for (final shipment in shipments) {
      final key = (shipment.poNumber?.isNotEmpty ?? false) ? shipment.poNumber! : shipment.shipmentNumber;
      byPo.putIfAbsent(key, () => []).add(shipment);
    }

    final orders = <TransportirAssignedOrder>[];
    for (final entry in byPo.entries) {
      final hasPo = entry.value.first.poNumber?.isNotEmpty ?? false;
      OrderDetail? detail;
      if (hasPo) {
        try {
          detail = await _service.getOrderDetail(entry.key);
        } catch (_) {
          detail = null;
        }
      }
      orders.add(TransportirAssignedOrder(poNumber: entry.key, detail: detail, shipments: entry.value));
    }

    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _ordersFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/transportir-home', arguments: widget.session),
        ),
        title: Text('GCommers', style: AppTheme.title(size: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<TransportirAssignedOrder>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                children: [
                  Icon(Icons.error_outline, color: Colors.grey.shade400, size: 48),
                  const SizedBox(height: 12),
                  Text('Gagal memuat pesanan: ${snapshot.error}', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              );
            }

            final orders = snapshot.data ?? const [];
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                const Text(
                  'Daftar Pemesanan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F261F)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pesanan yang ditugaskan kepada Anda oleh admin transport.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5E7D66), height: 1.3),
                ),
                const SizedBox(height: 18),
                if (orders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 48),
                        const SizedBox(height: 12),
                        Text('Belum ada pesanan yang ditugaskan.', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFB5D4BC)),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < orders.length; i++) ...[
                          if (i > 0) const Divider(height: 1, color: Color(0xFFE2EFE6)),
                          _TransportirOrderRow(
                            order: orders[i],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TransportirOrderDetailPage(order: orders[i], session: widget.session),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 1, session: widget.session),
    );
  }
}

/// One assigned order, with the (possibly several) surat jalan/shipments fulfilling it.
class TransportirAssignedOrder {
  const TransportirAssignedOrder({
    required this.poNumber,
    required this.detail,
    required this.shipments,
  });

  final String poNumber;
  final OrderDetail? detail;
  final List<ShipmentSummary> shipments;

  bool get isPartial => shipments.length > 1;

  String get statusLabel => detail?.orderStatusLabel ?? shipments.first.statusLabel;
  String? get orderStatus => detail?.orderStatus;

  DateTime get createdAt =>
      detail?.createdAt ?? shipments.map((s) => s.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);

  double get totalAmount => detail?.totalAmount ?? 0;
}

String _productLabel(ShipmentSummary shipment) {
  final parts = [shipment.productCode, shipment.productName].whereType<String>().where((s) => s.isNotEmpty);
  return parts.isEmpty ? '-' : parts.join(' · ');
}

Color _orderStatusColor(String? orderStatus) => switch (orderStatus) {
      'processing' => const Color(0xFF8A5A12),
      'shipping' => const Color(0xFF2F6C3F),
      'delivered' => const Color(0xFF0E8F61),
      'cancelled' => const Color(0xFFB3261E),
      _ => const Color(0xFF6B8C73),
    };

Color _orderStatusBackground(String? orderStatus) => switch (orderStatus) {
      'processing' => const Color(0xFFF7E9D2),
      'shipping' => const Color(0xFFDCEDE1),
      'delivered' => const Color(0xFFDFF6EC),
      'cancelled' => const Color(0xFFFBE3E1),
      _ => const Color(0xFFEAF2EC),
    };

Color _shipmentStatusColor(String status) => switch (status) {
      'dalam_perjalanan' => const Color(0xFF8A5A12),
      'selesai' => const Color(0xFF2F6C3F),
      _ => const Color(0xFF5E7D66),
    };

Color _shipmentStatusBackground(String status) => switch (status) {
      'dalam_perjalanan' => const Color(0xFFF7E9D2),
      'selesai' => const Color(0xFFE2F0E6),
      _ => const Color(0xFFEAF2EC),
    };

class TransportirOrderDetailPage extends StatelessWidget {
  const TransportirOrderDetailPage({super.key, required this.order, this.session});

  final TransportirAssignedOrder order;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('GCommers', style: AppTheme.title(size: 18)),
        actions: const [NotificationBadge(iconColor: AppTheme.ink)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          if (order.isPartial) ...[
            const _NoticeCard(
              title: 'Pengiriman Dipecah (Split Delivery)',
              body: 'Pesanan ini dikirim melalui beberapa truk terpisah.',
            ),
            const SizedBox(height: 14),
          ],
          _OrderLoadCard(order: order),
        ],
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 1, session: session),
    );
  }
}

/// Satu kartu gabungan: tujuan kios di paling atas, lalu nomor pesanan, lalu daftar
/// muatan (per truk) yang ditugaskan ke sopir ini saja — tidak menampilkan info
/// pesanan/harga yang bukan urusan sopir (lihat ORDER_FLOW_CONTRACT.md).
class _OrderLoadCard extends StatelessWidget {
  const _OrderLoadCard({required this.order});

  final TransportirAssignedOrder order;

  @override
  Widget build(BuildContext context) {
    final firstShipment = order.shipments.first;
    final buyerName = firstShipment.destinationLabel ?? 'Kios Tujuan';
    final buyerAddress = order.detail?.deliveryAddress ?? firstShipment.destinationAddress ?? '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB5D4BC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TUJUAN', style: TextStyle(color: Color(0xFF5E7D66), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: const Color(0xFFDCEDE1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.store_outlined, color: Color(0xFF2F6C3F), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(buyerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F261F))),
                    const SizedBox(height: 2),
                    Text(buyerAddress, style: const TextStyle(color: Color(0xFF5E7D66), fontSize: 13, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nomor Pesanan', style: TextStyle(color: Color(0xFF5E7D66), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('#${order.poNumber}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F261F))),
                  ],
                ),
              ),
              _StatusPill(
                label: order.statusLabel,
                foreground: _orderStatusColor(order.orderStatus),
                background: _orderStatusBackground(order.orderStatus),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          if (order.isPartial) ...[
            const Text('Daftar Muatan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F261F))),
            const SizedBox(height: 12),
          ],
          for (var i = 0; i < order.shipments.length; i++) ...[
            _LoadEntry(shipment: order.shipments[i]),
            if (i != order.shipments.length - 1) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

/// Satu muatan (1 truk/SJ) — hanya info yang relevan untuk sopir: produk, tonase,
/// kode SO, kendaraan, dan siapa admin transport yang menugaskan. Tidak ada harga
/// maupun nomor surat jalan (lihat permintaan UI terbaru).
class _LoadEntry extends StatelessWidget {
  const _LoadEntry({required this.shipment});

  final ShipmentSummary shipment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(_productLabel(shipment),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F261F))),
            ),
            _StatusPill(
              label: shipment.statusLabel,
              foreground: _shipmentStatusColor(shipment.status),
              background: _shipmentStatusBackground(shipment.status),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _InfoLineRow(
          icon: Icons.scale_outlined,
          label: 'Tonase',
          value: shipment.quotaTon != null ? '${shipment.quotaTon} Ton' : '-',
        ),
        const SizedBox(height: 8),
        _InfoLineRow(
          icon: Icons.qr_code_2_outlined,
          label: 'Kode SO',
          value: shipment.soCode ?? 'Belum tersedia',
        ),
        const SizedBox(height: 8),
        _InfoLineRow(
          icon: Icons.local_shipping_outlined,
          label: 'Kendaraan',
          value: '${shipment.truckLabel ?? 'Kendaraan belum diatur'} • ${shipment.driverName.isEmpty ? '-' : shipment.driverName}',
        ),
        if (shipment.assignedByName != null || shipment.assignedBy != null) ...[
          const SizedBox(height: 8),
          _InfoLineRow(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Ditugaskan Oleh',
            value: shipment.assignedByName?.trim().isNotEmpty == true ? shipment.assignedByName! : shipment.assignedBy!,
          ),
        ],
        if (shipment.note != null) ...[
          const SizedBox(height: 8),
          Text(shipment.note!, style: const TextStyle(fontSize: 12, color: Color(0xFF5E7D66))),
        ],
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0B67F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF8A5A12)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFF8A5A12), fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(body, style: const TextStyle(color: Color(0xFF5C4A37), fontSize: 14, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLineRow extends StatelessWidget {
  const _InfoLineRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B8C73)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B8C73))),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F261F))),
            ],
          ),
        ),
      ],
    );
  }
}

/// Baris pesanan bergaya sama dengan "Pemesanan Terbaru" di dashboard: ikon,
/// nomor pesanan + status, muatan (produk · tonase), lalu tujuan kios + tanggal.
class _TransportirOrderRow extends StatelessWidget {
  const _TransportirOrderRow({required this.order, required this.onTap});

  final TransportirAssignedOrder order;
  final VoidCallback onTap;

  String get _muatanLabel {
    if (order.shipments.length > 1) {
      final total = order.shipments.fold(0.0, (sum, s) => sum + (s.quotaTon ?? 0));
      return '${order.shipments.length} muatan${total > 0 ? ' · ${_fmtTon(total)} Ton' : ''}';
    }
    final shipment = order.shipments.first;
    final product = shipment.productName;
    if (product == null || product.isEmpty) return 'Muatan belum diatur';
    return shipment.quotaTon != null ? '$product · ${_fmtTon(shipment.quotaTon!)} Ton' : product;
  }

  String get _destinationLabel {
    final s = order.shipments.first;
    return s.destinationLabel ?? order.detail?.deliveryAddress ?? s.destinationAddress ?? 'Kios tujuan';
  }

  static String _fmtTon(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppTheme.tertiaryGreenSoft, borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.receipt_long_rounded, color: AppTheme.tertiaryGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(order.poNumber, style: AppTheme.subtitle(size: 14))),
                      StatusChip(label: order.statusLabel, color: _orderStatusColor(order.orderStatus)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 13, color: AppTheme.muted),
                      const SizedBox(width: 5),
                      Expanded(child: Text(_muatanLabel, style: AppTheme.body(size: 12, color: AppTheme.muted))),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.flag_outlined, size: 13, color: AppTheme.muted),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(_destinationLabel,
                            style: AppTheme.body(size: 12, color: AppTheme.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Text(shortDateTime(order.createdAt), style: AppTheme.body(size: 11, color: AppTheme.muted)),
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.foreground, required this.background});

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: foreground, fontSize: 12, fontWeight: FontWeight.w800),
      ),
    );
  }
}
