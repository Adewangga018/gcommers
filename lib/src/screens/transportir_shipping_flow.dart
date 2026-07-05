import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/auth_models.dart';
import '../models/commerce_models.dart';
import '../services/commerce_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/transportir_bottom_nav.dart';

class TransportirShipmentsPage extends StatefulWidget {
  const TransportirShipmentsPage({super.key, this.session});
  final AuthSession? session;

  @override
  State<TransportirShipmentsPage> createState() => _TransportirShipmentsPageState();
}

class _TransportirShipmentsPageState extends State<TransportirShipmentsPage> {
  final _service = CommerceService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<List<TransportirShipmentCardData>> _shipmentsFuture;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _shipmentsFuture = _load();
    // Polling ringan agar status load-in/load-out terlihat hampir real-time tanpa
    // websocket (lihat ORDER_FLOW_CONTRACT.md §1.5 — cukup level status, bukan GPS live).
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _refresh().catchError((_) {}));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<TransportirShipmentCardData>> _load() async {
    final email = widget.session?.email;
    if (email == null || email.isEmpty) {
      throw Exception('Sesi berakhir, silakan login ulang.');
    }
    final shipments = await _service.getShipments(transportirEmail: email);
    return shipments.map((s) => TransportirShipmentCardData(shipment: s)).toList();
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _shipmentsFuture = future);
    await future;
  }

  List<TransportirShipmentCardData> _applyFilter(List<TransportirShipmentCardData> all) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return all;
    return all.where((shipment) {
      return shipment.poNumberLabel.toLowerCase().contains(query) ||
          shipment.soCodeLabel.toLowerCase().contains(query) ||
          shipment.origin.toLowerCase().contains(query) ||
          shipment.destination.toLowerCase().contains(query) ||
          shipment.destinationSubtitle.toLowerCase().contains(query);
    }).toList();
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
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/transportir-home', arguments: widget.session),
        ),
        title: Text('GCommers', style: AppTheme.title(size: 18)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<TransportirShipmentCardData>>(
          future: _shipmentsFuture,
          builder: (context, snapshot) {
            final loading = snapshot.connectionState == ConnectionState.waiting;
            final all = snapshot.data ?? const [];
            final visible = _applyFilter(all);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              children: [
                // Page header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daftar Pengiriman',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F261F)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kelola dan pantau status muatan',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFB5D4BC)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0F261F),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none, // Menghilangkan border default TextField
                      hintText: 'Cari nomor pesanan atau SO…',
                      hintStyle: const TextStyle(
                        color: Color(0xFF6B8C73),
                        fontSize: 14,
                      ),
                      contentPadding: EdgeInsets.zero, // Wajib zero agar sejajar dengan icon

                      // Ikon Kiri (Search)
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF6B8C73),
                        size: 22,
                      ),

                      // Ikon Kanan (Clear) - Otomatis hilang jika kosong
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.cancel, // Menggunakan icon cancel bawaan yang sudah membulat
                                color: Color(0xFFB5D4BC),
                                size: 20,
                              ),
                              onPressed: _searchController.clear,
                              splashRadius: 20, // Memperkecil efek sentuhan agar tetap rapi
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (loading)
                  const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator()))
                else if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('Gagal memuat pengiriman: ${snapshot.error}', textAlign: TextAlign.center)),
                  )
                else ...[
                  ...visible.map(
                    (shipment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ShipmentSummaryCard(
                        shipment: shipment,
                        session: widget.session,
                        onRefresh: _refresh,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TransportirShipmentDetailPage(
                                shipment: shipment,
                                session: widget.session,
                              ),
                            ),
                          );
                          _refresh();
                        },
                      ),
                    ),
                  ),
                  if (visible.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.search_off, color: Color(0xFF6B8C73), size: 42),
                          const SizedBox(height: 12),
                          Text(
                            all.isEmpty ? 'Belum ada pengiriman yang ditugaskan.' : 'Tidak ada pengiriman yang cocok.',
                            style: const TextStyle(color: Color(0xFF6B8C73), fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 2, session: widget.session),
    );
  }
}

class TransportirShipmentDetailPage extends StatelessWidget {
  const TransportirShipmentDetailPage({super.key, required this.shipment, this.session});

  final TransportirShipmentCardData shipment;
  final AuthSession? session;

  static const Color _primary = Color(0xFF2F6C3F);

