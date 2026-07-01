import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';

final _availableRequestsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiClient.instance.get(ApiConstants.availableRequests);
  return res.data as List;
});

final _myAssignmentsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiClient.instance.get(ApiConstants.myAssignments);
  return res.data as List;
});

class TransportRequestsScreen extends ConsumerStatefulWidget {
  const TransportRequestsScreen({super.key});

  @override
  ConsumerState<TransportRequestsScreen> createState() => _TransportRequestsScreenState();
}

class _TransportRequestsScreenState extends ConsumerState<TransportRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Jobs'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'My Assignments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _AvailableTab(onAccepted: () => ref.refresh(_availableRequestsProvider)),
          const _AssignmentsTab(),
        ],
      ),
    );
  }
}

class _AvailableTab extends ConsumerWidget {
  final VoidCallback onAccepted;
  const _AvailableTab({required this.onAccepted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(_availableRequestsProvider);

    return requests.when(
      loading: () => const LoadingView(message: 'Finding jobs near you…'),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(_availableRequestsProvider)),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No available jobs right now', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                SizedBox(height: 8),
                Text('Check back later for new requests', style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) => _RequestCard(
            request: list[i],
            showAccept: true,
            onAccepted: () {
              ref.invalidate(_availableRequestsProvider);
              onAccepted();
            },
          ),
        );
      },
    );
  }
}

class _AssignmentsTab extends ConsumerWidget {
  const _AssignmentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignments = ref.watch(_myAssignmentsProvider);

    return assignments.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(_myAssignmentsProvider)),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No assignments yet', style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) => _RequestCard(
            request: list[i]['transportRequest'] ?? list[i],
            showAccept: false,
            onAccepted: () {},
          ),
        );
      },
    );
  }
}

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

class _RequestCard extends StatefulWidget {
  final Map<String, dynamic> request;
  final bool showAccept;
  final VoidCallback onAccepted;

  const _RequestCard({required this.request, required this.showAccept, required this.onAccepted});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  Timer? _locationTimer;
  bool _sharingLocation = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.request['status']?.toString() ?? 'PENDING';
    if (_currentStatus == 'PICKED_UP' || _currentStatus == 'IN_TRANSIT') {
      _startLocationTimer();
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationTimer() {
    _locationTimer?.cancel();
    if (mounted) setState(() => _sharingLocation = true);
    _pushLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 30), (_) => _pushLocation());
  }

  void _stopLocationTimer() {
    _locationTimer?.cancel();
    _locationTimer = null;
    if (mounted) setState(() => _sharingLocation = false);
  }

  Future<void> _pushLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await ApiClient.instance.patch(
        '${ApiConstants.transportRequests}/${widget.request['id']}/location',
        data: {'lat': pos.latitude, 'lng': pos.longitude},
      );
    } catch (_) {
      // Best-effort — silent fail
    }
  }

  Color _statusColor(String status) => switch (status) {
        'PENDING'    => AppTheme.primary,
        'MATCHED'    => AppTheme.primaryLight,
        'ACCEPTED'   => AppTheme.primary,
        'PICKED_UP'  => AppTheme.primaryLight,
        'IN_TRANSIT' => AppTheme.primary,
        'DELIVERED'  => AppTheme.primary,
        'CANCELLED'  => Colors.red,
        _            => Colors.grey,
      };

  Future<void> _accept(String id) async {
    await ApiClient.instance.post('${ApiConstants.transportRequests}/$id/accept', data: {});
    widget.onAccepted();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job accepted!'), backgroundColor: AppTheme.primary),
      );
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    await ApiClient.instance.patch(
      '${ApiConstants.transportRequests}/$id/status',
      data: {'status': newStatus},
    );
    if (mounted) setState(() => _currentStatus = newStatus);
    if (newStatus == 'PICKED_UP' || newStatus == 'IN_TRANSIT') {
      _startLocationTimer();
    } else {
      _stopLocationTimer();
    }
    widget.onAccepted();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${newStatus.replaceAll("_", " ")}'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final req           = widget.request;
    final status        = _currentStatus;
    final estimatedCost = req['estimatedCost'];
    final scheduled     = req['scheduledPickupAt']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Job #${req['id'].toString().substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status.replaceAll('_', ' '),
                      style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.w600)),
                ),
              ],
            ),

            // GPS sharing badge
            if (_sharingLocation) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on, size: 12, color: AppTheme.primary),
                    SizedBox(width: 4),
                    Text('Sharing GPS location',
                        style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Pickup → Dropoff
            Row(
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, color: AppTheme.primaryLight, size: 12),
                    Container(width: 2, height: 24, color: Colors.grey.shade300),
                    const Icon(Icons.location_on, color: AppTheme.primary, size: 16),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From: ${req['pickupAddress'] ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      Text('To: ${req['deliveryAddress'] ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),

            if (req['cargoDescription'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(req['cargoDescription'],
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  if (req['weightKg'] != null)
                    Text('${req['weightKg']} kg',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ],

            if (req['requesterName'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text('Posted by: ${req['requesterName']}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ],

            if (scheduled != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 14, color: AppTheme.primaryLight),
                  const SizedBox(width: 6),
                  Text('Scheduled: ${_fmtSchedule(scheduled)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.primaryLight, fontWeight: FontWeight.w500)),
                ],
              ),
            ],

            if (estimatedCost != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: AppTheme.primary),
                  Text('Estimated: GHS $estimatedCost',
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ],

            const SizedBox(height: 10),

            if (widget.showAccept) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _accept(req['id']),
                  child: const Text('Accept Job'),
                ),
              ),
            ] else if (status == 'ACCEPTED') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(req['id'], 'PICKED_UP'),
                  icon: const Icon(Icons.local_shipping, size: 16),
                  label: const Text('Mark as Picked Up'),
                ),
              ),
            ] else if (status == 'PICKED_UP') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(req['id'], 'IN_TRANSIT'),
                  icon: const Icon(Icons.directions_car, size: 16),
                  label: const Text('Start Transit'),
                ),
              ),
            ] else if (status == 'IN_TRANSIT') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(req['id'], 'DELIVERED'),
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Mark as Delivered'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
