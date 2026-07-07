import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'smartkash.access_token';
  static const _tokenTypeKey = 'smartkash.token_type';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveBackendToken({
    required String accessToken,
    String tokenType = 'Bearer',
  }) async {
    await _secureStorage.write(key: _accessTokenKey, value: accessToken);
    await _secureStorage.write(key: _tokenTypeKey, value: tokenType);
  }

  Future<String?> readAccessToken() {
    return _secureStorage.read(key: _accessTokenKey);
  }

  Future<String> readTokenType() async {
    return await _secureStorage.read(key: _tokenTypeKey) ?? 'Bearer';
  }

  Future<void> clearBackendToken() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _tokenTypeKey);
  }
}
