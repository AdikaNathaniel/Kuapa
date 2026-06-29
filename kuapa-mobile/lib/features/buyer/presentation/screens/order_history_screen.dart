import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';

final _buyerOrdersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiClient.instance.get(ApiConstants.myOrders);
  return res.data as List;
});

final _transactionsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiClient.instance.get(ApiConstants.paymentHistory);
  return res.data as List;
});

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen>
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
        title: const Text('Orders & Transactions'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primary,
          tabs: const [
            Tab(text: 'My Orders'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OrdersTab(onRefresh: () => ref.refresh(_buyerOrdersProvider)),
          const _TransactionsTab(),
        ],
      ),
    );
  }
}

// ─── Orders tab ───────────────────────────────────────────────────────────────

class _OrdersTab extends ConsumerWidget {
  final VoidCallback onRefresh;
  const _OrdersTab({required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(_buyerOrdersProvider);

    return orders.when(
      loading: () => const LoadingView(message: 'Loading orders…'),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(_buyerOrdersProvider)),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 72, color: Colors.grey),
                SizedBox(height: 16),
                Text('No orders yet', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                SizedBox(height: 8),
                Text(
                  'Browse the marketplace to place your first order',
                  style: TextStyle(color: AppTheme.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) => _BuyerOrderCard(
            order: list[i] as Map<String, dynamic>,
            onRefresh: () => ref.refresh(_buyerOrdersProvider),
          ),
        );
      },
    );
  }
}

// ─── Order card ───────────────────────────────────────────────────────────────

class _BuyerOrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final VoidCallback onRefresh;

  const _BuyerOrderCard({required this.order, required this.onRefresh});

  @override
  State<_BuyerOrderCard> createState() => _BuyerOrderCardState();
}

