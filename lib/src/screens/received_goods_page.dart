import 'package:flutter/material.dart';

import '../models/commerce_models.dart';
import '../services/commerce_service.dart';
import '../services/session_manager.dart';
import '../utils/formatters.dart';

class ReceivedGoodsPage extends StatefulWidget {
  const ReceivedGoodsPage({super.key});

  @override
  State<ReceivedGoodsPage> createState() => _ReceivedGoodsPageState();
}

class _ReceivedGoodsPageState extends State<ReceivedGoodsPage> {
  final _commerceService = CommerceService();
  Future<OrderDetail>? _detailFuture;
  String? _poNumber;
  bool _confirming = false;
  String _recipientName = '...';

  @override
  void initState() {
    super.initState();
    _loadRecipient();
  }

  Future<void> _loadRecipient() async {
    final session = await sessionManager.getSession();
    if (!mounted) return;
    setState(() => _recipientName = session?.displayName ?? '-');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final nextPoNumber = args is String ? args : 'PO-2026-10-9842';
    if (_poNumber != nextPoNumber) {
      _poNumber = nextPoNumber;
      _detailFuture = _commerceService.getOrderDetail(nextPoNumber);
    }
  }

  Future<void> _finish() async {
    final poNumber = _poNumber;
    if (poNumber == null) return;

    setState(() => _confirming = true);
    try {
      await _commerceService.confirmReceived(poNumber);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/history', (route) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan konfirmasi: $error')),
      );
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bg = Color(0xFF0F261F);
    const Color primaryGreen = Color(0xFF16C38A);
    const Color cardBg = Color(0xFF0F261F);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FutureBuilder<OrderDetail>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: primaryGreen));
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Gagal memuat barang: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                ),
              );
            }
            final order = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text('GCommers', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(color: primaryGreen.withValues(alpha: 0.16), shape: BoxShape.circle),
                    child: const Icon(Icons.check, color: primaryGreen, size: 46),
                  ),
                  const SizedBox(height: 26),
                  const Text(
                    'Barang Diterima!',
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(order.poNumber, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(formatDateTime(order.createdAt), style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detail Penerimaan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Colors.white12),
                        const SizedBox(height: 14),
                        ...order.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ReceivedRow(
                              title: item.productName,
                              subtitle: '${formatCurrency(item.unitPrice)} per ${item.unit}',
                              value: '${item.quantity} ${item.unit}',
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Colors.white12),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Penerima', style: TextStyle(color: Colors.white54, fontSize: 13)),
                            Text(_recipientName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _confirming ? null : _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 12,
                        shadowColor: primaryGreen.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        _confirming ? 'MENYIMPAN...' : 'SELESAI',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReceivedRow extends StatelessWidget {
  const _ReceivedRow({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.inventory_2_outlined, color: Colors.white54, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(value, style: const TextStyle(color: Color(0xFF16C38A), fontSize: 15, fontWeight: FontWeight.w800)),
      ],
    );
  }
}
