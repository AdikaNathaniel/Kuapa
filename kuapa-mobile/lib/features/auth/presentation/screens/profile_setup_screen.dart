import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../shared/widgets/kuapa_button.dart';
import '../../../../shared/widgets/kuapa_text_field.dart';
import '../../data/models/auth_models.dart';
import '../providers/auth_provider.dart';

const _ghanaRegions = [
  'Greater Accra', 'Ashanti', 'Western', 'Eastern', 'Central',
  'Volta', 'Northern', 'Upper East', 'Upper West', 'Bono',
  'Bono East', 'Ahafo', 'Savannah', 'North East', 'Oti', 'Western North',
];

const _businessTypes = ['RETAILER', 'WHOLESALER', 'RESTAURANT', 'INDIVIDUAL'];
const _vehicleTypes  = ['MOTORCYCLE', 'TRICYCLE', 'PICKUP_TRUCK', 'MINI_VAN', 'TRUCK'];

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameCtrl     = TextEditingController();
  final _farmNameCtrl     = TextEditingController();
  final _districtCtrl     = TextEditingController();
  final _bioCtrl          = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _addressCtrl      = TextEditingController();
  final _vehicleNumCtrl   = TextEditingController();
  final _capacityCtrl     = TextEditingController();

  String? _region;
  String? _businessType;
  String? _vehicleType;
  final List<String> _selectedCrops = [];
  bool _isLoading = false;
  String? _error;

  static const _cropOptions = [
    'Tomato', 'Pepper', 'Onion', 'Okra', 'Cabbage', 'Carrot',
    'Garden Egg', 'Yam', 'Cassava', 'Plantain', 'Maize', 'Rice',
    'Cocoyam', 'Sweet Potato', 'Groundnut', 'Cowpea',
    'Mango', 'Watermelon', 'Pineapple', 'Ginger',
  ];

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _farmNameCtrl.dispose();
    _districtCtrl.dispose();
    _bioCtrl.dispose();
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    _vehicleNumCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  String _dashboardFor(UserRole role) => switch (role) {
    UserRole.FARMER      => '/farmer/dashboard',
    UserRole.BUYER       => '/buyer/dashboard',
    UserRole.TRANSPORTER => '/transporter/dashboard',
    UserRole.ADMIN       => '/farmer/dashboard',
  };

  /// Returns true if the error signals that a profile already exists.
  bool _isConflict(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == 409) return true;
      final msg = e.response?.data?.toString().toLowerCase() ?? '';
      if (msg.contains('already') || msg.contains('conflict') || msg.contains('duplicate')) {
        return true;
      }
    }
    return false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null) return;

    setState(() { _isLoading = true; _error = null; });

    try {
      final Map<String, dynamic> body = {
        'fullName': _fullNameCtrl.text.trim(),
        if (_region != null) 'region': _region,
      };

      final String postEndpoint;
      final String patchEndpoint;

      switch (user.role) {
        case UserRole.FARMER:
          postEndpoint  = ApiConstants.farmerProfile;
          patchEndpoint = ApiConstants.farmerProfile;
          if (_farmNameCtrl.text.isNotEmpty) body['farmName']  = _farmNameCtrl.text.trim();
          if (_districtCtrl.text.isNotEmpty) body['district']  = _districtCtrl.text.trim();
          if (_bioCtrl.text.isNotEmpty)      body['bio']       = _bioCtrl.text.trim();
          if (_selectedCrops.isNotEmpty)     body['mainCrops'] = _selectedCrops;

        case UserRole.BUYER:
          postEndpoint  = ApiConstants.buyerProfile;
          patchEndpoint = ApiConstants.buyerProfile;
          if (_businessNameCtrl.text.isNotEmpty) body['businessName'] = _businessNameCtrl.text.trim();
          if (_businessType != null)             body['businessType'] = _businessType;
          if (_addressCtrl.text.isNotEmpty)      body['address']      = _addressCtrl.text.trim();

        case UserRole.TRANSPORTER:
          postEndpoint  = ApiConstants.transporterProfile;
          patchEndpoint = ApiConstants.transporterProfile;
          if (_vehicleType != null)            body['vehicleType']   = _vehicleType;
          if (_vehicleNumCtrl.text.isNotEmpty) body['vehicleNumber'] = _vehicleNumCtrl.text.trim();
          final cap = double.tryParse(_capacityCtrl.text);
          if (cap != null)                     body['capacityKg']   = cap;

        case UserRole.ADMIN:
          postEndpoint  = ApiConstants.farmerProfile;
          patchEndpoint = ApiConstants.farmerProfile;
      }

      // Attempt to create the profile; if it already exists, update instead.
      try {
        await ApiClient.instance.post(postEndpoint, data: body);
      } catch (createErr) {
        if (_isConflict(createErr)) {
          // Profile already exists — update it instead.
          await ApiClient.instance.patch(patchEndpoint, data: body);
        } else {
          rethrow;
        }
      }

      if (!mounted) return;
      _showSnackbar('Profile saved successfully!', isError: false);
      context.go(_dashboardFor(user.role));
    } catch (e) {
      final msg = parseApiError(e);
      if (mounted) {
        setState(() => _error = msg);
        _showSnackbar(msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: isError ? 5 : 2),
      ),
    );
  }

  void _skip() {
    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null) return;
    context.go(_dashboardFor(user.role));
  }

  Widget _regionDropdown() => DropdownButtonFormField<String>(
        initialValue: _region,
        decoration: const InputDecoration(
          labelText: 'Region',
          prefixIcon: Icon(Icons.location_on_outlined),
          border: OutlineInputBorder(),
        ),
        items: _ghanaRegions
            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
            .toList(),
        onChanged: (v) => setState(() => _region = v),
      );

  Widget _farmerFields() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KuapaTextField(label: 'Farm Name', controller: _farmNameCtrl, prefixIcon: Icons.agriculture),
          const SizedBox(height: 16),
          _regionDropdown(),
          const SizedBox(height: 16),
          KuapaTextField(label: 'District', controller: _districtCtrl, prefixIcon: Icons.map_outlined),
          const SizedBox(height: 16),
          KuapaTextField(
            label: 'About your farm (bio)',
            controller: _bioCtrl,
            prefixIcon: Icons.info_outline,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const Text('Main Crops', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _cropOptions.map((crop) {
              final selected = _selectedCrops.contains(crop);
              return FilterChip(
                label: Text(
                  crop,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
                selected: selected,
                selectedColor: AppTheme.primary,
                backgroundColor: Colors.grey.shade100,
                checkmarkColor: Colors.white,
                onSelected: (v) => setState(() {
                  if (v) { _selectedCrops.add(crop); }
                  else   { _selectedCrops.remove(crop); }
                }),
              );
            }).toList(),
          ),
        ],
      );

  Widget _buyerFields() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          KuapaTextField(
            label: 'Business Name (optional)',
            controller: _businessNameCtrl,
            prefixIcon: Icons.business_outlined,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _businessType,
            decoration: const InputDecoration(
              labelText: 'Business Type (optional)',
              prefixIcon: Icon(Icons.category_outlined),
              border: OutlineInputBorder(),
            ),
            items: _businessTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' '))))
                .toList(),
            onChanged: (v) => setState(() => _businessType = v),
          ),
          const SizedBox(height: 16),
          _regionDropdown(),
          const SizedBox(height: 16),
          KuapaTextField(
            label: 'Delivery Address (optional)',
            controller: _addressCtrl,
            prefixIcon: Icons.home_outlined,
            maxLines: 2,
          ),
        ],
      );

  Widget _transporterFields() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _vehicleType,
            decoration: const InputDecoration(
              labelText: 'Vehicle Type',
              prefixIcon: Icon(Icons.local_shipping_outlined),
              border: OutlineInputBorder(),
            ),
            items: _vehicleTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' '))))
                .toList(),
            onChanged: (v) => setState(() => _vehicleType = v),
          ),
          const SizedBox(height: 16),
          KuapaTextField(
            label: 'Vehicle Number Plate',
            controller: _vehicleNumCtrl,
            prefixIcon: Icons.confirmation_number_outlined,
          ),
          const SizedBox(height: 16),
          KuapaTextField(
            label: 'Carrying Capacity (kg)',
            controller: _capacityCtrl,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.scale_outlined,
          ),
          const SizedBox(height: 16),
          _regionDropdown(),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider).valueOrNull;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final roleLabel = user.role.name[0] + user.role.name.substring(1).toLowerCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _skip,
            child: const Text('Skip for now'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add_outlined, color: AppTheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set up your $roleLabel profile',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const Text(
                            'This helps buyers and farmers find and trust you',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Full name — required for all roles
              KuapaTextField(
                label: 'Full Name',
                controller: _fullNameCtrl,
                prefixIcon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Full name is required' : null,
              ),
              const SizedBox(height: 16),

              // Role-specific fields
              if (user.role == UserRole.FARMER)      _farmerFields(),
              if (user.role == UserRole.BUYER)       _buyerFields(),
              if (user.role == UserRole.TRANSPORTER) _transporterFields(),

              // Inline error (also shown in snackbar)
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),
              KuapaButton(
                label: 'Save Profile',
                onPressed: _isLoading ? null : _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _skip,
                  child: const Text(
                    'Skip and set up later',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
