import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _myListingsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final user = ref.watch(authUserProvider).valueOrNull;
  if (user == null) return [];
  final res = await ApiClient.instance.get('${ApiConstants.myListings}');
  return res.data as List;
});

class MyListingsScreen extends ConsumerWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(_myListingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/farmer/add-product'),
        icon: const Icon(Icons.add),
        label: const Text('Add Produce'),
        backgroundColor: AppTheme.primary,
      ),
      body: listings.when(
        loading: () => const LoadingView(message: 'Loading your listings...'),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(_myListingsProvider)),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No listings yet', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('Tap + to add your first produce', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (_, i) => _ListingCard(product: items[i], onDeleted: () => ref.refresh(_myListingsProvider)),
          );
        },
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onDeleted;

  const _ListingCard({required this.product, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final isAvailable = product['isAvailable'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(product['name'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable ? AppTheme.primary.withValues(alpha: 0.12) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Sold Out',
                    style: TextStyle(fontSize: 12, color: isAvailable ? AppTheme.primary : Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.scale, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text('${product['quantity']} ${product['unit']}', style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(width: 16),
                const Icon(Icons.attach_money, size: 14, color: AppTheme.textSecondary),
                Text('GHS ${product['pricePerUnit']}/${product['unit']}', style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
            if (product['region'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(product['region'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ],
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () async {
                    await ApiClient.instance.delete('${ApiConstants.products}/${product['id']}');
                    onDeleted();
                  },
                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
