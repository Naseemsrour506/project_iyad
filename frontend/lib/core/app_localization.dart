import 'package:intl/intl.dart';

/// Hebrew labels for the enum-like values the backend returns in English,
/// plus shared date formatting helpers.
class AppLabels {
  const AppLabels._();

  static const Map<String, String> _categories = <String, String>{
    'Normal': 'תקין',
    'Insult': 'העלבה',
    'Threat': 'איום',
    'Harassment': 'הטרדה',
    'Bullying': 'בריונות',
  };

  static const Map<String, String> _riskLevels = <String, String>{
    'Low': 'סיכון נמוך',
    'Medium': 'סיכון בינוני',
    'High': 'סיכון גבוה',
  };

  static const Map<String, String> _shortRiskLevels = <String, String>{
    'Low': 'נמוך',
    'Medium': 'בינוני',
    'High': 'גבוה',
  };

  /// Canonical category order, matching the backend classifier.
  static const List<String> categoryOrder = <String>[
    'Normal',
    'Insult',
    'Threat',
    'Harassment',
    'Bullying',
  ];

  /// Canonical risk order, from least to most severe.
  static const List<String> riskOrder = <String>['Low', 'Medium', 'High'];

  static String category(String value) => _categories[value] ?? value;

  static String riskLevel(String value) => _riskLevels[value] ?? value;

  static String shortRiskLevel(String value) =>
      _shortRiskLevels[value] ?? value;

  /// Formats a confidence value (0..1) as a whole percentage.
  static String confidence(double value) {
    final double clamped = value.clamp(0, 1).toDouble();
    return '${(clamped * 100).round()}%';
  }

  static final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  static String dateTime(DateTime? value) =>
      value == null ? '—' : _dateTimeFormat.format(value.toLocal());

  static String date(DateTime? value) =>
      value == null ? '—' : _dateFormat.format(value.toLocal());
}
