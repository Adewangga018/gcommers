import 'package:flutter/material.dart';

import '../models/auth_models.dart';
import '../models/commerce_models.dart';
import '../services/auth_service.dart';
import '../services/commerce_service.dart';
import '../services/session_manager.dart';
import '../utils/formatters.dart';
import '../widgets/address_editor.dart';

class OrderPreviewArgs {
  const OrderPreviewArgs({
    required this.products,
    required this.quantities,
    required this.userEmail,
    required this.region,
    required this.kecamatan,
  });

  final List<Product> products;
  final Map<int, int> quantities;
  final String? userEmail;
  final String? region;
  final String? kecamatan;
}

class OrderPreviewPage extends StatefulWidget {
  const OrderPreviewPage({super.key, required this.args});

  final OrderPreviewArgs args;

  @override
  State<OrderPreviewPage> createState() => _OrderPreviewPageState();
}

class _OrderPreviewPageState extends State<OrderPreviewPage> {
  static const _primaryPurple = Color(0xFF2F6C3F);

  final _authService = AuthService();
  final _commerceService = CommerceService();

  AuthSession? _session;
  EditableAddress? _current;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = await sessionManager.getSession();
    if (!mounted) return;
    setState(() {
      _session = session;
      _current = EditableAddress.fromSession(session);
      _loading = false;
    });
  }

  List<Product> get _selectedProducts => widget.args.products
      .where((p) => (widget.args.quantities[p.id] ?? 0) > 0)
      .toList();

  double get _subtotal {
    var total = 0.0;
    for (final product in widget.args.products) {
      total += product.price * (widget.args.quantities[product.id] ?? 0);
    }
    return total;
  }

  double get _shipping {
    var total = 0.0;
    for (final product in widget.args.products) {
      final quantity = widget.args.quantities[product.id] ?? 0;
      if (quantity <= 0) continue;
      total += product.biayaPengirimanPerKg * quantity * 1000;
    }
    return total;
  }

  double get _tax {
    for (final product in widget.args.products) {
      if ((widget.args.quantities[product.id] ?? 0) > 0) {
        return _subtotal * product.pajakPphPersen / 100;
      }
    }
    return 0;
  }

  double get _total => _subtotal + _shipping + _tax;

  Future<void> _continueToPayment() async {
    final session = _session;
    final current = _current;
    setState(() => _submitting = true);
    try {
      if (session != null && current != null) {
        final updated = await _authService.updateAddress(
          email: session.email,
          provinsiId: current.provinsi?.id,
          kabupatenId: current.kabupaten?.id,
          kecamatanId: current.kecamatan?.id,
          kelurahan: current.kelurahan,
          kodePos: current.kodePos,
          address: current.address,
          latitude: current.latitude,
          longitude: current.longitude,
        );
        await sessionManager.saveSession(updated);
      }

      final order = await _commerceService.createOrder(
        userEmail: widget.args.userEmail,
        region: widget.args.region,
        kecamatan: widget.args.kecamatan,
        quantities: widget.args.quantities,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamed('/payment', arguments: order.poNumber);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat pesanan: $error')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Preview Pesanan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ringkasan Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    _card(
                      child: Column(
                        children: [
                          for (final product in _selectedProducts) ...[
                            _itemRow(product, widget.args.quantities[product.id] ?? 0),
                            const Divider(height: 16),
                          ],
                          _totalRow('Subtotal', _subtotal),
                          const SizedBox(height: 6),
                          _totalRow('Ongkir', _shipping),
                          const SizedBox(height: 6),
                          _totalRow('Pajak', _tax),
                          const Divider(height: 16),
                          _totalRow('Total', _total, emphasize: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Alamat Pengiriman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    AddressEditorForm(
                      initialAddress: _current ?? const EditableAddress(),
                      onChanged: (value) => _current = value,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _continueToPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Text('LANJUTKAN KE PEMBAYARAN',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
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

  Widget _itemRow(Product product, int quantity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${product.name} x$quantity',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            formatCurrency(product.price * quantity),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 16 : 13,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
            color: emphasize ? Colors.black87 : Colors.black54,
          ),
        ),
        Text(
          formatCurrency(value),
          style: TextStyle(
            fontSize: emphasize ? 18 : 13,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            color: emphasize ? _primaryPurple : Colors.black87,
          ),
        ),
      ],
    );
  }
}
