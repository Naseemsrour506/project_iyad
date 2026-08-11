import 'json_parsing.dart';

/// The result returned by `POST /api/analyze`.
class AnalysisResultModel {
  const AnalysisResultModel({
    required this.messageId,
    required this.childId,
    required this.message,
    required this.category,
    required this.riskLevel,
    required this.confidence,
    required this.explanation,
  });

  final int messageId;
  final int childId;
  final String message;

  /// One of: Normal, Insult, Threat, Harassment, Bullying.
  final String category;

  /// One of: Low, Medium, High.
  final String riskLevel;

  /// Value between 0 and 1.
  final double confidence;

  final String explanation;

  bool get isHighRisk => riskLevel.toLowerCase() == 'high';

  factory AnalysisResultModel.fromJson(Map<String, dynamic> json) =>
      AnalysisResultModel(
        messageId: parseInt(json['message_id']),
        childId: parseInt(json['child_id']),
        message: parseString(json['message']),
        category: parseString(json['category']),
        riskLevel: parseString(json['risk_level']),
        confidence: parseDouble(json['confidence']),
        explanation: parseString(json['explanation']),
      );
}
