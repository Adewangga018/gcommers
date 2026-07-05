import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../models/commerce_models.dart';
import '../services/commerce_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/infographic_widgets.dart';
import '../widgets/transportir_bottom_nav.dart';
import 'settings_pages.dart';

/// Dashboard transportir — semua metrik diturunkan dari `Shipments` yang
/// ditugaskan admintransport ke akun ini (bukan `Orders`, yang UserEmail-nya
/// milik kios). Satu baris Shipment = satu "pesanan masuk" untuk transportir.
class TransportirDashboardScreen extends StatefulWidget {
  const TransportirDashboardScreen({super.key, this.session});
  final AuthSession? session;

  @override
  State<TransportirDashboardScreen> createState() => _TransportirDashboardScreenState();
}

class _TransportirDashboardScreenState extends State<TransportirDashboardScreen> {
  final _service = CommerceService();
  List<ShipmentSummary>? _shipments;
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
      final shipments = await _service.getShipments(transportirEmail: email);
      shipments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() {
        _shipments = shipments;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  void _goToOrders() => Navigator.of(context).pushReplacementNamed(
        '/transportir-orders',
        arguments: widget.session,
      );

  @override
  Widget build(BuildContext context) {
    final shipments = _shipments;
    final loading = shipments == null && !_failed;

    return Scaffold(
      backgroundColor: AppTheme.paper,
      appBar: AppBar(
        backgroundColor: AppTheme.paper,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('GCommers', style: AppTheme.title(size: 18)),
        actions: const [
          NotificationBadge(iconColor: AppTheme.ink),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          children: [
            _HeroCard(session: widget.session, stats: _TransportirStats.from(shipments)),
            const SizedBox(height: 14),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_failed)
              _ErrorBox(onRetry: _load)
            else ...[
              _SummaryCard(stats: _TransportirStats.from(shipments)),
              const SizedBox(height: 20),
              SectionKicker(
                label: 'Pemesanan Terbaru',
                action: TextButton(
                  onPressed: _goToOrders,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                  child: Text('LIHAT SEMUA',
                      style: AppTheme.body(size: 12, color: AppTheme.tertiaryGreen, weight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 10),
              _RecentShipments(shipments: shipments!, onTap: _goToOrders),
            ],
          ],
        ),
      ),
      bottomNavigationBar: TransportirBottomNav(currentIndex: 0, session: widget.session),
    );
  }
}

// ── Derived stats ────────────────────────────────────────────────────────────

class _TransportirStats {
  const _TransportirStats({
    required this.masuk,
    required this.berjalan,
    required this.selesai,
    required this.totalTon,
  });

  final int masuk;
  final int berjalan;
  final int selesai;
  final double totalTon;

  static _TransportirStats from(List<ShipmentSummary>? shipments) {
    if (shipments == null) {
      return const _TransportirStats(masuk: 0, berjalan: 0, selesai: 0, totalTon: 0);
    }
    return _TransportirStats(
      masuk: shipments.length,
      berjalan: shipments.where((s) => s.status == 'dalam_perjalanan').length,
      selesai: shipments.where((s) => s.status == 'selesai').length,
      totalTon: shipments.fold(0.0, (sum, s) => sum + (s.quotaTon ?? 0)),
    );
  }

  double get completedFraction => masuk == 0 ? 0 : selesai / masuk;
}

// ── Hero card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.session, required this.stats});

  final AuthSession? session;
  final _TransportirStats stats;

  @override
  Widget build(BuildContext context) {
    final companyName = (session?.companyName?.trim().isNotEmpty ?? false) ? session!.companyName! : 'Transportir';
    final vehicleLabel = (session?.vehicleType?.trim().isNotEmpty ?? false) ? session!.vehicleType! : 'Kendaraan';
    final policeNumber = (session?.policeNumber?.trim().isNotEmpty ?? false) ? session!.policeNumber! : '—';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF15382A), AppTheme.ink],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x2215382A), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping_rounded, color: AppTheme.tertiaryGold, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Halo,', style: AppTheme.body(size: 12, color: Colors.white60)),
                    const SizedBox(height: 1),
                    Text(
                      companyName,
                      style: AppTheme.title(size: 17, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(vehicleLabel, style: AppTheme.body(size: 12, color: Colors.white70)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: AppTheme.tertiaryGold, borderRadius: BorderRadius.circular(8)),
                child: Text(policeNumber,
                    style: AppTheme.subtitle(size: 13, color: AppTheme.ink).copyWith(letterSpacing: 1)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  icon: Icons.inbox_rounded,
                  label: 'Pesanan Masuk',
                  value: '${stats.masuk}',
                  accent: AppTheme.tertiaryGold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  icon: Icons.local_shipping_outlined,
                  label: 'Berjalan',
                  value: '${stats.berjalan}',
                  accent: const Color(0xFFF0B457),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Selesai',
                  value: '${stats.selesai}',
                  accent: const Color(0xFF16C38A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.label, required this.value, required this.accent});

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: 10),
          Text(value, style: AppTheme.title(size: 20, color: Colors.white)),
          const SizedBox(height: 2),
          Text(label, style: AppTheme.body(size: 10.5, color: Colors.white60), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Summary card (progress + tonase) ─────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats});

