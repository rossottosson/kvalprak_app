// lib/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage(
     // Optional: Configure Android options if needed
     // aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final String _keyUsername = 'kvalprak_username';
  final String _keyPassword = 'kvalprak_password';
  final String _keyBiometricsEnabled = 'kvalprak_biometrics_enabled';

  Future<void> saveCredentials(String username, String password) async {
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyPassword, value: password);
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: _keyUsername);
  }

  Future<String?> getPassword() async {
    return await _storage.read(key: _keyPassword);
  }

  Future<void> deleteCredentials() async {
    await _storage.delete(key: _keyUsername);
    await _storage.delete(key: _keyPassword);
    await _storage.delete(key: _keyBiometricsEnabled); // Also clear the enabled flag
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
     await _storage.write(key: _keyBiometricsEnabled, value: enabled ? 'true' : 'false');
  }

    Future<bool> areBiometricsEnabled() async {
    final value = await _storage.read(key: _keyBiometricsEnabled);
    return value == 'true';
  }

   Future<bool> hasCredentials() async {
    final username = await getUsername();
    final password = await getPassword();
    return username != null && password != null;
  }
}