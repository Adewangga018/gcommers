import 'package:flutter/material.dart';

import '../models/commerce_models.dart';
import '../services/commerce_service.dart';
import '../utils/formatters.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final _commerceService = CommerceService();
  final _searchController = TextEditingController();
  late Future<List<Product>> _productsFuture;
  final Map<int, int> _quantities = {};
  List<Product> _products = const [];
  String _selectedCategory = 'Subsidi';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _productsFuture = _commerceService.getProducts(category: _selectedCategory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _productsFuture = _commerceService.getProducts(category: category);
    });
  }

  void _changeQuantity(Product product, int delta) {
    final current = _quantities[product.id] ?? 0;
    final next = (current + delta).clamp(0, product.stock);
    setState(() => _quantities[product.id] = next);
  }

  Future<void> _confirmOrder() async {
    final selected = Map<int, int>.fromEntries(_quantities.entries.where((entry) => entry.value > 0));
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu produk terlebih dahulu.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final order = await _commerceService.createOrder(quantities: selected);
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
    const Color primaryPurple = Color(0xFF38804B);
    const Color bgLight = Color(0xFFF4FAF5);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Pesanan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Gagal memuat produk: ${snapshot.error}'));
            }

            final products = snapshot.data!;
            _products = products;
            final query = _searchController.text.trim().toLowerCase();
            final visibleProducts = query.isEmpty
                ? products
                : products
                    .where(
                      (product) =>
                          product.name.toLowerCase().contains(query) ||
                          product.code.toLowerCase().contains(query),
                    )
                    .toList();

            return Column(
              children: [
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9E5F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TabChip(
                            label: 'Subsidi',
                            selected: _selectedCategory == 'Subsidi',
                            onTap: () => _loadCategory('Subsidi'),
                          ),
                        ),
                        Expanded(
                          child: _TabChip(
                            label: 'Retail',
                            selected: _selectedCategory == 'Retail',
                            onTap: () => _loadCategory('Retail'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari nama produk atau SKU...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCFC8E5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFCFC8E5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: primaryPurple, width: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 96),
                    itemCount: visibleProducts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final product = visibleProducts[index];
                      return _ProductCard(
                        product: product,
                        quantity: _quantities[product.id] ?? 0,
                        onAdd: () => _changeQuantity(product, 1),
                        onRemove: () => _changeQuantity(product, -1),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProductDetailPage(product: product),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFD0E8D4))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_selectedCount()} item dipilih',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(_estimatedTotal()),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _confirmOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    _submitting ? 'MEMPROSES...' : 'KONFIRMASI PESANAN',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _selectedCount() => _quantities.values.where((quantity) => quantity > 0).length;

  num _estimatedTotal() {
    var total = 0.0;
    for (final product in _products) {
      total += product.price * (_quantities[product.id] ?? 0);
    }
    return total;
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF38804B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? primaryPurple : Colors.black54,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
  });

  final Product product;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF38804B);

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
            border: Border.all(color: const Color(0xFFD3CCE8)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _iconBg(product.iconName),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_productIcon(product.iconName), color: primaryPurple, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.code.isEmpty ? product.name : '${product.code} - ${product.name}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.unit} - Stok: ${product.stock}',
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formatCurrency(product.price),
                      style: const TextStyle(color: primaryPurple, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EFFB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _StepperButton(icon: Icons.remove, color: Colors.grey[700]!, onTap: onRemove),
                    Container(
                      width: 34,
                      alignment: Alignment.center,
                      child: Text('$quantity', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    _StepperButton(icon: Icons.add, color: primaryPurple, filled: true, onTap: onAdd),
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

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    const Color primaryPurple = Color(0xFF38804B);
    const Color bgLight = Color(0xFFF4FAF5);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Produk', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD3CCE8)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: _iconBg(product.iconName),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_productIcon(product.iconName), color: primaryPurple, size: 34),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.15)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (product.code.isNotEmpty) _InfoChip(text: product.code),
                              _InfoChip(text: product.category),
                              _InfoChip(text: product.unit),
                              _InfoChip(text: product.status),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _DetailSection(
                title: 'Deskripsi',
                child: Text(product.description, style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87)),
              ),
              const SizedBox(height: 16),
              _DetailSection(
                title: 'Informasi Produk',
                child: Column(
                  children: [
                    _DetailRow(label: 'Kategori', value: product.category),
                    if (product.code.isNotEmpty) _DetailRow(label: 'Kode', value: product.code),
                    _DetailRow(label: 'Harga', value: formatCurrency(product.price)),
                    _DetailRow(label: 'Stok', value: '${product.stock}'),
                    _DetailRow(label: 'Minimal Pembelian', value: '${product.minimumOrder}'),
                    _DetailRow(label: 'Satuan', value: product.unit),
                    _DetailRow(label: 'Status', value: product.status),
                    _DetailRow(label: 'Rating', value: product.rating.toStringAsFixed(1)),
                  ],
                ),
              ),
              if (product.specification?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                _DetailSection(
                  title: 'Spesifikasi',
                  child: Text(
                    product.specification!,
                    style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.black87),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD3CCE8)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13))),
          const SizedBox(width: 12),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFF3EFFB), borderRadius: BorderRadius.circular(999)),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFF38804B), fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.color, required this.onTap, this.filled = false});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 40,
        decoration: BoxDecoration(
          color: filled ? color : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: filled ? Colors.white : color, size: 18),
      ),
    );
  }
}

IconData _productIcon(String iconName) => switch (iconName) {
      'water_drop' => Icons.water_drop_outlined,
      'eco' => Icons.eco_outlined,
      'spa' => Icons.spa_outlined,
      _ => Icons.inventory_2_outlined,
    };

Color _iconBg(String iconName) => switch (iconName) {
      'water_drop' => const Color(0xFFE5F0FF),
      'eco' => const Color(0xFFF0E2CF),
      'spa' => const Color(0xFFDDF3EA),
      _ => const Color(0xFFF0EEF7),
    };
