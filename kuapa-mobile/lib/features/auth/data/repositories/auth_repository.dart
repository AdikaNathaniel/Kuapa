import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/constants/api_constants.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final _client = ApiClient.instance;

  Future<AuthResponse> register({
    String? email,
    String? phone,
    required String password,
    required UserRole role,
  }) async {
    final res = await _client.post(ApiConstants.register, data: {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'password': password,
      'role': role.name,
    });
    final auth = AuthResponse.fromJson(res.data);
    await SecureStorage.saveTokens(auth.accessToken, auth.refreshToken);
    await SecureStorage.saveUser(auth.user.toJson());
    return auth;
  }

  Future<AuthResponse> login({String? email, String? phone, required String password}) async {
    final res = await _client.post(ApiConstants.login, data: {
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'password': password,
    });
    final auth = AuthResponse.fromJson(res.data);
    await SecureStorage.saveTokens(auth.accessToken, auth.refreshToken);
    await SecureStorage.saveUser(auth.user.toJson());
    return auth;
  }

  Future<void> logout() async {
    try {
      await _client.post(ApiConstants.logout);
    } finally {
      await SecureStorage.clear();
    }
  }

  Future<AuthUser?> getCurrentUser() async {
    final data = await SecureStorage.getUser();
    if (data == null) return null;
    return AuthUser.fromJson(data);
  }
}
