import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/product_image.dart';
import '../../../../shared/widgets/notif_bell.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _featuredProductsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiClient.instance.get(ApiConstants.products, queryParams: {'limit': '6'});
  return (res.data['data'] as List?) ?? [];
});

class BuyerDashboard extends ConsumerWidget {
  const BuyerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user     = ref.watch(authUserProvider).valueOrNull;
    final featured = ref.watch(_featuredProductsProvider);

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
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

            // Welcome banner
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
                  Text('Welcome, ${user?.displayName ?? 'Buyer'}!',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  const Text('Fresh produce, direct from farmers',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Category strip
            const Text('Browse by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(label: 'All',        icon: Icons.grid_view,       onTap: () => context.go('/buyer/marketplace')),
                  _CategoryChip(label: 'Vegetables', icon: Icons.eco,             onTap: () => context.go('/buyer/marketplace')),
                  _CategoryChip(label: 'Staples',    icon: Icons.grain,           onTap: () => context.go('/buyer/marketplace')),
                  _CategoryChip(label: 'Fruits',     icon: Icons.apple,           onTap: () => context.go('/buyer/marketplace')),
                  _CategoryChip(label: 'Legumes',    icon: Icons.spa,             onTap: () => context.go('/buyer/marketplace')),
                  _CategoryChip(label: 'Spices',     icon: Icons.local_fire_department, onTap: () => context.go('/buyer/marketplace')),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Fresh Today
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
                  ? _EmptyProducts(onBrowse: () => context.go('/buyer/marketplace'))
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
              Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyProducts extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyProducts({required this.onBrowse});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.storefront_outlined, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            const Text('No products yet', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            TextButton(onPressed: onBrowse, child: const Text('Browse Marketplace')),
          ],
        ),
      );
}

// ─── Product card ─────────────────────────────────────────────────────────────

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
      onTap: () => context.push('/buyer/product/${product['id']}'),
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
                      Text(region, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
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
