import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/kuapa_button.dart';
import '../../../../shared/widgets/kuapa_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _categoriesProvider = FutureProvider<List<dynamic>>((ref) async {
  final res = await ApiClient.instance.get(ApiConstants.categories);
  return res.data as List;
});

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  String _unit = 'KG';
  String? _categoryId;
  bool _isLoading = false;

  static const _units = ['KG', 'BAG', 'CRATE', 'BUNCH', 'PIECE', 'BASKET'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _quantityCtrl.dispose();
    _priceCtrl.dispose();
    _regionCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authUserProvider).valueOrNull!;
      await ApiClient.instance.post(ApiConstants.products, data: {
        'farmerId': user.id,
        'farmerName': user.displayName,
        if (_categoryId != null) 'categoryId': _categoryId,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'quantity': double.parse(_quantityCtrl.text),
        'unit': _unit,
        'pricePerUnit': double.parse(_priceCtrl.text),
        'region': _regionCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produce listed successfully!'), backgroundColor: AppTheme.primary),
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

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(_categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('List Produce')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category picker
              categories.when(
                data: (cats) => DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                  items: cats.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(value: c['id'].toString(), child: Text(c['name']))).toList(),
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Could not load categories'),
              ),

              const SizedBox(height: 16),
              KuapaTextField(
                label: 'Produce Name *',
                hint: 'e.g. Fresh Tomatoes',
                controller: _nameCtrl,
                prefixIcon: Icons.eco_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              KuapaTextField(
                label: 'Description',
                hint: 'Describe your produce (variety, quality, etc.)',
                controller: _descCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(
                  child: KuapaTextField(
                    label: 'Quantity *',
                    controller: _quantityCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icons.scale_outlined,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ]),

              const SizedBox(height: 16),
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
              const SizedBox(height: 16),

              const Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 8),
              KuapaTextField(
                label: 'Region *',
                hint: 'e.g. Ashanti, Greater Accra',
                controller: _regionCtrl,
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              KuapaTextField(
                label: 'District',
                hint: 'e.g. Kumasi Metropolitan',
                controller: _districtCtrl,
                prefixIcon: Icons.map_outlined,
              ),

              const SizedBox(height: 28),
              KuapaButton(
                label: 'List Produce',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: Icons.publish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
