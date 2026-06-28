import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/crop_data.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/kuapa_button.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _productDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
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
  double _qty         = 1;
  bool _ordering      = false;
  bool _startingChat  = false;

  Future<void> _placeOrder(Map<String, dynamic> product) async {
    setState(() => _ordering = true);
    try {
      final user = ref.read(authUserProvider).valueOrNull!;
      await ApiClient.instance.post(ApiConstants.orders, data: {
        'buyerId':    user.id,
        'buyerName':  user.displayName,
        'farmerId':   product['farmerId'],
        'farmerName': product['farmerName'],
        'items': [
          {
            'productId':   product['id'],
            'productName': product['name'],
            'quantity':    _qty,
            'unit':        product['unit'],
            'unitPrice':   product['pricePerUnit'],
          }
        ],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: AppTheme.primary,
          ),
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

  Future<void> _startChat(Map<String, dynamic> product) async {
    setState(() => _startingChat = true);
    try {
      // Gateway reads p1Id/p1Name from JWT; we only supply the other party
      final res = await ApiClient.instance.post(
        ApiConstants.conversations,
        data: {
          'p2Id':   product['farmerId'],
          'p2Name': product['farmerName'],
        },
      );
      final conv = res.data as Map<String, dynamic>;
      if (mounted) {
        context.push('/chat/${conv['id']}', extra: product['farmerName']?.toString() ?? 'Farmer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open chat: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _startingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(_productDetailProvider(widget.productId));

    return Scaffold(
      body: product.when(
        loading: () => const Scaffold(body: LoadingView()),
        error:   (e, _) => Scaffold(body: ErrorView(message: e.toString())),
        data: (p) {
          final name       = p['name']?.toString() ?? '';
          final price      = double.tryParse(p['pricePerUnit'].toString()) ?? 0;
          final unit       = p['unit']?.toString() ?? '';
          final qty        = p['quantity']?.toString() ?? '0';
          final region     = p['region']?.toString();
          final district   = p['district']?.toString();
          final farmer     = p['farmerName']?.toString() ?? 'Farmer';
          final desc       = p['description']?.toString() ?? '';
          final assetPath  = CropData.assetFor(name);

          return CustomScrollView(
            slivers: [
              // Hero image in a SliverAppBar
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.eco, size: 100, color: AppTheme.primary),
                        ),
                      ),
                      // Gradient for AppBar readability
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + price chip
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  'GHS ${price.toStringAsFixed(2)}/$unit',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Info chips row
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              _InfoChip(
                                icon: Icons.scale_outlined,
                                label: '$qty $unit available',
                              ),
                              if (region != null)
                                _InfoChip(icon: Icons.location_on_outlined, label: region),
                              if (district != null)
                                _InfoChip(icon: Icons.map_outlined, label: district),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Farmer card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                                  child: const Icon(Icons.person, color: AppTheme.primary),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      farmer,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const Text(
                                      'Verified Farmer',
                                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                const Icon(Icons.verified, size: 20, color: AppTheme.primary),
                                const SizedBox(width: 4),
                                _startingChat
                                    ? const SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primary,
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primary),
                                        tooltip: 'Chat with farmer',
                                        onPressed: () => _startChat(p),
                                      ),
                              ],
                            ),
                          ),

                          if (desc.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Text(
                              'About this produce',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              desc,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                height: 1.6,
                                fontSize: 14,
                              ),
                            ),
                          ],

                          const SizedBox(height: 28),

                          // Quantity selector
                          const Text(
                            'Select Quantity',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onPressed: _qty > 1 ? () => setState(() => _qty -= 1) : null,
                              ),
                              const SizedBox(width: 20),
                              Text(
                                '$_qty $unit',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 20),
                              _QtyButton(
                                icon: Icons.add,
                                onPressed: () => setState(() => _qty += 1),
                              ),
                            ],
                          ),

                          const SizedBox(height: 100), // bottom padding for the sticky bar
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: product.whenOrNull(
        data: (p) {
          final price      = double.tryParse(p['pricePerUnit'].toString()) ?? 0;
          final totalPrice = price * _qty;

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    Text(
                      'GHS ${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
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
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppTheme.textSecondary),
            const SizedBox(width: 5),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      );
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QtyButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) => Material(
        color: onPressed != null
            ? AppTheme.primary.withValues(alpha: 0.12)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              icon,
              size: 22,
              color: onPressed != null ? AppTheme.primary : Colors.grey.shade400,
            ),
          ),
        ),
      );
}