  String get _currentStatusLabel => shipment.statusLabel;
  Color get _currentStatusColor => shipment.statusColor;
  Color get _currentStatusBg => shipment.statusBackground;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPad = screenWidth < 380 ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('Detail Pengiriman',
                style: TextStyle(
                    color: _primary, fontWeight: FontWeight.w800, fontSize: 15)),
            Text(shipment.shipmentNumber,
                style: const TextStyle(color: Color(0xFF6B8C73), fontSize: 11)),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(horizontalPad, 16, horizontalPad, 24),
        children: [
          // ── Info card ──────────────────────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCEDE1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.description_outlined,
                          color: Color(0xFF2F6C3F), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('No. Surat Jalan',
                              style: TextStyle(color: Color(0xFF5E7D66), fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(shipment.shipmentNumber,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F261F))),
                        ],
                      ),
                    ),
                    _StatusChip(
                      label: _currentStatusLabel,
                      foreground: _currentStatusColor,
                      background: _currentStatusBg,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFDEEBE2)),
                const SizedBox(height: 14),
                _infoRow(Icons.warehouse_outlined, 'Asal', shipment.origin),
                const SizedBox(height: 10),
                _infoRow(Icons.store_outlined, 'Tujuan', shipment.destination),
                const SizedBox(height: 10),
                _infoRow(Icons.schedule_rounded, 'Jadwal', shipment.scheduleLabel),
                const SizedBox(height: 10),
                _infoRow(Icons.inventory_2_outlined, 'Produk', shipment.productLabel),
                const SizedBox(height: 10),
                _infoRow(Icons.scale_outlined, 'Tonase', shipment.quotaLabel),
                const SizedBox(height: 10),
                _infoRow(Icons.qr_code_2_outlined, 'Kode SO', shipment.soCodeLabel),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Timeline card ──────────────────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.timeline_rounded, color: _primary, size: 18),
                    SizedBox(width: 8),
                    Text('Status Pengiriman',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F261F))),
                  ],
                ),
                const SizedBox(height: 18),
                _TimelineItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Muat',
                  subtitle: shipment.muatInDone
                      ? 'Foto tersimpan — barang dimuat ke kendaraan'
                      : 'Menunggu proses pemuatan',
                  done: shipment.muatInDone,
                  isLast: false,
                ),
                _TimelineItem(
                  icon: Icons.local_shipping_outlined,
                  title: 'Dalam Perjalanan',
                  subtitle: shipment.muatInDone
                      ? 'Kendaraan berangkat menuju tujuan'
                      : 'Belum dimulai',
                  done: shipment.muatInDone,
                  isLast: false,
                ),
                _TimelineItem(
                  icon: Icons.move_to_inbox_outlined,
                  title: 'Bongkar',
                  subtitle: shipment.muatOutDone
                      ? 'Foto tersimpan — barang tiba di tujuan'
                      : 'Menunggu konfirmasi tiba',
                  done: shipment.muatOutDone,
                  isLast: false,
                ),
                _TimelineItem(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Selesai',
                  subtitle: shipment.completed
                      ? 'Pengiriman berhasil diselesaikan'
                      : 'Estimasi: ${shipment.scheduleLabel}',
                  done: shipment.completed,
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Proof photos card ──────────────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.photo_library_outlined, color: _primary, size: 18),
                    SizedBox(width: 8),
                    Text('Bukti Foto Muat',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F261F))),
                  ],
                ),
                const SizedBox(height: 14),
                // Side-by-side photos on wide screens, stacked on small
                LayoutBuilder(builder: (_, constraints) {
                  final wide = constraints.maxWidth > 320;
                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ProofPhotoSection(
                            label: 'Muat',
                            photoUrl: shipment.shipment.muatInPhotoUrl,
                            done: shipment.muatInDone,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ProofPhotoSection(
                            label: 'Bongkar',
                            photoUrl: shipment.shipment.muatOutPhotoUrl,
                            done: shipment.muatOutDone,
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _ProofPhotoSection(
                        label: 'Muat',
                        photoUrl: shipment.shipment.muatInPhotoUrl,
                        done: shipment.muatInDone,
                      ),
                      const SizedBox(height: 14),
                      _ProofPhotoSection(
                        label: 'Bongkar',
                        photoUrl: shipment.shipment.muatOutPhotoUrl,
                        done: shipment.muatOutDone,
                      ),
                    ],
                  );
                }),
                if (shipment.shipment.note?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFDEEBE2)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_rounded,
                          size: 16, color: Color(0xFF6B8C73)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Keterangan',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF5E7D66))),
                            const SizedBox(height: 4),
                            Text(shipment.shipment.note!,
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF5E7D66))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Action buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 2, session: session),
    );
  }

  // Shared card wrapper
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDEEBE2)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B8C73)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF6B8C73))),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F261F))),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Timeline step with connecting vertical line ────────────────

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.isLast,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool done;
  final bool isLast;

  static const _done = Color(0xFF16C38A);
  static const _pending = Color(0xFFB5D4BC);
  static const _lineActive = Color(0xFF16C38A);
  static const _lineIdle = Color(0xFFDEEBE2);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: indicator + line
        SizedBox(
          width: 36,
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: done ? _done : const Color(0xFFEAF2EC),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done ? _done : _pending,
                    width: done ? 0 : 2,
                  ),
                  boxShadow: done
                      ? const [
                          BoxShadow(
                              color: Color(0x3316C38A), blurRadius: 8)
                        ]
                      : null,
                ),
                child: Icon(icon,
                    size: 16,
                    color: done ? Colors.white : const Color(0xFF6B8C73)),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: done ? _lineActive : _lineIdle,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Right: text
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: done
                              ? const Color(0xFF0F261F)
                              : const Color(0xFF6B8C73),
                        ),
                      ),
                    ),
                    if (done)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD5F3E2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('Selesai',
                            style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF0E8F61),
                                fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: done
                            ? const Color(0xFF5E7D66)
                            : const Color(0xFF6B8C73))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Proof photo section ────────────────────────────────────────

