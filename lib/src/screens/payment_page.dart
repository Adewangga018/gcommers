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
  Future<OrderDetail>? _orderFuture;
  String? _poNumber;
  bool _submitting = false;

  static const _primaryPurple = Color(0xFF3B309E);
  static const _bgLight = Color(0xFFF9F9FF);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final nextPo = args is String ? args : null;
    if (_poNumber != nextPo && nextPo != null) {
      _poNumber = nextPo;
      _orderFuture = _commerceService.getOrderDetail(nextPo);
    }
  }

  Future<void> _pay() async {
    final poNumber = _poNumber;
    if (poNumber == null) return;
    setState(() => _submitting = true);
    try {
      final result = await _commerceService.payOrder(poNumber: poNumber, method: 'MANDIRI');
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
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pembayaran',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 20)),
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
            if (snapshot.data == null) {
              return const Center(child: Text('Pesanan tidak ditemukan.'));
            }
            final order = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Order summary card ────────────────────────────
                        _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Nomor Pesanan',
                                          style: TextStyle(color: Colors.black54, fontSize: 12)),
                                      const SizedBox(height: 4),
                                      Text(order.poNumber,
                                          style: const TextStyle(
                                              fontSize: 16, fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFEAF1FF),
                                        borderRadius: BorderRadius.circular(8)),
                                    child: const Text('GCommers',
                                        style: TextStyle(
                                            color: _primaryPurple, fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 14),
                              const Text('Total Tagihan',
                                  style: TextStyle(color: Colors.black54, fontSize: 13)),
                              const SizedBox(height: 6),
                              Text(
                                formatCurrency(order.totalAmount),
                                style: const TextStyle(
                                    color: _primaryPurple,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Mandiri VA method card ────────────────────────
                        const Text('Metode Pembayaran',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _primaryPurple, width: 1.8),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF003D7C),
                                    borderRadius: BorderRadius.circular(10)),
                                alignment: Alignment.center,
                                child: const Text('mandiri',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Mandiri Virtual Account',
                                        style: TextStyle(
                                            fontSize: 15, fontWeight: FontWeight.w800)),
                                    SizedBox(height: 4),
                                    Text('Transfer via ATM, Livin\', atau Internet Banking.',
                                        style: TextStyle(color: Colors.black54, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.radio_button_checked, color: _primaryPurple),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── How to pay ────────────────────────────────────
                        const Text('Cara Pembayaran',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        _card(
                          child: Column(
                            children: [
                              _stepRow(1, 'Buka ATM Mandiri atau aplikasi Livin\' by Mandiri.'),
                              _stepRow(2, 'Pilih Pembayaran → Multi Payment.'),
                              _stepRow(3, 'Masukkan kode perusahaan 088908 lalu masukkan nomor Virtual Account.'),
                              _stepRow(4, 'Periksa detail tagihan lalu konfirmasi pembayaran.'),
                              _stepRow(5, 'Simpan bukti pembayaran sebagai referensi.', isLast: true),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // ── Confirm button ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE2DDF1)))),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _pay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                          : const Text('KONFIRMASI PEMBAYARAN',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD7D1EA)),
        ),
        child: child,
      );

  Widget _stepRow(int step, String text, {bool isLast = false}) => Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                  color: _primaryPurple.withAlpha(20),
                  shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('$step',
                  style: const TextStyle(
                      color: _primaryPurple, fontSize: 11, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
            ),
          ],
        ),
      );
}
