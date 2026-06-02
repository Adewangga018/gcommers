import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/auth_models.dart';
import '../theme/app_theme.dart';
import '../widgets/transportir_bottom_nav.dart';

class TransportirShipmentsPage extends StatefulWidget {
  const TransportirShipmentsPage({super.key, this.session});
  final AuthSession? session;

  @override
  State<TransportirShipmentsPage> createState() => _TransportirShipmentsPageState();
}

class _TransportirShipmentsPageState extends State<TransportirShipmentsPage> {
  static const List<TransportirShipmentCardData> _shipments = [
    TransportirShipmentCardData(
      shipmentNumber: 'SJ-20231024-001',
      statusLabel: 'Siap Muat',
      statusColor: Color(0xFF4D8FE8),
      statusBackground: Color(0xFFDDEBFF),
      scheduleLabel: 'Hari ini, 09.00 WIB',
      origin: 'Gudang Utama, Jakarta',
      destination: 'Pabrik Perakitan, Bekasi',
      destinationSubtitle: 'Pabrik Perakitan, Bekasi',
      actionPrimaryLabel: 'Muat Masuk',
      actionSecondaryLabel: '',
      actionSecondaryKind: TransportirShipmentActionKind.none,
    ),
    TransportirShipmentCardData(
      shipmentNumber: 'SJ-20231024-002',
      statusLabel: 'Dalam Perjalanan',
      statusColor: Color(0xFFB86B22),
      statusBackground: Color(0xFFF4E0CB),
      scheduleLabel: 'Est. Tiba: 14.30 WIB',
      origin: 'Gudang Utama, Jakarta',
      destination: 'Pabrik Perakitan, Bekasi',
      destinationSubtitle: 'Pabrik Perakitan, Bekasi',
      actionPrimaryLabel: 'Lacak',
      actionSecondaryLabel: 'Muat Keluar',
      actionSecondaryKind: TransportirShipmentActionKind.loadOut,
    ),
  ];

