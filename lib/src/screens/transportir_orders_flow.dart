import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/auth_models.dart';
import '../theme/app_theme.dart';
import '../widgets/transportir_bottom_nav.dart';
import 'settings_pages.dart';

class TransportirOrdersPage extends StatelessWidget {
  const TransportirOrdersPage({super.key, this.session});

  final AuthSession? session;

  static const List<TransportirOrderRecord> _orders = [
    TransportirOrderRecord(
      invoiceNumber: 'INV-2023-1102',
      invoiceLabel: 'INVOICE',
      statusLabel: 'Proses Bank',
      statusColor: Color(0xFF8A5A12),
      statusBackground: Color(0xFFF7E9D2),
      createdAtLabel: '24 Okt 2023',
      totalAmountLabel: 'Rp 45.000.000',
      clientName: 'PT. Pembangunan Jaya Perkasa',
      buyerName: 'Kios Makmur Jaya',
      buyerAddress: 'Jl. Sudirman No. 45, Kecamatan Sukabumi, Kota Bandar Lampung.',
      bptpReference: 'BPTP-23-4412',
      totalItemsLabel: '3 Jenis Pupuk (35 TON)',
      shipmentNoticeTitle: 'Pengiriman Dipecah (Split Delivery)',
      shipmentNoticeBody: 'Akses jalan sempit, armada kecil dikerahkan untuk menyelesaikan pengiriman.',
      shipments: [
        TransportirShipmentRecord(
          shipmentNumber: 'SJ-001',
          truckLabel: 'Truk A (Nopol: BB 8108 HA)',
          driverName: 'Hotma',
          statusLabel: 'Delivered',
          statusColor: Color(0xFF2F6C3F),
          statusBackground: Color(0xFFE2F0E6),
          items: [
            TransportirShipmentItem(name: 'UREA DO. 3640134773UR / BA.2', quantityText: '15,00'),
            TransportirShipmentItem(name: 'NPK DO. 3640134774NK / BA.2', quantityText: '10,00'),
          ],
          deliveryDateLabel: '24 Okt 2023',
          recipientName: 'Kios Makmur Jaya',
          destinationAddress: 'Jl. Raya Tano Tombangan Angko, Tapanuli Selatan',
          transportirName: 'PT Logistik Utama',
          policeNumber: 'B 1234 YXZ',
          totalQuantityLabel: '25,00 TON',
          qrHint: 'Tunjukkan QR ini ke petugas gudang atau penerima untuk dipindai',
        ),
        TransportirShipmentRecord(
          shipmentNumber: 'SJ-002',
          truckLabel: 'Truk B (Nopol: BB 9021 XB)',
          driverName: 'Budi',
          statusLabel: 'In Transit',
          statusColor: Color(0xFF8A5A12),
          statusBackground: Color(0xFFF7E9D2),
          items: [
            TransportirShipmentItem(name: 'ZA DO. 3640134775ZA / BA.2', quantityText: '10,00'),
          ],
          deliveryDateLabel: '25 Okt 2023',
          recipientName: 'Kios Makmur Jaya',
          destinationAddress: 'Jl. Raya Tano Tombangan Angko, Tapanuli Selatan',
          transportirName: 'PT Logistik Utama',
          policeNumber: 'B 9021 XB',
          totalQuantityLabel: '10,00 TON',
          qrHint: 'Tunjukkan QR ini ke petugas gudang atau penerima untuk dipindai',
        ),
      ],
    ),
    TransportirOrderRecord(
      invoiceNumber: 'INV-2023-1184',
      invoiceLabel: 'INVOICE',
      statusLabel: 'Terkirim',
      statusColor: Color(0xFF2F6C3F),
      statusBackground: Color(0xFFE2F0E6),
      createdAtLabel: '19 Okt 2023',
      totalAmountLabel: 'Rp 33.500.000',
      clientName: 'PT. Cahaya Agro Mandiri',
      buyerName: 'Gudang Tani Sejahtera',
      buyerAddress: 'Jl. Anggrek No. 12, Metro Pusat, Lampung',
      bptpReference: 'BPTP-23-4498',
      totalItemsLabel: '2 Jenis Pupuk (21 TON)',
      shipmentNoticeTitle: 'Pengiriman Selesai',
      shipmentNoticeBody: 'Seluruh surat jalan pada pemesanan ini telah diverifikasi dan dikirim.',
      shipments: [
        TransportirShipmentRecord(
          shipmentNumber: 'SJ-003',
          truckLabel: 'Truk C (Nopol: BE 9911 AC)',
          driverName: 'Agus',
          statusLabel: 'Delivered',
          statusColor: Color(0xFF2F6C3F),
          statusBackground: Color(0xFFE2F0E6),
          items: [
            TransportirShipmentItem(name: 'Urea Subsidi / BA.2', quantityText: '12,00'),
            TransportirShipmentItem(name: 'NPK Phonska / BA.2', quantityText: '9,00'),
          ],
          deliveryDateLabel: '19 Okt 2023',
          recipientName: 'Gudang Tani Sejahtera',
          destinationAddress: 'Jl. Anggrek No. 12, Metro Pusat, Lampung',
          transportirName: 'PT Logistik Utama',
          policeNumber: 'BE 9911 AC',
          totalQuantityLabel: '21,00 TON',
          qrHint: 'Tunjukkan QR ini ke petugas gudang atau penerima untuk dipindai',
        ),
      ],
    ),
  ];

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
          onPressed: () => Navigator.of(context).pushReplacementNamed('/transportir-home', arguments: session),
        ),
        title: Text('GCommers', style: AppTheme.title(size: 18)),

      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          const Text(
            'Daftar Pemesanan',
            style: TextStyle(fontSize: 30 / 2, fontWeight: FontWeight.w900, color: Color(0xFF0F261F)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kelola pemesanan BPTP dan tagihan invoices.',
            style: TextStyle(fontSize: 16, color: Color(0xFF5E7D66), height: 1.25),
          ),
          const SizedBox(height: 18),
          ..._orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _TransportirOrderCard(
                order: order,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TransportirOrderDetailPage(order: order, session: session),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 1, session: session),
    );
  }
}
class TransportirOrderDetailPage extends StatelessWidget {
  const TransportirOrderDetailPage({super.key, required this.order, this.session});

