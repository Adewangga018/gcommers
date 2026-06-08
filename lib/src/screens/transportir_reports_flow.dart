import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/auth_models.dart';
import '../models/commerce_models.dart';
import '../services/commerce_service.dart';
import '../widgets/transportir_bottom_nav.dart';

// ─── helpers ────────────────────────────────────────────────────────────────

String _fmtRupiah(double v) {
  final s = v.toStringAsFixed(0);
  final buf = StringBuffer('Rp ');
  for (var i = 0; i < s.length; i++) {
    buf.write(s[i]);
    final rem = s.length - i - 1;
    if (rem > 0 && rem % 3 == 0) buf.write('.');
  }
  return buf.toString();
}

final _monthNames = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];

String _monthLabel(DateTime d) => '${_monthNames[d.month - 1]} ${d.year}';

// ─── Main Reports Page ───────────────────────────────────────────────────────

class TransportirReportsPage extends StatefulWidget {
  const TransportirReportsPage({super.key, this.session});
  final AuthSession? session;

  @override
  State<TransportirReportsPage> createState() => _TransportirReportsPageState();
}

class _TransportirReportsPageState extends State<TransportirReportsPage> {
  final _service = CommerceService();
  DateTime _selected = DateTime(DateTime.now().year, DateTime.now().month);
  List<OrderSummary> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _service.getOrders(userEmail: widget.session?.email);
      if (mounted) setState(() { _orders = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  List<OrderSummary> _forMonth(DateTime d) => _orders
      .where((o) => o.createdAt.year == d.year && o.createdAt.month == d.month)
      .toList();

  double _total(DateTime d) => _forMonth(d).fold(0, (s, o) => s + o.totalAmount);
  int _count(DateTime d) => _forMonth(d).length;
  int _items(DateTime d) => _forMonth(d).fold(0, (s, o) => s + o.itemCount);

  Future<void> _openMonthPicker() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthPickerDialog(initial: _selected),
    );
    if (picked != null && mounted) setState(() => _selected = picked);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final monthOrders = _forMonth(_selected);
    final totalAmt = _total(_selected);
    final tripCnt  = _count(_selected);
    final itemCnt  = _items(_selected);
    
    // Mengambil 3 riwayat klaim terakhir
    final recentClaims = ClaimStore.instance.claims.take(3).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4FAF5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF409557)),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/transportir-home', arguments: session),
        ),
        title: const Text('GCommers',
            style: TextStyle(color: Color(0xFF409557), fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF409557)),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    children: [
                      const Text(
                        'Laporan Pengiriman Bulanan',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF17203A)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Data dari ${_orders.length} pesanan tersedia',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6A6780)),
                      ),
                      const SizedBox(height: 16),

                      // ── Month Picker ─────────────────────────────────────
                      _MonthSelectorButton(
                        label: _monthLabel(_selected),
                        onTap: _openMonthPicker,
                        onPrev: () => setState(() =>
                            _selected = DateTime(_selected.year, _selected.month - 1)),
                        onNext: DateTime(_selected.year, _selected.month + 1)
                                .isAfter(DateTime(DateTime.now().year, DateTime.now().month))
                            ? null
                            : () => setState(() =>
                                _selected = DateTime(_selected.year, _selected.month + 1)),
                      ),
                      const SizedBox(height: 16),

                      // ── Total Card ───────────────────────────────────────
                      _TotalCard(
                        total: _fmtRupiah(totalAmt),
                        month: _monthLabel(_selected),
                      ),
                      const SizedBox(height: 12),

                      // ── Stat Cards ───────────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.local_shipping_outlined,
                              title: 'Total Pesanan',
                              value: '$tripCnt Pesanan',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.inventory_2_outlined,
                              title: 'Total Barang',
                              value: '$itemCnt Item',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ── Status Breakdown ─────────────────────────────────
                      if (monthOrders.isNotEmpty)
                        _StatusBreakdownCard(orders: monthOrders),
                      if (monthOrders.isEmpty)
                        _EmptyMonthCard(month: _monthLabel(_selected)),
                      const SizedBox(height: 22),

                      // ── History (3 Klaim Terakhir) ────────────────────────
                      const Text(
                        '3 Riwayat Klaim Terakhir',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF17203A)),
                      ),
                      const SizedBox(height: 12),
                      if (recentClaims.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('Belum ada riwayat klaim diajukan.', style: TextStyle(color: Color(0xFF6A6780))),
                        )
                      else
                        ...recentClaims.map((claim) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ClaimHistoryCard(
                            claim: claim,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TransportirClaimDetailPage(claim: claim),
                              ),
                            ),
                          ),
                        )),
                      const SizedBox(height: 18),

                      // ── Actions ──────────────────────────────────────────
                      SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context)
                              .pushNamed('/transportir-report-history', arguments: session),
                          icon: const Icon(Icons.history),
                          label: const Text('Semua Riwayat Klaim'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4438A7),
                            side: const BorderSide(color: Color(0xFF4438A7)),
                            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context)
                              .pushNamed('/transportir-report-claim', arguments: session),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Ajukan Klaim Baru'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4438A7),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 3, session: session),
    );
  }
}

