import '../core/api_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'token_storage_service.dart';

/// Result of a successful login.
class LoginResult {
  const LoginResult({required this.accessToken, required this.user});

  final String accessToken;
  final UserModel user;
}

/// Authentication calls. Passwords are only ever passed through to the
/// backend — they are never stored or logged.
class AuthService {
  AuthService({required ApiService api, required TokenStorageService storage})
    : _api = api,
      _storage = storage;

  final ApiService _api;
  final TokenStorageService _storage;

  /// `POST /api/auth/register` — returns the created user.
  ///
  /// The endpoint returns a user object, not a token, so the caller must log
  /// the user in separately.
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> json = ApiService.asObject(
      await _api.post(
        ApiConstants.register,
        authenticated: false,
        body: <String, dynamic>{
          'full_name': fullName,
          'email': email,
          'password': password,
        },
      ),
    );

    return UserModel.fromJson(json);
  }

  /// `POST /api/auth/login` — stores the returned token and returns the user.
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> json = ApiService.asObject(
      await _api.post(
        ApiConstants.login,
        authenticated: false,
        body: <String, dynamic>{'email': email, 'password': password},
      ),
    );

    final String token = (json['access_token'] ?? '').toString();
    final LoginResult result = LoginResult(
      accessToken: token,
      user: UserModel.fromJson(ApiService.asObject(json['user'])),
    );

    await _storage.saveToken(token);
    return result;
  }

  /// `GET /api/auth/me` — used to restore a session from a stored token.
  Future<UserModel> currentUser() async {
    return UserModel.fromJson(await _api.getObject(ApiConstants.currentUser));
  }

  Future<void> logout() => _storage.deleteToken();

  Future<bool> hasStoredToken() => _storage.hasToken();
}
