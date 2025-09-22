/// Güvenli JSON parsing yardımcı fonksiyonları
/// AI'dan gelen "kirli" veriyi temizleyip doğru formata çevirir

/// Gelen değeri ne olursa olsun güvenli bir şekilde tam sayıya (int) çevirir
int safeParseInt(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    // String içindeki "kcal", "s", "g" gibi tüm harfleri temizle, sadece rakamları bırak
    final cleanString = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleanString) ?? defaultValue;
  }
  return defaultValue;
}

/// Gelen değeri ne olursa olsun güvenli bir şekilde ondalıklı sayıya (double) çevirir
double safeParseDouble(dynamic value, {double defaultValue = 0.0}) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    // String içindeki harfleri temizle, sadece rakam ve nokta bırak
    final cleanString = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleanString) ?? defaultValue;
  }
  return defaultValue;
}

/// Gelen değeri ne olursa olsun güvenli bir şekilde string'e çevirir
String safeParseString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  if (value is String) return value;
  return value.toString();
}

/// Gelen değeri ne olursa olsun güvenli bir şekilde boolean'a çevirir
bool safeParseBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is String) {
    final lowerValue = value.toLowerCase();
    return lowerValue == 'true' || lowerValue == '1' || lowerValue == 'yes';
  }
  if (value is int) return value != 0;
  if (value is double) return value != 0.0;
  return defaultValue;
}

/// Gelen değeri ne olursa olsun güvenli bir şekilde liste'ye çevirir
List<T> safeParseList<T>(dynamic value, T Function(dynamic) itemParser,
    {List<T> defaultValue = const []}) {
  if (value == null) return defaultValue;
  if (value is List) {
    try {
      final List<T> result = [];
      for (final item in value) {
        try {
          result.add(itemParser(item));
        } catch (e) {
          print('Item parsing error: $e for item: $item');
          // Hatalı item'ı atla, devam et
          continue;
        }
      }
      return result;
    } catch (e) {
      print('List parsing error: $e');
      return defaultValue;
    }
  }
  return defaultValue;
}
