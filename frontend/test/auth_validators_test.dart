import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/auth/auth_validators.dart';

void main() {
  group('fullName', () {
    test('rejects empty and too-short names', () {
      expect(AuthValidators.fullName(''), 'יש להזין שם מלא');
      expect(AuthValidators.fullName('   '), 'יש להזין שם מלא');
      expect(AuthValidators.fullName('A'), 'השם חייב להכיל לפחות 2 תווים');
    });

    test('rejects names longer than 120 characters', () {
      expect(AuthValidators.fullName('x' * 121), isNotNull);
    });

    test('accepts valid names at the boundaries', () {
      expect(AuthValidators.fullName('אב'), isNull);
      expect(AuthValidators.fullName('x' * 120), isNull);
    });
  });

  group('email', () {
    test('rejects malformed addresses', () {
      expect(AuthValidators.email(''), 'יש להזין כתובת אימייל');
      expect(AuthValidators.email('parent'), 'כתובת האימייל אינה תקינה');
      expect(AuthValidators.email('parent@'), isNotNull);
      expect(AuthValidators.email('parent@example'), isNotNull);
      expect(AuthValidators.email('@example.com'), isNotNull);
    });

    test('accepts valid addresses', () {
      expect(AuthValidators.email('parent@example.com'), isNull);
      expect(AuthValidators.email('first.last+tag@sub.example.co.il'), isNull);
    });
  });

  group('password', () {
    test('enforces the 8-128 character range from the API contract', () {
      expect(AuthValidators.password(''), 'יש להזין סיסמה');
      expect(
        AuthValidators.password('short12'),
        'הסיסמה חייבת להכיל לפחות 8 תווים',
      );
      expect(AuthValidators.password('x' * 129), isNotNull);
      expect(AuthValidators.password('StrongPassword123'), isNull);
      expect(AuthValidators.password('x' * 8), isNull);
    });

    test('login only requires a non-empty password', () {
      expect(AuthValidators.loginPassword(''), 'יש להזין סיסמה');
      // An existing short password must never be blocked by a client rule.
      expect(AuthValidators.loginPassword('short'), isNull);
    });
  });

  group('confirmPassword', () {
    test('rejects a mismatch', () {
      expect(
        AuthValidators.confirmPassword('abc12345', 'different'),
        'הסיסמאות אינן תואמות',
      );
    });

    test('rejects an empty confirmation', () {
      expect(
        AuthValidators.confirmPassword('', 'abc12345'),
        'יש לאשר את הסיסמה',
      );
    });

    test('accepts an exact match', () {
      expect(AuthValidators.confirmPassword('abc12345', 'abc12345'), isNull);
    });
  });

  group('childAge', () {
    test('enforces the 1-18 range', () {
      expect(AuthValidators.childAge(''), 'יש להזין גיל');
      expect(AuthValidators.childAge('abc'), 'הגיל חייב להיות מספר שלם');
      expect(AuthValidators.childAge('0'), 'הגיל חייב להיות בין 1 ל-18');
      expect(AuthValidators.childAge('19'), 'הגיל חייב להיות בין 1 ל-18');
      expect(AuthValidators.childAge('1'), isNull);
      expect(AuthValidators.childAge('18'), isNull);
    });
  });

  group('message', () {
    test('rejects blank messages', () {
      expect(AuthValidators.message(''), 'יש להזין הודעה לניתוח');
      expect(AuthValidators.message('   '), 'יש להזין הודעה לניתוח');
    });

    test('accepts a Hebrew message', () {
      expect(AuthValidators.message('אף אחד לא אוהב אותך'), isNull);
    });
  });
}
