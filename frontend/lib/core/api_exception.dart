/// A single exception type for every failure raised by the API layer.
///
/// It extracts FastAPI's `detail` field when the backend provides one, and
/// exposes a Hebrew message that is safe to show directly to the user.
class ApiException implements Exception {
  ApiException({required this.message, this.statusCode, this.detail});

  /// Friendly Hebrew message intended for the UI.
  final String message;

  /// HTTP status code, when the failure came from a real response.
  final int? statusCode;

  /// Raw `detail` value returned by FastAPI, when available.
  final String? detail;

  /// True when the session is missing, invalid or expired.
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  bool get isNotFound => statusCode == 404;

  /// Builds an exception from a decoded FastAPI error body.
  ///
  /// FastAPI uses `{"detail": "..."}` for `HTTPException` and
  /// `{"detail": [{"loc": [...], "msg": "..."}]}` for 422 validation errors.
  factory ApiException.fromResponse(int statusCode, dynamic body) {
    final String? detail = _extractDetail(body);

    return ApiException(
      statusCode: statusCode,
      detail: detail,
      message: _hebrewMessageFor(statusCode, detail),
    );
  }

  factory ApiException.network() => ApiException(
    message: 'לא ניתן להתחבר לשרת. ודאו שהשרת פועל ושכתובת ה-API נכונה.',
  );

  factory ApiException.timeout() =>
      ApiException(message: 'הבקשה ארכה זמן רב מדי. נסו שוב.');

  factory ApiException.badFormat() =>
      ApiException(message: 'התקבלה תשובה לא צפויה מהשרת.');

  static String? _extractDetail(dynamic body) {
    if (body is Map && body['detail'] != null) {
      final dynamic detail = body['detail'];

      if (detail is String) {
        return detail;
      }

      // 422 validation errors arrive as a list of error objects.
      if (detail is List) {
        final List<String> messages = detail
            .whereType<Map>()
            .map((Map<dynamic, dynamic> item) => item['msg']?.toString())
            .whereType<String>()
            .toList();

        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      return detail.toString();
    }

    if (body is String && body.trim().isNotEmpty) {
      return body.trim();
    }

    return null;
  }

  static String _hebrewMessageFor(int statusCode, String? detail) {
    switch (statusCode) {
      case 401:
      case 403:
        return _translateDetail(detail) ??
            'ההתחברות פגה או שאינה תקפה. יש להתחבר מחדש.';
      case 404:
        return _translateDetail(detail) ??
            'הפריט המבוקש לא נמצא או שאינו שייך לחשבון שלכם.';
      case 409:
        return _translateDetail(detail) ?? 'הפריט כבר קיים במערכת.';
      case 422:
        return 'חלק מהפרטים שהוזנו אינם תקינים. בדקו את השדות ונסו שוב.';
      case 500:
      case 502:
      case 503:
        return 'אירעה שגיאה בשרת. נסו שוב מאוחר יותר.';
      default:
        return _translateDetail(detail) ??
            'אירעה שגיאה בלתי צפויה (קוד $statusCode).';
    }
  }

  /// Maps the known English `detail` strings from the backend to Hebrew.
  static String? _translateDetail(String? detail) {
    if (detail == null || detail.trim().isEmpty) {
      return null;
    }

    const Map<String, String> translations = <String, String>{
      'Email is already registered': 'כתובת האימייל כבר רשומה במערכת.',
      'Incorrect email or password': 'האימייל או הסיסמה שגויים.',
      'Invalid or expired authentication token':
          'ההתחברות פגה. יש להתחבר מחדש.',
      'Not authenticated': 'נדרשת התחברות כדי להמשיך.',
      'Child not found': 'הילד לא נמצא או שאינו שייך לחשבון שלכם.',
      'Alert not found': 'ההתראה לא נמצאה או שאינה שייכת לחשבון שלכם.',
    };

    return translations[detail.trim()];
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