  final Map<String, ShipmentProgress> _shipmentProgress = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _loadProgress();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final loaded = <String, ShipmentProgress>{};
    for (final shipment in _shipments) {
      loaded[shipment.shipmentNumber] = await loadShipmentProgress(shipment.shipmentNumber);
    }
    if (!mounted) return;
    setState(() {
      _shipmentProgress.addAll(loaded);
      _isLoadingProgress = false;
    });
  }

  List<TransportirShipmentCardData> _buildFilteredShipments() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _shipments;
    return _shipments.where((shipment) {
      return shipment.shipmentNumber.toLowerCase().contains(query) ||
          shipment.origin.toLowerCase().contains(query) ||
          shipment.destination.toLowerCase().contains(query) ||
          shipment.destinationSubtitle.toLowerCase().contains(query);
    }).toList();
  }

  ShipmentProgress _progressFor(String shipmentNumber) {
    return _shipmentProgress[shipmentNumber] ?? ShipmentProgress(shipmentNumber: shipmentNumber);
  }

  Future<void> _saveProgress(ShipmentProgress progress) async {
    setState(() => _shipmentProgress[progress.shipmentNumber] = progress);
    await saveShipmentProgress(progress);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4A3AFF)),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/transportir-home', arguments: widget.session),
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD3CFE2)),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.search, color: Color(0xFF8D88A3)),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Cari No. Surat Jalan...',
                      hintStyle: TextStyle(color: Color(0xFFB0AAC4), fontSize: 15),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF8D88A3)),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_isLoadingProgress)
            const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator()))
          else ..._buildFilteredShipments().map(
            (shipment) {
              final progress = _progressFor(shipment.shipmentNumber);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ShipmentSummaryCard(
                  shipment: shipment,
                  session: widget.session,
                  progress: progress,
                  onProgressUpdated: _saveProgress,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TransportirShipmentDetailPage(
                          shipment: shipment,
                          progress: progress,
                          session: widget.session,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          if (!_isLoadingProgress && _buildFilteredShipments().isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: const [
                  Icon(Icons.search_off, color: Color(0xFF8D88A3), size: 42),
                  SizedBox(height: 12),
                  Text('Tidak ada pengiriman yang cocok.', style: TextStyle(color: Color(0xFF8D88A3), fontSize: 15)),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 2, session: widget.session),
    );
  }
}

class TransportirShipmentDetailPage extends StatelessWidget {
  const TransportirShipmentDetailPage({super.key, required this.shipment, required this.progress, this.session});

  final TransportirShipmentCardData shipment;
  final ShipmentProgress progress;
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
        title: const Text('Detail Pengiriman', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w800)),
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
                          const Text('Pengiriman', style: TextStyle(color: Color(0xFF6B6780), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(shipment.shipmentNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF20202D))),
                        ],
                      ),
                    ),
                    _StatusChip(
                      label: progress.completed ? 'Selesai' : progress.muatMasukCompleted ? 'Dalam Perjalanan' : shipment.statusLabel,
                      foreground: progress.completed ? const Color(0xFF16C38A) : progress.muatMasukCompleted ? const Color(0xFFB86B22) : shipment.statusColor,
                      background: progress.completed ? const Color(0xFFD5F3E2) : progress.muatMasukCompleted ? const Color(0xFFF4E0CB) : shipment.statusBackground,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                _KeyValue(label: 'Asal', value: shipment.origin),
                const SizedBox(height: 12),
                _KeyValue(label: 'Tujuan', value: shipment.destination),
                const SizedBox(height: 12),
                _KeyValue(label: 'Jadwal', value: shipment.scheduleLabel),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD3CFE2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pesanan tiba pada ${shipment.scheduleLabel}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DetailStatusChip(label: 'Sedang Dikirim', active: progress.muatMasukCompleted || progress.muatKeluarCompleted || progress.completed),
                    _DetailStatusChip(label: 'Menuju Alamatmu', active: progress.muatKeluarCompleted || progress.completed),
                    _DetailStatusChip(label: 'Pesanan Tiba', active: progress.completed),
                  ],
                ),
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
                const Text('Bukti Muat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _DetailStatusChip(label: 'Muat Masuk', active: progress.muatMasukCompleted)),
                    const SizedBox(width: 10),
                    Expanded(child: _DetailStatusChip(label: 'Muat Keluar', active: progress.muatKeluarCompleted)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Foto Muat Masuk', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF20202D))),
                const SizedBox(height: 10),
                _DetailImageCard(photoBase64: progress.muatMasukPhotoBase64, label: 'Muat Masuk'),
                const SizedBox(height: 16),
                const Text('Foto Muat Keluar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF20202D))),
                const SizedBox(height: 10),
                _DetailImageCard(photoBase64: progress.muatKeluarPhotoBase64, label: 'Muat Keluar'),
                const SizedBox(height: 16),
                const Text('Keterangan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF20202D))),
                const SizedBox(height: 10),
                Text(progress.statusDetail, style: const TextStyle(fontSize: 12, color: Color(0xFF5E5B70))),
                const SizedBox(height: 8),
                Text(progress.deliveryNote, style: const TextStyle(fontSize: 12, color: Color(0xFF5E5B70))),
                if (progress.muatMasukPhotoBase64 == null && progress.muatKeluarPhotoBase64 == null) ...[
                  const SizedBox(height: 16),
                  const Text('Belum ada bukti muat yang tersimpan untuk pengiriman ini.', style: TextStyle(fontSize: 12, color: Color(0xFF8D88A3))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 2, session: session),
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
                          const Text('Pelacakan Pengiriman', style: TextStyle(color: Color(0xFF6B6780), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(shipment.shipmentNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF20202D))),
                        ],
                      ),
                    ),
                    _StatusChip(label: shipment.statusLabel, foreground: shipment.statusColor, background: shipment.statusBackground),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                _KeyValue(label: 'Asal', value: shipment.origin),
                const SizedBox(height: 12),
                _KeyValue(label: 'Tujuan', value: shipment.destination),
                const SizedBox(height: 12),
                _KeyValue(label: 'Jadwal', value: shipment.scheduleLabel),
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
                const Text('Riwayat Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
                const SizedBox(height: 14),
                _TimelineStep(active: true, title: 'Pemuatan Dimulai', subtitle: 'Gudang Alpha - Dermaga 4', icon: Icons.local_shipping_outlined),
                _TimelineStep(active: true, title: 'Berangkat', subtitle: 'Koridor Jakarta - Bekasi', icon: Icons.route_rounded),
                _TimelineStep(active: false, title: 'Tiba', subtitle: 'Menunggu konfirmasi', icon: Icons.flag_outlined),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Lihat di Peta
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TransportirMapTrackingPage(shipment: shipment, session: session),
                ),
              ),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Lihat di Peta', style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TransportirSuratJalanPage(shipment: shipment, session: session),
                      ),
                    ),
                    icon: const Icon(Icons.description_outlined, size: 18),
                    label: const Text('Surat Jalan', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryPurple,
                      side: const BorderSide(color: primaryPurple),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TransportirShipmentProofPage(shipment: shipment, session: session),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Bukti Muat', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: primaryPurple,
                      side: const BorderSide(color: primaryPurple),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 2, session: session),
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
        title: const Text('Bukti Pemuatan', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w800)),
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
                                          _InfoLine(icon: Icons.location_on_outlined, label: 'LOKASI', value: 'Gudang Alpha - Dermaga 4'),
                                          Divider(height: 18, color: Colors.white12),
                                          _InfoLine(icon: Icons.gps_fixed_outlined, label: 'KOORDINAT GPS', value: '-6.2088° S, 106.8456° E'),
                                          Divider(height: 18, color: Colors.white12),
                                          _InfoLine(icon: Icons.access_time_rounded, label: 'WAKTU', value: '24 Okt 2023, 14.32.05 WIB'),
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
                    label: 'Ulangi',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur pengulangan sedang disiapkan.'))),
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
                    label: 'Konfirmasi',
                    filled: true,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan dikonfirmasi.'))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 2, session: session),
    );
  }
}

