import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/kuapa_button.dart';
import '../../../../shared/widgets/kuapa_text_field.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _ghanaRegions = [
  'Greater Accra', 'Ashanti', 'Western', 'Eastern', 'Central',
  'Volta', 'Northern', 'Upper East', 'Upper West', 'Bono',
  'Bono East', 'Ahafo', 'Savannah', 'North East', 'Oti', 'Western North',
];

String _fmtSchedule(String? iso) {
  if (iso == null) return '';
  try {
    final dt = DateTime.parse(iso).toLocal();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${days[dt.weekday - 1]} ${dt.day} ${months[dt.month - 1]} · $h:$m';
  } catch (_) {
    return iso;
  }
}

final _buyerDeliveryProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(authUserProvider);
  final res = await ApiClient.instance.get(ApiConstants.myRequests);
  return res.data as List;
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class BuyerDeliveryScreen extends ConsumerWidget {
  const BuyerDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(_buyerDeliveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Deliveries'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.refresh(_buyerDeliveryProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => _RequestDeliverySheet(
              onSubmitted: () => ref.refresh(_buyerDeliveryProvider),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Request Delivery'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: requests.when(
        loading: () => const LoadingView(message: 'Loading deliveries…'),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(_buyerDeliveryProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text(
                    'No delivery requests yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + Request Delivery to arrange pickup',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: items.length,
            itemBuilder: (_, i) => _DeliveryCard(request: items[i] as Map<String, dynamic>),
          );
        },
      ),
    );
  }
}

// ─── Delivery card ────────────────────────────────────────────────────────────