class TransportirReportClaimPage extends StatefulWidget {
  const TransportirReportClaimPage({super.key, this.session});
  final AuthSession? session;

  @override
  State<TransportirReportClaimPage> createState() =>
      _TransportirReportClaimPageState();
}

class _TransportirReportClaimPageState
    extends State<TransportirReportClaimPage> {
  DateTime _period = DateTime(DateTime.now().year, DateTime.now().month);
  final _shippingCtrl = TextEditingController();
  final _fuelCtrl     = TextEditingController();
  final _otherCtrl    = TextEditingController();
  final _noteCtrl     = TextEditingController();

  /// Proof-of-transaction photos (mandatory, multi-photo).
  final List<Uint8List> _proofPhotos = [];
  final _picker = ImagePicker();
  bool _photoError = false;

  static const int _maxPhotos = 8;

  int get _total =>
      _parse(_shippingCtrl.text) + _parse(_fuelCtrl.text) + _parse(_otherCtrl.text);

  @override
  void initState() {
    super.initState();
    _shippingCtrl.addListener(() => setState(() {}));
    _fuelCtrl.addListener(()     => setState(() {}));
    _otherCtrl.addListener(()    => setState(() {}));
  }

  @override
  void dispose() {
    _shippingCtrl.dispose();
    _fuelCtrl.dispose();
    _otherCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _addPhoto(ImageSource source) async {
    if (_proofPhotos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maksimal $_maxPhotos foto.')),
      );
      return;
    }
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _proofPhotos.add(bytes);
          _photoError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e')),
        );
      }
    }
  }

  void _removePhoto(int index) => setState(() => _proofPhotos.removeAt(index));

  void _showPhotoSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE9FF),
                  child: Icon(Icons.camera_alt_outlined, color: Color(0xFF4438A7)),
                ),
                title: const Text('Ambil Foto',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(context);
                  _addPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEDE9FF),
                  child: Icon(Icons.photo_library_outlined, color: Color(0xFF4438A7)),
                ),
                title: const Text('Pilih dari Galeri',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(context);
                  _addPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _parse(String v) =>
      int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer('Rp ');
    for (var i = 0; i < s.length; i++) {
      buf.write(s[i]);
      final r = s.length - i - 1;
      if (r > 0 && r % 3 == 0) buf.write('.');
    }
    return buf.toString();
  }

  Future<void> _pickPeriod() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => _MonthPickerDialog(initial: _period),
    );
    if (picked != null && mounted) setState(() => _period = picked);
  }

  void _submit() {
    if (_total == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi minimal satu rincian pengeluaran.')),
      );
      return;
    }
    if (_proofPhotos.isEmpty) {
      setState(() => _photoError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unggah minimal 1 bukti transaksi.'),
          backgroundColor: Color(0xFFEF5350),
        ),
      );
      return;
    }
    final claim = ClaimRecord(
      id: ClaimStore.instance.generateId(_period),
      submittedAt: DateTime.now(),
      period: _period,
      total: _total,
      shippingCost: _parse(_shippingCtrl.text),
      fuelCost: _parse(_fuelCtrl.text),
      otherCost: _parse(_otherCtrl.text),
      note: _noteCtrl.text.trim(),
      status: ClaimStatus.menunggu,
    );
    ClaimStore.instance.add(claim);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TransportirReportSuccessPage(session: widget.session, claim: claim),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF4438A7);
    const labelStyle = TextStyle(
        fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF54546A));

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: purple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ajukan Klaim Baru',
            style: TextStyle(color: purple, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          // ── Periode ──────────────────────────────────────────────────────
          const Text('Periode Klaim', style: labelStyle),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickPeriod,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD3D6E7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 20, color: purple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _monthLabel(_period),
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF17203A)),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Rincian Pengeluaran ──────────────────────────────────────────
          const Text('Rincian Pengeluaran', style: labelStyle),
          const SizedBox(height: 10),
          _ClaimField(
            label: 'Biaya Pengiriman',
            icon: Icons.local_shipping_outlined,
            controller: _shippingCtrl,
          ),
          const SizedBox(height: 10),
          _ClaimField(
            label: 'Biaya Bensin',
            icon: Icons.local_gas_station_outlined,
            controller: _fuelCtrl,
          ),
          const SizedBox(height: 10),
          _ClaimField(
            label: 'Biaya Lain-lain',
            icon: Icons.receipt_outlined,
            controller: _otherCtrl,
          ),
          const SizedBox(height: 20),

          // ── Catatan ──────────────────────────────────────────────────────
          const Text('Catatan (opsional)', style: labelStyle),
          const SizedBox(height: 8),
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tambahkan keterangan jika ada...',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD3D6E7))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD3D6E7))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: purple, width: 1.5)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),

          // ── Bukti Transaksi (wajib, multi-foto) ──────────────────────────
          RichText(
            text: const TextSpan(
              text: 'Bukti Transaksi / Struk ',
              style: labelStyle,
              children: [
                TextSpan(
                  text: '*',
                  style: TextStyle(color: Color(0xFFEF5350), fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_proofPhotos.length}/$_maxPhotos foto diunggah',
            style: TextStyle(
                fontSize: 12,
                color: _photoError
                    ? const Color(0xFFEF5350)
                    : const Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 8),
          // Photo grid
          if (_proofPhotos.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _proofPhotos.length +
                  (_proofPhotos.length < _maxPhotos ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _proofPhotos.length) {
                  // "Add more" tile
                  return GestureDetector(
                    onTap: _showPhotoSourceSheet,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF4438A7), width: 1.5,
                            style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: Color(0xFF4438A7), size: 28),
                          SizedBox(height: 4),
                          Text('Tambah',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF4438A7),
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  );
                }
                // Photo thumbnail
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        _proofPhotos[i],
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removePhoto(i),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
          ],
          // Initial add button (shown when no photos yet)
          if (_proofPhotos.isEmpty)
            GestureDetector(
              onTap: _showPhotoSourceSheet,
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  color: _photoError
                      ? const Color(0xFFFFF5F5)
                      : Colors.white,
                  border: Border.all(
                    color: _photoError
                        ? const Color(0xFFEF5350)
                        : const Color(0xFFD3D6E7),
                    width: _photoError ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _photoError
                            ? const Color(0xFFFFEBEE)
                            : const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.add_photo_alternate_outlined,
                          color: _photoError
                              ? const Color(0xFFEF5350)
                              : purple,
                          size: 26),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ambil Foto atau Pilih Galeri',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _photoError
                              ? const Color(0xFFEF5350)
                              : const Color(0xFF17203A)),
                    ),
                    const SizedBox(height: 4),
                    const Text('Format JPG / PNG · Bisa lebih dari 1 foto',
                        style: TextStyle(
                            color: Color(0xFF6C6D80), fontSize: 12)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),

          // ── Total ────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4438A7), Color(0xFF6C5CE7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL PENGAJUAN',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _fmt(_total),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _monthLabel(_period),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_outlined, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Submit ───────────────────────────────────────────────────────
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded),
              label: const Text('AJUKAN KLAIM'),
              style: FilledButton.styleFrom(
                backgroundColor: purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 3, session: widget.session),
    );
  }
}

