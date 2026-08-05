import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';
import 'package:frontend/screens/auth/login_screen.dart';
import 'package:frontend/screens/splash/splash_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/token_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// End-to-end startup behaviour of the app shell, with HTTP mocked out.
void main() {
  testWidgets('starts on the splash screen and falls back to login when no '
      'token is stored', (WidgetTester tester) async {
    final InMemoryTokenStorageService storage = InMemoryTokenStorageService();

    await tester.pumpWidget(
      SafeKidApp(
        tokenStorage: storage,
        apiService: ApiService(
          tokenStorage: storage,
          client: MockClient(
            (http.Request request) async => http.Response('{}', 200),
          ),
        ),
      ),
    );

    // The first frame shows the splash while the session is restored.
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('ברוכים הבאים'), findsOneWidget);
  });

  testWidgets('renders right-to-left', (WidgetTester tester) async {
    final InMemoryTokenStorageService storage = InMemoryTokenStorageService();

    await tester.pumpWidget(
      SafeKidApp(
        tokenStorage: storage,
        apiService: ApiService(
          tokenStorage: storage,
          client: MockClient(
            (http.Request request) async => http.Response('{}', 200),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The direction that actually applies to the visible screen is the
    // innermost Directionality above it, not the harness's outer one.
    expect(
      Directionality.of(tester.element(find.byType(LoginScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('restores an authenticated session from a stored token', (
    WidgetTester tester,
  ) async {
    final InMemoryTokenStorageService storage = InMemoryTokenStorageService();
    await storage.saveToken('valid-jwt-token');

    await tester.pumpWidget(
      SafeKidApp(
        tokenStorage: storage,
        apiService: ApiService(
          tokenStorage: storage,
          client: MockClient((http.Request request) async {
            if (request.url.path == '/api/auth/me') {
              return http.Response(
                '{"user_id":1,"full_name":"Parent Name",'
                '"email":"parent@example.com","role":"Parent",'
                '"created_at":"2026-07-08T14:24:15"}',
                200,
              );
            }
            // Every other startup call (children, alerts, stats) returns empty.
            return http.Response('[]', 200);
          }),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Safe Kid'), findsOneWidget);
  });

  testWidgets('discards an expired token and shows login', (
    WidgetTester tester,
  ) async {
    final InMemoryTokenStorageService storage = InMemoryTokenStorageService();
    await storage.saveToken('expired-jwt-token');

    await tester.pumpWidget(
      SafeKidApp(
        tokenStorage: storage,
        apiService: ApiService(
          tokenStorage: storage,
          client: MockClient(
            (http.Request request) async => http.Response(
              '{"detail":"Invalid or expired authentication token"}',
              401,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(await storage.readToken(), isNull);
  });
}
