import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/auth_models.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/services/notification_service.dart';

final authRepositoryProvider = Provider((_) => AuthRepository());

final authUserProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>(
  (ref) => AuthNotifier(ref.read(authRepositoryProvider)),
);

class AuthNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final user = await _repo.getCurrentUser();
    state = AsyncValue.data(user);
  }

  Future<void> register({
    String? username,
    String? email,
    String? phone,
    required String password,
    required UserRole role,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.register(
          username: username,
          email: email,
          phone: phone,
          password: password,
          role: role,
        ).then((r) => r.user));
    if (state.hasValue && state.value != null) {
      NotificationService.instance.registerTokenAfterLogin();
    }
  }

  Future<void> login({String? email, String? phone, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.login(
          email: email,
          phone: phone,
          password: password,
        ).then((r) => r.user));
    if (state.hasValue && state.value != null) {
      NotificationService.instance.registerTokenAfterLogin();
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }
}
