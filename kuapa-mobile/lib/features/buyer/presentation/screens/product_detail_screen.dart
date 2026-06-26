import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/kuapa_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _productDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final res = await ApiClient.instance.get('${ApiConstants.products}/$id');
  return res.data as Map<String, dynamic>;
});

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  double _qty = 1;
  bool _ordering = false;

  Future<void> _placeOrder(Map<String, dynamic> product) async {
    setState(() => _ordering = true);
    try {
      final user = ref.read(authUserProvider).valueOrNull!;
      await ApiClient.instance.post(ApiConstants.orders, data: {
        'buyerId': user.id,
        'buyerName': user.displayName,
        'farmerId': product['farmerId'],
        'farmerName': product['farmerName'],
        'items': [
          {
            'productId': product['id'],
            'productName': product['name'],
            'quantity': _qty,
            'unit': product['unit'],
            'unitPrice': product['pricePerUnit'],
          }
        ],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!'), backgroundColor: AppTheme.primary),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _ordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(_productDetailProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Produce Details')),
      body: product.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(message: e.toString()),
        data: (p) {
          final totalPrice = (double.tryParse(p['pricePerUnit'].toString()) ?? 0) * _qty;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero image placeholder
                      Container(
                        height: 220,
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        child: const Center(child: Icon(Icons.eco, size: 100, color: AppTheme.primary)),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(p['name'] ?? '',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('GHS ${p['pricePerUnit']}/${p['unit']}',
                                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Farmer info
                            Row(
                              children: [
                                const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['farmerName'] ?? 'Farmer',
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                    if (p['region'] != null)
                                      Text(p['region'],
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  ],
                                ),
                              ],
                            ),

                            const Divider(height: 24),

                            // Details
                            _InfoRow(icon: Icons.scale, label: 'Available', value: '${p['quantity']} ${p['unit']}'),
                            if (p['district'] != null)
                              _InfoRow(icon: Icons.location_on, label: 'District', value: p['district']),
                            if (p['harvestDate'] != null)
                              _InfoRow(icon: Icons.calendar_today, label: 'Harvest Date', value: p['harvestDate'].toString().substring(0, 10)),

                            if (p['description'] != null && p['description'].toString().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(p['description'], style: const TextStyle(color: AppTheme.textSecondary, height: 1.5)),
                            ],

                            const SizedBox(height: 24),

                            // Quantity selector
                            const Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton.filled(
                                  onPressed: _qty > 1 ? () => setState(() => _qty -= 1) : null,
                                  icon: const Icon(Icons.remove),
                                  style: IconButton.styleFrom(backgroundColor: AppTheme.primary.withValues(alpha: 0.1)),
                                ),
                                const SizedBox(width: 16),
                                Text('$_qty ${p['unit']}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 16),
                                IconButton.filled(
                                  onPressed: () => setState(() => _qty += 1),
                                  icon: const Icon(Icons.add),
                                  style: IconButton.styleFrom(backgroundColor: AppTheme.primary.withValues(alpha: 0.1)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))],
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Total', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text('GHS ${totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: KuapaButton(
                        label: 'Place Order',
                        onPressed: () => _placeOrder(p),
                        isLoading: _ordering,
                        icon: Icons.shopping_bag_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text('$label: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );
}
