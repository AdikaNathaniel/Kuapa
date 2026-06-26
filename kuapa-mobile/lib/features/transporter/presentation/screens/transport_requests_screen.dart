import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          _AssignmentsTab(),
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

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool showAccept;
  final VoidCallback onAccepted;

  const _RequestCard({required this.request, required this.showAccept, required this.onAccepted});

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING': return Colors.orange;
      case 'MATCHED': return Colors.blue;
      case 'ACCEPTED': return Colors.indigo;
      case 'PICKED_UP': return Colors.teal;
      case 'IN_TRANSIT': return Colors.purple;
      case 'DELIVERED': return Colors.green;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  Future<void> _accept(BuildContext context, String id) async {
    await ApiClient.instance.post('${ApiConstants.transportRequests}/$id/accept', data: {});
    onAccepted();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job accepted!'), backgroundColor: AppTheme.primary),
      );
    }
  }

  Future<void> _updateStatus(BuildContext context, String id, String status) async {
    await ApiClient.instance.patch('${ApiConstants.transportRequests}/$id/status', data: {'status': status});
    onAccepted();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${status.replaceAll("_", " ")}'), backgroundColor: AppTheme.primary),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = request['status'] ?? 'PENDING';
    final estimatedCost = request['estimatedCost'];

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
                Text('Job #${request['id'].toString().substring(0, 8).toUpperCase()}',
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
            const SizedBox(height: 10),

            // Pickup → Dropoff
            Row(
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 12),
                    Container(width: 2, height: 24, color: Colors.grey.shade300),
                    const Icon(Icons.location_on, color: Colors.red, size: 16),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From: ${request['pickupRegion'] ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      Text('To: ${request['dropoffRegion'] ?? 'Unknown'}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),

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

            if (showAccept) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _accept(context, request['id']),
                  child: const Text('Accept Job'),
                ),
              ),
            ] else if (status == 'ACCEPTED') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(context, request['id'], 'PICKED_UP'),
                  icon: const Icon(Icons.local_shipping, size: 16),
                  label: const Text('Mark as Picked Up'),
                ),
              ),
            ] else if (status == 'PICKED_UP') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(context, request['id'], 'IN_TRANSIT'),
                  icon: const Icon(Icons.directions_car, size: 16),
                  label: const Text('Start Transit'),
                ),
              ),
            ] else if (status == 'IN_TRANSIT') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(context, request['id'], 'DELIVERED'),
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Mark as Delivered'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
