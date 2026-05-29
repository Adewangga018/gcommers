import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/auth_models.dart';
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
          statusColor: Color(0xFF7268D8),
          statusBackground: Color(0xFFE7E4FF),
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
      statusColor: Color(0xFF1F6CBF),
      statusBackground: Color(0xFFE2EEFF),
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
          statusColor: Color(0xFF7268D8),
          statusBackground: Color(0xFFE7E4FF),
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
            'Daftar Pemesanan',
            style: TextStyle(fontSize: 30 / 2, fontWeight: FontWeight.w900, color: Color(0xFF17203A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kelola pemesanan BPTP dan tagihan invoices.',
            style: TextStyle(fontSize: 16, color: Color(0xFF6A6780), height: 1.25),
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
      bottomNavigationBar: _TransportirBottomBar(currentIndex: 1, session: session),
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
      backgroundColor: const Color(0xFFF6F4FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4A3AFF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('GCommers', style: TextStyle(color: Color(0xFF4A3AFF), fontWeight: FontWeight.w800)),
        actions: const [NotificationBadge(iconColor: Color(0xFF4A3AFF))],
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF17203A)),
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
      bottomNavigationBar: _TransportirBottomBar(currentIndex: 1, session: session),
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
    const Color primaryBlue = Color(0xFF2F77C4);
    const Color primaryPurple = Color(0xFF3B309E);
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
          'GCommers',
          style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w700),
        ),
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
                  border: Border.all(color: const Color(0xFFD1CBE4)),
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
                              Text(shipment.deliveryDateLabel, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF20202D))),
                              const SizedBox(height: 12),
                              const Text('Pengemudi', style: TextStyle(color: Colors.black54, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(shipment.driverName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF20202D))),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Transportir', style: TextStyle(color: Colors.black54, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(shipment.transportirName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF20202D))),
                              const SizedBox(height: 12),
                              const Text('Plat Nomor', style: TextStyle(color: Colors.black54, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(shipment.policeNumber, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF20202D))),
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
                  border: Border.all(color: const Color(0xFFD1CBE4)),
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
                        color: const Color(0xFFF5F1FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shipment.recipientName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF20202D))),
                          const SizedBox(height: 4),
                          Text(shipment.destinationAddress, style: const TextStyle(color: Color(0xFF66637A), fontSize: 14, height: 1.35)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2ECF6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD8CDE8), style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          const Text('PINDAI UNTUK KONFIRMASI', style: TextStyle(color: Color(0xFF6A647D), fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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
                            child: const Center(
                              child: Icon(Icons.qr_code_2_rounded, color: Color(0xFF2B2B39), size: 72),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            shipment.qrHint,
                            style: const TextStyle(color: Color(0xFF6A647D), fontSize: 13, height: 1.35),
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
                  border: Border.all(color: const Color(0xFFD1CBE4)),
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
      bottomNavigationBar: _TransportirBottomBar(currentIndex: 1, session: session),
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

Future<void> _downloadShipmentPdf(
  BuildContext context, {
  required TransportirOrderRecord order,
  required TransportirShipmentRecord shipment,
  required AuthSession? session,
}) async {
  try {
    final bytes = await _buildShipmentPdf(order: order, shipment: shipment, session: session);
    await Printing.sharePdf(bytes: bytes, filename: 'surat-jalan-${shipment.shipmentNumber}.pdf');
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal membuat PDF surat jalan: $error')),
    );
  }
}

Future<Uint8List> _buildShipmentPdf({
  required TransportirOrderRecord order,
  required TransportirShipmentRecord shipment,
  required AuthSession? session,
}) async {
  final logoData = await rootBundle.load('gcs.jpg');
  final logo = pw.MemoryImage(logoData.buffer.asUint8List());
  final pdf = pw.Document();

  final driverName  = _firstFilled([session?.displayName, shipment.driverName]);
  final ownerName   = _firstFilled([session?.companyName, session?.transportirName, shipment.transportirName]);
  final phone       = _firstFilled([session?.phone, '-']);
  final policeNumber = _firstFilled([session?.policeNumber, shipment.policeNumber]);

  pw.Widget infoRow(String label, String value, {double labelWidth = 110}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: labelWidth,
          child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ),
        pw.Text(':  ', style: const pw.TextStyle(fontSize: 9)),
        pw.Expanded(
          child: pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(32, 26, 32, 26),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Image(logo, width: 60, height: 60, fit: pw.BoxFit.contain),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PT. GRESIK CIPTA SEJAHTERA',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Jl. KIG Raya Selatan Blok A5 - Gresik',
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Telp. (031) 3985543, 3984822, 3973239',
                          style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('No.', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      shipment.shipmentNumber,
                      style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // ── Title ────────────────────────────────────────────────────────
            pw.Text(
              'SURAT PENGANTAR',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                decoration: pw.TextDecoration.underline,
              ),
            ),
            pw.Text('Surat Jalan Pengiriman Barang',
                style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 8),

            // ── Info Block ───────────────────────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Left: vehicle info
                pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      infoRow('Kendaraan No. Pol', policeNumber, labelWidth: 112),
                      pw.SizedBox(height: 5),
                      infoRow('Barang EX', order.clientName, labelWidth: 112),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                // Right: date + recipient
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Tanggal  :  ${shipment.deliveryDateLabel}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('Kepada Yth.',
                          style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(
                        shipment.recipientName,
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('Di', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text(
                        shipment.destinationAddress,
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // ── Table (no Harga / Nilai / Total Nilai) ───────────────────────
            pw.Table(
              border: pw.TableBorder.all(width: 0.7),
              columnWidths: const {
                0: pw.FixedColumnWidth(26),
                1: pw.FlexColumnWidth(),
                2: pw.FixedColumnWidth(60),
                3: pw.FixedColumnWidth(58),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFE8E8E8)),
                  children: [
                    _pdfCell('NO', bold: true, align: pw.TextAlign.center),
                    _pdfCell('URAIAN BARANG', bold: true),
                    _pdfCell('JUMLAH', bold: true, align: pw.TextAlign.center),
                    _pdfCell('SATUAN', bold: true, align: pw.TextAlign.center),
                  ],
                ),
                for (var i = 0; i < shipment.items.length; i++)
                  pw.TableRow(
                    children: [
                      _pdfCell('${i + 1}', align: pw.TextAlign.center),
                      _pdfCell(shipment.items[i].name),
                      _pdfCell(shipment.items[i].quantityText, align: pw.TextAlign.center),
                      _pdfCell('TON', align: pw.TextAlign.center),
                    ],
                  ),
              ],
            ),

            pw.Spacer(),

            // ── Footer Info ──────────────────────────────────────────────────
            pw.Divider(thickness: 0.6),
            pw.SizedBox(height: 5),
            pw.Text(
              'Dikirim ke alamat tersebut untuk memenuhi permintaan',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 3),
            pw.Text('Pemilik  :  $ownerName', style: const pw.TextStyle(fontSize: 9)),
            pw.SizedBox(height: 2),
            pw.Row(
              children: [
                pw.Text('Telp       :  $phone', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(width: 24),
                pw.Text('GP : ${order.bptpReference}', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Catatan :',
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            for (final note in const [
              '1. Dilarang menjual di atas HET, sesuai SK mentan.',
              '2. Dilarang menjual antar kios, industri, dan di luar peruntukannya.',
              '3. Harap menyimpan surat pengantar ini sebagai arsip.',
              '4. Surat pengantar ini sebagai Nota Penjualan.',
            ])
              pw.Text(note, style: const pw.TextStyle(fontSize: 8)),

            pw.SizedBox(height: 16),

            // ── Signatures ───────────────────────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _pdfSignBox('Penerima,', ''),
                pw.SizedBox(width: 20),
                _pdfSignBox('Tanda Tangan,\nSopir/Pembawa', driverName),
                pw.SizedBox(width: 20),
                _pdfSignBox('Pengirim,', ownerName),
              ],
            ),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

pw.Widget _pdfSignBox(String title, String name) {
  return pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 44),
        pw.Container(
          width: 110,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 0.8)),
          ),
        ),
        pw.SizedBox(height: 4),
        if (name.isNotEmpty)
          pw.Text(name, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center),
      ],
    ),
  );
}

