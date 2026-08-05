import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction over token persistence.
///
/// The rest of the app depends on this interface, never on
/// `flutter_secure_storage` directly, so storage can be swapped or faked in
/// tests without touching call sites.
abstract class TokenStorageService {
  Future<void> saveToken(String token);

  Future<String?> readToken();

  Future<void> deleteToken();

  Future<bool> hasToken();
}

/// Default implementation backed by `flutter_secure_storage`.
///
/// Secure storage can fail on some platforms/browsers (for example a browser
/// with storage disabled). Rather than crashing the app on startup, failures
/// fall back to an in-memory value that lives for the current session only.
class SecureTokenStorageService implements TokenStorageService {
  SecureTokenStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'safe_kid_access_token';

  final FlutterSecureStorage _storage;

  /// Session-only fallback used when the secure backend is unavailable.
  String? _inMemoryToken;

  @override
  Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (error) {
      // Never log the token itself.
      debugPrint('Secure storage write failed; using in-memory session token.');
    }
  }

  @override
  Future<String?> readToken() async {
    try {
      final String? stored = await _storage.read(key: _tokenKey);
      if (stored != null && stored.isNotEmpty) {
        _inMemoryToken = stored;
        return stored;
      }
    } catch (error) {
      debugPrint('Secure storage read failed; falling back to session token.');
    }
    return _inMemoryToken;
  }

  @override
  Future<void> deleteToken() async {
    _inMemoryToken = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (error) {
      debugPrint('Secure storage delete failed.');
    }
  }

  @override
  Future<bool> hasToken() async {
    final String? token = await readToken();
    return token != null && token.isNotEmpty;
  }
}

/// Simple in-memory implementation, useful for tests.
class InMemoryTokenStorageService implements TokenStorageService {
  String? _token;

  @override
  Future<void> saveToken(String token) async => _token = token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> deleteToken() async => _token = null;

  @override
  Future<bool> hasToken() async => _token != null && _token!.isNotEmpty;
}
