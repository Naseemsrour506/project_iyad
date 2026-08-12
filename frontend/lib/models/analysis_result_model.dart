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

/// The result returned by `POST /api/messages/upload`.
class BatchAnalysisResultModel {
  const BatchAnalysisResultModel({
    required this.childId,
    required this.totalMessages,
    required this.results,
  });

  final int childId;
  final int totalMessages;
  final List<AnalysisResultModel> results;

  int get highRiskCount =>
      results.where((AnalysisResultModel result) => result.isHighRisk).length;

  factory BatchAnalysisResultModel.fromJson(Map<String, dynamic> json) {
    final Object? rawResults = json['results'];

    return BatchAnalysisResultModel(
      childId: parseInt(json['child_id']),
      totalMessages: parseInt(json['total_messages']),
      results: rawResults is List
          ? rawResults
                .map(
                  (Object? item) => AnalysisResultModel.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
          : <AnalysisResultModel>[],
    );
  }
}
