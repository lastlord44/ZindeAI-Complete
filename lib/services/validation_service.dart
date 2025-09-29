// lib/services/validation_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/logger.dart';

/// Kapsamlı validasyon ve bug önleme sistemi
class ValidationService {
  static final ValidationService _instance = ValidationService._internal();
  factory ValidationService() => _instance;
  ValidationService._internal();

  /// Profil verilerini validate et ve temizle
  Map<String, dynamic> validateAndCleanProfileData(Map<String, dynamic> data) {
    Logger.debug('Profil validasyonu başlatılıyor',
        tag: 'ValidationService',
        data: {
          'inputKeys': data.keys.toList(),
          'inputDataSize': data.toString().length,
        });

    final cleaned = <String, dynamic>{};

    try {
      // Temel bilgiler
      cleaned['userId'] = _validateUserId(data['userId']);
      cleaned['age'] = _validateAge(data['age']);
      cleaned['gender'] = _validateGender(data['gender']);
      cleaned['weight'] = _validateWeight(data['weight']);
      cleaned['height'] = _validateHeight(data['height']);

      // Aktivite ve hedefler
      cleaned['activityLevel'] = _validateActivityLevel(data['activityLevel']);
      cleaned['fitnessLevel'] = _validateFitnessLevel(data['fitnessLevel']);
      cleaned['goal'] = _validateGoal(data['goal']);

      // Hesaplanan değerler
      final bmr = _calculateBMR(
        cleaned['gender'],
        cleaned['weight'],
        cleaned['height'],
        cleaned['age'],
      );
      cleaned['bmr'] = bmr;

      final tdee = _calculateTDEE(bmr, cleaned['activityLevel']);
      cleaned['tdee'] = tdee;

      // Makro hesaplamaları
      final macros = _calculateMacros(tdee, cleaned['goal']);
      cleaned['dailyCalories'] = macros['calories'];
      cleaned['dailyProtein'] = macros['protein'];
      cleaned['dailyCarbs'] = macros['carbs'];
      cleaned['dailyFat'] = macros['fat'];

      // Opsiyonel alanlar - null safe
      cleaned['restrictions'] = _validateRestrictions(data['restrictions']);
      cleaned['allergies'] = _validateAllergies(data['allergies']);
      cleaned['equipment'] = _validateEquipment(data['equipment']);
      cleaned['injuries'] = _validateInjuries(data['injuries']);

      Logger.success('Profil validasyonu başarılı',
          tag: 'ValidationService',
          data: {
            'cleanedKeys': cleaned.keys.toList(),
            'cleanedDataSize': cleaned.toString().length,
          });
      return cleaned;
    } catch (e, stackTrace) {
      Logger.error('Profil validasyon hatası',
          tag: 'ValidationService',
          error: e,
          stackTrace: stackTrace,
          data: {
            'inputData': data,
          });

      // Hata durumunda varsayılan değerlerle dön
      Logger.warning('Varsayılan profil kullanılıyor',
          tag: 'ValidationService');
      return _getDefaultProfile();
    }
  }

  /// User ID validasyonu
  String _validateUserId(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      Logger.validation('userId', 'User ID boş olamaz');
      throw ValidationException('User ID boş olamaz');
    }

    final userId = value.toString().trim();

    // UUID formatı kontrolü
    final uuidRegex = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

    if (!uuidRegex.hasMatch(userId) &&
        !userId.startsWith('user_') &&
        !userId.startsWith('test_')) {
      Logger.validation('userId', 'Geçersiz User ID formatı', data: {
        'userId': userId,
        'isUuid': uuidRegex.hasMatch(userId),
        'startsWithUser': userId.startsWith('user_'),
        'startsWithTest': userId.startsWith('test_'),
      });
      throw ValidationException('Geçersiz User ID formatı');
    }

