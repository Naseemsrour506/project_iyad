import 'json_parsing.dart';

/// An authenticated parent account (`/api/auth/me`).
class UserModel {
  const UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.createdAt,
  });

  final int userId;
  final String fullName;
  final String email;
  final String role;
  final DateTime? createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    userId: parseInt(json['user_id']),
    fullName: parseString(json['full_name']),
    email: parseString(json['email']),
    role: parseString(json['role'], fallback: 'Parent'),
    createdAt: parseDateTime(json['created_at']),
  );

  /// First letter of the full name, used for the avatar.
  String get initial {
    final String trimmed = fullName.trim();
    return trimmed.isEmpty ? '?' : trimmed.substring(0, 1).toUpperCase();
  }
}
