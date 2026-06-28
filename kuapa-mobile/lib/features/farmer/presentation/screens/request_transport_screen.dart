import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/kuapa_button.dart';
import '../../../../shared/widgets/kuapa_text_field.dart';
import '../../../../shared/widgets/map_location_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../logistics/presentation/screens/nearby_transporters_screen.dart';

const _ghanaRegions = [
  'Greater Accra', 'Ashanti', 'Western', 'Eastern', 'Central',
  'Volta', 'Northern', 'Upper East', 'Upper West', 'Bono',
  'Bono East', 'Ahafo', 'Savannah', 'North East', 'Oti', 'Western North',
];

class RequestTransportScreen extends ConsumerStatefulWidget {
  const RequestTransportScreen({super.key});

  @override
  ConsumerState<RequestTransportScreen> createState() => _RequestTransportScreenState();
}

class _RequestTransportScreenState extends ConsumerState<RequestTransportScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _cargoCtrl    = TextEditingController();
  final _weightCtrl   = TextEditingController();

  PickedLocation? _pickup;
  PickedLocation? _delivery;
  String? _pickupRegion;
  String? _deliveryRegion;
  DateTime? _scheduledPickupAt;
  bool _loading = false;
  Map<String, dynamic>? _estimate;
  bool _loadingEstimate = false;

  @override
  void dispose() {
    _cargoCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  String _formatSchedule(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final day = days[dt.weekday - 1];
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day ${dt.day} $month · $hour:$min';
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Select pickup date',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 2))),
      helpText: 'Select pickup time',
    );
    if (time == null) return;
    setState(() {
      _scheduledPickupAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickOnMap(bool isPickup) async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPicker(
          title: isPickup ? 'Pick Pickup Location' : 'Pick Delivery Location',
          initialLocation: isPickup ? _pickup : _delivery,
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      if (isPickup) {
        _pickup = result;
      } else {
        _delivery = result;
      }
      _estimate = null;
    });
    if (_pickup != null && _delivery != null) _fetchEstimate();
  }

  Future<void> _fetchEstimate() async {
    if (_pickup == null || _delivery == null) return;
    setState(() => _loadingEstimate = true);
    try {
      final res = await ApiClient.instance.get(ApiConstants.estimateCost, queryParams: {
        'pickupLat':   _pickup!.lat.toString(),
        'pickupLng':   _pickup!.lng.toString(),
        'deliveryLat': _delivery!.lat.toString(),
        'deliveryLng': _delivery!.lng.toString(),
      });
      setState(() => _estimate = res.data as Map<String, dynamic>);
    } catch (_) {
      // Estimate not critical
    } finally {
      if (mounted) setState(() => _loadingEstimate = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a pickup location on the map'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = ref.read(authUserProvider).valueOrNull!;
      await ApiClient.instance.post(ApiConstants.transportRequests, data: {
        'requesterName':    user.displayName,
        'requesterType':    'FARMER',
        'pickupAddress':    _pickup!.address,
        'pickupLat':        _pickup!.lat,
        'pickupLng':        _pickup!.lng,
        'deliveryAddress':  _delivery?.address ?? '',
        if (_delivery != null) 'deliveryLat': _delivery!.lat,
        if (_delivery != null) 'deliveryLng': _delivery!.lng,
        'cargoDescription': _cargoCtrl.text.trim(),
        if (_weightCtrl.text.isNotEmpty)
          'weightKg': double.tryParse(_weightCtrl.text) ?? 0,
        'region': _pickupRegion,
        if (_scheduledPickupAt != null)
          'scheduledPickupAt': _scheduledPickupAt!.toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted! Transporters in your region will be notified.'),
            backgroundColor: AppTheme.primary,
            duration: Duration(seconds: 4),
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Transport'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.map_outlined, size: 18),
            label: const Text('Find Transporters'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NearbyTransportersScreen(
                  pickupLat:   _pickup?.lat,
                  pickupLng:   _pickup?.lng,
                  deliveryLat: _delivery?.lat,
                  deliveryLng: _delivery?.lng,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.primary, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pin your pickup and delivery locations on the map for accurate cost estimation.',
                        style: TextStyle(fontSize: 13, color: AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Pickup ────────────────────────────────────────────────
              const _SectionHeader(icon: Icons.circle, color: AppTheme.primaryLight, label: 'Pickup Location'),
              const SizedBox(height: 12),

              _LocationTile(
                label: 'Tap to pin pickup on map',
                picked: _pickup,
                accentColor: AppTheme.primaryLight,
                onTap: () => _pickOnMap(true),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _pickupRegion,
                decoration: const InputDecoration(
                  labelText: 'Pickup Region *',
                  prefixIcon: Icon(Icons.map_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _ghanaRegions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _pickupRegion = v),
                validator: (v) => v == null ? 'Select a region' : null,
              ),

              const SizedBox(height: 24),

              // ── Delivery ──────────────────────────────────────────────
              const _SectionHeader(icon: Icons.location_on, color: AppTheme.primary, label: 'Delivery Location'),
              const SizedBox(height: 12),

              _LocationTile(
                label: 'Tap to pin delivery on map',
                picked: _delivery,
                accentColor: AppTheme.primary,
                onTap: () => _pickOnMap(false),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _deliveryRegion,
                decoration: const InputDecoration(
                  labelText: 'Delivery Region',
                  prefixIcon: Icon(Icons.map_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _ghanaRegions.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) => setState(() => _deliveryRegion = v),
              ),

              // Estimate card
              if (_loadingEstimate)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_estimate != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(children: [
                        const Text('Distance', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        Text('${_estimate!['distanceKm']} km',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ]),
                      Container(width: 1, height: 36, color: Colors.green.shade200),
                      Column(children: [
                        const Text('Est. Cost', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        Text('GHS ${_estimate!['estimatedCost']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
                      ]),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ── Schedule ──────────────────────────────────────────────
              const _SectionHeader(icon: Icons.schedule_outlined, color: AppTheme.primary, label: 'Pickup Schedule'),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickSchedule,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: _scheduledPickupAt != null
                        ? AppTheme.primary.withValues(alpha: 0.06)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _scheduledPickupAt != null
                          ? AppTheme.primary.withValues(alpha: 0.4)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: _scheduledPickupAt != null ? AppTheme.primary : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _scheduledPickupAt != null
                              ? _formatSchedule(_scheduledPickupAt!)
                              : 'Schedule a pickup time (optional)',
                          style: TextStyle(
                            color: _scheduledPickupAt != null ? Colors.black87 : Colors.grey,
                            fontSize: 13,
                            fontWeight: _scheduledPickupAt != null ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (_scheduledPickupAt != null)
                        GestureDetector(
                          onTap: () => setState(() => _scheduledPickupAt = null),
                          child: const Icon(Icons.close, size: 16, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Cargo ─────────────────────────────────────────────────
              const _SectionHeader(icon: Icons.inventory_2_outlined, color: AppTheme.primary, label: 'Cargo Details'),
              const SizedBox(height: 12),

              KuapaTextField(
                label: 'What are you transporting? *',
                hint: 'e.g. 50 bags of tomatoes, 20 crates of pepper',
                controller: _cargoCtrl,
                prefixIcon: Icons.inventory_2_outlined,
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              KuapaTextField(
                label: 'Total Weight (KG)',
                hint: 'Approximate weight',
                controller: _weightCtrl,
                prefixIcon: Icons.scale_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 32),
              KuapaButton(
                label: 'Submit Request',
                onPressed: _submit,
                isLoading: _loading,
                icon: Icons.local_shipping_outlined,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationTile extends StatelessWidget {
  final String label;
  final PickedLocation? picked;
  final Color accentColor;
  final VoidCallback onTap;

  const _LocationTile({
    required this.label,
    required this.picked,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: picked != null ? accentColor.withValues(alpha: 0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: picked != null ? accentColor.withValues(alpha: 0.5) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              picked != null ? Icons.location_pin : Icons.add_location_alt_outlined,
              color: picked != null ? accentColor : Colors.grey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                picked != null ? picked!.address : label,
                style: TextStyle(
                  color: picked != null ? Colors.black87 : Colors.grey,
                  fontSize: 13,
                  fontWeight: picked != null ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _SectionHeader({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      );
}
