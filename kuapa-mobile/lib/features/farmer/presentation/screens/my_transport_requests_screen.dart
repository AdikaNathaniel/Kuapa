import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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

final _myTransportProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(authUserProvider);
  final res = await ApiClient.instance.get(ApiConstants.myRequests);
  return res.data as List;
});

class MyTransportRequestsScreen extends ConsumerWidget {
  const MyTransportRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(_myTransportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Transport Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.refresh(_myTransportProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/farmer/request-transport'),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: requests.when(
        loading: () => const LoadingView(message: 'Loading requests…'),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(_myTransportProvider),
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
                    'No transport requests yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap + New Request to arrange delivery',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/farmer/request-transport'),
                    icon: const Icon(Icons.add),
                    label: const Text('Request Transport'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: items.length,
            itemBuilder: (_, i) => _TransportCard(request: items[i] as Map<String, dynamic>),
          );
        },
      ),
    );
  }
}

// ─── Request card ─────────────────────────────────────────────────────────────

class _TransportCard extends StatelessWidget {
  final Map<String, dynamic> request;
  const _TransportCard({required this.request});

  static const _statusLabels = {
    'PENDING':    'Waiting for transporter',
    'ACCEPTED':   'Transporter assigned',
    'PICKED_UP':  'Cargo picked up',
    'IN_TRANSIT': 'On the way',
    'DELIVERED':  'Delivered',
    'CANCELLED':  'Cancelled',
  };

  Color _statusColor(String status) => switch (status) {
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
    final status       = request['status']?.toString() ?? 'PENDING';
    final pickup       = request['pickupAddress']?.toString() ?? '—';
    final delivery     = request['deliveryAddress']?.toString() ?? '—';
    final cargo        = request['cargoDescription']?.toString();
    final weight       = request['weightKg'];
    final cost         = request['estimatedCost'];
    final assignment   = request['assignment'] as Map<String, dynamic>?;
    final isCancelled  = status == 'CANCELLED';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Column(
        children: [
          // ── Header bar ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _statusColor(status).withValues(alpha: 0.1),
            ),
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
                            pickup,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            delivery,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Details ───────────────────────────────────────────
                if (cargo != null)
                  _Detail(icon: Icons.inventory_2_outlined, text: cargo),
                if (weight != null)
                  _Detail(icon: Icons.scale_outlined, text: '$weight kg'),
                if (cost != null)
                  _Detail(
                    icon: Icons.attach_money,
                    text: 'Estimated: GHS $cost',
                    color: AppTheme.primary,
                  ),

                // ── Transporter info (once assigned) ──────────────────
                if (assignment != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                        child: const Icon(Icons.person, color: AppTheme.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
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
                      if (assignment['transporterPhone'] != null)
                        const Icon(Icons.phone_outlined, color: AppTheme.primary, size: 20),
                    ],
                  ),
                ],

                // ── Scheduled pickup time ─────────────────────────────
                if (request['scheduledPickupAt'] != null) ...[
                  const SizedBox(height: 8),
                  _Detail(
                    icon: Icons.schedule_outlined,
                    text: 'Scheduled: ${_fmtSchedule(request['scheduledPickupAt'])}',
                    color: AppTheme.primaryLight,
                  ),
                ],

                // ── Track button (once transporter assigned) ──────────
                if (!isCancelled && assignment != null && status != 'DELIVERED') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '/logistics/track/${request['id']}',
                      ),
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Track on Map'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary),
                    ),
                  ),
                ],

                // ── Progress stepper (non-cancelled) ──────────────────
                if (!isCancelled) ...[
                  const SizedBox(height: 16),
                  _StatusStepper(currentStatus: status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status progress stepper ──────────────────────────────────────────────────

class _StatusStepper extends StatelessWidget {
  final String currentStatus;
  const _StatusStepper({required this.currentStatus});

  static const _steps = ['PENDING', 'ACCEPTED', 'PICKED_UP', 'IN_TRANSIT', 'DELIVERED'];
  static const _labels = ['Posted', 'Matched', 'Picked Up', 'In Transit', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final current = _steps.indexOf(currentStatus);

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIndex = i ~/ 2;
          final done = current > stepIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: done ? AppTheme.primary : Colors.grey.shade200,
            ),
          );
        }
        // Step dot
        final stepIndex = i ~/ 2;
        final done = current >= stepIndex;
        return Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppTheme.primary : Colors.grey.shade200,
              ),
              child: done
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              _labels[stepIndex],
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

// ─── Detail row ───────────────────────────────────────────────────────────────

class _Detail extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _Detail({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color ?? AppTheme.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: color ?? AppTheme.textSecondary,
                  fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
}
