import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/chat_socket_service.dart';

final _conversationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(authUserProvider);
  final res = await ApiClient.instance.get(ApiConstants.conversations);
  return res.data as List;
});

final _farmersListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final res = await ApiClient.instance.get(ApiConstants.farmers);
  return res.data as List? ?? [];
});

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user          = ref.watch(authUserProvider).valueOrNull;
    final conversations = ref.watch(_conversationsProvider);
    final isBuyer       = user?.role == UserRole.BUYER;

    // Ensure socket is connected
    if (user != null) ChatSocketService.instance.connect(user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.refresh(_conversationsProvider),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Farmers to message (buyers only) ──────────────────────────
          if (isBuyer) _FarmersRow(user: user!),

          // ── Conversations list ─────────────────────────────────────────
          Expanded(
            child: conversations.when(
              loading: () => const LoadingView(message: 'Loading conversations…'),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.refresh(_conversationsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'No conversations yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isBuyer ? 'Tap a farmer above to start chatting' : 'Start a chat from a product listing',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                  itemBuilder: (_, i) {
                    final conv      = items[i] as Map<String, dynamic>;
                    final myId      = user?.id ?? '';
                    final isP1      = conv['participant1Id'] == myId;
                    final otherName = isP1
                        ? conv['participant2Name']?.toString() ?? 'User'
                        : conv['participant1Name']?.toString() ?? 'User';
                    final lastMsg   = conv['lastMessage']?.toString();
                    final lastAt    = conv['lastMessageAt'] != null
                        ? DateTime.tryParse(conv['lastMessageAt'].toString())
                        : null;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                        child: Text(
                          otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      title: Text(
                        otherName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      subtitle: lastMsg != null
                          ? Text(
                              lastMsg,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                            )
                          : const Text(
                              'Start the conversation',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                      trailing: lastAt != null
                          ? Text(
                              timeago.format(lastAt, allowFromNow: true),
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            )
                          : null,
                      onTap: () => context.push(
                        '/chat/${conv['id']}',
                        extra: otherName,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Horizontal farmers row (buyers only) ─────────────────────────────────────

class _FarmersRow extends ConsumerWidget {
  final AuthUser user;
  const _FarmersRow({required this.user});

  Future<void> _startChat(BuildContext context, WidgetRef ref, Map<String, dynamic> farmer) async {
    final farmerId   = farmer['userId']?.toString() ?? farmer['id']?.toString() ?? '';
    final farmerName = farmer['fullName']?.toString() ?? farmer['username']?.toString() ?? 'Farmer';
    if (farmerId.isEmpty) return;

    try {
      final res = await ApiClient.instance.post(ApiConstants.conversations, data: {
        'p1Id':   user.id,
        'p1Name': user.username ?? user.email ?? 'Buyer',
        'p2Id':   farmerId,
        'p2Name': farmerName,
      });
      final convId = res.data['id']?.toString() ?? '';
      if (convId.isNotEmpty && context.mounted) {
        context.push('/chat/$convId', extra: farmerName);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start chat. Try again.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmers = ref.watch(_farmersListProvider);

    return farmers.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Text(
                'Farmers on Kuapa',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
            ),
            SizedBox(
              height: 96,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final farmer = list[i] as Map<String, dynamic>;
                  final name   = farmer['fullName']?.toString() ?? farmer['username']?.toString() ?? 'Farmer';
                  final region = farmer['region']?.toString();

                  return GestureDetector(
                    onTap: () => _startChat(context, ref, farmer),
                    child: Container(
                      width: 72,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'F',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name.split(' ').first,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          if (region != null)
                            Text(
                              region,
                              style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                'Recent Chats',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
            ),
          ],
        );
      },
    );
  }
}