class ShipmentProgress {
  ShipmentProgress({
    required this.shipmentNumber,
    this.muatMasukCompleted = false,
    this.muatKeluarCompleted = false,
    this.muatMasukPhotoBase64,
    this.muatKeluarPhotoBase64,
    this.statusDetail = 'Menunggu proses muat',
    this.deliveryNote = 'Detail pengiriman akan muncul di sini.',
  });

  final String shipmentNumber;
  final bool muatMasukCompleted;
  final bool muatKeluarCompleted;
  final String? muatMasukPhotoBase64;
  final String? muatKeluarPhotoBase64;
  final String statusDetail;
  final String deliveryNote;

  bool get completed => muatKeluarCompleted;

  ShipmentProgress copyWith({
    bool? muatMasukCompleted,
    bool? muatKeluarCompleted,
    String? muatMasukPhotoBase64,
    String? muatKeluarPhotoBase64,
    String? statusDetail,
    String? deliveryNote,
  }) {
    return ShipmentProgress(
      shipmentNumber: shipmentNumber,
      muatMasukCompleted: muatMasukCompleted ?? this.muatMasukCompleted,
      muatKeluarCompleted: muatKeluarCompleted ?? this.muatKeluarCompleted,
      muatMasukPhotoBase64: muatMasukPhotoBase64 ?? this.muatMasukPhotoBase64,
      muatKeluarPhotoBase64: muatKeluarPhotoBase64 ?? this.muatKeluarPhotoBase64,
      statusDetail: statusDetail ?? this.statusDetail,
      deliveryNote: deliveryNote ?? this.deliveryNote,
    );
  }

  Map<String, dynamic> toJson() => {
        'shipmentNumber': shipmentNumber,
        'muatMasukCompleted': muatMasukCompleted,
        'muatKeluarCompleted': muatKeluarCompleted,
        'muatMasukPhotoBase64': muatMasukPhotoBase64,
        'muatKeluarPhotoBase64': muatKeluarPhotoBase64,
        'statusDetail': statusDetail,
        'deliveryNote': deliveryNote,
      };

  factory ShipmentProgress.fromJson(Map<String, dynamic> json) => ShipmentProgress(
        shipmentNumber: json['shipmentNumber'] as String,
        muatMasukCompleted: json['muatMasukCompleted'] as bool? ?? false,
        muatKeluarCompleted: json['muatKeluarCompleted'] as bool? ?? false,
        muatMasukPhotoBase64: json['muatMasukPhotoBase64'] as String?,
        muatKeluarPhotoBase64: json['muatKeluarPhotoBase64'] as String?,
        statusDetail: json['statusDetail'] as String? ?? 'Menunggu proses muat',
        deliveryNote: json['deliveryNote'] as String? ?? 'Detail pengiriman akan muncul di sini.',
      );
}

class TransportirMuatResult {
  TransportirMuatResult({
    required this.muatType,
    required this.photoBase64,
    required this.timestamp,
  });

  final String muatType;
  final String photoBase64;
  final DateTime timestamp;
}

Future<ShipmentProgress> loadShipmentProgress(String shipmentNumber) async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('shipment_progress_$shipmentNumber');
  if (stored == null) {
    return ShipmentProgress(shipmentNumber: shipmentNumber);
  }
  try {
    final map = jsonDecode(stored) as Map<String, dynamic>;
    return ShipmentProgress.fromJson(map);
  } catch (_) {
    return ShipmentProgress(shipmentNumber: shipmentNumber);
  }
}