class _ProofPhotoSection extends StatelessWidget {
  const _ProofPhotoSection({
    required this.label,
    required this.photoUrl,
    required this.done,
  });

  final String label;
  final String? photoUrl;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 14,
              color:
                  done ? const Color(0xFF16C38A) : const Color(0xFF6B8C73),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: done
                    ? const Color(0xFF0F261F)
                    : const Color(0xFF6B8C73),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2EC),
              border: Border.all(
                color: done
                    ? const Color(0xFFB8EDD7)
                    : const Color(0xFFDEEBE2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: hasPhoto
                ? Image.network(
                    '${CommerceService().baseUrl}$photoUrl',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.broken_image_outlined : Icons.camera_alt_outlined,
            size: 32,
            color: const Color(0xFF6B8C73),
          ),
          const SizedBox(height: 6),
          Text(
            done ? 'Foto tidak dapat dimuat' : 'Belum ada foto',
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF6B8C73)),
          ),
        ],
      ),
    );
  }
}

class TransportirShipmentTrackingPage extends StatelessWidget {
  const TransportirShipmentTrackingPage({super.key, required this.shipment, this.session});

  final TransportirShipmentCardData shipment;
  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF2F6C3F);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
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
              border: Border.all(color: const Color(0xFFB5D4BC)),
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
                          const Text('Pelacakan Pengiriman', style: TextStyle(color: Color(0xFF5E7D66), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(shipment.shipmentNumber, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F261F))),
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
                const SizedBox(height: 12),
                _KeyValue(label: 'Produk', value: shipment.productLabel),
                const SizedBox(height: 12),
                _KeyValue(label: 'Tonase', value: shipment.quotaLabel),
                const SizedBox(height: 12),
                _KeyValue(label: 'Kode SO', value: shipment.soCodeLabel),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFB5D4BC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Riwayat Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F261F))),
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
          SizedBox(
            width: double.infinity,
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
    const Color primaryPurple = Color(0xFF2F6C3F);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
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
                color: Color(0xFFFFFFFF),
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
                      backgroundColor: Color(0xFFB5D4BC),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFFFFFFF),
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

class TransportirShipmentCardData {
  const TransportirShipmentCardData({required this.shipment});

  final ShipmentSummary shipment;

  String get shipmentNumber => shipment.shipmentNumber;
  String get statusLabel => shipment.statusLabel;
  Color get statusColor => _shipmentCardStatusColor(shipment.status);
  Color get statusBackground => _shipmentCardStatusBackground(shipment.status);
  String get scheduleLabel => shortDateTime(shipment.createdAt);
  String get origin => shipment.warehouseName ?? 'Gudang belum ditentukan';
  String get destination => shipment.destinationLabel ?? 'Kios Tujuan';
  String get destinationSubtitle => shipment.destinationAddress ?? '';

  String get productLabel {
    final parts = [shipment.productCode, shipment.productName].whereType<String>().where((s) => s.isNotEmpty);
    return parts.isEmpty ? '-' : parts.join(' · ');
  }

  String get quotaLabel => shipment.quotaTon != null ? '${shipment.quotaTon} Ton' : '-';
  String get soCodeLabel => shipment.soCode ?? 'SO belum tersedia';
  String get poNumberLabel => shipment.poNumber ?? 'Belum ada nomor pesanan';

  /// Precise GPS coordinates — when set the map uses these directly (no geocoding needed).
  LatLng? get originLatLng =>
      shipment.originLat != null && shipment.originLng != null ? LatLng(shipment.originLat!, shipment.originLng!) : null;
  LatLng? get destinationLatLng => shipment.destinationLat != null && shipment.destinationLng != null
      ? LatLng(shipment.destinationLat!, shipment.destinationLng!)
      : null;

  bool get muatInDone => shipment.muatInCompletedAt != null;
  bool get muatOutDone => shipment.muatOutCompletedAt != null;
  bool get completed => shipment.status == 'selesai';
}