  final TransportirOrderRecord order;
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
          _DetailHeaderCard(order: order),
          const SizedBox(height: 14),
          _NoticeCard(title: order.shipmentNoticeTitle, body: order.shipmentNoticeBody),
          const SizedBox(height: 20),
          const Text(
            'Daftar Surat Jalan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F261F)),
          ),
          const SizedBox(height: 14),
          ...order.shipments.map(
            (shipment) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ShipmentSummaryCard(
                shipment: shipment,
                order: order,
                session: session,
                onOpen: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TransportirShipmentDetailPage(
                      order: order,
                      shipment: shipment,
                      session: session,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 1, session: session),
    );
  }
}

class TransportirShipmentDetailPage extends StatelessWidget {
  const TransportirShipmentDetailPage({super.key, required this.order, required this.shipment, this.session});

  final TransportirOrderRecord order;
  final TransportirShipmentRecord shipment;
  final AuthSession? session;

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
          icon: const Icon(Icons.arrow_back, color: AppTheme.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('GCommers', style: AppTheme.title(size: 18)),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur cetak sedang disiapkan.'))),
            icon: const Icon(Icons.print_outlined, color: primaryBlue),
            label: const Text('Cetak', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w800)),
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
                  border: Border.all(color: const Color(0xFFB5D4BC)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8)),
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
                              const Text('Tanggal', style: TextStyle(color: Colors.black54, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(shipment.deliveryDateLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F261F))),
                              const SizedBox(height: 12),
                              const Text('Pengemudi', style: TextStyle(color: Colors.black54, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(shipment.driverName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F261F))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Transportir', style: TextStyle(color: Colors.black54, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(shipment.transportirName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F261F))),
                              const SizedBox(height: 12),
                              const Text('Plat Nomor', style: TextStyle(color: Colors.black54, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(shipment.policeNumber, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F261F))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _KeyText(label: 'Nomor Invoice', value: order.invoiceNumber),
                    const SizedBox(height: 12),
                    _KeyText(label: 'Surat Jalan', value: shipment.shipmentNumber),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
                    const Text('Tujuan (Kios)', style: TextStyle(color: primaryBlue, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2EC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shipment.recipientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F261F))),
                          const SizedBox(height: 4),
                          Text(shipment.destinationAddress, style: const TextStyle(color: Color(0xFF5E7D66), fontSize: 14, height: 1.35)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFB5D4BC), style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          const Text('PINDAI UNTUK KONFIRMASI', style: TextStyle(color: Color(0xFF5E7D66), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                          const SizedBox(height: 16),
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 6)),
                              ],
                            ),
                            child: Center(
                              child: QrImageView(
                                data: shipment.shipmentNumber,
                                version: QrVersions.auto,
                                size: 88,
                                backgroundColor: Colors.white,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: primaryPurple,
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF0F261F),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            shipment.shipmentNumber,
                            style: const TextStyle(color: primaryPurple, fontSize: 12, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            shipment.qrHint,
                            style: const TextStyle(color: Color(0xFF5E7D66), fontSize: 13, height: 1.35),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
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
                    const Text('Daftar Barang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    ...shipment.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ShipmentItemRow(item: item),
                      ),
                    ),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _KeyText(label: 'Total Quantity', value: shipment.totalQuantityLabel, valueColor: primaryPurple),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 1, session: session),
    );
  }
}

