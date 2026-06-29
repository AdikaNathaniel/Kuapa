import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';

class NotificationsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  NotificationsNotifier() : super(const AsyncValue.loading()) {
    fetch();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final res = await ApiClient.instance.get(ApiConstants.notifications);
      return res.data as Map<String, dynamic>;
    });
  }

  Future<void> markRead(String id) async {
    try {
      await ApiClient.instance.patch('${ApiConstants.notifications}/$id/read', data: {});
      fetch();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await ApiClient.instance.patch('${ApiConstants.notifications}/read-all', data: {});
      fetch();
    } catch (_) {}
  }
}

final notificationsProvider =
    StateNotifierProvider.autoDispose<NotificationsNotifier, AsyncValue<Map<String, dynamic>>>(
  (_) => NotificationsNotifier(),
);

/// Derives the unread count from the notifications response.
/// Returns 0 when loading or on error so the badge stays clean.
final unreadCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(notificationsProvider).maybeWhen(
    data: (d) => (d['unread'] as num?)?.toInt() ?? 0,
    orElse: () => 0,
  );
});
