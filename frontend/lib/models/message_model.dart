import 'json_parsing.dart';

/// A previously analyzed message from `GET /api/messages`.
///
/// Same shape as [AnalysisResultModel] plus `created_at`.
class AnalyzedMessageModel {
  const AnalyzedMessageModel({
    required this.messageId,
    required this.childId,
    required this.message,
    required this.category,
    required this.riskLevel,
    required this.confidence,
    required this.explanation,
    this.createdAt,
  });

  final int messageId;
  final int childId;
  final String message;
  final String category;
  final String riskLevel;
  final double confidence;
  final String explanation;
  final DateTime? createdAt;

  bool get isHighRisk => riskLevel.toLowerCase() == 'high';

  factory AnalyzedMessageModel.fromJson(Map<String, dynamic> json) =>
      AnalyzedMessageModel(
        messageId: parseInt(json['message_id']),
        childId: parseInt(json['child_id']),
        message: parseString(json['message']),
        category: parseString(json['category']),
        riskLevel: parseString(json['risk_level']),
        confidence: parseDouble(json['confidence']),
        explanation: parseString(json['explanation']),
        createdAt: parseDateTime(json['created_at']),
      );
}