Future<void> saveShipmentProgress(ShipmentProgress progress) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('shipment_progress_${progress.shipmentNumber}', jsonEncode(progress.toJson()));
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
  const _ShipmentSummaryCard({
    required this.shipment,
    required this.session,
    required this.progress,
    required this.onProgressUpdated,
    required this.onTap,
  });

  final TransportirShipmentCardData shipment;
  final AuthSession? session;
  final ShipmentProgress progress;
  final ValueChanged<ShipmentProgress> onProgressUpdated;
  final VoidCallback onTap;

  bool get muatMasukDone => progress.muatMasukCompleted;
  bool get muatKeluarDone => progress.muatKeluarCompleted;
  bool get completed => progress.completed;

  String get _primaryLabel {
    if (!muatMasukDone && shipment.actionPrimaryLabel == 'Muat Masuk') return 'Muat Masuk';
    return 'Lacak';
  }

  bool get _showSecondary => !completed && (muatMasukDone || shipment.actionSecondaryKind != TransportirShipmentActionKind.none);

  String get _secondaryLabel => muatMasukDone ? 'Muat Keluar' : shipment.actionSecondaryLabel;

  String get _statusLabel {
    if (completed) return 'Selesai';
    if (muatMasukDone) return 'Dalam Perjalanan';
    return shipment.statusLabel;
  }

  Color get _statusColor {
    if (completed) return const Color(0xFF16C38A);
    if (muatMasukDone) return const Color(0xFFB86B22);
    return shipment.statusColor;
  }

  Color get _statusBg {
    if (completed) return const Color(0xFFD5F3E2);
    if (muatMasukDone) return const Color(0xFFF4E0CB);
    return shipment.statusBackground;
  }

  @override
  Widget build(BuildContext context) {
    final faded = completed;
    final titleColor = faded ? Colors.grey.shade500 : const Color(0xFF20202D);
    final bodyColor = faded ? Colors.grey.shade400 : const Color(0xFF9A93AC);
    final subTitleColor = faded ? Colors.grey.shade500 : const Color(0xFF2A2740);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
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
                              _StatusChip(label: _statusLabel, foreground: _statusColor, background: _statusBg),
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
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: titleColor, decoration: faded ? TextDecoration.lineThrough : TextDecoration.none),
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
              if (muatMasukDone || muatKeluarDone) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F6FD),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detail Muat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.grey.shade800)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _DetailStatusChip(label: 'Muat Masuk', active: muatMasukDone),
                            _DetailStatusChip(label: 'Muat Keluar', active: muatKeluarDone),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(progress.statusDetail, style: const TextStyle(fontSize: 12, color: Color(0xFF5E5B70))),
                        const SizedBox(height: 6),
                        Text(progress.deliveryNote, style: const TextStyle(fontSize: 12, color: Color(0xFF5E5B70))),
                        if (progress.muatMasukPhotoBase64 != null || progress.muatKeluarPhotoBase64 != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (progress.muatMasukPhotoBase64 != null) _PhotoPreview(label: 'Masuk', photoBase64: progress.muatMasukPhotoBase64!),
                              if (progress.muatMasukPhotoBase64 != null && progress.muatKeluarPhotoBase64 != null) const SizedBox(width: 10),
                              if (progress.muatKeluarPhotoBase64 != null) _PhotoPreview(label: 'Keluar', photoBase64: progress.muatKeluarPhotoBase64!),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: _primaryLabel,
                        primary: true,
                        onTap: () => _handlePrimary(context),
                      ),
                    ),
                    if (_showSecondary) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ActionButton(
                          label: _secondaryLabel,
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
        ),
      ),
    );
  }

  Future<void> _handlePrimary(BuildContext context) async {
    if (_primaryLabel == 'Lacak') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TransportirMapTrackingPage(shipment: shipment, session: session),
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<TransportirMuatResult?>(
      MaterialPageRoute<TransportirMuatResult?>(
        builder: (_) => TransportirMuatKameraPage(muatType: 'masuk', shipment: shipment, session: session),
      ),
    );

    if (result != null && result.muatType == 'masuk') {
      final updated = progress.copyWith(
        muatMasukCompleted: true,
        muatMasukPhotoBase64: result.photoBase64,
        statusDetail: 'Foto muat masuk berhasil disimpan.',
        deliveryNote: 'Kendaraan meninggalkan gudang menuju tujuan.',
      );
      onProgressUpdated(updated);
    }
  }

  Future<void> _handleSecondary(BuildContext context) async {
    if (completed) return;

    if (muatMasukDone || shipment.actionSecondaryKind == TransportirShipmentActionKind.loadOut) {
      final result = await Navigator.of(context).push<TransportirMuatResult?>(
        MaterialPageRoute<TransportirMuatResult?>(
          builder: (_) => TransportirMuatKameraPage(muatType: 'keluar', shipment: shipment, session: session),
        ),
      );
      if (result != null && result.muatType == 'keluar') {
        final updated = progress.copyWith(
          muatKeluarCompleted: true,
          muatKeluarPhotoBase64: result.photoBase64,
          statusDetail: 'Pesanan selesai dan foto muat keluar tersimpan.',
          deliveryNote: 'Surat jalan dan bukti muat keluar telah diarsipkan.',
        );
        onProgressUpdated(updated);
      }
      return;
    }

    if (shipment.actionSecondaryKind == TransportirShipmentActionKind.proof) {
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => TransportirShipmentProofPage(shipment: shipment, session: session)),
        );
      }
    }
  }

}

class _DetailStatusChip extends StatelessWidget {
  const _DetailStatusChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDDEBFF) : const Color(0xFFF4F4F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.check_circle : Icons.info_outline, size: 14, color: active ? const Color(0xFF3B309E) : const Color(0xFF7A7490)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: active ? const Color(0xFF3B309E) : const Color(0xFF7A7490), fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.label, required this.photoBase64});

  final String label;
  final String photoBase64;

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(photoBase64);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5E5B70))),
      ],
    );
  }
}

class _DetailImageCard extends StatelessWidget {
  const _DetailImageCard({this.photoBase64, required this.label});

