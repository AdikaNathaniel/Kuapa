import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/crop_data.dart';
import '../../../../shared/widgets/product_image.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';

const _ghanaRegions = [
  'Greater Accra', 'Ashanti', 'Western', 'Eastern', 'Central',
  'Volta', 'Northern', 'Upper East', 'Upper West', 'Bono',
  'Bono East', 'Ahafo', 'Savannah', 'North East', 'Oti', 'Western North',
];

// ─── Providers ───────────────────────────────────────────────────────────────

final _searchQueryProvider      = StateProvider<String>((ref) => '');
final _selectedCategoryProvider = StateProvider<String?>((ref) => null);
final _selectedRegionProvider   = StateProvider<String?>((ref) => null);
final _minPriceProvider         = StateProvider<double?>((ref) => null);
final _maxPriceProvider         = StateProvider<double?>((ref) => null);

final _marketplaceProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final search   = ref.watch(_searchQueryProvider);
  final category = ref.watch(_selectedCategoryProvider);
  final region   = ref.watch(_selectedRegionProvider);
  final minPrice = ref.watch(_minPriceProvider);
  final maxPrice = ref.watch(_maxPriceProvider);

  final res = await ApiClient.instance.get(ApiConstants.products, queryParams: {
    if (search.isNotEmpty) 'search': search,
    if (category != null)  'category': category,
    if (region != null)    'region': region,
    if (minPrice != null)  'minPrice': minPrice.toStringAsFixed(2),
    if (maxPrice != null)  'maxPrice': maxPrice.toStringAsFixed(2),
    'limit': '40',
  });
  return res.data as Map<String, dynamic>;
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    ref.read(_selectedRegionProvider.notifier).state = null;
    ref.read(_minPriceProvider.notifier).state       = null;
    ref.read(_maxPriceProvider.notifier).state       = null;
  }

  Future<void> _openFilterSheet() async {
    // Local temps so we only commit on Apply
    String? tempRegion   = ref.read(_selectedRegionProvider);
    double? tempMinPrice = ref.read(_minPriceProvider);
    double? tempMaxPrice = ref.read(_maxPriceProvider);

    final minCtrl = TextEditingController(
      text: tempMinPrice != null ? tempMinPrice.toStringAsFixed(0) : '',
    );
    final maxCtrl = TextEditingController(
      text: tempMaxPrice != null ? tempMaxPrice.toStringAsFixed(0) : '',
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20, 20, 20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        tempRegion   = null;
                        tempMinPrice = null;
                        tempMaxPrice = null;
                        minCtrl.clear();
                        maxCtrl.clear();
                      });
                    },
                    child: const Text('Clear All', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Region ────────────────────────────────────────────────
              const Text('Region', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: tempRegion,
                decoration: const InputDecoration(
                  hintText: 'Any region',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any region')),
                  ..._ghanaRegions.map(
                    (r) => DropdownMenuItem(value: r, child: Text(r)),
                  ),
                ],
                onChanged: (v) => setSheetState(() => tempRegion = v),
              ),

              const SizedBox(height: 20),

              // ── Price range ───────────────────────────────────────────
              const Text('Price Range (GHS)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Min price',
                        prefixIcon: Icon(Icons.attach_money, size: 18),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      onChanged: (v) => tempMinPrice = double.tryParse(v),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('–', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: maxCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Max price',
                        prefixIcon: Icon(Icons.attach_money, size: 18),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      onChanged: (v) => tempMaxPrice = double.tryParse(v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Apply ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ref.read(_selectedRegionProvider.notifier).state = tempRegion;
                    ref.read(_minPriceProvider.notifier).state       = tempMinPrice;
                    ref.read(_maxPriceProvider.notifier).state       = tempMaxPrice;
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Apply Filters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    minCtrl.dispose();
    maxCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketplace      = ref.watch(_marketplaceProvider);
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final selectedRegion   = ref.watch(_selectedRegionProvider);
    final minPrice         = ref.watch(_minPriceProvider);
    final maxPrice         = ref.watch(_maxPriceProvider);

    final activeFilters = (selectedRegion != null ? 1 : 0) +
        (minPrice != null ? 1 : 0) +
        (maxPrice != null ? 1 : 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: Column(
        children: [
          // ── Search + filter button row ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search produce…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref.read(_searchQueryProvider.notifier).state = '';
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => ref.read(_searchQueryProvider.notifier).state = v,
                  ),
                ),
                const SizedBox(width: 10),
                Badge(
                  isLabelVisible: activeFilters > 0,
                  label: Text('$activeFilters'),
                  backgroundColor: AppTheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'Filters',
                    style: IconButton.styleFrom(
                      backgroundColor: activeFilters > 0
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : null,
                      foregroundColor: activeFilters > 0
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                    onPressed: _openFilterSheet,
                  ),
                ),
              ],
            ),
          ),

          // ── Category chips ────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: CropData.categories.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return ChoiceChip(
                    label: const Text('All'),
                    selected: selectedCategory == null,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(
                      color: selectedCategory == null ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) =>
                        ref.read(_selectedCategoryProvider.notifier).state = null,
                  );
                }
                final cat = CropData.categories[i - 1];
                final isSelected = selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) =>
                      ref.read(_selectedCategoryProvider.notifier).state = cat,
                );
              },
            ),
          ),

          // ── Active filter pills ───────────────────────────────────────
          if (activeFilters > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (selectedRegion != null)
                          _FilterPill(
                            label: selectedRegion,
                            onRemove: () => ref.read(_selectedRegionProvider.notifier).state = null,
                          ),
                        if (minPrice != null)
                          _FilterPill(
                            label: 'Min GHS ${minPrice.toStringAsFixed(0)}',
                            onRemove: () => ref.read(_minPriceProvider.notifier).state = null,
                          ),
                        if (maxPrice != null)
                          _FilterPill(
                            label: 'Max GHS ${maxPrice.toStringAsFixed(0)}',
                            onRemove: () => ref.read(_maxPriceProvider.notifier).state = null,
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _clearAllFilters,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Clear all', style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                ],
              ),
            ),

          // ── Product grid ──────────────────────────────────────────────
          Expanded(
            child: marketplace.when(
              loading: () => const LoadingView(message: 'Loading produce…'),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.refresh(_marketplaceProvider),
              ),
              data: (data) {
                final products = (data['data'] as List?) ?? [];
                final total    = data['total'] ?? 0;

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'No produce found',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try adjusting your filters or search term',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                        ),
                        if (activeFilters > 0) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _clearAllFilters,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear Filters'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: Text(
                        '$total listing${total == 1 ? '' : 's'} found',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: products.length,
                        itemBuilder: (_, i) => _ProductCard(product: products[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Active filter pill ───────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterPill({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.only(left: 10, right: 4, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close, size: 14, color: AppTheme.primary),
            ),
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
    final name      = product['name']?.toString() ?? '';
    final price     = product['pricePerUnit']?.toString() ?? '0';
    final unit      = product['unit']?.toString() ?? '';
    final qty       = product['quantity']?.toString() ?? '0';
    final region  = product['region']?.toString();
    final farmer  = product['farmerName']?.toString() ?? '';
    final images  = product['images'] as List?;

    return GestureDetector(
      onTap: () => context.push('/buyer/product/${product['id']}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop image
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(
                    productName: name,
                    images: images,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$qty $unit',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'by $farmer',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (region != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 11, color: AppTheme.textSecondary),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              region,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    Text(
                      'GHS $price/$unit',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
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
