import 'json_parsing.dart';

/// Aggregated statistics from `GET /api/dashboard/stats`.
class DashboardStatsModel {
  const DashboardStatsModel({
    required this.totalChildren,
    required this.totalMessages,
    required this.riskLevels,
    required this.categories,
  });

  final int totalChildren;
  final int totalMessages;

  /// Message count per risk level, keyed by `Low` / `Medium` / `High`.
  final Map<String, int> riskLevels;

  /// Message count per category, keyed by the backend category names.
  final Map<String, int> categories;

  int get lowRiskCount => riskLevels['Low'] ?? 0;

  int get mediumRiskCount => riskLevels['Medium'] ?? 0;

  int get highRiskCount => riskLevels['High'] ?? 0;

  int categoryCount(String category) => categories[category] ?? 0;

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) =>
      DashboardStatsModel(
        totalChildren: parseInt(json['total_children']),
        totalMessages: parseInt(json['total_messages']),
        riskLevels: parseIntMap(json['risk_levels']),
        categories: parseIntMap(json['categories']),
      );
}