  final String? photoBase64;
  final String label;

  @override
  Widget build(BuildContext context) {
    final hasImage = photoBase64 != null && photoBase64!.isNotEmpty;
    final Uint8List? bytes = hasImage ? base64Decode(photoBase64!) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E0EA)),
            color: const Color(0xFFF7F4FB),
            image: hasImage ? DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover) : null,
          ),
          child: !hasImage
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.photo_camera_outlined, color: Color(0xFF9A93AC), size: 36),
                      SizedBox(height: 8),
                      Text('Belum ada foto', style: TextStyle(color: Color(0xFF9A93AC), fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                )
              : null,
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF5E5B70))),
      ],
    );
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

// ────────────────────────────────────────────────────────────
// Surat Jalan Page
// ────────────────────────────────────────────────────────────

class TransportirSuratJalanPage extends StatelessWidget {
  const TransportirSuratJalanPage({super.key, required this.shipment, this.session});

  final TransportirShipmentCardData shipment;
  final AuthSession? session;

  static const _primaryPurple = Color(0xFF3B309E);

  @override
  Widget build(BuildContext context) {
    final sjNumber = shipment.shipmentNumber;
    final now = DateTime.now();
    final tanggal =
        '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF0EDF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _primaryPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Surat Jalan', style: TextStyle(color: _primaryPurple, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: _primaryPurple),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Fitur berbagi sedang disiapkan.')),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _SuratJalanDocument(
          sjNumber: sjNumber,
          tanggal: tanggal,
          shipment: shipment,
          session: session,
        ),
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 2, session: session),
    );
  }
}

class _SuratJalanDocument extends StatelessWidget {
  const _SuratJalanDocument({
    required this.sjNumber,
    required this.tanggal,
    required this.shipment,
    this.session,
  });

  final String sjNumber;
  final String tanggal;
  final TransportirShipmentCardData shipment;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD0C8E8)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(sjNumber, tanggal),
          const Divider(height: 1, thickness: 1.5),
          _buildMeta(),
          const Divider(height: 1, thickness: 1.5),
          _buildFooter(sjNumber),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
                      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildHeader(String sjNumber, String tanggal) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo and company header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset('gcs.png', width: 120, height: 120, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(color: const Color(0xFF3B309E), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.business, color: Colors.white, size: 56),
                    )),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PT. GRESIK CIPTA SEJAHTERA',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
                    const SizedBox(height: 6),
                    const Text('Jl. KIG Raya Selatan Blok A5 - Gresik',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF5A5670))),
                    const SizedBox(height: 3),
                    const Text('Telp. (031) 3985543, 3984822, 3973239',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF5A5670))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('No. Dokumen', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF5A5670))),
                  Text(sjNumber.replaceFirst('SJ-', ''),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 1.5, color: Color(0xFFE0DDF0)),
          const SizedBox(height: 18),
          const Text('SURAT PENGANTAR',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.3, color: Color(0xFF17203A))),
          const Text('Surat Jalan Pengiriman Barang',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF7A7490))),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetaRow(label: 'Tanggal Pengiriman', value: _formatDate(tanggal)),
                    const SizedBox(height: 8),
                    _MetaRow(label: 'No. Polisi Kendaraan', value: session?.policeNumber ?? 'N 9456 UU'),
                    const SizedBox(height: 8),
                    _MetaRow(label: 'Barang Dari', value: 'PETROKIMIA GRESIK, PT'),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pengiriman kepada Yth.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7A7490))),
                  Text(shipment.destination.split(',').first,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 180,
                    child: Text(shipment.destination,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF5A5670), height: 1.5)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeta() {
    return Table(
      border: const TableBorder(
        top: BorderSide(width: 1.5),
        bottom: BorderSide(width: 1.5),
        verticalInside: BorderSide(color: Color(0xFFD0C8E8)),
      ),
      columnWidths: const {
        0: FixedColumnWidth(28),
        1: FlexColumnWidth(3),
        2: FixedColumnWidth(60),
        3: FixedColumnWidth(60),
      },
      children: [
        _tableHeaderRow(['NO', 'URAIAN BARANG', 'JUMLAH', 'SATUAN']),
        _tableDataRow(['1', 'PHONSKA DO. 3101490463PH / BA.1', '1,00', 'TON']),
      ],
    );
  }

  TableRow _tableHeaderRow(List<String> cells) {
    return TableRow(
      decoration: const BoxDecoration(color: Color(0xFFF4F0FF)),
      children: cells.map((c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Text(c, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF3B309E))),
      )).toList(),
    );
  }

  TableRow _tableDataRow(List<String> cells) {
    return TableRow(
      children: cells.map((c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Text(c, style: const TextStyle(fontSize: 12, color: Color(0xFF17203A))),
      )).toList(),
    );
  }

  Widget _buildFooter(String sjNumber) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery note
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dikirim ke alamat tersebut untuk memenuhi permintaan',
                        style: TextStyle(fontSize: 11, color: Color(0xFF5A5670))),
                    const SizedBox(height: 6),
                    Text('Pemilik : ${shipment.destination.split(',').first}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF17203A))),
                    const SizedBox(height: 2),
                    const Text('Telp   : 081334045678',
                        style: TextStyle(fontSize: 12, color: Color(0xFF17203A))),
                    const SizedBox(height: 8),
                    const Text('GP : GPP PAKISAJI - PG',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF17203A))),
                  ],
                ),
              ),
              // QR Code
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFF3B309E), width: 2),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 8, offset: Offset(0, 3))],
                    ),
                    child: QrImageView(
                      data: sjNumber,
                      version: QrVersions.auto,
                      size: 110,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF3B309E),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1C1B33),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0EDFF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sjNumber,
                      style: const TextStyle(fontSize: 9, color: Color(0xFF3B309E), fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text('Scan untuk konfirmasi', style: TextStyle(fontSize: 8, color: Color(0xFF9A93AC))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Terbilang
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD0C8E8)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Terbilang :', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF17203A))),
                SizedBox(height: 2),
                Text('# Satu Juta Enam Ratus Sembilan Puluh Lima Ribu Tujuh Ratus Enam Puluh Rupiah #',
                    style: TextStyle(fontSize: 10, color: Color(0xFF5A5670))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Catatan
          const Text('Catatan :', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF17203A))),
          const SizedBox(height: 4),
          ...const [
            '1. Dilarang menjual di atas HET, sesuai SK mentan.',
            '2. Dilarang menjual antar kios, industri, dan di luar peruntukannya.',
            '3. Harap menyimpan surat pengantar ini sebagai arsip.',
            '4. Surat pengantar ini sebagai Nota Penjualan.',
          ].map((note) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(note, style: const TextStyle(fontSize: 10, color: Color(0xFF5A5670))),
          )),
          const SizedBox(height: 16),
          // Tanda Tangan
          Row(
            children: [
              _TandaTangan(label: 'Penerima'),
              _TandaTangan(label: 'Tanda Tangan,\nSopir/Pembawa',
                  name: session?.transportirName ?? session?.displayName ?? 'NANANG'),
              _TandaTangan(label: 'Pengirim'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7A7490))),
        ),
        const Text(': ', style: TextStyle(fontSize: 12, color: Color(0xFF7A7490))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF17203A)))),
      ],
    );
  }
}