class TransportirOrderRecord {
  const TransportirOrderRecord({
    required this.invoiceNumber,
    required this.invoiceLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.createdAtLabel,
    required this.totalAmountLabel,
    required this.clientName,
    required this.buyerName,
    required this.buyerAddress,
    required this.bptpReference,
    required this.totalItemsLabel,
    required this.shipmentNoticeTitle,
    required this.shipmentNoticeBody,
    required this.shipments,
  });

  final String invoiceNumber;
  final String invoiceLabel;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final String createdAtLabel;
  final String totalAmountLabel;
  final String clientName;
  final String buyerName;
  final String buyerAddress;
  final String bptpReference;
  final String totalItemsLabel;
  final String shipmentNoticeTitle;
  final String shipmentNoticeBody;
  final List<TransportirShipmentRecord> shipments;
}

class TransportirShipmentRecord {
  const TransportirShipmentRecord({
    required this.shipmentNumber,
    required this.truckLabel,
    required this.driverName,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackground,
    required this.items,
    required this.deliveryDateLabel,
    required this.recipientName,
    required this.destinationAddress,
    required this.transportirName,
    required this.policeNumber,
    required this.totalQuantityLabel,
    required this.qrHint,
  });

  final String shipmentNumber;
  final String truckLabel;
  final String driverName;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackground;
  final List<TransportirShipmentItem> items;
  final String deliveryDateLabel;
  final String recipientName;
  final String destinationAddress;
  final String transportirName;
  final String policeNumber;
  final String totalQuantityLabel;
  final String qrHint;
}

class TransportirShipmentItem {
  const TransportirShipmentItem({required this.name, required this.quantityText});

  final String name;
  final String quantityText;
}

class _TransportirOrderCard extends StatelessWidget {
  const _TransportirOrderCard({required this.order, required this.onTap});