Color _shipmentCardStatusColor(String status) => switch (status) {
      'dalam_perjalanan' => const Color(0xFFB86B22),
      'selesai' => const Color(0xFF16C38A),
      _ => const Color(0xFF2F6C3F),
    };

Color _shipmentCardStatusBackground(String status) => switch (status) {
      'dalam_perjalanan' => const Color(0xFFF4E0CB),
      'selesai' => const Color(0xFFD5F3E2),
      _ => const Color(0xFFDCEDE1),
    };

class _ShipmentSummaryCard extends StatelessWidget {
  const _ShipmentSummaryCard({
    required this.shipment,
    required this.session,
    required this.onRefresh,
    required this.onTap,
  });

  final TransportirShipmentCardData shipment;
  final AuthSession? session;
  final Future<void> Function() onRefresh;
  final VoidCallback onTap;

  bool get muatInDone => shipment.muatInDone;
  bool get muatOutDone => shipment.muatOutDone;
  bool get completed => shipment.completed;

  /// Satu tombol aksi kontekstual (fitur Lacak dihapus): 'Muat' sebelum load-in,
  /// 'Bongkar' setelah load-in, dan tidak ada tombol saat sudah selesai.
  String? get _actionLabel {
    if (completed) return null;
    if (!muatInDone) return 'Muat';
    if (!muatOutDone) return 'Bongkar';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final faded = completed;
    final titleColor = faded ? Colors.grey.shade500 : const Color(0xFF0F261F);
    final accent = faded ? Colors.grey.shade500 : const Color(0xFF2F6C3F);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFB5D4BC)),
            boxShadow: const [
              BoxShadow(color: Color(0x0C000000), blurRadius: 14, offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: nomor pesanan + status, lalu kode SO + tanggal ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCEDE1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.receipt_long_rounded, color: accent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NOMOR PESANAN',
                                style: TextStyle(fontSize: 10, letterSpacing: 0.6, fontWeight: FontWeight.w700, color: Colors.grey.shade500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                shipment.poNumberLabel,
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: titleColor),
                              ),
                            ],
                          ),
                        ),
                        _StatusChip(label: shipment.statusLabel, foreground: shipment.statusColor, background: shipment.statusBackground),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _MetaPill(icon: Icons.qr_code_2_rounded, text: shipment.soCodeLabel, faded: faded),
                        const SizedBox(width: 8),
                        _MetaPill(icon: Icons.event_rounded, text: shipment.scheduleLabel, faded: faded),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEAF2EC)),
              // ── Rute + muatan ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: _RouteBlock(
                  origin: shipment.origin,
                  destination: shipment.destinationSubtitle.isNotEmpty ? shipment.destinationSubtitle : shipment.destination,
                  product: shipment.productLabel,
                  quota: shipment.quotaLabel,
                  faded: faded,
                ),
              ),
              // ── Progres muatan: Muat → Bongkar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F8F4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Progres Muatan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade800)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _DetailStatusChip(label: 'Muat', active: muatInDone)),
                          Icon(Icons.arrow_forward_rounded, size: 16, color: muatInDone ? const Color(0xFF2F6C3F) : const Color(0xFFB5D4BC)),
                          Expanded(child: _DetailStatusChip(label: 'Bongkar', active: muatOutDone)),
                        ],
                      ),
                      if (shipment.shipment.muatInPhotoUrl != null || shipment.shipment.muatOutPhotoUrl != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (shipment.shipment.muatInPhotoUrl != null)
                              _PhotoPreview(label: 'Muat', photoUrl: shipment.shipment.muatInPhotoUrl!),
                            if (shipment.shipment.muatInPhotoUrl != null && shipment.shipment.muatOutPhotoUrl != null)
                              const SizedBox(width: 10),
                            if (shipment.shipment.muatOutPhotoUrl != null)
                              _PhotoPreview(label: 'Bongkar', photoUrl: shipment.shipment.muatOutPhotoUrl!),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // ── Aksi kontekstual (tanpa Lacak) ──
              if (_actionLabel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: _ActionButton(
                    label: _actionLabel!,
                    primary: true,
                    onTap: () => _handleAction(context),
                  ),
                )
              else
                const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context) async {
    // muatInDone menentukan langkah berikutnya: belum load-in → foto masuk (Muat),
    // sudah load-in → foto keluar (Bongkar).
    final muatType = muatInDone ? 'keluar' : 'masuk';
    final uploaded = await Navigator.of(context).push<bool?>(
      MaterialPageRoute<bool?>(
        builder: (_) => TransportirMuatKameraPage(muatType: muatType, shipment: shipment, session: session),
      ),
    );
    if (uploaded == true) {
      await onRefresh();
    }
  }
}

