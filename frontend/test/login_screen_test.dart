import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/auth/login_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_auth_service.dart';

Widget wrapScreen(AuthProvider provider, Widget screen) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: provider,
    child: MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: screen),
    ),
  );
}

void main() {
  testWidgets('shows Hebrew validation errors when the form is empty', (
    WidgetTester tester,
  ) async {
    final FakeAuthService service = FakeAuthService();
    final AuthProvider provider = AuthProvider(authService: service);

    await tester.pumpWidget(wrapScreen(provider, const LoginScreen()));

    await tester.tap(find.widgetWithText(FilledButton, 'התחברות'));
    await tester.pump();

    expect(find.text('יש להזין כתובת אימייל'), findsOneWidget);
    expect(find.text('יש להזין סיסמה'), findsOneWidget);
    // Nothing should have been sent to the service.
    expect(service.lastLoginEmail, isNull);
  });

  testWidgets('rejects a malformed email without calling the service', (
    WidgetTester tester,
  ) async {
    final FakeAuthService service = FakeAuthService();
    final AuthProvider provider = AuthProvider(authService: service);

    await tester.pumpWidget(wrapScreen(provider, const LoginScreen()));

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(FilledButton, 'התחברות'));
    await tester.pump();

    expect(find.text('כתובת האימייל אינה תקינה'), findsOneWidget);
    expect(service.lastLoginEmail, isNull);
  });

  testWidgets('submits valid credentials to the auth service', (
    WidgetTester tester,
  ) async {
    final FakeAuthService service = FakeAuthService(
      loginResult: LoginResult(accessToken: 'jwt-token', user: buildTestUser()),
    );
    final AuthProvider provider = AuthProvider(authService: service);

    await tester.pumpWidget(wrapScreen(provider, const LoginScreen()));

    await tester.enterText(
      find.byType(TextFormField).first,
      'parent@example.com',
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'StrongPassword123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'התחברות'));
    await tester.pumpAndSettle();

    expect(service.lastLoginEmail, 'parent@example.com');
    expect(provider.isAuthenticated, isTrue);
  });

  testWidgets('displays the provider error message', (
    WidgetTester tester,
  ) async {
    final FakeAuthService service = FakeAuthService(
      loginError: ApiException.fromResponse(401, <String, dynamic>{
        'detail': 'Incorrect email or password',
      }),
    );
    final AuthProvider provider = AuthProvider(authService: service);

    await tester.pumpWidget(wrapScreen(provider, const LoginScreen()));

    await tester.enterText(
      find.byType(TextFormField).first,
      'parent@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, 'התחברות'));
    await tester.pumpAndSettle();

    expect(find.text('האימייל או הסיסמה שגויים.'), findsOneWidget);
  });

  testWidgets('password visibility toggle switches the obscure state', (
    WidgetTester tester,
  ) async {
    final AuthProvider provider = AuthProvider(authService: FakeAuthService());

    await tester.pumpWidget(wrapScreen(provider, const LoginScreen()));

    EditableText passwordField() =>
        tester.widget<EditableText>(find.byType(EditableText).last);

    expect(passwordField().obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();

    expect(passwordField().obscureText, isFalse);
  });
}
