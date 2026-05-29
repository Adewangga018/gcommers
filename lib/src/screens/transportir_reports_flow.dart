import 'package:flutter/material.dart';

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

  // Past 3 months before the selected one
  List<DateTime> get _history {
    final list = <DateTime>[];
    var cur = DateTime(_selected.year, _selected.month - 1);
    for (var i = 0; i < 3; i++) {
      list.add(cur);
      cur = DateTime(cur.year, cur.month - 1);
    }
    return list;
  }

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
        title: const Text('GCommers',
            style: TextStyle(color: Color(0xFF4A3AFF), fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4A3AFF)),
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

                      // ── History ──────────────────────────────────────────
                      const Text(
                        'Riwayat Bulan Sebelumnya',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF17203A)),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFD3D6E7)),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < _history.length; i++) ...[
                              _MonthHistoryTile(
                                month: _history[i],
                                total: _total(_history[i]),
                                count: _count(_history[i]),
                              ),
                              if (i < _history.length - 1)
                                const Divider(height: 1, indent: 16, endIndent: 16),
                            ],
                          ],
                        ),
                      ),
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
  State<TransportirReportClaimPage> createState() => _TransportirReportClaimPageState();
}

class _TransportirReportClaimPageState extends State<TransportirReportClaimPage> {
  late final TextEditingController _periodController;
  late final TextEditingController _shippingController;
  late final TextEditingController _fuelController;
  late final TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    _periodController = TextEditingController(text: 'November 2023');
    _shippingController = TextEditingController(text: '450000');
    _fuelController = TextEditingController(text: '1200000');
    _otherController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _periodController.dispose();
    _shippingController.dispose();
    _fuelController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final total = _parseMoney(_shippingController.text) + _parseMoney(_fuelController.text) + _parseMoney(_otherController.text);
    final totalText = _formatRupiah(total);

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
        title: const Text('Pengajuan Klaim Baru', style: TextStyle(color: Color(0xFF4438A7), fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        children: [
          Container(
            height: 42,
            decoration: BoxDecoration(color: const Color(0xFF4438A7), borderRadius: BorderRadius.circular(4)),
            alignment: Alignment.center,
            child: const Text('Detail Klaim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 18),
          const Text('Periode Klaim', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF54546A))),
          const SizedBox(height: 8),
          _ReportInputField(controller: _periodController, suffixIcon: Icons.calendar_month_outlined),
          const SizedBox(height: 18),
          const Text('Rincian Pengeluaran', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF54546A))),
          const SizedBox(height: 10),
          _ExpenseField(label: 'Biaya Pengiriman', controller: _shippingController, onTapEdit: () => _focusField(context, _shippingController)),
          const SizedBox(height: 10),
          _ExpenseField(label: 'Biaya Bensin', controller: _fuelController, onTapEdit: () => _focusField(context, _fuelController)),
          const SizedBox(height: 10),
          _ExpenseField(label: 'Biaya Lain-lain', controller: _otherController, onTapEdit: () => _focusField(context, _otherController)),
          const SizedBox(height: 18),
          const Text('Unggah Bukti Transaksi/Struk', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF54546A))),
          const SizedBox(height: 10),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFCDD1E4)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 22, backgroundColor: Color(0xFFE0E7FF), child: Icon(Icons.photo_camera_outlined, color: Color(0xFF4438A7))),
                  SizedBox(height: 14),
                  Text('Ambil Foto atau Pilih Galeri', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text('Format JPG, PNG (Max 5MB)', style: TextStyle(color: Color(0xFF6C6D80))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF4438A7), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL PENGAJUAN', style: TextStyle(color: Color(0xFFCFCBFF), fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(totalText, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.receipt_long_outlined, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pushNamed('/transportir-report-success', arguments: session),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4438A7),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              child: const Text('AJUKAN KLAIM'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 3, session: session),
    );
  }

  void _focusField(BuildContext context, TextEditingController controller) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit ${controller.text.isEmpty ? 'nilai' : controller.text} lewat keyboard.')));
  }

  int _parseMoney(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer('Rp ');
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      final remaining = digits.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }
}

class TransportirReportSuccessPage extends StatelessWidget {
  const TransportirReportSuccessPage({super.key, this.session});