/// Pill kecil untuk metadata sekunder (kode SO, tanggal) di kartu pengiriman.
class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.text, this.faded = false});

  final IconData icon;
  final String text;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final fg = faded ? Colors.grey.shade500 : const Color(0xFF3F6B4C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4EE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
        ],
      ),
    );
  }
}

/// Blok rute asal → tujuan bergaya timeline vertikal, plus produk & tonase muatan.
class _RouteBlock extends StatelessWidget {
  const _RouteBlock({
    required this.origin,
    required this.destination,
    required this.product,
    required this.quota,
    required this.faded,
  });

  final String origin;
  final String destination;
  final String product;
  final String quota;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final labelColor = faded ? Colors.grey.shade400 : const Color(0xFF6B8C73);
    final valueColor = faded ? Colors.grey.shade500 : const Color(0xFF0F261F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline rail
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: faded ? Colors.grey.shade400 : const Color(0xFF2F6C3F),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(child: Container(width: 2, color: const Color(0xFFCADFCF))),
                  Icon(Icons.location_on, size: 14, color: faded ? Colors.grey.shade400 : const Color(0xFFB86B22)),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ASAL', style: TextStyle(fontSize: 9, letterSpacing: 0.5, fontWeight: FontWeight.w700, color: labelColor)),
                    const SizedBox(height: 1),
                    Text(origin, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor)),
                    const SizedBox(height: 12),
                    Text('TUJUAN', style: TextStyle(fontSize: 9, letterSpacing: 0.5, fontWeight: FontWeight.w700, color: labelColor)),
                    const SizedBox(height: 1),
                    Text(destination, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: valueColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (product != '-') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 16, color: labelColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  quota != '-' ? '$product · $quota' : product,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor),
                ),
              ),
            ],
          ),
        ],
      ],
    );
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
        color: active ? const Color(0xFFDCEDE1) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.check_circle : Icons.info_outline, size: 14, color: active ? const Color(0xFF2F6C3F) : const Color(0xFF6B8C73)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: active ? const Color(0xFF2F6C3F) : const Color(0xFF6B8C73), fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.label, required this.photoUrl});

  final String label;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage('${CommerceService().baseUrl}$photoUrl'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5E7D66))),
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
    final background = primary ? const Color(0xFF0F261F) : Colors.white;
    final foreground = primary ? Colors.white : const Color(0xFF0F261F);

    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          side: primary ? BorderSide.none : const BorderSide(color: Color(0xFF0F261F)),
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
        Text(label, style: const TextStyle(color: Color(0xFF5E7D66), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F261F))),
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
    final fg = active ? const Color(0xFF2F6C3F) : const Color(0xFF8DB89A);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: active ? const Color(0xFF2F6C3F) : const Color(0xFFD0E8D4), shape: BoxShape.circle),
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
    final fg = filled ? Colors.white : const Color(0xFF5E7D66);
    final bg = filled ? const Color(0xFF2F6C3F) : Colors.transparent;

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
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF5E7D66))),
      ],
    );
  }
}

class _WarehousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = const Color(0xFF2F3342);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45), basePaint);

    final lightPaint = Paint()..color = const Color(0xFF5E7D66);
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

// ═══════════════════════════════════════════════════════════════
// Muat Kamera Page  (embedded in-app camera — Muat Masuk / Keluar)
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

