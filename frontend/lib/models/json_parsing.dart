/// Small, shared helpers so every model parses backend JSON defensively.
///
/// The backend is strongly typed, but a client that crashes on one unexpected
/// null is worse than one that degrades gracefully.
library;

int parseInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double parseDouble(dynamic value, {double fallback = 0}) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool parseBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final String normalized = value.toLowerCase().trim();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return fallback;
}

String parseString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

/// Parses an ISO-8601 timestamp. Returns null instead of throwing so the UI
/// can simply render a placeholder.
DateTime? parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

/// Parses a `{"Low": 1, "High": 2}` style counter map.
Map<String, int> parseIntMap(dynamic value) {
  if (value is! Map) return <String, int>{};

  return <String, int>{
    for (final MapEntry<dynamic, dynamic> entry in value.entries)
      entry.key.toString(): parseInt(entry.value),
  };
}
