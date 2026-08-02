import 'json_parsing.dart';

/// An alert created automatically by the backend for a high-risk message.
class AlertModel {
  const AlertModel({
    required this.alertId,
    required this.childId,
    required this.messageId,
    required this.title,
    required this.category,
    required this.riskLevel,
    required this.isRead,
    this.createdAt,
  });

  final int alertId;
  final int childId;
  final int messageId;
  final String title;
  final String category;
  final String riskLevel;
  final bool isRead;
  final DateTime? createdAt;

  factory AlertModel.fromJson(Map<String, dynamic> json) => AlertModel(
    alertId: parseInt(json['alert_id']),
    childId: parseInt(json['child_id']),
    messageId: parseInt(json['message_id']),
    title: parseString(json['title']),
    category: parseString(json['category']),
    riskLevel: parseString(json['risk_level']),
    isRead: parseBool(json['is_read']),
    createdAt: parseDateTime(json['created_at']),
  );

  AlertModel copyWith({bool? isRead}) => AlertModel(
    alertId: alertId,
    childId: childId,
    messageId: messageId,
    title: title,
    category: category,
    riskLevel: riskLevel,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}