class _TransportirMuatKameraPageState extends State<TransportirMuatKameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Uint8List? _capturedBytes;
  bool _initializing = true;
  bool _isCapturing = false;
  bool _isProcessing = false;
  String? _error;

  String get _title => widget.muatType == 'masuk' ? 'Muat' : 'Bongkar';
  Color get _accentColor =>
      widget.muatType == 'masuk' ? const Color(0xFF16C38A) : const Color(0xFF2F6C3F);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      ctrl.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _capturedBytes == null) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    // Ensure camera permission is granted on iOS/Android.
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          setState(() {
            _error = 'Izin kamera ditolak. Aktifkan permission kamera di pengaturan.';
            _initializing = false;
          });
        }
        return;
      }
    } catch (e) {
      // Continue to attempt camera init; some platforms may not support runtime permission request.
    }

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception('Tidak ada kamera tersedia.');
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      _controller = ctrl;
      setState(() => _initializing = false);
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _initializing = false; });
    }
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final file = await ctrl.takePicture();
      final bytes = await file.readAsBytes();
      if (mounted) setState(() { _capturedBytes = bytes; _isCapturing = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto: $e')),
        );
      }
    }
  }

  void _retake() => setState(() => _capturedBytes = null);

  Future<void> _confirm() async {
    final bytes = _capturedBytes;
    if (bytes == null) return;
    final email = widget.session?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi transportir tidak ditemukan. Silakan login ulang.')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      await CommerceService().uploadShipmentPhoto(
        shipmentNumber: widget.shipment.shipmentNumber,
        muatType: widget.muatType == 'masuk' ? 'load-in' : 'load-out',
        transportirEmail: email,
        photoBytes: bytes,
        fileName: '${widget.shipment.shipmentNumber}-${widget.muatType}.jpg',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_title berhasil disimpan!'),
          backgroundColor: const Color(0xFF16C38A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunggah $_title: $e'),
          backgroundColor: const Color(0xFFEF5350),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildViewport()),
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 16, 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context, null),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  widget.shipment.shipmentNumber,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _accentColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              _title.toUpperCase(),
              style: TextStyle(
                  color: _accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewport() {
    // Show captured photo preview
    if (_capturedBytes != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(_capturedBytes!, fit: BoxFit.cover),
          const CustomPaint(painter: _MuatCornerGuide()),
          // "Preview" badge
          const Positioned(
            top: 12,
            left: 12,
            child: _CameraBadge(label: 'PREVIEW', color: Color(0xFFFFA000)),
          ),
        ],
      );
    }

    // Loading / error states
    if (_initializing) {
      return Container(
        color: const Color(0xFF0D0D14),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF2F6C3F), strokeWidth: 3),
              SizedBox(height: 18),
              Text('Membuka kamera…',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        color: const Color(0xFF0D0D14),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white24, size: 64),
            const SizedBox(height: 18),
            const Text('Kamera tidak dapat dibuka',
                style: TextStyle(
                    color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initCamera,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F6C3F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    // Live camera preview
    final ctrl = _controller!;
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(ctrl),
        const CustomPaint(painter: _MuatCornerGuide()),
        // Live badge
        const Positioned(
          top: 12,
          left: 12,
          child: _CameraBadge(label: '● LIVE', color: Color(0xFF16C38A)),
        ),
        // Capture flash overlay
        if (_isCapturing)
          Container(color: Colors.white.withValues(alpha: 0.3)),
      ],
    );
  }

  Widget _buildControls() {
    if (_capturedBytes != null) {
      // Retake + Confirm
      return Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _retake,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Ulangi', style: TextStyle(fontWeight: FontWeight.w800)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _confirm,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isProcessing ? 'Menyimpan…' : 'Konfirmasi',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16C38A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Shutter button row
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Cancel
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.close_rounded, color: Colors.white54),
            onPressed: () => Navigator.pop(context, null),
          ),
          // Shutter
          GestureDetector(
            onTap: (_initializing || _isCapturing) ? null : _capture,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: _isCapturing ? 50 : 60,
                  height: _isCapturing ? 50 : 60,
                  decoration: BoxDecoration(
                    color: _isCapturing ? Colors.grey.shade400 : Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          // Spacer to balance
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ── Camera helper widgets ─────────────────────────────────────

class _CameraBadge extends StatelessWidget {
  const _CameraBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }
}

class _MuatCornerGuide extends CustomPainter {
  const _MuatCornerGuide();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 28.0;
    const pad = 22.0;
    // top-left
    canvas.drawLine(const Offset(pad, pad + len), const Offset(pad, pad), paint);
    canvas.drawLine(const Offset(pad, pad), const Offset(pad + len, pad), paint);
    // top-right
    canvas.drawLine(Offset(size.width - pad - len, pad), Offset(size.width - pad, pad), paint);
    canvas.drawLine(Offset(size.width - pad, pad), Offset(size.width - pad, pad + len), paint);
    // bottom-left
    canvas.drawLine(
        Offset(pad, size.height - pad - len), Offset(pad, size.height - pad), paint);
    canvas.drawLine(
        Offset(pad, size.height - pad), Offset(pad + len, size.height - pad), paint);
    // bottom-right
    canvas.drawLine(Offset(size.width - pad - len, size.height - pad),
        Offset(size.width - pad, size.height - pad), paint);
    canvas.drawLine(Offset(size.width - pad, size.height - pad),
        Offset(size.width - pad, size.height - pad - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}



// ═══════════════════════════════════════════════════════════════
// Map Tracking Page  (real OSM map with GPS)
// ═══════════════════════════════════════════════════════════════

class TransportirMapTrackingPage extends StatefulWidget {
  const TransportirMapTrackingPage({super.key, required this.shipment, this.session});

  final TransportirShipmentCardData shipment;
  final AuthSession? session;

  @override
  State<TransportirMapTrackingPage> createState() => _TransportirMapTrackingPageState();
}

class _TransportirMapTrackingPageState extends State<TransportirMapTrackingPage> {
  static const Color _primary = Color(0xFF2F6C3F);

  final MapController _mapCtrl = MapController();

  late final LatLng _originCoords;
  late final LatLng _destCoords;

  /// 0 = Gudang (Load In pending)
  /// 1 = Kios  (Load Out pending — truck moved to kiosk after Load In)
  /// 2 = Selesai (Load Out done)
  int _currentStop = 0;
  bool _following = true;
  bool _validating = false;

  LatLng get _truckPos => _currentStop == 0 ? _originCoords : _destCoords;
  /// true once the truck has moved to the kiosk (after Load In)
  bool get _atKios => _currentStop >= 1;
  /// true after Load Out is confirmed — order complete
  bool get _completed => _currentStop >= 2;

  double get _distanceKm =>
      const Distance().as(LengthUnit.Kilometer, _truckPos, _destCoords);

  String get _distLabel {
    final d = _distanceKm;
    if (d < 1) return '${(d * 1000).round()} m';
    return '${d.toStringAsFixed(1)} km';
  }

  String get _etaLabel {
    if (_atKios) return 'Tiba';
    final mins = (_distanceKm / 60 * 60).round();
    if (mins < 60) return '$mins mnt';
    return '${(mins / 60).floor()}j ${mins % 60}m';
  }

  String get _actionLabel {
    if (_currentStop == 0) return 'Muat  –  Konfirmasi di Gudang';
    if (_currentStop == 1) return 'Bongkar  –  Konfirmasi di Kios';
    return 'Pesanan Selesai';
  }

  @override
  void initState() {
    super.initState();
    _originCoords = widget.shipment.originLatLng ?? _coordsFor(widget.shipment.origin);
    _destCoords   = widget.shipment.destinationLatLng ?? _coordsFor(widget.shipment.destination);
  }

  static LatLng _coordsFor(String location) {
    final l = location.toLowerCase();
    if (l.contains('gresik') || l.contains('kig')) return const LatLng(-7.1400, 112.6300);
    if (l.contains('surabaya'))                    return const LatLng(-7.2600, 112.7500);
    if (l.contains('jakarta') || l.contains('gudang utama')) return const LatLng(-6.2088, 106.8456);
    if (l.contains('bekasi')  || l.contains('perakitan'))    return const LatLng(-6.2456, 106.9824);
    if (l.contains('bandung'))                     return const LatLng(-6.9175, 107.6191);
    if (l.contains('semarang'))                    return const LatLng(-6.9667, 110.4167);
    return const LatLng(-7.1400, 112.6300);
  }

  // ── GPS proximity → Load In / Load Out ───────────────────────────────────

  Future<void> _advanceCheckpoint() async {
    if (_atKios || _validating) return;
    setState(() => _validating = true);

    final target = _currentStop == 0 ? _originCoords : _destCoords;
    final name   = _currentStop == 0 ? 'Gudang' : 'Kios Tujuan';

    final ok = await _checkProximity(target, name);
    if (!ok || !mounted) {
      setState(() => _validating = false);
      return;
    }

    setState(() {
      _validating = false;
      _currentStop = 1;
    });
    if (_following) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (mounted) _mapCtrl.move(_truckPos, _mapCtrl.camera.zoom);
    }
  }

  Future<bool> _checkProximity(LatLng target, String name) async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('GPS tidak tersedia. Konfirmasi di $name diterima.'),
            backgroundColor: const Color(0xFFFFA000),
          ));
        }
        return true;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 8));

      final distM = const Distance().as(
          LengthUnit.Meter, LatLng(pos.latitude, pos.longitude), target);

      if (distM > 500) {
        if (!mounted) return false;
        final bypass = await _showFarDialog(name, distM.round());
        return bypass ?? false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<bool?> _showFarDialog(String name, int distMeters) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: Color(0xFFEF5350)),
            SizedBox(width: 8),
            Text('Lokasi Tidak Sesuai',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Anda berada ${distMeters}m dari $name.\n\n'
          'Harap pastikan kendaraan sudah berada di lokasi yang benar '
          'sebelum mengkonfirmasi.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali',
                style: TextStyle(color: Color(0xFF5E7D66))),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350)),
            child: const Text('Konfirmasi Tetap'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _openGoogleMaps() async {
    final origin = Uri.encodeComponent(widget.shipment.origin);
    final dest = Uri.encodeComponent(widget.shipment.destination);
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&travelmode=driving',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final truck = _truckPos;
    final mapCenter = LatLng(
      (_originCoords.latitude + _destCoords.latitude) / 2,
      (_originCoords.longitude + _destCoords.longitude) / 2,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0C1524),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1524),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('Pelacakan Rute',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            Text(widget.shipment.shipmentNumber,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _following ? Icons.center_focus_strong : Icons.center_focus_weak,
              color: _following ? const Color(0xFF16C38A) : Colors.white54,
            ),
            onPressed: () {
              setState(() => _following = !_following);
              if (_following) _mapCtrl.move(truck, _mapCtrl.camera.zoom);
            },
            tooltip: 'Pusatkan peta',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white70),
            onPressed: _openGoogleMaps,
            tooltip: 'Buka di Google Maps',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats bar (ETA · Jarak · Posisi) ────────────────────────────
          Container(
            color: const Color(0xFF111D2E),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: _MapStatTile(
                    icon: Icons.access_time_rounded,
                    label: 'ETA',
                    value: _atKios ? 'Tiba' : _etaLabel,
                    color: const Color(0xFF2F6C3F),
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.white12),
                Expanded(
                  child: _MapStatTile(
                    icon: Icons.straighten_rounded,
                    label: 'Jarak',
                    value: _atKios ? '0 km' : _distLabel,
                    color: const Color(0xFF2F6C3F),
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.white12),
                Expanded(
                  child: _MapStatTile(
                    icon: Icons.local_shipping_outlined,
                    label: 'Posisi',
                    value: _atKios
                        ? 'Kios'
                        : _currentStop == 0
                            ? 'Gudang'
                            : 'Menuju Kios',
                    color: const Color(0xFFFFA726),
                  ),
                ),
              ],
            ),
          ),
          // ── Map ─────────────────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: 11.0,
                    onPositionChanged: (_, hasGesture) {
                      if (hasGesture && _following) {
                        setState(() => _following = false);
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.gcommers.app',
                      maxNativeZoom: 19,
                    ),
                    // Completed portion (bright)
                    if (_atKios)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_originCoords, _destCoords],
                            color: const Color(0xFF2F6C3F),
                            strokeWidth: 5,
                          ),
                        ],
                      ),
                    // Remaining portion (dimmed)
                    if (!_atKios)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [_originCoords, _destCoords],
                            color: const Color(0x772F6C3F),
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // Origin (Gudang)
                        Marker(
                          point: _originCoords,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _currentStop > 0
                                  ? const Color(0xFF16C38A)
                                  : const Color(0xFF16C38A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(color: Color(0x6616C38A), blurRadius: 10),
                              ],
                            ),
                            child: const Icon(Icons.warehouse,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        // Destination (Kios)
                        Marker(
                          point: _destCoords,
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _atKios
                                  ? const Color(0xFF16C38A)
                                  : const Color(0xFFFF5050),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(color: Color(0x66FF5050), blurRadius: 10),
                              ],
                            ),
                            child: Icon(
                              _atKios ? Icons.check : Icons.store,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        // Truck at current stop
                        Marker(
                          point: truck,
                          width: 52,
                          height: 52,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _atKios ? const Color(0xFF16C38A) : _primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [
                                BoxShadow(color: Color(0x992F6C3F), blurRadius: 16),
                              ],
                            ),
                            child: Icon(
                              _atKios
                                  ? Icons.check_rounded
                                  : Icons.local_shipping,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Status badge top-left
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.93),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFB5D4BC)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x22000000), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _atKios
                                ? const Color(0xFF16C38A)
                                : _currentStop == 0
                                    ? const Color(0xFF2F6C3F)
                                    : const Color(0xFFFFA000),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _atKios
                              ? 'Tiba di Kios'
                              : _currentStop == 0
                                  ? 'Di Gudang – menunggu Muat'
                                  : 'Dalam Perjalanan ke Kios',
                          style: const TextStyle(
                              color: Color(0xFF0F261F),
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Bottom panel ─────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEEBE2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Route endpoints
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _RouteEndpoint(
                          icon: Icons.warehouse,
                          iconColor: const Color(0xFF16C38A),
                          label: 'Asal (Gudang)',
                          value: widget.shipment.origin,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: List.generate(
                            4,
                            (_) => Container(
                              width: 2,
                              height: 4,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              color: const Color(0xFFB5D4BC),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _RouteEndpoint(
                          icon: Icons.store,
                          iconColor: const Color(0xFFFF5050),
                          label: 'Tujuan (Kios)',
                          value: widget.shipment.destination,
                        ),
                      ),
                    ],
                  ),
                ),
                // Distance / ETA info row
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      if (!_atKios) ...[
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _validating ? null : _advanceCheckpoint,
                              icon: _validating
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_circle_outline,
                                      size: 18),
                              label: Text(
                                _validating ? 'Memeriksa…' : _actionLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentStop == 0
                                    ? const Color(0xFF16C38A)
                                    : const Color(0xFFFF5050),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _openGoogleMaps,
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Maps',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
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

// ── Supporting widgets ────────────────────────────────────────

class _MapStatTile extends StatelessWidget {
  const _MapStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _RouteEndpoint extends StatelessWidget {
  const _RouteEndpoint({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      const TextStyle(fontSize: 10, color: Color(0xFF6B8C73))),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F261F)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