class _BuyerOrderCardState extends State<_BuyerOrderCard> with WidgetsBindingObserver {
  bool _cancelling  = false;
  bool _paying      = false;
  bool _verifying   = false;
  String? _pendingRef;
  bool _awaitingReturn = false; // true while user is in the Paystack browser

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from Paystack browser, auto-verify
    if (state == AppLifecycleState.resumed && _awaitingReturn && _pendingRef != null) {
      _awaitingReturn = false;
      _verifyPayment();
    }
  }

  Color _statusColor(String s) => switch (s) {
    'PENDING'          => Colors.orange,
    'CONFIRMED'        => AppTheme.primaryLight,
    'PROCESSING'       => AppTheme.primary,
    'READY_FOR_PICKUP' => AppTheme.primaryLight,
    'IN_TRANSIT'       => AppTheme.primary,
    'DELIVERED'        => Colors.green,
    'CANCELLED'        => Colors.red,
    'DISPUTED'         => Colors.deepOrange,
    _                  => Colors.grey,
  };

  IconData _statusIcon(String s) => switch (s) {
    'PENDING'          => Icons.schedule,
    'CONFIRMED'        => Icons.check_circle_outline,
    'PROCESSING'       => Icons.agriculture,
    'READY_FOR_PICKUP' => Icons.inventory,
    'IN_TRANSIT'       => Icons.local_shipping,
    'DELIVERED'        => Icons.done_all,
    'CANCELLED'        => Icons.cancel_outlined,
    _                  => Icons.help_outline,
  };

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('This action cannot be undone. The order will be cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Order')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      await ApiClient.instance.patch(
        '${ApiConstants.orders}/${widget.order['id']}/status',
        data: {'status': 'CANCELLED'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled'), backgroundColor: Colors.red),
        );
        widget.onRefresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _initiatePayment() async {
    setState(() => _paying = true);
    try {
      final res = await ApiClient.instance.post(ApiConstants.initiatePayment, data: {
        'orderId': widget.order['id'],
        'amount':  widget.order['totalAmount'],
        'method':  'MTN_MOBILE_MONEY',
      });

      final authUrl = res.data['authorizationUrl'] as String?;
      final ref     = res.data['transactionRef'] as String?;

      if (authUrl != null && authUrl.isNotEmpty) {
        final uri = Uri.parse(authUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (mounted) {
            setState(() {
              _pendingRef = ref;
              _awaitingReturn = true;
            });
          }
        } else {
          throw Exception('Could not open payment page');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  Future<void> _verifyPayment() async {
    if (_pendingRef == null) return;
    setState(() => _verifying = true);
    try {
      final res = await ApiClient.instance.get('${ApiConstants.verifyPayment}/$_pendingRef');
      final status = res.data['status'] as String?;

      if (mounted) {
        if (status == 'COMPLETED') {
          setState(() => _pendingRef = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment confirmed!'), backgroundColor: Colors.green),
          );
          widget.onRefresh();
        } else if (status == 'FAILED') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment failed. Please try again.'), backgroundColor: Colors.red),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment still processing — tap again in a moment'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status        = widget.order['status']?.toString() ?? 'PENDING';
    final paymentStatus = widget.order['paymentStatus']?.toString() ?? 'PENDING';
    final items         = (widget.order['items'] as List?) ?? [];
    final color         = _statusColor(status);
    final isCancelled   = status == 'CANCELLED' || status == 'DISPUTED';
    final isPending     = status == 'PENDING';
    final isPaid        = paymentStatus == 'PAID';
    final createdAt     = widget.order['createdAt'] != null
        ? DateTime.tryParse(widget.order['createdAt'].toString())
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: color.withValues(alpha: 0.08),
            child: Row(
              children: [
                Icon(_statusIcon(status), color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${widget.order['id'].toString().substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'From ${widget.order['farmerName'] ?? 'Farmer'}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.replaceAll('_', ' '),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d MMM y').format(createdAt),
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Items ─────────────────────────────────────────────
                ...items.map<Widget>((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item['productName']} × ${item['quantity']} ${item['unit']}',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text(
                            'GHS ${item['totalPrice']}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )),

                const Divider(height: 16),

                // ── Total + payment badge ──────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: GHS ${widget.order['totalAmount']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        fontSize: 15,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPaid ? Icons.check_circle : Icons.pending_outlined,
                            size: 12,
                            color: isPaid ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPaid ? 'Paid' : 'Payment Pending',
                            style: TextStyle(
                              fontSize: 11,
                              color: isPaid ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Status progress stepper ────────────────────────────
                if (!isCancelled) ...[
                  const SizedBox(height: 18),
                  _StatusStepper(currentStatus: status),
                ],

                // ── Action buttons ─────────────────────────────────────
                if (!isCancelled) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (!isPaid) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _paying ? null : _initiatePayment,
                            icon: _paying
                                ? const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.payment, size: 16),
                            label: const Text('Pay Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (isPending)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _cancelling ? null : _cancelOrder,
                            icon: _cancelling
                                ? const SizedBox(
                                    width: 14, height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Shown after browser returns — lets user confirm payment landed
                  if (_pendingRef != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _verifying ? null : _verifyPayment,
                        icon: _verifying
                            ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Check Payment Status'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                  if (status == 'DELIVERED') ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/reviews/write', extra: {
                          'revieweeId': widget.order['farmerId']?.toString() ?? '',
                          'revieweeName': widget.order['farmerName']?.toString() ?? 'Farmer',
                          'revieweeType': 'FARMER',
                          'orderId': widget.order['id']?.toString(),
                        }),
                        icon: const Icon(Icons.star_outline_rounded, size: 16),
                        label: const Text('Review Farmer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFFFC107),
                          side: const BorderSide(color: Color(0xFFFFC107)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 6-step order status stepper ─────────────────────────────────────────────

class _StatusStepper extends StatelessWidget {
  final String currentStatus;
  const _StatusStepper({required this.currentStatus});

  static const _steps  = ['PENDING', 'CONFIRMED', 'PROCESSING', 'READY_FOR_PICKUP', 'IN_TRANSIT', 'DELIVERED'];
  static const _labels = ['Placed', 'Confirmed', 'Processing', 'Ready', 'Transit', 'Delivered'];

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
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppTheme.primary : Colors.grey.shade200,
              ),
              child: done ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
            ),
            const SizedBox(height: 4),
            Text(
              _labels[idx],
              style: TextStyle(
                fontSize: 8,
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

// ─── Transactions tab ─────────────────────────────────────────────────────────

class _TransactionsTab extends ConsumerWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(_transactionsProvider);

    return txns.when(
      loading: () => const LoadingView(message: 'Loading transactions…'),
      error: (e, _) => ErrorView(message: e.toString(), onRetry: () => ref.refresh(_transactionsProvider)),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey),
                SizedBox(height: 16),
                Text('No transactions yet', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                SizedBox(height: 8),
                Text('Your payment history will appear here', style: TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => _TransactionTile(txn: list[i] as Map<String, dynamic>),
        );
      },
    );
  }
}

// ─── Transaction tile ─────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> txn;
  const _TransactionTile({required this.txn});

  Color _statusColor(String s) => switch (s) {
    'COMPLETED'  => Colors.green,
    'PROCESSING' => Colors.orange,
    'FAILED'     => Colors.red,
    'REFUNDED'   => Colors.purple,
    _            => Colors.grey,
  };

  IconData _methodIcon(String? m) => switch (m) {
    'MTN_MOBILE_MONEY'     => Icons.phone_android,
    'VODAFONE_CASH'        => Icons.phone_iphone,
    'AIRTELTIGO_MONEY'     => Icons.smartphone,
    'CARD'                 => Icons.credit_card,
    _                      => Icons.payment,
  };

  String _methodLabel(String? m) => switch (m) {
    'MTN_MOBILE_MONEY'  => 'MTN MoMo',
    'VODAFONE_CASH'     => 'Vodafone Cash',
    'AIRTELTIGO_MONEY'  => 'AirtelTigo Money',
    'CARD'              => 'Card',
    _                   => 'Payment',
  };

  @override
  Widget build(BuildContext context) {
    final status    = txn['status']?.toString() ?? 'PENDING';
    final method    = txn['method']?.toString();
    final amount    = txn['amount'];
    final ref       = txn['transactionRef']?.toString() ?? '';
    final createdAt = txn['createdAt'] != null
        ? DateTime.tryParse(txn['createdAt'].toString())
        : null;
    final color = _statusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_methodIcon(method), color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _methodLabel(method),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                Text(
                  ref,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
                if (createdAt != null)
                  Text(
                    DateFormat('d MMM y · HH:mm').format(createdAt),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'GHS $amount',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primary),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
