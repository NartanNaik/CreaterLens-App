import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the session token in the Android Keystore-backed secure storage (not plain preferences).
class TokenStore {
  static const _storage = FlutterSecureStorage();
  static const _kToken = 'auth_token';
  static const _kName = 'user_name';
  static const _kEmail = 'user_email';

  Future<String?> readToken() => _storage.read(key: _kToken);
  Future<String?> readName() => _storage.read(key: _kName);
  Future<String?> readEmail() => _storage.read(key: _kEmail);

  Future<void> saveToken(String token) => _storage.write(key: _kToken, value: token);

  Future<void> saveUser({String? name, String? email}) async {
    if (name != null) await _storage.write(key: _kName, value: name);
    if (email != null) await _storage.write(key: _kEmail, value: email);
  }

  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kName);
    await _storage.delete(key: _kEmail);
  }
}