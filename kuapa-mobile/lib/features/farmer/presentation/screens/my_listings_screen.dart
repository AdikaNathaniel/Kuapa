import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/crop_data.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/kuapa_button.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _myListingsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(authUserProvider);
  final res = await ApiClient.instance.get(ApiConstants.myListings);
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
        foregroundColor: Colors.white,
      ),
      body: listings.when(
        loading: () => const LoadingView(message: 'Loading your listings...'),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(_myListingsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No listings yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + Add Produce to create your first listing',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: items.length,
            itemBuilder: (_, i) => _ListingCard(
              product: items[i],
              onRefresh: () => ref.refresh(_myListingsProvider),
            ),
          );
        },
      ),
    );
  }
}

// ─── Listing Card ─────────────────────────────────────────────────────────────

class _ListingCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onRefresh;

  const _ListingCard({required this.product, required this.onRefresh});

  @override
  State<_ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<_ListingCard> {
  late bool _isAvailable;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _isAvailable = widget.product['isAvailable'] == true;
  }

  Future<void> _toggleAvailability() async {
    setState(() => _toggling = true);
    try {
      await ApiClient.instance.patch(
        '${ApiConstants.products}/${widget.product['id']}',
        data: {'isAvailable': !_isAvailable},
      );
      setState(() => _isAvailable = !_isAvailable);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _openEditSheet() async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditInventorySheet(product: widget.product),
    );
    if (updated == true) widget.onRefresh();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Listing'),
        content: Text('Remove "${widget.product['name']}" from your listings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ApiClient.instance.delete('${ApiConstants.products}/${widget.product['id']}');
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name      = widget.product['name']?.toString() ?? '';
    final qty       = widget.product['quantity']?.toString() ?? '0';
    final unit      = widget.product['unit']?.toString() ?? '';
    final price     = widget.product['pricePerUnit']?.toString() ?? '0';
    final region    = widget.product['region']?.toString();
    final assetPath = CropData.assetFor(name);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Column(
        children: [
          // ── Image banner ──────────────────────────────────────────────────
          SizedBox(
            height: 140,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    child: const Center(
                      child: Icon(Icons.eco, size: 56, color: AppTheme.primary),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                          ),
                        ),
                      ),
                      // ── Availability toggle ───────────────────────────
                      GestureDetector(
                        onTap: _toggling ? null : _toggleAvailability,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _isAvailable ? AppTheme.primary : Colors.grey.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: _toggling
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isAvailable
                                          ? Icons.check_circle_outline
                                          : Icons.cancel_outlined,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isAvailable ? 'Available' : 'Sold Out',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Stats row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Row(
              children: [
                _Stat(icon: Icons.scale_outlined, label: '$qty $unit'),
                const SizedBox(width: 20),
                _Stat(
                  icon: Icons.attach_money,
                  label: 'GHS $price/$unit',
                  color: AppTheme.primary,
                ),
                if (region != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stat(
                      icon: Icons.location_on_outlined,
                      label: region,
                      overflow: true,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Actions ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                // Quick restock hint
                Expanded(
                  child: Text(
                    'Tap badge to toggle availability',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ),
                TextButton.icon(
                  onPressed: _openEditSheet,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit / Inventory Update Bottom Sheet ─────────────────────────────────────

class _EditInventorySheet extends StatefulWidget {
  final Map<String, dynamic> product;
  const _EditInventorySheet({required this.product});

  @override
  State<_EditInventorySheet> createState() => _EditInventorySheetState();
}

class _EditInventorySheetState extends State<_EditInventorySheet> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;
  late bool _isAvailable;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _qtyCtrl    = TextEditingController(text: widget.product['quantity']?.toString() ?? '');
    _priceCtrl  = TextEditingController(text: widget.product['pricePerUnit']?.toString() ?? '');
    _isAvailable = widget.product['isAvailable'] == true;
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty   = double.tryParse(_qtyCtrl.text);
    final price = double.tryParse(_priceCtrl.text);

    if (qty == null || price == null) {
      setState(() => _error = 'Enter valid numbers for quantity and price');
      return;
    }
    setState(() { _saving = true; _error = null; });

    try {
      await ApiClient.instance.patch(
        '${ApiConstants.products}/${widget.product['id']}',
        data: {
          'quantity':    qty,
          'pricePerUnit': price,
          'isAvailable': _isAvailable,
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = 'Failed to update: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.product['name']?.toString() ?? '';
    final unit = widget.product['unit']?.toString() ?? '';

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  CropData.assetFor(name),
                  width: 48, height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48, height: 48,
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.eco, color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text('Update inventory', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quantity
          TextFormField(
            controller: _qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Quantity in stock ($unit)',
              prefixIcon: const Icon(Icons.scale_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Price
          TextFormField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Price per $unit (GHS)',
              prefixIcon: const Icon(Icons.attach_money),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Availability toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  _isAvailable ? Icons.storefront_outlined : Icons.store_outlined,
                  color: _isAvailable ? AppTheme.primary : AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isAvailable ? 'Listed as Available' : 'Listed as Sold Out',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isAvailable ? AppTheme.primary : AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        _isAvailable
                            ? 'Buyers can see and order this produce'
                            : 'Hidden from buyers until restocked',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
                  activeThumbColor: AppTheme.primary,
                  activeTrackColor: AppTheme.primary.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],

          const SizedBox(height: 24),
          KuapaButton(
            label: 'Save Changes',
            onPressed: _save,
            isLoading: _saving,
            icon: Icons.save_outlined,
          ),
        ],
      ),
    );
  }
}

// ─── Shared stat widget ───────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool overflow;

  const _Stat({required this.icon, required this.label, this.color, this.overflow = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppTheme.textSecondary),
          const SizedBox(width: 4),
          overflow
              ? Flexible(
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 12, color: color ?? AppTheme.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : Text(label, style: TextStyle(fontSize: 12, color: color ?? AppTheme.textSecondary)),
        ],
      );
}
