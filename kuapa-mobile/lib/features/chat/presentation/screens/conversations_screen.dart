import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/chat_socket_service.dart';

final _conversationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  ref.watch(authUserProvider);
  final res = await ApiClient.instance.get(ApiConstants.conversations);
  return res.data as List;
});

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user         = ref.watch(authUserProvider).valueOrNull;
    final conversations = ref.watch(_conversationsProvider);

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
      body: conversations.when(
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
                  const Text(
                    'Start a chat from a product listing',
                    style: TextStyle(color: AppTheme.textSecondary),
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
    );
  }
}