  final _TransportirStats stats;

  String _fmtTon(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ProgressBarRow(
                  label: 'Progres Pengiriman',
                  value: '${stats.selesai}/${stats.masuk} selesai',
                  fraction: stats.completedFraction,
                  color: AppTheme.tertiaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: AppTheme.tertiaryGoldSoft, borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.scale_rounded, color: AppTheme.tertiaryGold, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Total Muatan Ditugaskan', style: AppTheme.body(size: 13, color: AppTheme.muted)),
              ),
              Text('${_fmtTon(stats.totalTon)} Ton', style: AppTheme.title(size: 18, color: AppTheme.ink)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Recent shipments ─────────────────────────────────────────────────────────

class _RecentShipments extends StatelessWidget {
  const _RecentShipments({required this.shipments, required this.onTap});

  final List<ShipmentSummary> shipments;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, color: AppTheme.muted, size: 40),
            const SizedBox(height: 10),
            Text('Belum ada pesanan yang ditugaskan.',
                style: AppTheme.body(size: 13, color: AppTheme.muted), textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final recent = shipments.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppTheme.border),
            _ShipmentRow(shipment: recent[i], onTap: onTap),
          ],
        ],
      ),
    );
  }
}

class _ShipmentRow extends StatelessWidget {
  const _ShipmentRow({required this.shipment, required this.onTap});

  final ShipmentSummary shipment;
  final VoidCallback onTap;

  String get _poLabel => shipment.poNumber ?? shipment.shipmentNumber;

  String get _muatanLabel {
    final product = shipment.productName;
    if (product == null || product.isEmpty) return 'Muatan belum diatur';
    if (shipment.quotaTon != null) {
      final ton = shipment.quotaTon! == shipment.quotaTon!.roundToDouble()
          ? shipment.quotaTon!.toStringAsFixed(0)
          : shipment.quotaTon!.toStringAsFixed(1);
      return '$product · $ton Ton';
    }
    return product;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _shipmentStatusColor(shipment.status);
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
                      Expanded(child: Text(_poLabel, style: AppTheme.subtitle(size: 14))),
                      StatusChip(label: shipment.statusLabel, color: statusColor),
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
                        child: Text(
                          shipment.destinationLabel ?? shipment.destinationAddress ?? 'Kios tujuan',
                          style: AppTheme.body(size: 12, color: AppTheme.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(shortDateTime(shipment.createdAt), style: AppTheme.body(size: 11, color: AppTheme.muted)),
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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, color: AppTheme.muted, size: 40),
          const SizedBox(height: 10),
          Text('Gagal memuat data pengiriman.', style: AppTheme.body(size: 13, color: AppTheme.muted)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.ink,
              side: const BorderSide(color: AppTheme.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

Color _shipmentStatusColor(String status) => switch (status) {
      'dalam_perjalanan' => const Color(0xFFB86B22),
      'selesai' => const Color(0xFF16C38A),
      'siap_muat' => AppTheme.tertiaryGreen,
      _ => AppTheme.muted,
    };
