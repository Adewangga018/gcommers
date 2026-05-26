import 'package:flutter/material.dart';

import '../models/commerce_models.dart';
import '../services/commerce_service.dart';
import '../utils/formatters.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _commerceService = CommerceService();
  String _selectedMethod = 'BRI';
  Future<OrderDetail>? _orderFuture;
  String? _poNumber;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final nextPoNumber = args is String ? args : 'PO-2026-10-9842';
    if (_poNumber != nextPoNumber) {
      _poNumber = nextPoNumber;
      _orderFuture = _commerceService.getOrderDetail(nextPoNumber);
    }
  }

  Future<void> _pay() async {
    final poNumber = _poNumber;
    if (poNumber == null) return;

    setState(() => _submitting = true);
    try {
      final result = await _commerceService.payOrder(poNumber: poNumber, method: _selectedMethod);
      if (!mounted) return;
      Navigator.of(context).pushNamed('/payment-success', arguments: result);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pembayaran gagal: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF3B309E);
    const Color bgLight = Color(0xFFF9F9FF);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pembayaran', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<OrderDetail>(
          future: _orderFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Gagal memuat tagihan: ${snapshot.error}'));
            }
            final order = snapshot.data!;
            return Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD7D1EA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nomor Pesanan', style: TextStyle(color: Colors.black54, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(order.poNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF1FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('GCommers', style: TextStyle(color: primaryPurple, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        const Text('Total Tagihan', style: TextStyle(color: Colors.black54, fontSize: 13)),
                        const SizedBox(height: 6),
                        Text(
                          formatCurrency(order.totalAmount),
                          style: const TextStyle(color: primaryPurple, fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Pilih Metode Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _PaymentMethodCard(
                    logoBg: const Color(0xFF00529B),
                    logoText: 'BRI',
                    title: 'BRI Virtual Account',
                    description: 'Verifikasi otomatis, bebas biaya admin.',
                    selected: _selectedMethod == 'BRI',
                    onTap: () => setState(() => _selectedMethod = 'BRI'),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _PaymentMethodCard(
                    logoBg: const Color(0xFF003D7C),
                    logoText: 'mandiri',
                    title: 'Mandiri Virtual Account',
                    description: 'Transfer dari Bank Mandiri.',
                    selected: _selectedMethod == 'MANDIRI',
                    onTap: () => setState(() => _selectedMethod = 'MANDIRI'),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _pay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _submitting ? 'MEMPROSES...' : 'LANJUT BAYAR',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.logoBg,
    required this.logoText,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final Color logoBg;
  final String logoText;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF3B309E);

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
            border: Border.all(
              color: selected ? primaryPurple : const Color(0xFFCFC8E5),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: logoBg, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: Text(
                  logoText,
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? primaryPurple : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
