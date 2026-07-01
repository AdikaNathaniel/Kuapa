import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          state.maybeWhen(
            data: (d) {
              final unread = (d['unread'] as num?)?.toInt() ?? 0;
              if (unread == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
                child: const Text('Mark all read', style: TextStyle(color: Colors.white, fontSize: 13)),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.read(notificationsProvider.notifier).fetch(),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(notificationsProvider.notifier).fetch(),
        ),
        data: (response) {
          final items = (response['data'] as List?) ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_outlined, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No notifications yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  const Text('You\'ll be notified about orders, deliveries, and messages.',
                      style: TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(notificationsProvider.notifier).fetch(),
            color: AppTheme.primary,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (_, i) => _NotifTile(
                notif: items[i] as Map<String, dynamic>,
                onTap: (id, route) {
                  ref.read(notificationsProvider.notifier).markRead(id);
                  if (route != null) context.push(route);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Notification tile ────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final Map<String, dynamic> notif;
  final void Function(String id, String? route) onTap;

  const _NotifTile({required this.notif, required this.onTap});

  IconData _icon(String? type) => switch (type) {
        'ORDER'     => Icons.shopping_bag_outlined,
        'TRANSPORT' => Icons.local_shipping_outlined,
        'MESSAGE'   => Icons.chat_bubble_outline,
        'PAYMENT'   => Icons.payment_outlined,
        _           => Icons.notifications_outlined,
      };

  Color _color(String? type) => switch (type) {
        'ORDER'     => AppTheme.primaryLight,
        'TRANSPORT' => AppTheme.primary,
        'MESSAGE'   => AppTheme.primary,
        'PAYMENT'   => AppTheme.primary,
        _           => Colors.grey,
      };

  String? _route(String? type, String? refId) => switch (type) {
        'TRANSPORT' => refId != null ? '/logistics/track/$refId' : null,
        'ORDER'     => '/buyer/orders',
        'MESSAGE'   => refId != null ? '/chat/$refId' : '/chat',
        _           => null,
      };

  String _relTime(String? iso) {
    if (iso == null) return '';
    try {
      final dt   = DateTime.parse(iso).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24)   return '${diff.inHours}h ago';
      if (diff.inDays < 7)     return '${diff.inDays}d ago';
      const mo = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${dt.day} ${mo[dt.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type    = notif['type']?.toString();
    final refId   = notif['referenceId']?.toString();
    final isRead  = notif['isRead'] as bool? ?? false;
    final color   = _color(type);
    final route   = _route(type, refId);

    return InkWell(
      onTap: () => onTap(notif['id']?.toString() ?? '', route),
      child: Container(
        color: isRead ? null : AppTheme.primary.withValues(alpha: 0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon(type), color: color, size: 20),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notif['title']?.toString() ?? '',
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _relTime(notif['createdAt']?.toString()),
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif['body']?.toString() ?? '',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (route != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Tap to view →',
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),

            // Unread dot
            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