class TransportirReportSuccessPage extends StatelessWidget {
  const TransportirReportSuccessPage({super.key, this.session, this.claim});

  final AuthSession? session;
  final ClaimRecord? claim;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF4A4A61)),
                        onPressed: () => Navigator.of(context).popUntil((route) => route.settings.name == '/transportir-reports'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(color: const Color(0xFF6EF0A8), borderRadius: BorderRadius.circular(18)),
                      child: const Icon(Icons.check, size: 54, color: Color(0xFF0D7A4A)),
                    ),
                    const SizedBox(height: 22),
                    const Text('Pengajuan Klaim Berhasil!', textAlign: TextAlign.center, style: TextStyle(fontSize: 24 / 2, fontWeight: FontWeight.w900, color: Color(0xFF4438A7))),
                    const SizedBox(height: 12),
                    const Text(
                      'Klaim biaya pengiriman Anda untuk periode November 2023 telah berhasil diajukan dan sedang dalam proses verifikasi oleh Kantor Pusat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Color(0xFF5D5E6F), height: 1.45),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD2D5E8))),
                      child: Column(
                        children: [
                          _InfoLine(label: 'Nomor Referensi', value: claim?.id ?? 'CLM-202311-082'),
                          const Divider(height: 24),
                          _InfoLine(
                            label: 'Tanggal',
                            value: claim != null
                                ? '${claim!.submittedAt.day.toString().padLeft(2, '0')} ${_monthNames[claim!.submittedAt.month - 1]} ${claim!.submittedAt.year}'
                                : '14 Nov 2023',
                          ),
                          const Divider(height: 24),
                          _InfoLine(
                            label: 'Total Pengajuan',
                            value: claim != null ? _fmtRupiah(claim!.total.toDouble()) : 'Rp 1.650.000',
                            isEmphasized: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFF2F4FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFC8CDEF))),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF409557)),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Estimasi waktu verifikasi adalah 3-5 hari kerja. Anda akan menerima notifikasi jika status klaim berubah.',
                              style: TextStyle(color: Color(0xFF5A5C73), height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).popUntil((route) => route.settings.name == '/transportir-reports'),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4438A7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontWeight: FontWeight.w800)),
                        child: const Text('Kembali ke Laporan'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed('/transportir-report-history', arguments: session),
                        style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF4438A7), side: const BorderSide(color: Color(0xFF4438A7)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontWeight: FontWeight.w800)),
                        child: const Text('Lihat Riwayat Klaim'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class TransportirReportHistoryPage extends StatefulWidget {
  const TransportirReportHistoryPage({super.key, this.session});
  final AuthSession? session;

  @override
  State<TransportirReportHistoryPage> createState() =>
      _TransportirReportHistoryPageState();
}

class _TransportirReportHistoryPageState
    extends State<TransportirReportHistoryPage> {
  final _searchCtrl = TextEditingController();
  String _filter = 'Semua';

  static const _filters = ['Semua', 'Menunggu', 'Diverifikasi', 'Disetujui', 'Ditolak'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ClaimRecord> get _filtered {
    var list = ClaimStore.instance.claims.toList();
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) => c.id.toLowerCase().contains(q)).toList();
    }
    if (_filter != 'Semua') {
      final targetStatus = switch (_filter) {
        'Menunggu'    => ClaimStatus.menunggu,
        'Diverifikasi'=> ClaimStatus.diverifikasi,
        'Disetujui'   => ClaimStatus.disetujui,
        'Ditolak'     => ClaimStatus.ditolak,
        _              => null,
      };
      if (targetStatus != null) {
        list = list.where((c) => c.status == targetStatus).toList();
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final total = ClaimStore.instance.claims.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4438A7)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Riwayat Klaim',
                style: TextStyle(color: Color(0xFF4438A7), fontWeight: FontWeight.w800, fontSize: 16)),
            Text('$total pengajuan', style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Search ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nomor klaim (CLM-...)...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF6D6E86)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD3D6E7))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFD3D6E7))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4438A7), width: 1.5)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
              ),
            ),
          ),
          // ── Filter Chips ─────────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final active = _filter == _filters[i];
                return GestureDetector(
                  onTap: () => setState(() => _filter = _filters[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF4438A7) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active ? const Color(0xFF4438A7) : const Color(0xFFD3D6E7)),
                    ),
                    child: Text(
                      _filters[i],
                      style: TextStyle(
                        color: active ? Colors.white : const Color(0xFF4A5568),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // ── Claim list ────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 52, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          _searchCtrl.text.isNotEmpty
                              ? 'Klaim tidak ditemukan'
                              : 'Belum ada klaim untuk filter ini',
                          style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final claim = filtered[i];
                      return _ClaimHistoryCard(
                        claim: claim,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TransportirClaimDetailPage(claim: claim),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 3, session: widget.session),
    );
  }
}