class _TandaTangan extends StatelessWidget {
  const _TandaTangan({required this.label, this.name});

  final String label;
  final String? name;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFF5A5670))),
          const SizedBox(height: 44),
          if (name != null)
            Text(name!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline, color: Color(0xFF17203A))),
          if (name == null)
            Container(height: 1, color: const Color(0xFFD0C8E8)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Muat Kamera Page  (Muat Masuk / Muat Keluar)
// ═══════════════════════════════════════════════════════════════

class TransportirMuatKameraPage extends StatefulWidget {
  const TransportirMuatKameraPage({
    super.key,
    required this.muatType,
    required this.shipment,
    this.session,
  });

  final String muatType; // 'masuk' or 'keluar'
  final TransportirShipmentCardData shipment;
  final AuthSession? session;

  @override
  State<TransportirMuatKameraPage> createState() => _TransportirMuatKameraPageState();
}

class _TransportirMuatKameraPageState extends State<TransportirMuatKameraPage> {
  static const Color _primary = AppTheme.primary;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _photoBytes;
  bool _isStarting = true;
  bool _isProcessing = false;
  String? _cameraError;

  String get _title => widget.muatType == 'masuk' ? 'Muat Masuk' : 'Muat Keluar';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickCameraImage();
    });
  }

  Future<void> _pickCameraImage() async {
    if (!mounted) return;
    setState(() {
      _isStarting = true;
      _cameraError = null;
    });

    try {
      final photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (!mounted) return;

      if (photo == null) {
        setState(() {
          _cameraError = 'Foto dibatalkan. Silakan coba lagi.';
          _isStarting = false;
        });
        return;
      }

      final bytes = await photo.readAsBytes();
      if (!mounted) return;

      setState(() {
        _photoBytes = bytes;
        _cameraError = null;
        _isStarting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'Gagal membuka kamera: $error';
        _isStarting = false;
      });
    }
  }

  Future<void> _confirm() async {
    if (_photoBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ambil foto terlebih dahulu.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_title berhasil disimpan!'),
        backgroundColor: const Color(0xFF16C38A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    final payload = TransportirMuatResult(
      muatType: widget.muatType,
      photoBase64: base64Encode(_photoBytes!),
      timestamp: DateTime.now(),
    );
    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF3B309E)),
              const SizedBox(height: 20),
              Text(
                'Membuka kamera...',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _primary),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(_title, style: const TextStyle(color: _primary, fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _cameraError != null
                    ? _buildCameraError(_cameraError!)
                    : Container(
                        color: const Color(0xFF1A1B30),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _photoBytes != null
                                ? Image.memory(_photoBytes!, key: const ValueKey('photoPreview'), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
                                : Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.camera_alt_outlined, color: Colors.white70, size: 68),
                                      SizedBox(height: 16),
                                      Text('Mengambil foto...', style: TextStyle(color: Colors.white70, fontSize: 16)),
                                    ],
                                  ),
                        ),
                      ),
              ),
            ),
          ),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildCameraError(String message) {
    return Container(
      color: const Color(0xFF1A1B30),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_photography_outlined, color: Colors.white38, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Kamera tidak dapat dibuka',
                style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _retryCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B309E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Coba lagi', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final now = DateTime.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4D0E3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFEBE8F8), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt_outlined, color: _primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.shipment.shipmentNumber,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
                    const SizedBox(height: 2),
                    Text('${widget.shipment.origin} → ${widget.shipment.destination}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF7A7490))),
                  ],
                ),
              ),
              Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF7A7490), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: _isProcessing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isProcessing ? 'Menyimpan...' : 'Konfirmasi',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Map Tracking Page  (Shopee-style route view)
