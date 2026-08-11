import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/auth/register_screen.dart';
import 'package:provider/provider.dart';

import 'fakes/fake_auth_service.dart';

Widget wrapScreen(AuthProvider provider) {
  return ChangeNotifierProvider<AuthProvider>.value(
    value: provider,
    child: const MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: RegisterScreen(),
      ),
    ),
  );
}

/// Fills the four registration fields in order.
Future<void> fillForm(
  WidgetTester tester, {
  String fullName = 'Parent Name',
  String email = 'parent@example.com',
  String password = 'StrongPassword123',
  required String confirmPassword,
}) async {
  final Finder fields = find.byType(TextFormField);

  await tester.enterText(fields.at(0), fullName);
  await tester.enterText(fields.at(1), email);
  await tester.enterText(fields.at(2), password);
  await tester.enterText(fields.at(3), confirmPassword);
}

void main() {
  testWidgets('blocks submission when the passwords do not match', (
    WidgetTester tester,
  ) async {
    final FakeAuthService service = FakeAuthService();
    final AuthProvider provider = AuthProvider(authService: service);

    await tester.pumpWidget(wrapScreen(provider));

    await fillForm(tester, confirmPassword: 'DifferentPassword123');
    await tester.tap(find.widgetWithText(FilledButton, 'הרשמה'));
    await tester.pump();

    expect(find.text('הסיסמאות אינן תואמות'), findsOneWidget);
    expect(service.lastRegisteredEmail, isNull);
  });

  testWidgets('requires the confirmation field to be filled', (
    WidgetTester tester,
  ) async {
    final FakeAuthService service = FakeAuthService();
    final AuthProvider provider = AuthProvider(authService: service);

    await tester.pumpWidget(wrapScreen(provider));

    await fillForm(tester, confirmPassword: '');
    await tester.tap(find.widgetWithText(FilledButton, 'הרשמה'));
    await tester.pump();

    expect(find.text('יש לאשר את הסיסמה'), findsOneWidget);
    expect(service.lastRegisteredEmail, isNull);
  });

  testWidgets('registers when both passwords match', (
    WidgetTester tester,
  ) async {
    final FakeAuthService service = FakeAuthService();
    final AuthProvider provider = AuthProvider(authService: service);

    await tester.pumpWidget(wrapScreen(provider));

    await fillForm(tester, confirmPassword: 'StrongPassword123');
    await tester.tap(find.widgetWithText(FilledButton, 'הרשמה'));
    await tester.pumpAndSettle();

    expect(service.lastRegisteredEmail, 'parent@example.com');
    // Registration returns no token, so the user must not be signed in.
    expect(provider.isAuthenticated, isFalse);
  });

  testWidgets('enforces the minimum password length', (
    WidgetTester tester,
  ) async {
    final FakeAuthService service = FakeAuthService();
    final AuthProvider provider = AuthProvider(authService: service);

    await tester.pumpWidget(wrapScreen(provider));

    await fillForm(tester, password: 'short12', confirmPassword: 'short12');
    await tester.tap(find.widgetWithText(FilledButton, 'הרשמה'));
    await tester.pump();

    expect(find.text('הסיסמה חייבת להכיל לפחות 8 תווים'), findsOneWidget);
    expect(service.lastRegisteredEmail, isNull);
  });

  testWidgets('shows a Hebrew message when the email is already taken', (
    WidgetTester tester,
  ) async {
    final FakeAuthService service = FakeAuthService(
      registerError: ApiException.fromResponse(409, <String, dynamic>{
        'detail': 'Email is already registered',
      }),
    );
    final AuthProvider provider = AuthProvider(authService: service);

    await tester.pumpWidget(wrapScreen(provider));

    await fillForm(tester, confirmPassword: 'StrongPassword123');
    await tester.tap(find.widgetWithText(FilledButton, 'הרשמה'));
    await tester.pumpAndSettle();

    expect(find.text('כתובת האימייל כבר רשומה במערכת.'), findsOneWidget);
  });
}