class TransportirReportDetailPage extends StatelessWidget {
  const TransportirReportDetailPage({super.key, required this.args});

  final TransportirReportDetailArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF4438A7)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Riwayat', style: TextStyle(color: Color(0xFF4438A7), fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD3D6E7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: args.badgeColor.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                      child: Icon(args.statusIcon, color: args.badgeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(args.number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
                          const SizedBox(height: 2),
                          Text(args.statusLabel, style: TextStyle(color: args.badgeColor, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: args.badgeColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
                      child: Text(args.statusLabel, style: TextStyle(color: args.badgeColor, fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 14),
                _DetailRow(label: 'Tanggal pengajuan', value: args.date),
                const SizedBox(height: 10),
                _DetailRow(label: 'Periode klaim', value: args.period),
                const SizedBox(height: 10),
                _DetailRow(label: 'Total klaim', value: args.amount, emphasize: true),
                const SizedBox(height: 10),
                _DetailRow(label: 'Biaya pengiriman', value: args.shippingCost),
                const SizedBox(height: 10),
                _DetailRow(label: 'Biaya bensin', value: args.fuelCost),
                const SizedBox(height: 10),
                _DetailRow(label: 'Biaya lain-lain', value: args.otherCost),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8CDEF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF409557)),
                const SizedBox(width: 10),
                Expanded(child: Text(args.note, style: const TextStyle(color: Color(0xFF5A5C73), height: 1.35))),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4438A7), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontWeight: FontWeight.w800)),
              child: const Text('Kembali'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Month Selector Button ───────────────────────────────────────────────────

class _MonthSelectorButton extends StatelessWidget {
  const _MonthSelectorButton({
    required this.label,
    required this.onTap,
    required this.onPrev,
    this.onNext,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD3D6E7)),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF409557)),
            onPressed: onPrev,
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF4438A7)),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF4438A7),
                        fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right_rounded,
                color: onNext != null ? const Color(0xFF409557) : Colors.grey[300]),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

