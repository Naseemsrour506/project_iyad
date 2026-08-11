import 'json_parsing.dart';

/// A child profile owned by the logged-in parent (`/api/children`).
class ChildModel {
  const ChildModel({
    required this.childId,
    required this.parentId,
    required this.fullName,
    required this.age,
    this.createdAt,
  });

  final int childId;
  final int parentId;
  final String fullName;
  final int age;
  final DateTime? createdAt;

  factory ChildModel.fromJson(Map<String, dynamic> json) => ChildModel(
    childId: parseInt(json['child_id']),
    parentId: parseInt(json['parent_id']),
    fullName: parseString(json['full_name']),
    age: parseInt(json['age']),
    createdAt: parseDateTime(json['created_at']),
  );
}
