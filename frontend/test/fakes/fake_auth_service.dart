import 'package:frontend/core/api_exception.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/auth_service.dart';

/// In-memory stand-in for [AuthService] so provider tests never touch HTTP.
class FakeAuthService implements AuthService {
  FakeAuthService({
    this.storedToken,
    this.currentUserResult,
    this.currentUserError,
    this.loginResult,
    this.loginError,
    this.registerError,
  });

  String? storedToken;
  UserModel? currentUserResult;
  ApiException? currentUserError;
  LoginResult? loginResult;
  ApiException? loginError;
  ApiException? registerError;

  int currentUserCallCount = 0;
  int logoutCallCount = 0;

  /// Recorded so tests can assert the password is passed through but never kept.
  String? lastLoginEmail;
  String? lastRegisteredEmail;

  @override
  Future<bool> hasStoredToken() async =>
      storedToken != null && storedToken!.isNotEmpty;

  @override
  Future<UserModel> currentUser() async {
    currentUserCallCount++;
    if (currentUserError != null) throw currentUserError!;
    if (currentUserResult == null) {
      throw ApiException(message: 'no user configured');
    }
    return currentUserResult!;
  }

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    lastLoginEmail = email;
    if (loginError != null) throw loginError!;
    if (loginResult == null) {
      throw ApiException(message: 'no login result configured');
    }
    storedToken = loginResult!.accessToken;
    return loginResult!;
  }

  @override
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    lastRegisteredEmail = email;
    if (registerError != null) throw registerError!;
    return UserModel(
      userId: 1,
      fullName: fullName,
      email: email,
      role: 'Parent',
    );
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
    storedToken = null;
  }
}

/// Convenience factory for a valid parent user.
UserModel buildTestUser({
  int userId = 1,
  String fullName = 'Parent Name',
  String email = 'parent@example.com',
}) => UserModel(
  userId: userId,
  fullName: fullName,
  email: email,
  role: 'Parent',
  createdAt: DateTime.parse('2026-07-08T14:24:15'),
);
