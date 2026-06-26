import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final _transporterStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await ApiClient.instance.get(ApiConstants.myAssignments);
  final assignments = res.data as List;
  final delivered = assignments.where((a) => a['status'] == 'DELIVERED').length;
  final inTransit = assignments.where((a) => a['status'] == 'IN_TRANSIT' || a['status'] == 'PICKED_UP').length;
  return {'total': assignments.length, 'delivered': delivered, 'inTransit': inTransit};
});

class TransporterDashboard extends ConsumerWidget {
  const TransporterDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).valueOrNull;
    final stats = ref.watch(_transporterStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuapa'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.logout),
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
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.local_shipping, color: Colors.white, size: 36),
                  const SizedBox(height: 8),
                  Text('Hello, ${user?.displayName ?? 'Transporter'}!',
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Find transport requests near you',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stats
            stats.when(
              loading: () => const LoadingView(),
              error: (_, __) => const SizedBox.shrink(),
              data: (s) => Row(
                children: [
                  _StatCard(label: 'Total Trips', value: s['total'].toString(), icon: Icons.route, color: Colors.blue),
                  const SizedBox(width: 12),
                  _StatCard(label: 'Delivered', value: s['delivered'].toString(), icon: Icons.done_all, color: Colors.green),
                  const SizedBox(width: 12),
                  _StatCard(label: 'In Transit', value: s['inTransit'].toString(), icon: Icons.local_shipping, color: Colors.orange),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _ActionCard(
                  icon: Icons.search,
                  label: 'Find Requests',
                  subtitle: 'Browse available jobs',
                  color: Colors.blue,
                  onTap: () => context.push('/transporter/requests'),
                ),
                _ActionCard(
                  icon: Icons.assignment_turned_in_outlined,
                  label: 'My Assignments',
                  subtitle: 'Active deliveries',
                  color: Colors.green,
                  onTap: () => context.push('/transporter/requests'),
                ),
                _ActionCard(
                  icon: Icons.location_on_outlined,
                  label: 'Update Location',
                  subtitle: 'Share your position',
                  color: Colors.orange,
                  onTap: () => _updateLocation(context, ref),
                ),
                _ActionCard(
                  icon: Icons.account_circle_outlined,
                  label: 'My Profile',
                  subtitle: 'Vehicle & settings',
                  color: Colors.purple,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/transporter/requests'),
                icon: const Icon(Icons.directions_car),
                label: const Text('Browse Transport Requests'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF1565C0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateLocation(BuildContext context, WidgetRef ref) async {
    // In production: use geolocator to get real coordinates
    await ApiClient.instance.patch('${ApiConstants.transporterProfile}/location', data: {
      'latitude': 5.6037,
      'longitude': -0.1870,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location updated'), backgroundColor: AppTheme.primary),
      );
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
