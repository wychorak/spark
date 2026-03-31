import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static final SecureStorageService instance = SecureStorageService._();

  static const _storage = FlutterSecureStorage();

  Future<bool> readBool(String key, {bool fallback = false}) async {
    final raw = await _storage.read(key: key);
    if (raw == null) return fallback;
    return raw == 'true';
  }

  Future<void> writeBool(String key, bool value) async {
    await _storage.write(key: key, value: value ? 'true' : 'false');
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
