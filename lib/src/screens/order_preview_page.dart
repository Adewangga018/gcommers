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
      final quantity = widget.args.quantities[product.id] ?? 0;
      if (quantity <= 0) continue;
      total += product.price * quantity * 1000;
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

  double get _total => _subtotal + _shipping;

  bool get _hasAddress {
    final current = _current;
    return current != null && current.kecamatan != null && current.address.trim().isNotEmpty;
  }

  Future<void> _openAddressDetail() async {
    final updated = await showModalBottomSheet<EditableAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddressDetailSheet(address: _current ?? const EditableAddress()),
    );
    if (updated != null) {
      setState(() => _current = updated);
    }
  }

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
                    _addressSummaryCard(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        Text('${_selectedProducts.length} produk',
                            style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
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
                          const Divider(height: 16),
                          _totalRow('Total', _total, emphasize: true),
                        ],
                      ),
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

  Widget _addressSummaryCard() {
    final current = _current;
    final session = _session;
    final name = (session?.picName?.trim().isNotEmpty ?? false) ? session!.picName!.trim() : session?.displayName ?? '';
    final phone = session?.phone?.trim();

    final addressLine = current == null
        ? ''
        : [
            current.address.trim(),
            current.kecamatan?.nama,
            current.kabupaten?.nama,
            current.provinsi?.nama,
            current.kodePos.trim(),
          ].where((part) => part != null && part.trim().isNotEmpty).join(', ');

    return InkWell(
      onTap: _openAddressDetail,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFB5D4BC)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.location_on, color: _primaryPurple, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: _hasAddress
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (phone != null && phone.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(phone, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          addressLine,
                          style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.35),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  : const Text(
                      'Lengkapi alamat pengiriman',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _primaryPurple),
                    ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
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

class _AddressDetailSheet extends StatelessWidget {
  const _AddressDetailSheet({required this.address});

  final EditableAddress address;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Alamat Pengiriman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 20),
            _row('Provinsi', address.provinsi?.nama),
            _row('Kabupaten/Kota', address.kabupaten?.nama),
            _row('Kecamatan', address.kecamatan?.nama),
            _row('Kelurahan/Desa', address.kelurahan),
            _row('Kode Pos', address.kodePos),
            _row('Alamat Lengkap', address.address),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final edited = await Navigator.of(context).push<EditableAddress>(
                    MaterialPageRoute(builder: (_) => _AddressEditPage(initialAddress: address)),
                  );
                  if (edited != null && context.mounted) {
                    Navigator.of(context).pop(edited);
                  }
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Ubah Alamat'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    final display = (value == null || value.trim().isEmpty) ? '-' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13))),
          const SizedBox(width: 8),
          Expanded(child: Text(display, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}

class _AddressEditPage extends StatefulWidget {
  const _AddressEditPage({required this.initialAddress});

  final EditableAddress initialAddress;

  @override
  State<_AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<_AddressEditPage> {
  late EditableAddress _value = widget.initialAddress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Ubah Alamat',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: AddressEditorForm(
            initialAddress: _value,
            onChanged: (value) => _value = value,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_value),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F6C3F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Simpan Alamat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ),
      ),
    );
  }
}