pw.Widget _pdfCell(String text, {bool bold = false, pw.TextAlign align = pw.TextAlign.left}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      textAlign: align,
    ),
  );
}

String _firstFilled(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return '-';
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
            border: Border.all(color: const Color(0xFFD1CBE4)),
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
                      color: const Color(0xFFEAE8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF4A3AFF)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.invoiceLabel, style: const TextStyle(color: Color(0xFF6A6780), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                        const SizedBox(height: 3),
                        Text(order.invoiceNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF20202D))),
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
                  Expanded(child: _KeyText(label: 'Nilai Tagihan', value: order.totalAmountLabel, valueColor: const Color(0xFF4A3AFF))),
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
                    foregroundColor: const Color(0xFF4A3AFF),
                    side: const BorderSide(color: Color(0xFFB9B5E4)),
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
                    const Text('Nomor Invoice', style: TextStyle(color: Color(0xFF6A6780), fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('#${order.invoiceNumber}', style: const TextStyle(fontSize: 26 / 2, fontWeight: FontWeight.w900, color: Color(0xFF20202D))),
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
          Text(order.buyerAddress, style: const TextStyle(color: Color(0xFF66637A), fontSize: 14, height: 1.35)),
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
        border: Border.all(color: const Color(0xFFD1CBE4)),
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
                    color: const Color(0xFFE9F1FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: Color(0xFF2F77C4)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Surat Jalan #${shipment.shipmentNumber}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF20202D))),
                      const SizedBox(height: 3),
                      Text('${shipment.truckLabel} • Supir: ${shipment.driverName}', style: const TextStyle(color: Color(0xFF66637A), fontSize: 13, height: 1.2)),
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
                Text('Produk', style: TextStyle(color: Color(0xFF6A6780), fontSize: 13)),
                Text('Jumlah (TON)', style: TextStyle(color: Color(0xFF6A6780), fontSize: 13)),
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
                          child: Icon(Icons.circle, size: 8, color: Color(0xFF777184)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(item.name, style: const TextStyle(color: Color(0xFF20202D), fontSize: 14, height: 1.3)),
                        ),
                        const SizedBox(width: 10),
                        Text(item.quantityText, style: const TextStyle(color: Color(0xFF20202D), fontSize: 15, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => _downloadShipmentPdf(context, order: order, shipment: shipment, session: session),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4438A7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: const Text('Download Surat Jalan', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download BPTP sedang disiapkan.'))),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3D394A),
                      side: const BorderSide(color: Color(0xFFD1CBE4)),
                      backgroundColor: const Color(0xFFF7F4FC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Download BPTP', style: TextStyle(fontWeight: FontWeight.w800)),
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
          child: Icon(Icons.circle, size: 8, color: Color(0xFF777184)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(item.name, style: const TextStyle(color: Color(0xFF20202D), fontSize: 14, height: 1.35)),
        ),
        const SizedBox(width: 10),
        Text(item.quantityText, style: const TextStyle(color: Color(0xFF20202D), fontSize: 15, fontWeight: FontWeight.w800)),
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
        Text(label, style: const TextStyle(color: Color(0xFF6A6780), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: valueColor ?? const Color(0xFF20202D))),
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

class _TransportirBottomBar extends StatelessWidget {
  const _TransportirBottomBar({required this.currentIndex, this.session});

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