// ─── Month Picker Dialog ─────────────────────────────────────────────────────

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initial});
  final DateTime initial;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;
  final _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
  }

  bool _isDisabled(int month) =>
      DateTime(_year, month).isAfter(DateTime(_now.year, _now.month));

  bool _isSelected(int month) =>
      _year == widget.initial.year && month == widget.initial.month;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Year navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF409557)),
                  onPressed: () => setState(() => _year--),
                ),
                Text(
                  '$_year',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF17203A)),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right_rounded,
                      color: _year < _now.year ? const Color(0xFF409557) : Colors.grey[300]),
                  onPressed: _year < _now.year ? () => setState(() => _year++) : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Month grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.6,
              ),
              itemCount: 12,
              itemBuilder: (_, i) {
                final month = i + 1;
                final disabled = _isDisabled(month);
                final selected = _isSelected(month);
                return GestureDetector(
                  onTap: disabled
                      ? null
                      : () => Navigator.pop(context, DateTime(_year, month)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF4438A7)
                          : disabled
                              ? const Color(0xFFF0F0F0)
                              : const Color(0xFFEEEBFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _monthNames[i].substring(0, 3),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? Colors.white
                            : disabled
                                ? Colors.grey[400]
                                : const Color(0xFF4438A7),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal',
                    style: TextStyle(color: Color(0xFF6A6780), fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status Breakdown Card ───────────────────────────────────────────────────

class _StatusBreakdownCard extends StatelessWidget {
  const _StatusBreakdownCard({required this.orders});
  final List<OrderSummary> orders;

  @override
  Widget build(BuildContext context) {
    final groups = <String, int>{};
    for (final o in orders) {
      groups[o.statusLabel] = (groups[o.statusLabel] ?? 0) + 1;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD3D6E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('STATUS PESANAN',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w900,
                  color: Color(0xFF5A5D73), letterSpacing: 0.6)),
          const SizedBox(height: 12),
          ...groups.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key,
                              style: const TextStyle(
                                  fontSize: 13, color: Color(0xFF17203A))),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: e.value / orders.length,
                              minHeight: 7,
                              backgroundColor: const Color(0xFFEEEBFF),
                              valueColor: const AlwaysStoppedAnimation(Color(0xFF4438A7)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text('${e.value}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF4438A7))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Empty Month Card ─────────────────────────────────────────────────────────

class _EmptyMonthCard extends StatelessWidget {
  const _EmptyMonthCard({required this.month});
  final String month;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD3D6E7)),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: Colors.grey[350]),
          const SizedBox(height: 10),
          Text('Tidak ada data pesanan\npada $month',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], height: 1.4)),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF5E6076))),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4438A7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.month});

  final String total;
  final String month;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4438A7), Color(0xFF6C5CE7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Nilai Pesanan',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(total,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 4),
                Text(month,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
              ],
            ),
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 26),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD3D6E7))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF409557)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF5E6076))),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
        ],
      ),
    );
  }
}

// ─── Claim Input Field ───────────────────────────────────────────────────────

class _ClaimField extends StatelessWidget {
  const _ClaimField({
    required this.label,
    required this.icon,
    required this.controller,
  });

  final String label;
  final IconData icon;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD3D6E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF4438A7)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4438A7),
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixText: 'Rp  ',
              prefixStyle: const TextStyle(
                  color: Color(0xFF17203A),
                  fontWeight: FontWeight.w700,
                  fontSize: 15),
              hintText: '0',
              hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
              filled: true,
              fillColor: const Color(0xFFF8F8FB),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD3D6E7))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD3D6E7))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF4438A7), width: 1.5)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value, this.isEmphasized = false});

  final String label;
  final String value;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: const Color(0xFF5E6076), fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w600)),
        Text(value, style: TextStyle(color: const Color(0xFF17203A), fontWeight: FontWeight.w900, fontSize: isEmphasized ? 18 : 14)),
      ],
    );
  }
}

