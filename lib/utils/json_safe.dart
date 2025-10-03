// lib/utils/json_safe.dart
import 'dart:convert';

Map<String, dynamic> asMap(dynamic v) {
  if (v is Map) return Map<String, dynamic>.from(v as Map);
  return <String, dynamic>{};
}

List<T> asList<T>(dynamic v) {
  if (v is List) return v.cast<T>();
  return <T>[];
}

Map<String, dynamic> decodeMapOrEmpty(String? s) {
  if (s == null || s.trim().isEmpty) return {};
  try {
    final d = jsonDecode(s);
    return asMap(d);
  } catch (_) {
    return {};
  }
}