  final AuthSession? session;

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
                      child: const Column(
                        children: [
                          _InfoLine(label: 'Nomor Referensi', value: 'CLM-202311-082'),
                          Divider(height: 24),
                          _InfoLine(label: 'Tanggal', value: '14 Nov 2023'),
                          Divider(height: 24),
                          _InfoLine(label: 'Total Pengajuan', value: 'Rp 1.650.000', isEmphasized: true),
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
                          Icon(Icons.info_outline, color: Color(0xFF4A3AFF)),
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

class TransportirReportHistoryPage extends StatelessWidget {
  const TransportirReportHistoryPage({super.key, this.session});

  final AuthSession? session;

  @override
  Widget build(BuildContext context) {
    const records = <TransportirHistoryRecord>[
      TransportirHistoryRecord('CLM-202311-082', '14 Nov 2023', 'Rp 1.650.000', 'MENUNGGU VERIFIKASI', Color(0xFFF2C98E)),
      TransportirHistoryRecord('CLM-202311-045', '10 Nov 2023', 'Rp 4.200.000', 'TERVERIFIKASI', Color(0xFF6AE8A1)),
      TransportirHistoryRecord('CLM-202311-012', '02 Nov 2023', 'Rp 850.000', 'DITOLAK', Color(0xFFF2A7A4)),
      TransportirHistoryRecord('CLM-202310-988', '28 Okt 2023', 'Rp 2.100.000', 'TERVERIFIKASI', Color(0xFF6AE8A1)),
      TransportirHistoryRecord('CLM-202310-901', '20 Okt 2023', 'Rp 12.500.000', 'TERVERIFIKASI', Color(0xFF6AE8A1)),
    ];

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
        title: const Text('Riwayat Klaim', style: TextStyle(color: Color(0xFF4438A7), fontWeight: FontWeight.w800)),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              _SearchField(onTapPlus: () => Navigator.of(context).pushNamed('/transportir-report-claim', arguments: session)),
              const SizedBox(height: 14),
              const _FilterChips(),
              const SizedBox(height: 14),
              for (final record in records) ...[
                _HistoryRecordCard(
                  record: record,
                  onTap: () => Navigator.of(context).pushNamed('/transportir-report-detail', arguments: TransportirReportDetailArgs.fromHistoryRecord(record)),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF4438A7),
              onPressed: () => Navigator.of(context).pushNamed('/transportir-report-claim', arguments: session),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 3, session: session),
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
                const Icon(Icons.info_outline, color: Color(0xFF4A3AFF)),
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
            icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF4A3AFF)),
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
                color: onNext != null ? const Color(0xFF4A3AFF) : Colors.grey[300]),
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
                  icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF4A3AFF)),
                  onPressed: () => setState(() => _year--),
                ),
                Text(
                  '$_year',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF17203A)),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right_rounded,
                      color: _year < _now.year ? const Color(0xFF4A3AFF) : Colors.grey[300]),
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

// ─── Month History Tile ──────────────────────────────────────────────────────

class _MonthHistoryTile extends StatelessWidget {
  const _MonthHistoryTile({
    required this.month,
    required this.total,
    required this.count,
  });

  final DateTime month;
  final double total;
  final int count;

  @override
  Widget build(BuildContext context) {
    final hasData = count > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: hasData ? const Color(0xFFE7E4FF) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              hasData ? Icons.bar_chart_rounded : Icons.remove_circle_outline,
              color: hasData ? const Color(0xFF4438A7) : Colors.grey[400],
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _monthLabel(month),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF17203A)),
                ),
                const SizedBox(height: 2),
                Text(
                  hasData ? '$count pesanan' : 'Tidak ada data',
                  style: TextStyle(
                      fontSize: 12,
                      color: hasData ? const Color(0xFF6A6780) : Colors.grey[400]),
                ),
              ],
            ),
          ),
          Text(
            hasData ? _fmtRupiah(total) : '-',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: hasData ? const Color(0xFF4438A7) : Colors.grey[400],
            ),
          ),
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
          Icon(icon, size: 20, color: const Color(0xFF4A3AFF)),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF5E6076))),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
        ],
      ),
    );
  }
}


class _SearchField extends StatelessWidget {
  const _SearchField({required this.onTapPlus});

  final VoidCallback onTapPlus;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Cari nomor klaim...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6D6E86)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD3D6E7))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD3D6E7))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onTapPlus,
          child: Container(width: 52, height: 52, decoration: BoxDecoration(color: const Color(0xFF4438A7), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.add, color: Colors.white)),
        ),
      ],
    );
  }
}

class _ReportInputField extends StatelessWidget {
  const _ReportInputField({required this.controller, required this.suffixIcon});

  final TextEditingController controller;
  final IconData suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFD3D6E7))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFD3D6E7))),
        suffixIcon: Icon(suffixIcon, color: const Color(0xFF5E6076)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    final labels = const ['Semua', 'Menunggu', 'Terverifikasi', 'Ditolak'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = index == 0;
          return Chip(
            label: Text(labels[index]),
            backgroundColor: selected ? const Color(0xFF4438A7) : const Color(0xFFE3E7F4),
            labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF4A5568), fontWeight: FontWeight.w700),
            side: BorderSide(color: selected ? Colors.transparent : const Color(0xFFC7CCDE)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          );
        },
      ),
    );
  }
}

class _ExpenseField extends StatelessWidget {
  const _ExpenseField({required this.label, required this.controller, required this.onTapEdit});

  final String label;
  final TextEditingController controller;
  final VoidCallback onTapEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFD3D6E7))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4438A7), fontSize: 13))),
              GestureDetector(onTap: onTapEdit, child: const Icon(Icons.edit, color: Color(0xFF7F8297))),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: 'Rp  ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFD3D6E7))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFFD3D6E7))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      period: 'November 2023',
      amount: record.amount,
      statusLabel: record.badge,
      statusIcon: Icons.receipt_long_outlined,
      badgeColor: record.badgeColor,
      shippingCost: 'Rp 450.000',
      fuelCost: 'Rp 1.200.000',
      otherCost: 'Rp 0',
      note: 'Estimasi waktu verifikasi adalah 3-5 hari kerja. Anda akan menerima notifikasi jika status klaim berubah.',
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

class _HistoryRecordCard extends StatelessWidget {
  const _HistoryRecordCard({required this.record, this.onTap});

  final TransportirHistoryRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFD3D6E7))),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: const Color(0xFFE1FAEA), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.check_circle_outline, color: Color(0xFF4FD48B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.number, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF4438A7))),
                  const SizedBox(height: 4),
                  Text(record.date, style: const TextStyle(color: Color(0xFF5E6076))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: record.badgeColor.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(999)),
                  child: Text(record.badge, style: TextStyle(color: record.badgeColor, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                Text(record.amount, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF17203A))),
              ],
            ),
          ],
        ),
      ),
    );
  }
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