class TransportirHistoryRecord {
  const TransportirHistoryRecord(this.number, this.date, this.amount, this.badge, this.badgeColor);

  final String number;
  final String date;
  final String amount;
  final String badge;
  final Color badgeColor;
}

class TransportirReportDetailArgs {
  const TransportirReportDetailArgs({
    required this.number,
    required this.date,
    required this.period,
    required this.amount,
    required this.statusLabel,
    required this.statusIcon,
    required this.badgeColor,
    required this.shippingCost,
    required this.fuelCost,
    required this.otherCost,
    required this.note,
  });

  factory TransportirReportDetailArgs.fromHistoryRecord(TransportirHistoryRecord record) {
    return TransportirReportDetailArgs(
      number: record.number,
      date: record.date,
      period: '-',
      amount: record.amount,
      statusLabel: record.badge,
      statusIcon: Icons.receipt_long_outlined,
      badgeColor: record.badgeColor,
      shippingCost: '-',
      fuelCost: '-',
      otherCost: '-',
      note: 'Estimasi waktu verifikasi adalah 3-5 hari kerja.',
    );
  }

  factory TransportirReportDetailArgs.fromOrder(OrderSummary order) {
    final d = order.createdAt;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')} ${_monthNames[d.month - 1]} ${d.year}';
    final periodStr = '${_monthNames[d.month - 1]} ${d.year}';
    const statusColors = {
      'delivered': Color(0xFF6AE8A1), 'completed': Color(0xFF6AE8A1),
      'paid':      Color(0xFF4A7DFF), 'shipping':   Color(0xFF4A7DFF),
      'cancelled': Color(0xFFF2A7A4),
    };
    return TransportirReportDetailArgs(
      number: order.poNumber,
      date: dateStr,
      period: periodStr,
      amount: _fmtRupiah(order.totalAmount),
      statusLabel: order.statusLabel,
      statusIcon: Icons.receipt_long_outlined,
      badgeColor: statusColors[order.status] ?? const Color(0xFFF2C98E),
      shippingCost: '-',
      fuelCost: '-',
      otherCost: '-',
      note: 'Detail biaya pengiriman dapat diajukan melalui menu Ajukan Klaim Baru.',
    );
  }