class _DeliveryCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _DeliveryCard({required this.request});

  static const _statusLabels = {
    'PENDING':    'Waiting for transporter',
    'ACCEPTED':   'Transporter assigned',
    'PICKED_UP':  'Order picked up',
    'IN_TRANSIT': 'On the way to you',
    'DELIVERED':  'Delivered',
    'CANCELLED':  'Cancelled',
  };

  Color _statusColor(String s) => switch (s) {
    'PENDING'    => Colors.orange,
    'ACCEPTED'   => AppTheme.primaryLight,
    'PICKED_UP'  => AppTheme.primary,
    'IN_TRANSIT' => AppTheme.primary,
    'DELIVERED'  => Colors.green,
    'CANCELLED'  => Colors.red,
    _            => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final status     = request['status']?.toString() ?? 'PENDING';
    final pickup     = request['pickupAddress']?.toString() ?? '—';
    final delivery   = request['deliveryAddress']?.toString() ?? '—';
    final cargo      = request['cargoDescription']?.toString();
    final cost       = request['estimatedCost'];
    final assignment = request['assignment'] as Map<String, dynamic>?;
    final isCancelled = status == 'CANCELLED';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Column(
        children: [
          // ── Status header ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: _statusColor(status).withValues(alpha: 0.1),
            child: Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: _statusColor(status), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _statusLabels[status] ?? status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _statusColor(status),
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.replaceAll('_', ' '),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Route ─────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.circle, color: AppTheme.primaryLight, size: 12),
                        Container(width: 2, height: 28, color: Colors.grey.shade300),
                        const Icon(Icons.location_on, color: AppTheme.primary, size: 16),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From: $pickup',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'To: $delivery',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (cargo != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(cargo, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      ),
                    ],
                  ),
                ],

                if (cost != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.attach_money, size: 14, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Estimated cost: GHS $cost',
                        style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],

                // ── Transporter info (once assigned) ──────────────────
                if (assignment != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                        child: const Icon(Icons.person, color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment['transporterName']?.toString() ?? 'Transporter',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            if (assignment['vehicleType'] != null)
                              Text(
                                '${assignment['vehicleType']}  •  ${assignment['vehicleNumber'] ?? ''}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified, size: 18, color: AppTheme.primary),
                    ],
                  ),

                  // Live status note for IN_TRANSIT
                  if (status == 'IN_TRANSIT') ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.directions_car, color: AppTheme.primary, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your order is on its way — the transporter is heading to your location.',
                              style: TextStyle(fontSize: 12, color: AppTheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                // ── Scheduled pickup time ─────────────────────────────
                if (request['scheduledPickupAt'] != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined, size: 14, color: AppTheme.primaryLight),
                      const SizedBox(width: 6),
                      Text(
                        'Scheduled: ${_fmtSchedule(request['scheduledPickupAt']?.toString())}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.primaryLight, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],

                // ── Track button ──────────────────────────────────────
                if (!isCancelled && assignment != null && status != 'DELIVERED') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/logistics/track/${request['id']}'),
                      icon: const Icon(Icons.my_location, size: 16),
                      label: const Text('Track on Map'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary),
                    ),
                  ),
                ],

                // ── Progress stepper ──────────────────────────────────
                if (!isCancelled) ...[
                  const SizedBox(height: 16),
                  _DeliveryStepper(currentStatus: status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Delivery progress stepper ────────────────────────────────────────────────

class _DeliveryStepper extends StatelessWidget {
  final String currentStatus;
  const _DeliveryStepper({required this.currentStatus});

  static const _steps  = ['PENDING', 'ACCEPTED', 'PICKED_UP', 'IN_TRANSIT', 'DELIVERED'];
  static const _labels = ['Requested', 'Matched', 'Picked Up', 'In Transit', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final current = _steps.indexOf(currentStatus);

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = current > i ~/ 2;
          return Expanded(
            child: Container(height: 2, color: done ? AppTheme.primary : Colors.grey.shade200),
          );
        }
        final idx  = i ~/ 2;
        final done = current >= idx;
        return Column(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppTheme.primary : Colors.grey.shade200,
              ),
              child: done ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
            ),
            const SizedBox(height: 4),
            Text(
              _labels[idx],
              style: TextStyle(
                fontSize: 9,
                color: done ? AppTheme.primary : Colors.grey.shade400,
                fontWeight: done ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Request delivery bottom sheet ───────────────────────────────────────────

class _RequestDeliverySheet extends ConsumerStatefulWidget {
  final VoidCallback onSubmitted;
  const _RequestDeliverySheet({required this.onSubmitted});

  @override
  ConsumerState<_RequestDeliverySheet> createState() => _RequestDeliverySheetState();
}

class _RequestDeliverySheetState extends ConsumerState<_RequestDeliverySheet> {
  final _formKey      = GlobalKey<FormState>();
  final _pickupCtrl   = TextEditingController();
  final _deliveryCtrl = TextEditingController();
  final _cargoCtrl    = TextEditingController();
  final _weightCtrl   = TextEditingController();

  String? _pickupRegion;
  bool _loading = false;

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _deliveryCtrl.dispose();
    _cargoCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final user = ref.read(authUserProvider).valueOrNull!;
      await ApiClient.instance.post(ApiConstants.transportRequests, data: {
        'requesterName':    user.displayName,
        'requesterType':    'BUYER',
        'pickupAddress':    _pickupCtrl.text.trim(),
        'deliveryAddress':  _deliveryCtrl.text.trim(),
        'cargoDescription': _cargoCtrl.text.trim(),
        if (_weightCtrl.text.isNotEmpty)
          'weightKg': double.tryParse(_weightCtrl.text) ?? 0,
        if (_pickupRegion != null) 'region': _pickupRegion,
      });

      if (mounted) {
        Navigator.of(context).pop();
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery request submitted! Transporters will be notified.'),
            backgroundColor: AppTheme.primary,
            duration: Duration(seconds: 4),
          ),
        );
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
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
              const Text('Request Delivery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              KuapaTextField(
                label: 'Pickup Address (from farmer) *',
                hint: 'Where should the transporter collect from?',
                controller: _pickupCtrl,
                prefixIcon: Icons.circle_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _pickupRegion,
                decoration: const InputDecoration(
                  labelText: 'Pickup Region *',
                  prefixIcon: Icon(Icons.map_outlined),
                  border: OutlineInputBorder(),
                ),
                items: _ghanaRegions
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _pickupRegion = v),
                validator: (v) => v == null ? 'Select a region' : null,
              ),
              const SizedBox(height: 14),

              KuapaTextField(
                label: 'Delivery Address (to you) *',
                hint: 'Where should it be delivered?',
                controller: _deliveryCtrl,
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              KuapaTextField(
                label: 'What is being delivered? *',
                hint: 'e.g. 20kg tomatoes, 5 crates pepper',
                controller: _cargoCtrl,
                prefixIcon: Icons.inventory_2_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              KuapaTextField(
                label: 'Estimated Weight (KG)',
                controller: _weightCtrl,
                prefixIcon: Icons.scale_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 24),
              KuapaButton(
                label: 'Submit Request',
                onPressed: _submit,
                isLoading: _loading,
                icon: Icons.local_shipping_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
