DateTime asDate(dynamic value) {
  if (value == null || value.toString().isEmpty) return DateTime(2026, 1, 1);
  return DateTime.tryParse(value.toString()) ?? DateTime(2026, 1, 1);
}

DateTime? asDateOrNull(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  return DateTime.tryParse(value.toString());
}

List<String> asStrings(dynamic value) {
  if (value is List) return value.map((e) => e.toString()).toList();
  return [];
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  if (value is! List) return [];
  return value.map(asMap).toList();
}

String asString(dynamic value, [String fallback = '']) => value?.toString() ?? fallback;

int asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double asDouble(dynamic value, [double fallback = 0]) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

double? asDoubleOrNull(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

bool asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) return value;
  if (value == null) return fallback;
  return value.toString() == 'true';
}