  final String number;
  final String date;
  final String period;
  final String amount;
  final String statusLabel;
  final IconData statusIcon;
  final Color badgeColor;
  final String shippingCost;
  final String fuelCost;
  final String otherCost;
  final String note;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: const Color(0xFF5E6076), fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600)),
        Text(value, style: TextStyle(color: const Color(0xFF17203A), fontWeight: FontWeight.w900, fontSize: emphasize ? 18 : 14)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Claim data model + in-session store
// ═══════════════════════════════════════════════════════════════

enum ClaimStatus { menunggu, diverifikasi, disetujui, ditolak }

extension ClaimStatusX on ClaimStatus {
  String get label => switch (this) {
        ClaimStatus.menunggu     => 'Menunggu Verifikasi',
        ClaimStatus.diverifikasi => 'Sedang Diverifikasi',
        ClaimStatus.disetujui    => 'Disetujui',
        ClaimStatus.ditolak      => 'Ditolak',
      };

  Color get color => switch (this) {
        ClaimStatus.menunggu     => const Color(0xFFFFB74D),
        ClaimStatus.diverifikasi => const Color(0xFF42A5F5),
        ClaimStatus.disetujui    => const Color(0xFF66BB6A),
        ClaimStatus.ditolak      => const Color(0xFFEF5350),
      };

  Color get bg => switch (this) {
        ClaimStatus.menunggu     => const Color(0xFFFFF3E0),
        ClaimStatus.diverifikasi => const Color(0xFFE3F2FD),
        ClaimStatus.disetujui    => const Color(0xFFE8F5E9),
        ClaimStatus.ditolak      => const Color(0xFFFFEBEE),
      };

  IconData get icon => switch (this) {
        ClaimStatus.menunggu     => Icons.hourglass_empty_rounded,
        ClaimStatus.diverifikasi => Icons.manage_search_rounded,
        ClaimStatus.disetujui    => Icons.check_circle_rounded,
        ClaimStatus.ditolak      => Icons.cancel_rounded,
      };
}

class ClaimRecord {
  ClaimRecord({
    required this.id,
    required this.submittedAt,
    required this.period,
    required this.total,
    required this.shippingCost,
    required this.fuelCost,
    required this.otherCost,
    required this.note,
    required this.status,
  });

  final String id;
  final DateTime submittedAt;
  final DateTime period;
  final int total;
  final int shippingCost;
  final int fuelCost;
  final int otherCost;
  final String note;
  ClaimStatus status;
}

class ClaimStore {
  ClaimStore._() {
    _claims = [
      ClaimRecord(
        id: 'CLM-202604-001',
        submittedAt: DateTime(2026, 4, 15),
        period: DateTime(2026, 4),
        total: 1650000,
        shippingCost: 1000000,
        fuelCost: 450000,
        otherCost: 200000,
        note: 'Pengiriman bulan April 2026.',
        status: ClaimStatus.disetujui,
      ),
      ClaimRecord(
        id: 'CLM-202603-001',
        submittedAt: DateTime(2026, 3, 10),
        period: DateTime(2026, 3),
        total: 1920000,
        shippingCost: 1400000,
        fuelCost: 320000,
        otherCost: 200000,
        note: 'Tiga rute pengiriman Maret 2026.',
        status: ClaimStatus.disetujui,
      ),
      ClaimRecord(
        id: 'CLM-202605-001',
        submittedAt: DateTime(2026, 5, 20),
        period: DateTime(2026, 5),
        total: 2100000,
        shippingCost: 1500000,
        fuelCost: 400000,
        otherCost: 200000,
        note: '',
        status: ClaimStatus.diverifikasi,
      ),
      ClaimRecord(
        id: 'CLM-202602-001',
        submittedAt: DateTime(2026, 2, 5),
        period: DateTime(2026, 2),
        total: 800000,
        shippingCost: 600000,
        fuelCost: 200000,
        otherCost: 0,
        note: 'Dokumen pendukung kurang lengkap.',
        status: ClaimStatus.ditolak,
      ),
    ];
  }

  static final ClaimStore instance = ClaimStore._();

  late List<ClaimRecord> _claims;
  List<ClaimRecord> get claims => List.unmodifiable(_claims);

  int get _nextSeq => _claims.where((c) {
        final now = DateTime.now();
        return c.submittedAt.year == now.year && c.submittedAt.month == now.month;
      }).length + 1;

  String generateId(DateTime period) {
    final seq = _nextSeq.toString().padLeft(3, '0');
    return 'CLM-${period.year}${period.month.toString().padLeft(2, '0')}-$seq';
  }

  void add(ClaimRecord claim) => _claims.insert(0, claim);
}

// ═══════════════════════════════════════════════════════════════
// Claim History Card
// ═══════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════
// Claim History Card
// ═══════════════════════════════════════════════════════════════

class _ClaimHistoryCard extends StatelessWidget {
  const _ClaimHistoryCard({required this.claim, required this.onTap});

  final ClaimRecord claim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = claim.submittedAt;
    final dateStr = '${d.day.toString().padLeft(2, '0')} ${_monthNames[d.month - 1].substring(0, 3)} ${d.year}';
    final periodStr = '${_monthNames[claim.period.month - 1]} ${claim.period.year}';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4E0F0)),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        // SOLUSI: Dibungkus dengan IntrinsicHeight agar CrossAxisAlignment.stretch tidak error
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status color bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: claim.status.color,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: claim.status.bg, borderRadius: BorderRadius.circular(11)),
                  child: Icon(claim.status.icon, color: claim.status.color, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              // Info (Expanded untuk fluid responsive)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(claim.id, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
                      const SizedBox(height: 3),
                      Text('Periode: $periodStr', style: const TextStyle(fontSize: 11, color: Color(0xFF6B8C73))),
                      const SizedBox(height: 2),
                      Text(dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFFADA6C0))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Amount + status (responsive fix)
              Padding(
                padding: const EdgeInsets.only(right: 12, left: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_fmtRupiah(claim.total.toDouble()),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF4438A7))),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 100), 
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: claim.status.bg, borderRadius: BorderRadius.circular(6)), 
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(claim.status.label,
                            style: TextStyle(color: claim.status.color, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Claim Detail Page  (full status timeline)
// ═══════════════════════════════════════════════════════════════

class TransportirClaimDetailPage extends StatelessWidget {
  const TransportirClaimDetailPage({super.key, required this.claim});
  final ClaimRecord claim;

  static const _primary = Color(0xFF4438A7);

  @override
  Widget build(BuildContext context) {
    final d = claim.submittedAt;
    final dateStr = '${d.day.toString().padLeft(2, '0')} ${_monthNames[d.month - 1]} ${d.year}';
    final periodStr = '${_monthNames[claim.period.month - 1]} ${claim.period.year}';
    final steps = _buildSteps(claim.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Klaim', style: TextStyle(color: _primary, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, const Color(0xFF6C5CE7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(claim.status.icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(claim.id, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(claim.status.label,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_fmtRupiah(claim.total.toDouble()),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(periodStr, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Status timeline
          _SectionCard(
            title: 'Status Pengajuan',
            child: Column(
              children: steps.asMap().entries.map((e) {
                final i = e.key;
                final step = e.value;
                return _ClaimTimelineStep(
                  step: step,
                  isLast: i == steps.length - 1,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Cost breakdown
          _SectionCard(
            title: 'Rincian Pengeluaran',
            child: Column(
              children: [
                _CostRow(label: 'Biaya Pengiriman', value: claim.shippingCost),
                const SizedBox(height: 10),
                _CostRow(label: 'Biaya Bensin', value: claim.fuelCost),
                const SizedBox(height: 10),
                _CostRow(label: 'Biaya Lain-lain', value: claim.otherCost),
                const Divider(height: 20),
                _CostRow(label: 'TOTAL', value: claim.total, emphasize: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Info
          _SectionCard(
            title: 'Informasi Pengajuan',
            child: Column(
              children: [
                _DetailRow(label: 'Tanggal Diajukan', value: dateStr),
                const SizedBox(height: 10),
                _DetailRow(label: 'Periode Klaim', value: periodStr),
                if (claim.note.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _DetailRow(label: 'Catatan', value: claim.note),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
              child: const Text('Kembali'),
            ),
          ),
        ],
      ),
    );
  }

  List<_ClaimStep> _buildSteps(ClaimStatus status) {
    final diajukan = _ClaimStep(
      title: 'Klaim Diajukan',
      subtitle: '${claim.submittedAt.day.toString().padLeft(2, '0')} ${_monthNames[claim.submittedAt.month - 1]} ${claim.submittedAt.year}',
      state: _StepState.done,
    );
    final verifikasi = _ClaimStep(
      title: 'Sedang Diverifikasi',
      subtitle: status == ClaimStatus.menunggu ? 'Menunggu giliran' : 'Oleh tim Kantor Pusat',
      state: status == ClaimStatus.menunggu
          ? _StepState.pending
          : _StepState.done,
    );
    final keputusan = _ClaimStep(
      title: status == ClaimStatus.ditolak ? 'Klaim Ditolak' : 'Klaim Disetujui',
      subtitle: status == ClaimStatus.disetujui
          ? 'Dana akan ditransfer dalam 3-5 hari kerja'
          : status == ClaimStatus.ditolak
              ? 'Hubungi admin untuk informasi lebih lanjut'
              : 'Menunggu keputusan verifikator',
      state: (status == ClaimStatus.disetujui || status == ClaimStatus.ditolak)
          ? _StepState.done
          : _StepState.pending,
      isRejected: status == ClaimStatus.ditolak,
    );
    return [diajukan, verifikasi, keputusan];
  }
}

enum _StepState { done, active, pending }

class _ClaimStep {
  const _ClaimStep({required this.title, required this.subtitle, required this.state, this.isRejected = false});
  final String title;
  final String subtitle;
  final _StepState state;
  final bool isRejected;
}

class _ClaimTimelineStep extends StatelessWidget {
  const _ClaimTimelineStep({required this.step, required this.isLast});
  final _ClaimStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color dotColor = step.isRejected
        ? const Color(0xFFEF5350)
        : step.state == _StepState.done
            ? const Color(0xFF66BB6A)
            : step.state == _StepState.active
                ? const Color(0xFF42A5F5)
                : const Color(0xFFD0C8E8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              child: Icon(
                step.state == _StepState.pending
                    ? Icons.circle_outlined
                    : step.isRejected
                        ? Icons.close_rounded
                        : Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 36, color: const Color(0xFFE0D8F0)),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: step.state == _StepState.pending ? const Color(0xFFADA6C0) : const Color(0xFF17203A))),
                const SizedBox(height: 2),
                Text(step.subtitle, style: TextStyle(fontSize: 12, color: step.state == _StepState.pending ? const Color(0xFFCCC7DE) : const Color(0xFF6B8C73))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E0F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF9A93AC), letterSpacing: 0.7)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.label, required this.value, this.emphasize = false});
  final String label;
  final int value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: emphasize ? const Color(0xFF17203A) : const Color(0xFF5E6076),
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500, fontSize: emphasize ? 14 : 13)),
        Text(value == 0 ? '-' : _fmtRupiah(value.toDouble()),
            style: TextStyle(color: emphasize ? const Color(0xFF4438A7) : const Color(0xFF17203A),
                fontWeight: FontWeight.w800, fontSize: emphasize ? 15 : 13)),
      ],
    );
  }
}