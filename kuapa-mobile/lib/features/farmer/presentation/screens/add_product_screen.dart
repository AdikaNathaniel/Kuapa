import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/crop_data.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/kuapa_button.dart';
import '../../../../shared/widgets/kuapa_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _ghanaRegions = [
  'Greater Accra', 'Ashanti', 'Western', 'Eastern', 'Central',
  'Volta', 'Northern', 'Upper East', 'Upper West', 'Bono',
  'Bono East', 'Ahafo', 'Savannah', 'North East', 'Oti', 'Western North',
];

const _units = ['KG', 'BAG', 'CRATE', 'BUNCH', 'PIECE', 'BASKET', 'TUBER'];

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  final _formKey    = GlobalKey<FormState>();
  final _priceCtrl  = TextEditingController();
  final _qtyCtrl    = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _distCtrl   = TextEditingController();

  CropInfo? _selectedCrop;
  String    _unit     = 'KG';
  String?   _region;
  bool      _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: CropData.categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _descCtrl.dispose();
    _distCtrl.dispose();
    super.dispose();
  }

  void _selectCrop(CropInfo crop) {
    setState(() {
      _selectedCrop = crop;
      _unit = crop.unit.toUpperCase();
      if (_priceCtrl.text.isEmpty) {
        _priceCtrl.text = crop.basePrice.toStringAsFixed(2);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crop first')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authUserProvider).valueOrNull!;
      await ApiClient.instance.post(ApiConstants.products, data: {
        'farmerId':     user.id,
        'farmerName':   user.displayName,
        'name':         _selectedCrop!.name,
        'categoryName': _selectedCrop!.category,
        'imageAsset':   _selectedCrop!.asset,
        'description':  _descCtrl.text.trim(),
        'quantity':     double.parse(_qtyCtrl.text),
        'unit':         _unit,
        'pricePerUnit': double.parse(_priceCtrl.text),
        if (_region != null) 'region': _region,
        if (_distCtrl.text.isNotEmpty) 'district': _distCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produce listed successfully!'),
            backgroundColor: AppTheme.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Crop picker ────────────────────────────────────────────────────────────

  Widget _cropPicker() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Crop',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            tabs: CropData.categories.map((c) => Tab(text: c)).toList(),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 130,
            child: TabBarView(
              controller: _tabCtrl,
              children: CropData.categories.map((cat) {
                final crops = CropData.byCategory(cat);
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: crops.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _CropTile(
                    crop: crops[i],
                    selected: _selectedCrop?.name == crops[i].name,
                    onTap: () => _selectCrop(crops[i]),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );

  // ─── Selected crop preview ──────────────────────────────────────────────────

  Widget _selectedPreview() {
    final crop = _selectedCrop!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              bottomLeft: Radius.circular(15),
            ),
            child: Image.asset(
              crop.asset,
              width: 110,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 110,
                height: 90,
                color: AppTheme.primary.withValues(alpha: 0.1),
                child: const Icon(Icons.eco, size: 40, color: AppTheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crop.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  crop.category,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Suggested: GHS ${crop.basePrice.toStringAsFixed(2)}/${crop.unit}',
                  style: TextStyle(fontSize: 12, color: AppTheme.primary.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _selectedCrop = null),
            icon: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─── Listing form ───────────────────────────────────────────────────────────

  Widget _listingForm() => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Listing Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: KuapaTextField(
                    label: 'Quantity *',
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.scale_outlined,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                    items: _units
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            KuapaTextField(
              label: 'Price per unit (GHS) *',
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.attach_money,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Invalid price';
                return null;
              },
            ),

            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _region,
              decoration: const InputDecoration(
                labelText: 'Region *',
                prefixIcon: Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(),
              ),
              items: _ghanaRegions
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setState(() => _region = v),
              validator: (v) => v == null ? 'Select a region' : null,
            ),

            const SizedBox(height: 14),
            KuapaTextField(
              label: 'District (optional)',
              hint: 'e.g. Kumasi Metropolitan',
              controller: _distCtrl,
              prefixIcon: Icons.map_outlined,
            ),

            const SizedBox(height: 14),
            KuapaTextField(
              label: 'Description (optional)',
              hint: 'Describe quality, variety, harvest freshness...',
              controller: _descCtrl,
              maxLines: 3,
            ),

            const SizedBox(height: 24),
            KuapaButton(
              label: 'List Produce',
              onPressed: _submit,
              isLoading: _isLoading,
              icon: Icons.publish,
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('List Produce')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cropPicker(),
              const SizedBox(height: 16),
              if (_selectedCrop != null) ...[
                _selectedPreview(),
                _listingForm(),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.touch_app_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        const Text(
                          'Tap a crop above to start your listing',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
}

class _CropTile extends StatelessWidget {
  final CropInfo crop;
  final bool selected;
  final VoidCallback onTap;

  const _CropTile({required this.crop, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppTheme.primary : Colors.grey.shade200,
              width: selected ? 2.5 : 1,
            ),
            color: selected ? AppTheme.primary.withValues(alpha: 0.06) : Colors.white,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  crop.asset,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.eco, color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                crop.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppTheme.primary : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
}