  final TransportirOrderRecord order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFB5D4BC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2F0E6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2F6C3F)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.invoiceLabel, style: const TextStyle(color: Color(0xFF5E7D66), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                        const SizedBox(height: 3),
                        Text(order.invoiceNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F261F))),
                      ],
                    ),
                  ),
                  _StatusPill(label: order.statusLabel, foreground: order.statusColor, background: order.statusBackground),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _KeyText(label: 'Tanggal', value: order.createdAtLabel)),
                  const SizedBox(width: 12),
                  Expanded(child: _KeyText(label: 'Nilai Tagihan', value: order.totalAmountLabel, valueColor: const Color(0xFF2F6C3F))),
                ],
              ),
              const SizedBox(height: 10),
              _KeyText(label: 'Klien', value: order.clientName),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2F6C3F),
                    side: const BorderSide(color: Color(0xFFB5D4BC)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Lihat Detail', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailHeaderCard extends StatelessWidget {
  const _DetailHeaderCard({required this.order});

  final TransportirOrderRecord order;

  @override
  Widget build(BuildContext context) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nomor Invoice', style: TextStyle(color: Color(0xFF5E7D66), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('#${order.invoiceNumber}', style: const TextStyle(fontSize: 26 / 2, fontWeight: FontWeight.w900, color: Color(0xFF0F261F))),
                  ],
                ),
              ),
              _StatusPill(label: 'Partial Delivery', foreground: const Color(0xFF8A5A12), background: const Color(0xFFF7E9D2)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _KeyText(label: 'Referensi BPTP', value: order.bptpReference),
          const SizedBox(height: 10),
          _KeyText(label: 'Tujuan Kios', value: order.buyerName),
          const SizedBox(height: 4),
          Text(order.buyerAddress, style: const TextStyle(color: Color(0xFF5E7D66), fontSize: 14, height: 1.35)),
          const SizedBox(height: 10),
          _KeyText(label: 'Total Item', value: order.totalItemsLabel),
        ],
      ),
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

class _ShipmentSummaryCard extends StatelessWidget {
  const _ShipmentSummaryCard({required this.shipment, required this.order, required this.session, required this.onOpen});

  final TransportirShipmentRecord shipment;
  final TransportirOrderRecord order;
  final AuthSession? session;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB5D4BC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEDE1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF2F6C3F)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Surat Jalan #${shipment.shipmentNumber}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F261F))),
                      const SizedBox(height: 3),
                      Text('${shipment.truckLabel} • Supir: ${shipment.driverName}', style: const TextStyle(color: Color(0xFF5E7D66), fontSize: 13, height: 1.2)),
                    ],
                  ),
                ),
                _StatusPill(label: shipment.statusLabel, foreground: shipment.statusColor, background: shipment.statusBackground),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Produk', style: TextStyle(color: Color(0xFF5E7D66), fontSize: 13)),
                Text('Jumlah (TON)', style: TextStyle(color: Color(0xFF5E7D66), fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              children: [
                ...shipment.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 7),
                          child: Icon(Icons.circle, size: 8, color: Color(0xFF5E7D66)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item.name, style: const TextStyle(color: Color(0xFF0F261F), fontSize: 14, height: 1.3)),
                        ),
                        const SizedBox(width: 10),
                        Text(item.quantityText, style: const TextStyle(color: Color(0xFF0F261F), fontSize: 15, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Admin-determined delivery info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFB5D4BC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_outlined,
                          color: Color(0xFF2F6C3F), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ditentukan Admin',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2F6C3F),
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              '${order.shipments.length > 1 ? "Partial Delivery" : "Pengiriman Langsung"}'
                              '  ·  ${shipment.totalQuantityLabel}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF0F261F),
                                  fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: order.shipments.length > 1
                              ? const Color(0xFFFFF3E0)
                              : const Color(0xFFDFF6EC),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.shipments.length > 1 ? 'PARTIAL' : 'LANGSUNG',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: order.shipments.length > 1
                                ? const Color(0xFFE65100)
                                : const Color(0xFF0E8F61),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipmentItemRow extends StatelessWidget {
  const _ShipmentItemRow({required this.item});

  final TransportirShipmentItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 6),
          child: Icon(Icons.circle, size: 8, color: Color(0xFF5E7D66)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(item.name, style: const TextStyle(color: Color(0xFF0F261F), fontSize: 14, height: 1.35)),
        ),
        const SizedBox(width: 10),
        Text(item.quantityText, style: const TextStyle(color: Color(0xFF0F261F), fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _KeyText extends StatelessWidget {
  const _KeyText({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF5E7D66), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor ?? const Color(0xFF0F261F))),
      ],
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