// ═══════════════════════════════════════════════════════════════

class TransportirMapTrackingPage extends StatefulWidget {
  const TransportirMapTrackingPage({super.key, required this.shipment, this.session});

  final TransportirShipmentCardData shipment;
  final AuthSession? session;

  @override
  State<TransportirMapTrackingPage> createState() => _TransportirMapTrackingPageState();
}

class _TransportirMapTrackingPageState extends State<TransportirMapTrackingPage>
    with TickerProviderStateMixin {
  static const Color _primary = Color(0xFF3B309E);

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _openMaps() async {
    final origin = Uri.encodeComponent(widget.shipment.origin);
    final dest = Uri.encodeComponent(widget.shipment.destination);
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF131E30),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pelacakan Rute', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white70),
            onPressed: _openMaps,
            tooltip: 'Buka di Maps',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Map area ──
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, __) => CustomPaint(
                    painter: _MapRoutePainter(pulseScale: _pulseAnim.value),
                  ),
                ),
                // Origin chip
                Positioned(
                  top: 14,
                  left: 14,
                  child: _MapChip(
                    icon: Icons.radio_button_checked,
                    color: const Color(0xFF16C38A),
                    label: widget.shipment.origin,
                  ),
                ),
                // Destination chip
                Positioned(
                  top: 14,
                  right: 14,
                  child: _MapChip(
                    icon: Icons.location_on,
                    color: const Color(0xFFFF5050),
                    label: widget.shipment.destination,
                    alignRight: true,
                  ),
                ),
                // ETA card
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xDD131E30),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _EtaCell(icon: Icons.access_time_rounded, label: 'ETA', value: '14.30 WIB'),
                        _EtaDivider(),
                        _EtaCell(icon: Icons.straighten_rounded, label: 'Jarak', value: '32 km'),
                        _EtaDivider(),
                        _EtaCell(icon: Icons.speed_rounded, label: 'Kecepatan', value: '65 km/h'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Info + timeline ──
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                children: [
                  // Route summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F0FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFD8D3EA)),
                    ),
                    child: Column(
                      children: [
                        _RouteRow(
                          icon: Icons.radio_button_checked,
                          iconColor: const Color(0xFF16C38A),
                          label: 'Asal',
                          value: widget.shipment.origin,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Column(
                            children: List.generate(
                              3,
                              (_) => Container(
                                width: 2, height: 5,
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                color: const Color(0xFFCCC7E0),
                              ),
                            ),
                          ),
                        ),
                        _RouteRow(
                          icon: Icons.location_on,
                          iconColor: const Color(0xFFFF5050),
                          label: 'Tujuan',
                          value: widget.shipment.destination,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status timeline
                  const Text('Status Pengiriman',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
                  const SizedBox(height: 12),
                  _TimelineStep(active: true, title: 'Pemuatan Dimulai', subtitle: '09.00 WIB · Gudang Utama', icon: Icons.inventory_2_outlined),
                  _TimelineStep(active: true, title: 'Dalam Perjalanan', subtitle: '10.15 WIB · Koridor Jalan Raya', icon: Icons.local_shipping_outlined),
                  _TimelineStep(active: false, title: 'Tiba di Tujuan', subtitle: 'Estimasi ${widget.shipment.scheduleLabel}', icon: Icons.flag_outlined),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _openMaps,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Buka di Google Maps', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
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

// ── Map route painter ─────────────────────────────────────────

class _MapRoutePainter extends CustomPainter {
  const _MapRoutePainter({required this.pulseScale});
  final double pulseScale;

  static const _progress = 0.45; // truck at 45% of route

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0F1929));

    // Street grid (faint)
    final gridPaint = Paint()
      ..color = const Color(0xFF1A2A3A)
      ..strokeWidth = 1;
    for (double x = 0; x < w; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = 0; y < h; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Major roads
    final roadPaint = Paint()
      ..color = const Color(0xFF1E3048)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, h * 0.38), Offset(w, h * 0.38), roadPaint);
    canvas.drawLine(Offset(w * 0.55, 0), Offset(w * 0.55, h), roadPaint);
    canvas.drawLine(Offset(0, h * 0.72), Offset(w, h * 0.72), roadPaint);
    canvas.drawLine(Offset(w * 0.22, 0), Offset(w * 0.22, h), roadPaint);

    // Bezier route definition
    final p0 = Offset(w * 0.08, h * 0.82);   // origin
    final c1 = Offset(w * 0.28, h * 0.75);
    final c2 = Offset(w * 0.45, h * 0.38);
    final p3 = Offset(w * 0.92, h * 0.15);   // destination

    // Shadow under route
    final shadowPath = Path()
      ..moveTo(p0.dx, p0.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p3.dx, p3.dy);
    canvas.drawPath(shadowPath, Paint()
      ..color = const Color(0x443B309E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Travelled portion (solid bright)
    final travelledPt = _cubic(p0, c1, c2, p3, _progress);
    canvas.drawPath(
      _partialCubicPath(p0, c1, c2, p3, 0, _progress),
      Paint()
        ..color = const Color(0xFF534AB7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // Remaining portion (dashed grey)
    _drawDashedPath(canvas, p0, c1, c2, p3, _progress, 1.0,
        Paint()
          ..color = const Color(0xFF3A4A5E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);

    // Origin circle
    canvas.drawCircle(p0, 10, Paint()..color = const Color(0xFF16C38A));
    canvas.drawCircle(p0, 6, Paint()..color = Colors.white);

    // Destination pin
    canvas.drawCircle(p3, 10, Paint()..color = const Color(0xFFFF5050));
    canvas.drawCircle(p3, 5, Paint()..color = Colors.white);

    // Truck pulse ring
    canvas.drawCircle(
      travelledPt,
      18 * pulseScale,
      Paint()..color = const Color(0x554A3AFF),
    );
    // Truck body
    canvas.drawCircle(travelledPt, 12, Paint()..color = const Color(0xFF4A3AFF));
    // Truck icon (small white circle inside)
    canvas.drawCircle(travelledPt, 6, Paint()..color = Colors.white.withValues(alpha: 0.9));
  }

  Offset _cubic(Offset p0, Offset c1, Offset c2, Offset p3, double t) {
    final mt = 1 - t;
    return Offset(
      mt * mt * mt * p0.dx + 3 * mt * mt * t * c1.dx + 3 * mt * t * t * c2.dx + t * t * t * p3.dx,
      mt * mt * mt * p0.dy + 3 * mt * mt * t * c1.dy + 3 * mt * t * t * c2.dy + t * t * t * p3.dy,
    );
  }

  Path _partialCubicPath(Offset p0, Offset c1, Offset c2, Offset p3, double from, double to) {
    const steps = 40;
    final path = Path();
    for (int i = 0; i <= steps; i++) {
      final t = from + (to - from) * i / steps;
      final pt = _cubic(p0, c1, c2, p3, t);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    return path;
  }

  void _drawDashedPath(Canvas canvas, Offset p0, Offset c1, Offset c2, Offset p3,
      double from, double to, Paint paint) {
    const steps = 60;
    const dashLen = 8.0;
    const gapLen = 6.0;
    double accumulated = 0;
    bool drawing = true;

    for (int i = 0; i < steps; i++) {
      final t0 = from + (to - from) * i / steps;
      final t1 = from + (to - from) * (i + 1) / steps;
      final a = _cubic(p0, c1, c2, p3, t0);
      final b = _cubic(p0, c1, c2, p3, t1);
      final segLen = math.sqrt(math.pow(b.dx - a.dx, 2) + math.pow(b.dy - a.dy, 2));
      accumulated += segLen;
      if (drawing) {
        canvas.drawLine(a, b, paint);
        if (accumulated >= dashLen) {
          accumulated = 0;
          drawing = false;
        }
      } else {
        if (accumulated >= gapLen) {
          accumulated = 0;
          drawing = true;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapRoutePainter old) => old.pulseScale != pulseScale;
}

// ── Map helper widgets ────────────────────────────────────────

class _MapChip extends StatelessWidget {
  const _MapChip({required this.icon, required this.color, required this.label, this.alignRight = false});

  final IconData icon;
  final Color color;
  final String label;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xDD131E30),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EtaCell extends StatelessWidget {
  const _EtaCell({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF534AB7), size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }
}

class _EtaDivider extends StatelessWidget {
  const _EtaDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: Colors.white12);
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.icon, required this.iconColor, required this.label, required this.value});

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9A93AC))),
              Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF17203A))),
            ],
          ),
        ),
      ],
    );
  }
}
