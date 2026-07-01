import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/crop_data.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/notif_bell.dart';
import '../../../../shared/widgets/product_image.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _seedProducts = [
  {'name': 'Fresh Tomatoes',  'pricePerUnit': '6.50', 'unit': 'kg',    'quantity': '200', 'region': 'Ashanti'},
  {'name': 'Sweet Plantain',  'pricePerUnit': '4.00', 'unit': 'bunch', 'quantity': '80',  'region': 'Brong-Ahafo'},
  {'name': 'Maize Grain',     'pricePerUnit': '2.80', 'unit': 'kg',    'quantity': '500', 'region': 'Northern'},
  {'name': 'Cocoyam',         'pricePerUnit': '5.00', 'unit': 'kg',    'quantity': '150', 'region': 'Eastern'},
];

const _seedBuyerOrders = [
  {'productName': 'Fresh Tomatoes', 'quantity': '20', 'unit': 'kg',    'totalAmount': '130.00', 'status': 'CONFIRMED'},
  {'productName': 'Maize Grain',    'quantity': '50', 'unit': 'kg',    'totalAmount': '140.00', 'status': 'DELIVERED'},
  {'productName': 'Sweet Plantain', 'quantity': '5',  'unit': 'bunch', 'totalAmount': '20.00',  'status': 'PENDING'},
];

final _featuredProductsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  try {
    final res      = await ApiClient.instance.get(ApiConstants.products, queryParams: {'limit': '6'});
    final products = (res.data['data'] as List?) ?? [];
    return products.isEmpty ? _seedProducts : products;
  } catch (_) {
    return _seedProducts;
  }
});

final _buyerProfileNameProvider = FutureProvider.autoDispose<String>((ref) async {
  final res = await ApiClient.instance.get(ApiConstants.buyerProfile);
  return (res.data['fullName'] as String?)?.trim() ?? '';
});

class BuyerDashboard extends ConsumerWidget {
  const BuyerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(authUserProvider).valueOrNull;
    final featured = ref.watch(_featuredProductsProvider);
    final fullName = ref.watch(_buyerProfileNameProvider).valueOrNull ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuapa'),
        actions: [
          const NotifBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authUserProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/buyer/chat'),
        backgroundColor: AppTheme.primary,
        tooltip: 'Messages',
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search bar ────────────────────────────────────────────────
            GestureDetector(
              onTap: () => context.go('/buyer/marketplace'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: AppTheme.textSecondary),
                    SizedBox(width: 10),
                    Text('Search for tomatoes, peppers…', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Welcome banner ────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1B5E20), AppTheme.primaryLight]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome, ${fullName.isNotEmpty ? fullName : (user?.username ?? 'Buyer')}!',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Fresh produce, direct from farmers',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Category strip ────────────────────────────────────────────
            const Text('Browse by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(label: 'All',        icon: Icons.grid_view,             onTap: () => context.go('/buyer/marketplace')),
                  _CategoryChip(label: 'Vegetables', icon: Icons.eco,                   onTap: () => context.go('/buyer/marketplace')),
                  _CategoryChip(label: 'Staples',    icon: Icons.grain,                 onTap: () => context.go('/buyer/marketplace')),
                  _CategoryChip(label: 'Fruits',     icon: Icons.apple,                 onTap: () => context.go('/buyer/marketplace')),
                  _CategoryChip(label: 'Legumes',    icon: Icons.spa,                   onTap: () => context.go('/buyer/marketplace')),
                  _CategoryChip(label: 'Spices',     icon: Icons.local_fire_department, onTap: () => context.go('/buyer/marketplace')),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Crop catalogue (always shown from local assets) ───────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Browse Crops', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.go('/buyer/marketplace'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              itemCount: CropData.all.length,
              itemBuilder: (_, i) => _CropCard(crop: CropData.all[i], onTap: () => context.go('/buyer/marketplace')),
            ),

            const SizedBox(height: 24),

            // ── Fresh Today (live API listings) ───────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Fresh Today', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.go('/buyer/marketplace'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            featured.when(
              loading: () => const LoadingView(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (products) => products.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.storefront_outlined, size: 32, color: Colors.grey.shade400),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'No live listings yet — check back soon!',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) => _ProductCard(product: products[i]),
                    ),
            ),

            const SizedBox(height: 24),

            // ── Recent Orders ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.go('/buyer/orders'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const _BuyerRecentOrders(),

            const SizedBox(height: 80), // space above FAB
          ],
        ),
      ),
    );
  }
}

// ─── Crop catalogue card (local assets + CropData pricing) ────────────────────

class _CropCard extends StatelessWidget {
  final CropInfo crop;
  final VoidCallback onTap;
  const _CropCard({required this.crop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop image from local assets
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    crop.asset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      child: const Center(child: Icon(Icons.eco, size: 48, color: AppTheme.primary)),
                    ),
                  ),
                  // Category badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        crop.category,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crop.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Market price',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                    const Spacer(),
                    Text(
                      'GHS ${crop.basePrice.toStringAsFixed(2)}/${crop.unit}',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Row(
                      children: [
                        Icon(Icons.storefront_outlined, size: 11, color: AppTheme.textSecondary),
                        SizedBox(width: 3),
                        Text(
                          'View listings',
                          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Live product card (from API) ─────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final name   = product['name']?.toString() ?? '';
    final price  = product['pricePerUnit']?.toString() ?? '0';
    final unit   = product['unit']?.toString() ?? '';
    final qty    = product['quantity']?.toString() ?? '0';
    final region = product['region']?.toString();
    final images = product['images'] as List?;

    return GestureDetector(
      onTap: () {
        final id = product['id'];
        if (id != null) {
          context.push('/buyer/product/$id');
        } else {
          context.go('/buyer/marketplace');
        }
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: ProductImage(productName: name, images: images, fit: BoxFit.cover),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('$qty $unit available',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    const Spacer(),
                    Text('GHS $price/$unit',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                    if (region != null)
                      Text(region,
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Category chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 72,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.primary, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ─── Buyer recent orders (seed fallback) ──────────────────────────────────────

class _BuyerRecentOrders extends StatefulWidget {
  const _BuyerRecentOrders();

  @override
  State<_BuyerRecentOrders> createState() => _BuyerRecentOrdersState();
}

class _BuyerRecentOrdersState extends State<_BuyerRecentOrders> {
  List<dynamic>? _orders;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res  = await ApiClient.instance.get(ApiConstants.myOrders);
      final all  = res.data as List? ?? [];
      final list = all.take(3).toList();
      if (mounted) setState(() { _orders = list.isEmpty ? _seedBuyerOrders : list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _orders = _seedBuyerOrders; _loading = false; });
    }
  }

  Color _statusColor(String s) => switch (s) {
    'PENDING'   => AppTheme.primaryLight,
    'CONFIRMED' => AppTheme.primary,
    'DELIVERED' => AppTheme.primary,
    'CANCELLED' => Colors.red,
    _           => AppTheme.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
    final orders = _orders ?? _seedBuyerOrders;
    return Column(
      children: orders.map((o) {
        final status = o['status']?.toString() ?? '';
        final color  = _statusColor(status);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.shopping_bag_outlined, color: color, size: 18),
            ),
            title: Text(
              '${o['productName'] ?? 'Order'} × ${o['quantity'] ?? ''} ${o['unit'] ?? ''}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text('GHS ${o['totalAmount'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
