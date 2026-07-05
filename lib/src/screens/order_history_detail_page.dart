import 'dart:async';

import 'package:flutter/material.dart';

import '../models/commerce_models.dart';
import '../services/commerce_service.dart';
import '../utils/formatters.dart';

class OrderHistoryDetailPage extends StatefulWidget {
  const OrderHistoryDetailPage({super.key, required this.poNumber});

  final String poNumber;

  @override
  State<OrderHistoryDetailPage> createState() => _OrderHistoryDetailPageState();
}

class _OrderHistoryDetailPageState extends State<OrderHistoryDetailPage> {
  final _commerceService = CommerceService();
  late Future<OrderDetail> _detailFuture;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _detailFuture = _commerceService.getOrderDetail(widget.poNumber);
    // Status pengiriman bisa berubah dari sisi Transportir kapan saja — polling ringan
    // di sini cukup untuk mendekati real-time tanpa perlu websocket (lihat ORDER_FLOW_CONTRACT.md §1.5).
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _pollRefresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollRefresh() async {
    try {
      final detail = await _commerceService.getOrderDetail(widget.poNumber);
      if (!mounted) return;
      if (detail.orderStatus == 'delivered' || detail.orderStatus == 'cancelled') {
        _pollTimer?.cancel();
      }
      setState(() => _detailFuture = Future.value(detail));
    } catch (_) {
      // Diamkan kalau gagal — pull-to-refresh manual masih tersedia.
    }
  }