    Logger.debug('User ID validasyonu başarılı',
        tag: 'ValidationService',
        data: {
          'userId': userId,
        });
    return userId;
  }

  /// Yaş validasyonu
  int _validateAge(dynamic value) {
    if (value == null) {
      throw ValidationException('Yaş bilgisi eksik');
    }

    int age;

    if (value is int) {
      age = value;
    } else if (value is double) {
      age = value.round();
    } else if (value is String) {
      age = int.tryParse(value) ?? 0;
    } else {
      throw ValidationException('Geçersiz yaş formatı');
    }

    // Yaş sınırları
    if (age < 16) {
      debugPrint('⚠️ Yaş 16\'dan küçük, 16 olarak ayarlanıyor');
      return 16;
    }

    if (age > 100) {
      debugPrint('⚠️ Yaş 100\'den büyük, 100 olarak ayarlanıyor');
      return 100;
    }

    return age;
  }

  /// Cinsiyet validasyonu
  String _validateGender(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      debugPrint('⚠️ Cinsiyet belirtilmemiş, varsayılan: Erkek');
      return 'Erkek';
    }

    final gender = value.toString().trim();
    final validGenders = ['Erkek', 'Kadın', 'Diğer'];

    // Farklı formatları normalize et
    final normalizedGender = _normalizeGender(gender);

    if (!validGenders.contains(normalizedGender)) {
      debugPrint('⚠️ Geçersiz cinsiyet: $gender, varsayılan: Erkek');
      return 'Erkek';
    }

    return normalizedGender;
  }

  /// Cinsiyet normalizasyonu
  String _normalizeGender(String gender) {
    final lowerGender = gender.toLowerCase();

    if (lowerGender.contains('erkek') ||
        lowerGender.contains('male') ||
        lowerGender == 'e' ||
        lowerGender == 'm') {
      return 'Erkek';
    }

    if (lowerGender.contains('kadın') ||
        lowerGender.contains('female') ||
        lowerGender.contains('bayan') ||
        lowerGender == 'k' ||
        lowerGender == 'f') {
      return 'Kadın';
    }

    return 'Diğer';
  }

  /// Kilo validasyonu
  double _validateWeight(dynamic value) {
    if (value == null) {
      throw ValidationException('Kilo bilgisi eksik');
    }

    double weight;

    if (value is num) {
      weight = value.toDouble();
    } else if (value is String) {
      // Virgülü noktaya çevir
      final cleanValue = value.replaceAll(',', '.');
      weight = double.tryParse(cleanValue) ?? 0;
    } else {
      throw ValidationException('Geçersiz kilo formatı');
    }

    // Kilo sınırları
    if (weight < 30) {
      debugPrint('⚠️ Kilo 30kg\'dan az, 30kg olarak ayarlanıyor');
      return 30.0;
    }

    if (weight > 300) {
      debugPrint('⚠️ Kilo 300kg\'dan fazla, 300kg olarak ayarlanıyor');
      return 300.0;
    }

    // Ondalık basamağı sınırla
    return double.parse(weight.toStringAsFixed(1));
  }

  /// Boy validasyonu
  double _validateHeight(dynamic value) {
    if (value == null) {
      throw ValidationException('Boy bilgisi eksik');
    }

    double height;

    if (value is num) {
      height = value.toDouble();
    } else if (value is String) {
      final cleanValue = value.replaceAll(',', '.');
      height = double.tryParse(cleanValue) ?? 0;
    } else {
      throw ValidationException('Geçersiz boy formatı');
    }

    // Metre cinsindense santimetreye çevir
    if (height < 3) {
      height = height * 100;
      debugPrint('⚠️ Boy metre cinsinden girilmiş, cm\'ye çevrildi: $height');
    }

    // Boy sınırları
    if (height < 120) {
      debugPrint('⚠️ Boy 120cm\'den az, 120cm olarak ayarlanıyor');
      return 120.0;
    }

    if (height > 250) {
      debugPrint('⚠️ Boy 250cm\'den fazla, 250cm olarak ayarlanıyor');
      return 250.0;
    }

    return double.parse(height.toStringAsFixed(1));
  }

  /// Aktivite seviyesi validasyonu
  String _validateActivityLevel(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      debugPrint('⚠️ Aktivite seviyesi belirtilmemiş, varsayılan: Orta');
      return 'Orta';
    }

    final level = value.toString().trim();
    final validLevels = [
      'Hareketsiz',
      'Az Aktif',
      'Orta',
      'Aktif',
      'Çok Aktif'
    ];

    // Normalize et
    final normalized = _normalizeActivityLevel(level);

    if (!validLevels.contains(normalized)) {
      debugPrint('⚠️ Geçersiz aktivite seviyesi: $level, varsayılan: Orta');
      return 'Orta';
    }

    return normalized;
  }

  /// Aktivite seviyesi normalizasyonu
  String _normalizeActivityLevel(String level) {
    final lower = level.toLowerCase();

    if (lower.contains('hareketsiz') ||
        lower.contains('sedanter') ||
        lower == '1') {
      return 'Hareketsiz';
    }
    if (lower.contains('az') || lower == '2') {
      return 'Az Aktif';
    }
    if (lower.contains('orta') || lower.contains('moderate') || lower == '3') {
      return 'Orta';
    }
    if (lower.contains('aktif') && !lower.contains('çok') || lower == '4') {
      return 'Aktif';
    }
    if (lower.contains('çok') || lower.contains('very') || lower == '5') {
      return 'Çok Aktif';
    }

    return 'Orta';
  }

  /// Fitness seviyesi validasyonu
  String _validateFitnessLevel(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Orta';
    }

    final level = value.toString().trim();
    final validLevels = ['Başlangıç', 'Orta', 'İleri', 'Profesyonel'];

    final normalized = _normalizeFitnessLevel(level);

    if (!validLevels.contains(normalized)) {
      return 'Orta';
    }

    return normalized;
  }

  /// Fitness seviyesi normalizasyonu
  String _normalizeFitnessLevel(String level) {
    final lower = level.toLowerCase();

    if (lower.contains('başla') || lower.contains('beginner') || lower == '1') {
      return 'Başlangıç';
    }
    if (lower.contains('orta') ||
        lower.contains('intermediate') ||
        lower == '2') {
      return 'Orta';
    }
    if (lower.contains('ileri') || lower.contains('advanced') || lower == '3') {
      return 'İleri';
    }
    if (lower.contains('pro') || lower.contains('expert') || lower == '4') {
      return 'Profesyonel';
    }

    return 'Orta';
  }

  /// Hedef validasyonu
  String _validateGoal(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Sağlıklı Yaşam';
    }

    final goal = value.toString().trim();
    final normalized = _normalizeGoal(goal);

    return normalized;
  }

  /// Hedef normalizasyonu
  String _normalizeGoal(String goal) {
    final lower = goal.toLowerCase();

    if (lower.contains('kilo ver') ||
        lower.contains('weight loss') ||
        lower.contains('zayıfla')) {
      return 'Kilo Verme';
    }
    if (lower.contains('kilo al') ||
        lower.contains('weight gain') ||
        lower.contains('bulk')) {
      return 'Kilo Alma';
    }
    if (lower.contains('kas') ||
        lower.contains('muscle') ||
        lower.contains('güçlen')) {
      return 'Kas Yapma';
    }
    if (lower.contains('güç') ||
        lower.contains('strength') ||
        lower.contains('power')) {
      return 'Güç Kazanma';
    }
    if (lower.contains('dayanıklılık') ||
        lower.contains('endurance') ||
        lower.contains('cardio')) {
      return 'Dayanıklılık';
    }

    return 'Sağlıklı Yaşam';
  }

  /// Kısıtlamaları validate et
  String? _validateRestrictions(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      final cleaned = value
          .where((item) => item != null && item.toString().isNotEmpty)
          .map((item) => _cleanText(item.toString()))
          .toList();

      return cleaned.isEmpty ? null : cleaned.join(', ');
    }

    if (value is String && value.isNotEmpty) {
      return _cleanText(value);
    }

    return null;
  }

  /// Alerjileri validate et
  String? _validateAllergies(dynamic value) {
    return _validateRestrictions(value); // Aynı mantık
  }

  /// Ekipmanları validate et
  String? _validateEquipment(dynamic value) {
    return _validateRestrictions(value); // Aynı mantık
  }

  /// Sakatlıkları validate et
  String? _validateInjuries(dynamic value) {
    return _validateRestrictions(value); // Aynı mantık
  }

  /// Metni temizle (özel karakterler, fazla boşluklar vb.)
  String _cleanText(String text) {
    // Tehlikeli karakterleri kaldır
    String cleaned = text
        .replaceAll('<', '')
        .replaceAll('>', '')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .replaceAll('`', '')
        .replaceAll(';', '')
        .replaceAll('(', '')
        .replaceAll(')', '');

    // Fazla boşlukları temizle
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Maksimum uzunluk
    if (cleaned.length > 500) {
      cleaned = cleaned.substring(0, 500);
    }

    return cleaned;
  }

  /// BMR hesaplama (Mifflin-St Jeor)
  double _calculateBMR(String gender, double weight, double height, int age) {
    if (gender == 'Erkek') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  /// TDEE hesaplama
  double _calculateTDEE(double bmr, String activityLevel) {
    final multipliers = {
      'Hareketsiz': 1.2,
      'Az Aktif': 1.375,
      'Orta': 1.55,
      'Aktif': 1.725,
      'Çok Aktif': 1.9,
    };

    return bmr * (multipliers[activityLevel] ?? 1.55);
  }

  /// Makro besin hesaplama
  Map<String, int> _calculateMacros(double tdee, String goal) {
    int calories;
    int proteinGrams;
    int carbGrams;
    int fatGrams;

    switch (goal) {
      case 'Kilo Verme':
        calories = (tdee - 500).round(); // 500 kalori açığı
        proteinGrams = (calories * 0.35 / 4).round(); // %35 protein
        fatGrams = (calories * 0.25 / 9).round(); // %25 yağ
        carbGrams = (calories * 0.40 / 4).round(); // %40 karb
        break;

      case 'Kilo Alma':
        calories = (tdee + 500).round(); // 500 kalori fazlası
        proteinGrams = (calories * 0.25 / 4).round(); // %25 protein
        fatGrams = (calories * 0.25 / 9).round(); // %25 yağ
        carbGrams = (calories * 0.50 / 4).round(); // %50 karb
        break;

      case 'Kas Yapma':
        calories = (tdee + 300).round(); // 300 kalori fazlası
        proteinGrams = (calories * 0.30 / 4).round(); // %30 protein
        fatGrams = (calories * 0.25 / 9).round(); // %25 yağ
        carbGrams = (calories * 0.45 / 4).round(); // %45 karb
        break;

      default:
        calories = tdee.round();
        proteinGrams = (calories * 0.25 / 4).round(); // %25 protein
        fatGrams = (calories * 0.30 / 9).round(); // %30 yağ
        carbGrams = (calories * 0.45 / 4).round(); // %45 karb
    }

    // Minimum ve maksimum değerler
    calories = calories.clamp(1200, 5000);
    proteinGrams = proteinGrams.clamp(50, 300);
    carbGrams = carbGrams.clamp(100, 600);
    fatGrams = fatGrams.clamp(30, 200);

    return {
      'calories': calories,
      'protein': proteinGrams,
      'carbs': carbGrams,
      'fat': fatGrams,
    };
  }

  /// Varsayılan profil
  Map<String, dynamic> _getDefaultProfile() {
    return {
      'userId': 'default_user',
      'age': 30,
      'gender': 'Erkek',
      'weight': 70.0,
      'height': 175.0,
      'activityLevel': 'Orta',
      'fitnessLevel': 'Orta',
      'goal': 'Sağlıklı Yaşam',
      'bmr': 1650.0,
      'tdee': 2557.5,
      'dailyCalories': 2500,
      'dailyProtein': 125,
      'dailyCarbs': 280,
      'dailyFat': 83,
      'restrictions': null,
      'allergies': null,
      'equipment': null,
      'injuries': null,
    };
  }

  /// JSON validasyonu
  bool isValidJson(String str) {
    try {
      json.decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Plan validasyonu
  bool validateMealPlan(Map<String, dynamic> plan) {
    Logger.debug('Meal plan validasyonu başlatılıyor',
        tag: 'ValidationService',
        data: {
          'planKeys': plan.keys.toList(),
          'planSize': plan.toString().length,
        });

    try {
      // Zorunlu alanlar - weeklyPlan, dailyPlan veya data.meals formatlarını destekle
      if (!plan.containsKey('weeklyPlan') &&
          !plan.containsKey('dailyPlan') &&
          !(plan.containsKey('data') &&
              plan['data'] is Map &&
              plan['data'].containsKey('meals'))) {
        Logger.validation(
            'mealPlan', 'weeklyPlan, dailyPlan veya data.meals key bulunamadı',
            data: {
              'availableKeys': plan.keys.toList(),
            });
        return false;
      }

      // weeklyPlan array formatında mı yoksa object formatında mı kontrol et
      dynamic weeklyPlan;
      bool isArrayFormat = false;

      if (plan.containsKey('weeklyPlan')) {
        weeklyPlan = plan['weeklyPlan'];
        if (weeklyPlan is List) {
          isArrayFormat = true;
        } else if (weeklyPlan is! Map) {
          Logger.validation('mealPlan', 'weeklyPlan ne Map ne de List', data: {
            'type': weeklyPlan.runtimeType.toString(),
            'value': weeklyPlan.toString(),
          });
          return false;
        }
      } else if (plan.containsKey('dailyPlan')) {
        weeklyPlan = plan['dailyPlan'];
        if (weeklyPlan is List) {
          isArrayFormat = true;
        } else if (weeklyPlan is! Map) {
          Logger.validation('mealPlan', 'dailyPlan ne Map ne de List', data: {
            'type': weeklyPlan.runtimeType.toString(),
            'value': weeklyPlan.toString(),
          });
          return false;
        }
      } else if (plan.containsKey('data') &&
          plan['data'] is Map &&
          plan['data'].containsKey('meals')) {
        // API'nin mevcut formatı: data.meals
        weeklyPlan = plan['data']['meals'];
        if (weeklyPlan is List) {
          isArrayFormat = true;
        } else if (weeklyPlan is! Map) {
          Logger.validation('mealPlan', 'data.meals ne Map ne de List', data: {
            'type': weeklyPlan.runtimeType.toString(),
            'value': weeklyPlan.toString(),
          });
          return false;
        }
      }

      if (isArrayFormat) {
        // Array formatında (backend'den gelen format)
        final weeklyPlanList = weeklyPlan as List;
        if (weeklyPlanList.isEmpty) {
          Logger.validation('mealPlan', 'weeklyPlan boş array', data: {});
          return false;
        }

        // Her günü kontrol et
        for (int i = 0; i < weeklyPlanList.length; i++) {
          final dayPlan = weeklyPlanList[i];
          if (dayPlan is! Map) {
            Logger.validation('mealPlan', 'Gün planı Map değil', data: {
              'dayIndex': i,
              'type': dayPlan.runtimeType.toString(),
            });
            return false;
          }

          // Öğünleri kontrol et - API'den gelen format: breakfast, lunch, dinner
          if (!dayPlan.containsKey('meals') &&
              !dayPlan.containsKey('breakfast') &&
              !dayPlan.containsKey('lunch') &&
              !dayPlan.containsKey('dinner')) {
            Logger.validation('mealPlan',
                'Gün planında meals veya breakfast/lunch/dinner key yok',
                data: {
                  'dayIndex': i,
                  'availableKeys': dayPlan.keys.toList(),
                });
            return false;
          }

          // API'den gelen format: breakfast, lunch, dinner
          if (dayPlan.containsKey('breakfast') ||
              dayPlan.containsKey('lunch') ||
              dayPlan.containsKey('dinner')) {
            // Yeni format - breakfast/lunch/dinner var, validation geçer
            continue;
          }

          // Eski format - meals array
          final meals = dayPlan['meals'];
          if (meals is! List) {
            Logger.validation('mealPlan', 'Meals List değil', data: {
              'dayIndex': i,
              'type': meals.runtimeType.toString(),
            });
            return false;
          }

          // Her öğünü kontrol et
          for (int j = 0; j < meals.length; j++) {
            final meal = meals[j];
            if (meal is! Map) {
              Logger.validation('mealPlan', 'Öğün Map değil', data: {
                'dayIndex': i,
                'mealIndex': j,
                'type': meal.runtimeType.toString(),
              });
              return false;
            }

            // Öğün detaylarını kontrol et
            if (!meal.containsKey('name') ||
                !meal.containsKey('calories') ||
                !meal.containsKey('items')) {
              Logger.validation('mealPlan', 'Öğün detayları eksik', data: {
                'dayIndex': i,
                'mealIndex': j,
                'availableKeys': meal.keys.toList(),
              });
              return false;
            }
          }
        }
      } else {
        // Object formatında (eski format)
        final weeklyPlanMap = weeklyPlan as Map<String, dynamic>;
        final dayNames = [
          'Pazartesi',
          'Salı',
          'Çarşamba',
          'Perşembe',
          'Cuma',
          'Cumartesi',
          'Pazar'
        ];

        for (final dayName in dayNames) {
          if (!weeklyPlanMap.containsKey(dayName)) {
            Logger.validation('mealPlan', 'Gün eksik', data: {
              'missingDay': dayName,
              'availableDays': weeklyPlanMap.keys.toList(),
            });
            return false;
          }
        }

        // Her günü kontrol et
        for (final dayName in dayNames) {
          final dayPlan = weeklyPlanMap[dayName];
          if (dayPlan is! Map) {
            Logger.validation('mealPlan', 'Gün planı Map değil', data: {
              'day': dayName,
              'type': dayPlan.runtimeType.toString(),
            });
            return false;
          }

          // Öğünleri kontrol et
          if (!dayPlan.containsKey('meals')) {
            Logger.validation('mealPlan', 'Gün planında meals key yok', data: {
              'day': dayName,
              'availableKeys': dayPlan.keys.toList(),
            });
            return false;
          }

          final meals = dayPlan['meals'];
          if (meals is! List) {
            Logger.validation('mealPlan', 'Meals List değil', data: {
              'day': dayName,
              'type': meals.runtimeType.toString(),
            });
            return false;
          }

          // Her öğünü kontrol et
          for (int i = 0; i < meals.length; i++) {
            final meal = meals[i];
            if (meal is! Map) {
              Logger.validation('mealPlan', 'Öğün Map değil', data: {
                'day': dayName,
                'mealIndex': i,
                'type': meal.runtimeType.toString(),
              });
              return false;
            }

            // Öğün detaylarını kontrol et
            if (!meal.containsKey('name') ||
                !meal.containsKey('calories') ||
                !meal.containsKey('items')) {
              Logger.validation('mealPlan', 'Öğün detayları eksik', data: {
                'day': dayName,
                'mealIndex': i,
                'availableKeys': meal.keys.toList(),
              });
              return false;
            }
          }
        }
      }

      Logger.success('Meal plan validasyonu başarılı',
          tag: 'ValidationService',
          data: {
            'format': isArrayFormat ? 'array' : 'object',
            'daysCount': isArrayFormat ? (weeklyPlan as List).length : 7,
          });
      return true;
    } catch (e) {
      Logger.error('Meal plan validasyon hatası',
          tag: 'ValidationService',
          data: {
            'error': e.toString(),
            'plan': plan,
          });
      return false;
    }
  }
}

/// Özel validasyon hatası
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}
