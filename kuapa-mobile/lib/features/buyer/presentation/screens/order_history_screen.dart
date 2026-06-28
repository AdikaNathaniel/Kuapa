import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';

final _buyerOrdersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiClient.instance.get(ApiConstants.myOrders);
  return res.data as List;
});

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(_buyerOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: orders.when(
        loading: () => const LoadingView(message: 'Loading orders...'),
        error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(_buyerOrdersProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No orders yet', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                  SizedBox(height: 8),
                  Text('Browse the marketplace to place your first order',
                      style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) => _BuyerOrderCard(order: list[i], onAction: () => ref.refresh(_buyerOrdersProvider)),
          );
        },
      ),
    );
  }
}

class _BuyerOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onAction;

  const _BuyerOrderCard({required this.order, required this.onAction});

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING': return AppTheme.primary;
      case 'CONFIRMED': return AppTheme.primaryLight;
      case 'PROCESSING': return AppTheme.primary;
      case 'READY_FOR_PICKUP': return AppTheme.primaryLight;
      case 'IN_TRANSIT': return AppTheme.primary;
      case 'DELIVERED': return AppTheme.primaryLight;
      case 'CANCELLED': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'PENDING': return Icons.schedule;
      case 'CONFIRMED': return Icons.check_circle_outline;
      case 'PROCESSING': return Icons.agriculture;
      case 'READY_FOR_PICKUP': return Icons.inventory;
      case 'IN_TRANSIT': return Icons.local_shipping;
      case 'DELIVERED': return Icons.done_all;
      case 'CANCELLED': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'PENDING';
    final paymentStatus = order['paymentStatus'] ?? 'PENDING';
    final items = (order['items'] as List?) ?? [];
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order #${order['id'].toString().substring(0, 8).toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('From: ${order['farmerName'] ?? 'Farmer'}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 13, color: color),
                      const SizedBox(width: 4),
                      Text(status.replaceAll('_', ' '),
                          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Items
            ...items.map<Widget>((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item['productName']} × ${item['quantity']} ${item['unit']}',
                          style: const TextStyle(fontSize: 13)),
                      Text('GHS ${item['totalPrice']}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),

            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: GHS ${order['totalAmount']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    paymentStatus == 'PAID' ? 'Paid' : 'Payment Pending',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Pay button
            if (paymentStatus != 'PAID' && status != 'CANCELLED') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _initiatePayment(context, order),
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Pay Now'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _initiatePayment(BuildContext context, Map<String, dynamic> order) async {
    await ApiClient.instance.post(ApiConstants.initiatePayment, data: {
      'orderId': order['id'],
      'amount': order['totalAmount'],
      'method': 'MTN_MOBILE_MONEY',
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment initiated — processing…'), backgroundColor: AppTheme.primary),
      );
      onAction();
    }
  }
}
