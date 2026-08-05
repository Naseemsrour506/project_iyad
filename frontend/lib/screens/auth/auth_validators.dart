/// Shared form validators, so login, registration and the child form apply the
/// same rules the backend enforces.
class AuthValidators {
  const AuthValidators._();

  static final RegExp _emailPattern = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  static String? fullName(String? value) {
    final String name = (value ?? '').trim();

    if (name.isEmpty) return 'יש להזין שם מלא';
    if (name.length < 2) return 'השם חייב להכיל לפחות 2 תווים';
    if (name.length > 120) return 'השם יכול להכיל עד 120 תווים';
    return null;
  }

  static String? email(String? value) {
    final String email = (value ?? '').trim();

    if (email.isEmpty) return 'יש להזין כתובת אימייל';
    if (!_emailPattern.hasMatch(email)) return 'כתובת האימייל אינה תקינה';
    return null;
  }

  static String? password(String? value) {
    final String password = value ?? '';

    if (password.isEmpty) return 'יש להזין סיסמה';
    if (password.length < 8) return 'הסיסמה חייבת להכיל לפחות 8 תווים';
    if (password.length > 128) return 'הסיסמה יכולה להכיל עד 128 תווים';
    return null;
  }

  /// Login only checks that a password was entered; length rules belong to
  /// registration so existing accounts are never locked out by a client rule.
  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'יש להזין סיסמה';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if ((value ?? '').isEmpty) return 'יש לאשר את הסיסמה';
    if (value != original) return 'הסיסמאות אינן תואמות';
    return null;
  }

  static String? childAge(String? value) {
    final String raw = (value ?? '').trim();

    if (raw.isEmpty) return 'יש להזין גיל';

    final int? age = int.tryParse(raw);
    if (age == null) return 'הגיל חייב להיות מספר שלם';
    if (age < 1 || age > 18) return 'הגיל חייב להיות בין 1 ל-18';
    return null;
  }

  static String? message(String? value) {
    if ((value ?? '').trim().isEmpty) return 'יש להזין הודעה לניתוח';
    return null;
  }
}
