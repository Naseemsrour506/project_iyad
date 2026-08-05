import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  /// Startup: the stored token has not been checked yet.
  unknown,
  authenticated,
  unauthenticated,
}

/// Owns the authentication session for the whole app.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _authService = authService;

  final AuthService _authService;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _isBusy = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Startup flow: read the stored token and, if one exists, validate it with
  /// `GET /api/auth/me`. An invalid or expired token is discarded.
  Future<void> initialize() async {
    _status = AuthStatus.unknown;
    notifyListeners();

    try {
      if (!await _authService.hasStoredToken()) {
        _setUnauthenticated();
        return;
      }

      _user = await _authService.currentUser();
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      notifyListeners();
    } on ApiException catch (error) {
      if (error.isAuthError) {
        await _authService.logout();
        _setUnauthenticated();
      } else {
        // A network failure should not silently discard a possibly valid
        // token, but the user still has to reach the login screen.
        _setUnauthenticated(message: error.message);
      }
    } catch (_) {
      _setUnauthenticated();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _beginRequest();

    try {
      final LoginResult result = await _authService.login(
        email: email,
        password: password,
      );

      _user = result.user;
      _status = AuthStatus.authenticated;
      _isBusy = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _failRequest(error.message);
      return false;
    } catch (_) {
      _failRequest('אירעה שגיאה בלתי צפויה. נסו שוב.');
      return false;
    }
  }

  /// Registers a new parent. Returns true on success.
  ///
  /// The register endpoint returns a user object without a token, so the user
  /// is sent back to the login screen afterwards.
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _beginRequest();

    try {
      await _authService.register(
        fullName: fullName,
        email: email,
        password: password,
      );

      _isBusy = false;
      notifyListeners();
      return true;
    } on ApiException catch (error) {
      _failRequest(error.message);
      return false;
    } catch (_) {
      _failRequest('אירעה שגיאה בלתי צפויה. נסו שוב.');
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _setUnauthenticated();
  }

  /// Called by the API layer when the backend rejects the token mid-session.
  Future<void> handleUnauthorized() async {
    if (_status == AuthStatus.unauthenticated) return;

    await _authService.logout();
    _user = null;
    _setUnauthenticated(message: 'ההתחברות פגה. יש להתחבר מחדש.');
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  void _beginRequest() {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _failRequest(String message) {
    _isBusy = false;
    _errorMessage = message;
    notifyListeners();
  }

  void _setUnauthenticated({String? message}) {
    _status = AuthStatus.unauthenticated;
    _isBusy = false;
    _errorMessage = message;
    notifyListeners();
  }
}