  Future<void> _refresh() async {
    final future = _commerceService.getOrderDetail(widget.poNumber);
    setState(() => _detailFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2F6C3F);
    const Color primaryPurple = Color(0xFF2F6C3F);
    const Color bgLight = Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Pesanan', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<OrderDetail>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: Text('Gagal memuat detail: ${snapshot.error}')),
                  ),
                ],
              );
            }

            final order = snapshot.data!;
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
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
                      border: Border.all(color: const Color(0xFFB5D4BC)),
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
                                  const Text('PURCHASE ORDER', style: TextStyle(color: Colors.black54, fontSize: 12, letterSpacing: 0.8)),
                                  const SizedBox(height: 6),
                                  Text(order.poNumber, style: const TextStyle(color: primaryPurple, fontSize: 22, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text(formatDateTime(order.createdAt), style: const TextStyle(color: Colors.black54, fontSize: 14)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCEDE1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                order.orderStatusLabel,
                                style: const TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _KeyValue(label: 'Wilayah', value: order.vendor)),
                            const SizedBox(width: 12),
                            Expanded(child: _KeyValue(label: 'Metode Pembayaran', value: order.paymentMethod)),
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
                      border: Border.all(color: const Color(0xFFB5D4BC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status Pengiriman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 18),
                        if (order.orderStatus == 'cancelled')
                          _CancelledStatusBanner(note: order.orderStatusNote)
                        else
                          _ShipmentStatusTracker(stage: _deliveryStage(order)),
                      ],
                    ),
                  ),
                  if (order.shipments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
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
                          const Text('Mitra & Sopir Pengiriman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(
                            order.shipments.length > 1
                                ? 'Pesanan ini dikirim oleh ${order.shipments.length} mitra transportir. Status "Pesanan Selesai" baru muncul setelah semua mitra menyelesaikan load-out.'
                                : 'Detail sopir yang bertugas mengantarkan pesanan ini.',
                            style: const TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          for (var i = 0; i < order.shipments.length; i++) ...[
                            if (i > 0) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                            _ShipmentCard(shipment: order.shipments[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Daftar Barang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(999)),
                              child: Text('${order.items.length} Items', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ItemRow(item: item),
                          ),
                        ),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        _SummaryLine(label: 'Subtotal', value: formatCurrency(order.subtotal)),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                            Text(
                              formatCurrency(order.totalAmount),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: primaryPurple),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (order.status == 'pending_payment')
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pushNamed('/payment', arguments: order.poNumber),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2F6C3F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.payment_rounded),
                        label: const Text('BAYAR SEKARANG', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
            );
          },
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
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

/// Tahap pengiriman untuk tracker "Status Pengiriman":
/// -1 belum dibayar, 0 diproses (belum ada sopir yang load-in),
/// 1 dalam perjalanan (minimal 1 sopir sudah load-in),
/// 2 selesai — **hanya** kalau SEMUA baris Shipments (semua mitra & sopir) sudah load-out,
/// bukan cuma satu (order bisa dikirim >1 mitra sekaligus, lihat _ShipmentCard).
String _formatQuotaTon(double value) {
  return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
}

int _deliveryStage(OrderDetail order) {
  if (order.paymentStatus != 'paid') return -1;
  if (order.shipments.isEmpty) return 0;
  final allLoadedOut = order.shipments.every((s) => s.muatOutCompletedAt != null);
  if (allLoadedOut) return 2;
  final anyLoadedIn = order.shipments.any((s) => s.muatInCompletedAt != null);
  return anyLoadedIn ? 1 : 0;
}

class _CancelledStatusBanner extends StatelessWidget {
  const _CancelledStatusBanner({this.note});

  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_rounded, color: Color(0xFFC0392B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pesanan Dibatalkan', style: TextStyle(color: Color(0xFFC0392B), fontWeight: FontWeight.w800, fontSize: 14)),
                if (note != null && note!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(note!, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tracker bundar bergaya Shopee: Pesanan Diproses -> Dalam Perjalanan -> Pesanan Selesai,
/// dihubungkan dengan anak panah yang menyala mengikuti [stage] (lihat _deliveryStage).
class _ShipmentStatusTracker extends StatelessWidget {
  const _ShipmentStatusTracker({required this.stage});

  final int stage;

  static const _stages = [
    (icon: Icons.receipt_long_rounded, label: 'Pesanan\nDiproses'),
    (icon: Icons.local_shipping_rounded, label: 'Dalam\nPerjalanan'),
    (icon: Icons.task_alt_rounded, label: 'Pesanan\nSelesai'),
  ];

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2F6C3F);
    const inactiveColor = Color(0xFFDCEDE1);
    const inactiveIconColor = Color(0xFF7FA98A);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _stages.length; i++) ...[
          if (i > 0)
            SizedBox(
              height: 40,
              child: Center(
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: i <= stage ? activeColor : inactiveColor,
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: i <= stage ? activeColor : inactiveColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _stages[i].icon,
                    color: i <= stage ? Colors.white : inactiveIconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _stages[i].label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == stage ? FontWeight.w800 : FontWeight.w600,
                    color: i <= stage ? Colors.black87 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({required this.shipment});

  final ShipmentSummary shipment;

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2F6C3F);
    return Column(
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
                    shipment.companyName?.trim().isNotEmpty == true ? shipment.companyName! : 'Mitra belum diketahui',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sopir: ${shipment.driverName.isNotEmpty ? shipment.driverName : '-'}'
                    '${shipment.truckLabel != null ? ' • ${shipment.truckLabel}' : ''}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xFFDCEDE1), borderRadius: BorderRadius.circular(999)),
              child: Text(
                shipment.statusLabel,
                style: const TextStyle(color: primaryGreen, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        if (shipment.productName != null) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.black45),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  shipment.quotaTon != null
                      ? 'Muatan: ${shipment.productName} • ${_formatQuotaTon(shipment.quotaTon!)} Ton'
                      : 'Muatan: ${shipment.productName}',
                  style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        _MuatStep(label: 'Load-in (muat di gudang)', completedAt: shipment.muatInCompletedAt),
        const SizedBox(height: 6),
        _MuatStep(label: 'Load-out (serah terima di kios)', completedAt: shipment.muatOutCompletedAt),
      ],
    );
  }
}

class _MuatStep extends StatelessWidget {
  const _MuatStep({required this.label, required this.completedAt});

  final String label;
  final DateTime? completedAt;

  @override
  Widget build(BuildContext context) {
    final done = completedAt != null;
    final color = done ? const Color(0xFF2F6C3F) : Colors.black38;
    return Row(
      children: [
        Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: TextStyle(color: done ? Colors.black87 : Colors.black45, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
        Text(
          done ? formatDateTime(completedAt!) : 'Menunggu',
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF5E7D66), size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${item.quantity} ${item.unit} x ${formatCurrency(item.unitPrice)}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          formatCurrency(item.totalPrice),
          style: const TextStyle(color: Color(0xFF2F6C3F), fontSize: 14, fontWeight: FontWeight.w800),
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
