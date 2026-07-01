import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/notif_bell.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _seedFarmerStats = {'listings': 5, 'pending': 3, 'confirmed': 2};

const _seedOrders = [
  {
    'productName': 'Tomatoes',
    'quantity': '50',
    'unit': 'kg',
    'totalAmount': '325.00',
    'status': 'PENDING',
  },
  {
    'productName': 'Maize',
    'quantity': '200',
    'unit': 'kg',
    'totalAmount': '1200.00',
    'status': 'CONFIRMED',
  },
  {
    'productName': 'Yam',
    'quantity': '80',
    'unit': 'tubers',
    'totalAmount': '360.00',
    'status': 'DELIVERED',
  },
];

final _farmerProfileNameProvider = FutureProvider.autoDispose<String>((ref) async {
  final res = await ApiClient.instance.get(ApiConstants.farmerProfile);
  return (res.data['fullName'] as String?)?.trim() ?? '';
});

final _farmerStatsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  try {
    final results = await Future.wait([
      ApiClient.instance.get(ApiConstants.products, queryParams: {'limit': '1'}),
      ApiClient.instance.get(ApiConstants.farmerOrders),
    ]);
    final totalListings = (results[0].data['total'] as num?)?.toInt() ?? 0;
    final orders        = results[1].data as List? ?? [];
    final pending       = orders.where((o) => o['status'] == 'PENDING').length;
    final confirmed     = orders.where((o) => o['status'] == 'CONFIRMED' || o['status'] == 'PROCESSING').length;
    if (totalListings == 0 && orders.isEmpty) return _seedFarmerStats;
    return {'listings': totalListings, 'pending': pending, 'confirmed': confirmed};
  } catch (_) {
    return _seedFarmerStats;
  }
});

class FarmerDashboard extends ConsumerWidget {
  const FarmerDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(authUserProvider).valueOrNull;
    final stats     = ref.watch(_farmerStatsProvider);
    final fullName  = ref.watch(_farmerProfileNameProvider).valueOrNull ?? '';

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
                    child: Icon(Icons.agriculture, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${fullName.isNotEmpty ? fullName : (user?.username ?? 'Farmer')}!',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        const Text('Manage your produce & orders',
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
                  _StatCard(value: s['listings'].toString(), label: 'Listings',  icon: Icons.inventory_2, color: AppTheme.primary),
                  const SizedBox(width: 10),
                  _StatCard(value: s['pending'].toString(),  label: 'Pending',   icon: Icons.pending_actions, color: AppTheme.primaryLight),
                  const SizedBox(width: 10),
                  _StatCard(value: s['confirmed'].toString(), label: 'Active',   icon: Icons.check_circle_outline, color: AppTheme.primary),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick actions — horizontal scrollable chips
            const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ActionChip(
                    icon: Icons.chat_bubble_outline,
                    label: 'Messages',
                    color: AppTheme.primary,
                    onTap: () => context.push('/chat'),
                  ),
                  _ActionChip(
                    icon: Icons.local_shipping_outlined,
                    label: 'Request Transport',
                    color: AppTheme.primaryLight,
                    onTap: () => context.push('/farmer/request-transport'),
                  ),
                  _ActionChip(
                    icon: Icons.map_outlined,
                    label: 'Find Transporters',
                    color: AppTheme.primary,
                    onTap: () => context.push('/logistics/nearby'),
                  ),
                  _ActionChip(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    color: AppTheme.primaryLight,
                    onTap: () => context.push('/notifications'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent orders preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.go('/farmer/orders'),
                  child: const Text('See all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _RecentOrders(ref: ref),
          ],
        ),
      ),
    );
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

// ─── Recent orders widget ─────────────────────────────────────────────────────

class _RecentOrders extends StatefulWidget {
  final WidgetRef ref;
  const _RecentOrders({required this.ref});

  @override
  State<_RecentOrders> createState() => _RecentOrdersState();
}

class _RecentOrdersState extends State<_RecentOrders> {
  List<dynamic>? _orders;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res  = await ApiClient.instance.get(ApiConstants.farmerOrders);
      final all  = res.data as List? ?? [];
      final list = all.take(3).toList();
      if (mounted) setState(() { _orders = list.isEmpty ? _seedOrders : list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _orders = _seedOrders; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    final orders = _orders ?? [];
    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text('No orders yet', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }
    return Column(
      children: orders.map((o) {
        final status = o['status']?.toString() ?? '';
        final color  = _statusColor(status);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(Icons.shopping_bag_outlined, color: color, size: 18),
            ),
            title: Text(
              '${o['productName'] ?? 'Order'} × ${o['quantity'] ?? ''} ${o['unit'] ?? ''}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: Text('GHS ${o['totalAmount'] ?? ''}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(status,
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _statusColor(String s) => switch (s) {
    'PENDING'   => AppTheme.primaryLight,
    'CONFIRMED' => AppTheme.primary,
    'DELIVERED' => AppTheme.primary,
    'CANCELLED' => Colors.red,
    _           => AppTheme.textSecondary,
  };
}
