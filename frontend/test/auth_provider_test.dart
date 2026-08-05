import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/auth_service.dart';

import 'fakes/fake_auth_service.dart';

void main() {
  group('AuthProvider.initialize', () {
    test('goes to unauthenticated when no token is stored', () async {
      final FakeAuthService service = FakeAuthService();
      final AuthProvider provider = AuthProvider(authService: service);

      await provider.initialize();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
      expect(service.currentUserCallCount, 0);
    });

    test('restores the session when the stored token is valid', () async {
      final UserModel user = buildTestUser();
      final FakeAuthService service = FakeAuthService(
        storedToken: 'stored-token',
        currentUserResult: user,
      );
      final AuthProvider provider = AuthProvider(authService: service);

      await provider.initialize();

      expect(provider.status, AuthStatus.authenticated);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.user?.email, 'parent@example.com');
      expect(service.currentUserCallCount, 1);
    });

    test('clears an expired token and requires login again', () async {
      final FakeAuthService service = FakeAuthService(
        storedToken: 'expired-token',
        currentUserError: ApiException.fromResponse(401, <String, dynamic>{
          'detail': 'Invalid or expired authentication token',
        }),
      );
      final AuthProvider provider = AuthProvider(authService: service);

      await provider.initialize();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
      expect(service.logoutCallCount, 1);
      expect(service.storedToken, isNull);
    });

    test(
      'surfaces a network failure without keeping the user signed in',
      () async {
        final FakeAuthService service = FakeAuthService(
          storedToken: 'token',
          currentUserError: ApiException.network(),
        );
        final AuthProvider provider = AuthProvider(authService: service);

        await provider.initialize();

        expect(provider.status, AuthStatus.unauthenticated);
        expect(provider.errorMessage, contains('לא ניתן להתחבר לשרת'));
        // A network blip must not silently delete a possibly valid token.
        expect(service.logoutCallCount, 0);
      },
    );
  });

  group('AuthProvider.login', () {
    test('authenticates and exposes the user on success', () async {
      final FakeAuthService service = FakeAuthService(
        loginResult: LoginResult(
          accessToken: 'jwt-token',
          user: buildTestUser(),
        ),
      );
      final AuthProvider provider = AuthProvider(authService: service);

      final bool result = await provider.login(
        email: 'parent@example.com',
        password: 'StrongPassword123',
      );

      expect(result, isTrue);
      expect(provider.status, AuthStatus.authenticated);
      expect(provider.user?.fullName, 'Parent Name');
      expect(provider.isBusy, isFalse);
      expect(provider.errorMessage, isNull);
      expect(service.lastLoginEmail, 'parent@example.com');
    });

    test('reports a Hebrew error on wrong credentials', () async {
      final FakeAuthService service = FakeAuthService(
        loginError: ApiException.fromResponse(401, <String, dynamic>{
          'detail': 'Incorrect email or password',
        }),
      );
      final AuthProvider provider = AuthProvider(authService: service);

      final bool result = await provider.login(
        email: 'parent@example.com',
        password: 'wrong-password',
      );

      expect(result, isFalse);
      expect(provider.status, AuthStatus.unknown);
      expect(provider.isAuthenticated, isFalse);
      expect(provider.errorMessage, 'האימייל או הסיסמה שגויים.');
      expect(provider.isBusy, isFalse);
    });

    test('notifies listeners while the request is in flight', () async {
      final FakeAuthService service = FakeAuthService(
        loginResult: LoginResult(
          accessToken: 'jwt-token',
          user: buildTestUser(),
        ),
      );
      final AuthProvider provider = AuthProvider(authService: service);

      final List<bool> busyStates = <bool>[];
      provider.addListener(() => busyStates.add(provider.isBusy));

      await provider.login(email: 'a@b.com', password: 'password123');

      expect(busyStates.first, isTrue);
      expect(busyStates.last, isFalse);
    });
  });

  group('AuthProvider.register', () {
    test('succeeds without authenticating the user', () async {
      final FakeAuthService service = FakeAuthService();
      final AuthProvider provider = AuthProvider(authService: service);

      final bool result = await provider.register(
        fullName: 'Parent Name',
        email: 'new@example.com',
        password: 'StrongPassword123',
      );

      expect(result, isTrue);
      expect(service.lastRegisteredEmail, 'new@example.com');
      // The register endpoint returns no token, so the user stays signed out.
      expect(provider.isAuthenticated, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('reports a duplicate email in Hebrew', () async {
      final FakeAuthService service = FakeAuthService(
        registerError: ApiException.fromResponse(409, <String, dynamic>{
          'detail': 'Email is already registered',
        }),
      );
      final AuthProvider provider = AuthProvider(authService: service);

      final bool result = await provider.register(
        fullName: 'Parent Name',
        email: 'taken@example.com',
        password: 'StrongPassword123',
      );

      expect(result, isFalse);
      expect(provider.errorMessage, 'כתובת האימייל כבר רשומה במערכת.');
    });
  });

  group('AuthProvider session teardown', () {
    test('logout clears the user and the stored token', () async {
      final FakeAuthService service = FakeAuthService(
        loginResult: LoginResult(
          accessToken: 'jwt-token',
          user: buildTestUser(),
        ),
      );
      final AuthProvider provider = AuthProvider(authService: service);

      await provider.login(email: 'a@b.com', password: 'password123');
      expect(provider.isAuthenticated, isTrue);

      await provider.logout();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
      expect(service.storedToken, isNull);
      expect(service.logoutCallCount, 1);
    });

    test('handleUnauthorized ends the session with a Hebrew notice', () async {
      final FakeAuthService service = FakeAuthService(
        loginResult: LoginResult(
          accessToken: 'jwt-token',
          user: buildTestUser(),
        ),
      );
      final AuthProvider provider = AuthProvider(authService: service);

      await provider.login(email: 'a@b.com', password: 'password123');
      await provider.handleUnauthorized();

      expect(provider.status, AuthStatus.unauthenticated);
      expect(provider.user, isNull);
      expect(provider.errorMessage, 'ההתחברות פגה. יש להתחבר מחדש.');
    });

    test('handleUnauthorized is a no-op when already signed out', () async {
      final FakeAuthService service = FakeAuthService();
      final AuthProvider provider = AuthProvider(authService: service);

      await provider.initialize();
      await provider.handleUnauthorized();

      expect(service.logoutCallCount, 0);
    });
  });
}
