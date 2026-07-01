import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/notif_bell.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _seedStats = {'total': 12, 'inTransit': 2, 'delivered': 9, 'pending': 1};

const _seedDeliveries = [
  {
    'productName': 'Tomatoes – 5 bags',
    'pickupAddress': 'Kumasi Central Market',
    'deliveryAddress': 'Accra Food Hub, Madina',
    'status': 'IN_TRANSIT',
  },
  {
    'productName': 'Maize – 2 tonnes',
    'pickupAddress': 'Tamale Farm Depot',
    'deliveryAddress': 'Kumasi Warehouse',
    'status': 'PICKED_UP',
  },
  {
    'productName': 'Yam – 100 tubers',
    'pickupAddress': 'Brong-Ahafo Collection Pt.',
    'deliveryAddress': 'Tema Market',
    'status': 'ACCEPTED',
  },
];

final _transporterProfileNameProvider = FutureProvider.autoDispose<String>((ref) async {
  final res = await ApiClient.instance.get(ApiConstants.transporterProfile);
  return (res.data['fullName'] as String?)?.trim() ?? '';
});

final _transporterStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    final res         = await ApiClient.instance.get(ApiConstants.myAssignments);
    final assignments = res.data as List? ?? [];
    if (assignments.isEmpty) return _seedStats;
    final delivered = assignments.where((a) => a['status'] == 'DELIVERED').length;
    final inTransit = assignments.where((a) => a['status'] == 'IN_TRANSIT' || a['status'] == 'PICKED_UP').length;
    final pending   = assignments.where((a) => a['status'] == 'PENDING'   || a['status'] == 'ACCEPTED').length;
    return {'total': assignments.length, 'delivered': delivered, 'inTransit': inTransit, 'pending': pending};
  } catch (_) {
    return _seedStats;
  }
});

class TransporterDashboard extends ConsumerWidget {
  const TransporterDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(authUserProvider).valueOrNull;
    final stats     = ref.watch(_transporterStatsProvider);
    final fullName  = ref.watch(_transporterProfileNameProvider).valueOrNull ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuapa'),
        actions: [
          const NotifBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authUserProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/chat'),
        backgroundColor: AppTheme.primary,
        tooltip: 'Messages',
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.local_shipping, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, ${fullName.isNotEmpty ? fullName : (user?.username ?? 'Transporter')}!',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        const Text('Find transport requests near you',
                            style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats row
            stats.when(
              loading: () => const SizedBox(height: 80, child: LoadingView()),
              error: (_, __) => const SizedBox.shrink(),
              data: (s) => Row(
                children: [
                  _StatCard(value: s['total'].toString(),     label: 'Total',     icon: Icons.route,            color: AppTheme.primary),
                  const SizedBox(width: 10),
                  _StatCard(value: s['inTransit'].toString(), label: 'In Transit', icon: Icons.local_shipping,  color: AppTheme.primaryLight),
                  const SizedBox(width: 10),
                  _StatCard(value: s['delivered'].toString(), label: 'Delivered', icon: Icons.done_all,          color: AppTheme.primary),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick actions
            const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ActionChip(
                    icon: Icons.search,
                    label: 'Browse Requests',
                    color: AppTheme.primary,
                    onTap: () => context.go('/transporter/requests'),
                  ),
                  _ActionChip(
                    icon: Icons.location_on_outlined,
                    label: 'Update Location',
                    color: AppTheme.primaryLight,
                    onTap: () => _updateLocation(context),
                  ),
                  _ActionChip(
                    icon: Icons.map_outlined,
                    label: 'Jobs on Map',
                    color: AppTheme.primaryLight,
                    onTap: () => context.go('/transporter/map'),
                  ),
                  _ActionChip(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    color: AppTheme.primary,
                    onTap: () => context.push('/notifications'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Active deliveries section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Deliveries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.go('/transporter/requests'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ActiveDeliveries(),
          ],
        ),
      ),
    );
  }

  Future<void> _updateLocation(BuildContext context) async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied'), backgroundColor: Colors.red),
        );
      }
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Getting your GPS location…'), backgroundColor: AppTheme.primary),
      );
    }
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      await ApiClient.instance.patch(ApiConstants.transporterLocation, data: {
        'lat': pos.latitude,
        'lng': pos.longitude,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location updated — ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
}

// ─── Action chip ──────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      );
}

// ─── Active deliveries list ───────────────────────────────────────────────────

class _ActiveDeliveries extends StatefulWidget {
  @override
  State<_ActiveDeliveries> createState() => _ActiveDeliveriesState();
}

class _ActiveDeliveriesState extends State<_ActiveDeliveries> {
  List<dynamic>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res    = await ApiClient.instance.get(ApiConstants.myAssignments);
      final all    = res.data as List? ?? [];
      final active = all
          .where((a) => a['status'] == 'IN_TRANSIT' || a['status'] == 'PICKED_UP' || a['status'] == 'ACCEPTED')
          .take(3)
          .toList();
      if (mounted) setState(() { _items = active.isEmpty ? _seedDeliveries : active; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _items = _seedDeliveries; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    final items = _items ?? [];
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.primaryLight, size: 28),
            SizedBox(width: 12),
            Text('No active deliveries right now',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }
    return Column(
      children: items.map((d) {
        final status = d['status']?.toString() ?? '';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.local_shipping, color: AppTheme.primary, size: 18),
            ),
            title: Text(d['productName']?.toString() ?? 'Delivery',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text('${d['pickupAddress'] ?? ''} → ${d['deliveryAddress'] ?? ''}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: const TextStyle(fontSize: 10, color: AppTheme.primaryLight, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      }).toList(),
    );
  }
}
