import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_exception.dart';

void main() {
  group('ApiException.fromResponse', () {
    test('extracts a string detail and translates a known message', () {
      final ApiException exception = ApiException.fromResponse(
        409,
        <String, dynamic>{'detail': 'Email is already registered'},
      );

      expect(exception.statusCode, 409);
      expect(exception.detail, 'Email is already registered');
      expect(exception.message, 'כתובת האימייל כבר רשומה במערכת.');
    });

    test('translates an incorrect-login detail', () {
      final ApiException exception = ApiException.fromResponse(
        401,
        <String, dynamic>{'detail': 'Incorrect email or password'},
      );

      expect(exception.message, 'האימייל או הסיסמה שגויים.');
      expect(exception.isAuthError, isTrue);
    });

    test('joins FastAPI 422 validation details', () {
      final ApiException exception = ApiException.fromResponse(
        422,
        <String, dynamic>{
          'detail': <dynamic>[
            <String, dynamic>{
              'loc': <String>['body', 'password'],
              'msg': 'String should have at least 8 characters',
            },
            <String, dynamic>{
              'loc': <String>['body', 'email'],
              'msg': 'value is not a valid email address',
            },
          ],
        },
      );

      expect(exception.statusCode, 422);
      expect(exception.detail, contains('at least 8 characters'));
      expect(exception.detail, contains('valid email address'));
      // 422 always shows a single friendly Hebrew message.
      expect(
        exception.message,
        'חלק מהפרטים שהוזנו אינם תקינים. בדקו את השדות ונסו שוב.',
      );
    });

    test('falls back to a generic Hebrew message for 500', () {
      final ApiException exception = ApiException.fromResponse(500, null);

      expect(exception.detail, isNull);
      expect(exception.message, 'אירעה שגיאה בשרת. נסו שוב מאוחר יותר.');
      expect(exception.isAuthError, isFalse);
    });

    test('marks 403 as an auth error', () {
      final ApiException exception = ApiException.fromResponse(
        403,
        <String, dynamic>{'detail': 'Not authenticated'},
      );

      expect(exception.isAuthError, isTrue);
      expect(exception.message, 'נדרשת התחברות כדי להמשיך.');
    });

    test('reports 404 as not found', () {
      final ApiException exception = ApiException.fromResponse(
        404,
        <String, dynamic>{'detail': 'Child not found'},
      );

      expect(exception.isNotFound, isTrue);
      expect(exception.message, 'הילד לא נמצא או שאינו שייך לחשבון שלכם.');
    });

    test('keeps an untranslated detail out of the user message for 500', () {
      final ApiException exception = ApiException.fromResponse(
        500,
        <String, dynamic>{'detail': 'Some internal trace'},
      );

      expect(exception.detail, 'Some internal trace');
      expect(exception.message, isNot(contains('trace')));
    });

    test('handles a plain string body', () {
      final ApiException exception = ApiException.fromResponse(
        400,
        'Bad Request',
      );

      expect(exception.detail, 'Bad Request');
    });
  });

  group('named constructors', () {
    test('network and timeout produce Hebrew messages', () {
      expect(ApiException.network().message, contains('לא ניתן להתחבר לשרת'));
      expect(ApiException.timeout().message, contains('זמן רב מדי'));
      expect(ApiException.badFormat().message, contains('לא צפויה'));
    });

    test('non-response exceptions have no status code', () {
      expect(ApiException.network().statusCode, isNull);
      expect(ApiException.network().isAuthError, isFalse);
    });
  });
}
