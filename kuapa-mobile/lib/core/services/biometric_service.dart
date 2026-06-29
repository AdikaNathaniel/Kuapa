import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  BiometricService._();
  static final instance = BiometricService._();

  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  static const _keyPhone = 'bio_phone';
  static const _keyPassword = 'bio_password';

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isSupported) return false;
      final biometrics = await _auth.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasStoredCredentials() async {
    final phone = await _storage.read(key: _keyPhone);
    return phone != null && phone.isNotEmpty;
  }

  Future<void> saveCredentials(String phone, String password) async {
    await _storage.write(key: _keyPhone, value: phone);
    await _storage.write(key: _keyPassword, value: password);
  }

  Future<({String phone, String password})?> getCredentials() async {
    final phone = await _storage.read(key: _keyPhone);
    final password = await _storage.read(key: _keyPassword);
    if (phone == null || password == null) return null;
    return (phone: phone, password: password);
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: _keyPhone);
    await _storage.delete(key: _keyPassword);
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Use your fingerprint to sign in to Kuapa',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
