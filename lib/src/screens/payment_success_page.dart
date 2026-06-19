import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/commerce_models.dart';
import '../utils/formatters.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  static const _navy = Color(0xFF0F261F);
  static const _purple = Color(0xFF2F6C3F);
  static const _mandiriBlue = Color(0xFF0F261F);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final result = args is PaymentResult ? args : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: const Text('Konfirmasi Pembayaran',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Success banner ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_purple, _navy],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 16),
                    const Text('Pembayaran Dikonfirmasi',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                      result == null ? '-' : formatCurrency(result.totalAmount),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── VA number card ──────────────────────────────────────────
              if (result != null) ...[
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                                color: _mandiriBlue,
                                borderRadius: BorderRadius.circular(8)),
                            alignment: Alignment.center,
                            child: const Text('M',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 10),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Mandiri Virtual Account',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w700)),
                              Text('Nomor VA untuk pembayaran',
                                  style:
                                      TextStyle(color: Colors.black54, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              result.virtualAccount,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                  color: _purple),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: result.virtualAccount));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Nomor VA disalin.'),
                                    duration: Duration(seconds: 2)),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded,
                                color: _purple, size: 22),
                            tooltip: 'Salin',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 14, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            'Berlaku hingga ${formatDateTime(result.expiredAt)}',
                            style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Order details ─────────────────────────────────────────
                _card(
                  child: Column(
                    children: [
                      _detailRow('No. Pesanan', result.poNumber),
                      const Divider(height: 20),
                      _detailRow('Metode', 'Mandiri Virtual Account'),
                      const Divider(height: 20),
                      _detailRow('Status', _statusLabel(result.status)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Instructions ──────────────────────────────────────────
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cara Pembayaran',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      ...result.instructions.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                        color: _purple.withAlpha(20),
                                        shape: BoxShape.circle),
                                    alignment: Alignment.center,
                                    child: Text('${e.key + 1}',
                                        style: const TextStyle(
                                            color: _purple,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(e.value,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black87,
                                            height: 1.4)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('KEMBALI KE BERANDA',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamedAndRemoveUntil('/history', (_) => false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _purple,
                    side: const BorderSide(color: _purple),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('LIHAT RIWAYAT PESANAN',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
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
          border: Border.all(color: const Color(0xFFB5D4BC)),
        ),
        child: child,
      );

  String _statusLabel(String status) => switch (status) {
        'pending_payment' || 'pending' => 'Menunggu Pembayaran',
        'paid' => 'Pembayaran Diterima',
        'expired' => 'Kedaluwarsa',
        _ => status,
      };

  Widget _detailRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      );
}
