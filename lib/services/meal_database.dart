// meal_database.dart
// AUTO-GENERATED FROM meal_gold_10000.json
// Kahvaltı: 2041 | Öğle: 1978 | Akşam: 2025 | Ara: 1981 = 8002 meals

import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class MealDatabase {
  static List<Map<String, dynamic>> _breakfastMeals = [];
  static List<Map<String, dynamic>> _lunchMeals = [];
  static List<Map<String, dynamic>> _dinnerMeals = [];
  static List<Map<String, dynamic>> _snackMeals = [];
  static bool _isLoaded = false;

  final Random _random;

  // Default constructor
  MealDatabase() : _random = Random();

  // Constructor with seed for daily variety
  MealDatabase.withSeed(int seed) : _random = Random(seed);

  /// JSON verilerini yükle (ilk çağrıda)
  static Future<void> _ensureLoaded() async {
    if (_isLoaded) return;

    try {
      // JSON dosyasını assets'den oku
      final String jsonString =
          await rootBundle.loadString('assets/meal_gold_10000_clean.json');
      final List<dynamic> data = json.decode(jsonString);

      // Temizle
      _breakfastMeals.clear();
      _lunchMeals.clear();
      _dinnerMeals.clear();
      _snackMeals.clear();

      // Kategorilere ayır
      for (final item in data) {
        final meal = {
          'meal_id': item['id'],
          'name': item['name_tr'],
          'category': item['category'],
          'calories': (item['kcal'] as num).toDouble(),
          'protein': (item['protein_g'] as num).toDouble(),
          'carbs': (item['carb_g'] as num).toDouble(),
          'fat': (item['fat_g'] as num).toDouble(),
          'grams': item['grams'] ?? 100.0,
          'portion_text': item['portion_text'] ?? '1 porsiyon',
          'ingredients': _generateIngredientsFromMeal(item['name_tr']),
          'instructions': _generateInstructionsFromMeal(item['name_tr']),
        };

        final category = item['category'];
        if (category == 'breakfast') {
          _breakfastMeals.add(meal);
        } else if (category == 'lunch') {
          _lunchMeals.add(meal);
        } else if (category == 'dinner') {
          _dinnerMeals.add(meal);
        } else if (category == 'snack') {
          _snackMeals.add(meal);
        }
      }

      _isLoaded = true;
      print(
          '✅ MealDatabase yüklendi: ${_breakfastMeals.length + _lunchMeals.length + _dinnerMeals.length + _snackMeals.length} öğün');
    } catch (e) {
      print('❌ JSON yüklenemedi: $e');
      // Fallback - örnek veriler
      _loadFallbackData();
      _isLoaded = true;
    }
  }

  /// Fallback veriler (JSON yüklenemezse)
  static void _loadFallbackData() {
    _breakfastMeals = [
      {
        'meal_id': 'FALLBACK-001',
        'name': 'Yulaf ezmesi + süt + chia tohumu + böğürtlen',
        'category': 'breakfast',
        'calories': 257.0,
        'protein': 13.8,
        'carbs': 41.3,
        'fat': 5.5
      },
    ];

    _lunchMeals = [
      {
        'meal_id': 'FALLBACK-002',
        'name': 'Kuru fasulye (az yağlı) + esmer pirinç pilavı',
        'category': 'lunch',
        'calories': 464.0,
        'protein': 24.1,
        'carbs': 67.6,
        'fat': 8.7
      },
    ];

    _dinnerMeals = [
      {
        'meal_id': 'FALLBACK-003',
        'name': 'Hünkar beğendi (az yağlı et ile)',
        'category': 'dinner',
        'calories': 431.0,
        'protein': 29.8,
        'carbs': 23.2,
        'fat': 18.2
      },
    ];

    _snackMeals = [
      {
        'meal_id': 'FALLBACK-004',
        'name': 'Light süt + 1 avuç badem',
        'category': 'snack',
        'calories': 243.0,
        'protein': 11.6,
        'carbs': 11.6,
        'fat': 13.9
      },
    ];

    print('⚠️ Fallback verileri yüklendi');
  }

  /// Öğle öğünü seç - kalori ve protein hedefine göre
  Future<Map<String, dynamic>> getLunchMeal({
    required double targetCalories,
    required double targetProtein,
    double tolerance = 150,
  }) async {
    await _ensureLoaded();

    var candidates = _lunchMeals.where((meal) {
      final calDiff = (meal['calories'] - targetCalories).abs();
      final proteinDiff = (meal['protein'] - targetProtein).abs();
      return calDiff <= tolerance && proteinDiff <= (targetProtein * 0.3);
    }).toList();

    if (candidates.isEmpty) {
      candidates = _lunchMeals.where((meal) {
        return (meal['calories'] - targetCalories).abs() <= tolerance;
      }).toList();
    }

    if (candidates.isEmpty) {
      _lunchMeals.sort((a, b) {
        final diffA = (a['calories'] - targetCalories).abs();
        final diffB = (b['calories'] - targetCalories).abs();
        return diffA.compareTo(diffB);
      });
      return _formatMeal(_lunchMeals.first);
    }

    return _formatMeal(candidates[_random.nextInt(candidates.length)]);
  }

  /// Akşam öğünü seç
  Future<Map<String, dynamic>> getDinnerMeal({
    required double targetCalories,
    required double targetProtein,
    double tolerance = 100,
  }) async {
    await _ensureLoaded();

    var candidates = _dinnerMeals.where((meal) {
      final calDiff = (meal['calories'] - targetCalories).abs();
      final proteinDiff = (meal['protein'] - targetProtein).abs();
      return calDiff <= tolerance && proteinDiff <= (targetProtein * 0.3);
    }).toList();

    if (candidates.isEmpty) {
      candidates = _dinnerMeals.where((meal) {
        return (meal['calories'] - targetCalories).abs() <= tolerance;
      }).toList();
    }

    if (candidates.isEmpty) {
      _dinnerMeals.sort((a, b) {
        final diffA = (a['calories'] - targetCalories).abs();
        final diffB = (b['calories'] - targetCalories).abs();
        return diffA.compareTo(diffB);
      });
      return _formatMeal(_dinnerMeals.first);
    }

    return _formatMeal(candidates[_random.nextInt(candidates.length)]);
  }

  /// Kahvaltı seç
  Future<Map<String, dynamic>> getBreakfastMeal({
    required double targetCalories,
    required double targetProtein,
    double tolerance = 100,
  }) async {
    await _ensureLoaded();

    var candidates = _breakfastMeals.where((meal) {
      return (meal['calories'] - targetCalories).abs() <= tolerance;
    }).toList();

    if (candidates.isEmpty) {
      _breakfastMeals.sort((a, b) {
        final diffA = (a['calories'] - targetCalories).abs();
        final diffB = (b['calories'] - targetCalories).abs();
        return diffA.compareTo(diffB);
      });
      return _formatMeal(_breakfastMeals.first);
    }

    return _formatMeal(candidates[_random.nextInt(candidates.length)]);
  }

  /// Ara öğün seç
  Future<Map<String, dynamic>> getSnackMeal({
    required double targetCalories,
    required double targetProtein,
    double tolerance = 50,
  }) async {
    await _ensureLoaded();

    var candidates = _snackMeals.where((meal) {
      return (meal['calories'] - targetCalories).abs() <= tolerance;
    }).toList();

    if (candidates.isEmpty) {
      _snackMeals.sort((a, b) {
        final diffA = (a['calories'] - targetCalories).abs();
        final diffB = (b['calories'] - targetCalories).abs();
        return diffA.compareTo(diffB);
      });
      return _formatMeal(_snackMeals.first);
    }

    return _formatMeal(candidates[_random.nextInt(candidates.length)]);
  }

  /// Öğünü formatla
  Map<String, dynamic> _formatMeal(Map<String, dynamic> meal) {
    return {
      'name': meal['name'],
      'calories': meal['calories'].toDouble(),
      'protein': meal['protein'].toDouble(),
      'carbs': meal['carbs'].toDouble(),
      'fat': meal['fat'].toDouble(),
      'grams': meal['grams'] ?? 200.0, // DEFAULT gramaj
      'portion_text': meal['portion_text'] ??
          _generatePortionText(meal), // DEFAULT porsiyon
      'meal_id': meal['meal_id'], // Track için ID
      'ingredients': _generateDetailedIngredients(meal['name']),
      'instructions': _generateInstructions(meal),
    };
  }

  /// Portion text generate et
  String _generatePortionText(Map<String, dynamic> meal) {
    final grams = (meal['grams'] ?? 200).toStringAsFixed(0);
    return '$grams g porsiyon';
  }

  /// Detaylı malzeme listesi generate et
  List<String> _generateDetailedIngredients(String mealName) {
    final baseIngredients = mealName
        .split('+')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return baseIngredients
        .map((ingredient) => _addTypicalPortion(ingredient))
        .toList();
  }

  /// Typical portion ekleyen helper
  String _addTypicalPortion(String ingredient) {
    final typicalPortions = {
      'ekmek': '2 dilim ekmek',
      'peynir': '50 g peynir',
      'domates': '1 adet domates (120g)',
      'yumurta': '2 adet yumurta',
      'süt': '200 ml süt',
      'peynir': '100 g peynir',
      'salata': '150 g salata',
    };

    return typicalPortions[ingredient.toLowerCase()] ?? ingredient;
  }

  /// Malzemeleri çıkar
  List<String> _extractIngredients(String mealName) {
    return mealName
        .split('+')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Tarif oluştur
  String _generateInstructions(Map<String, dynamic> meal) {
    final name = meal['name'] as String;
    final instructions = <String>['1. Tüm malzemeleri hazırlayın'];

    if (name.contains('köfte') || name.contains('et')) {
      instructions.add('2. Ana yemeği ızgara veya fırında pişirin (20-25 dk)');
    } else if (name.contains('nohut') || name.contains('sebze')) {
      instructions.add('2. Sebzeleri yıkayıp doğrayın, pişirin (15-20 dk)');
    } else {
      instructions.add('2. Ana yemeği orta ateşte pişirin');
    }

    if (name.contains('pilav') || name.contains('makarna')) {
      instructions.add('3. Pilav/makarnayı ayrı tencerede pişirin');
    }

    if (name.contains('salata') || name.contains('ezme')) {
      instructions.add('4. Salatayı/ezmeyi hazırlayın');
    }

    instructions.add('${instructions.length + 1}. Sıcak olarak servis yapın');

    return instructions.join('\n');
  }

  /// Database istatistikleri
  Future<Map<String, dynamic>> getStats() async {
    await _ensureLoaded();

    final allMeals = [
      ..._breakfastMeals,
      ..._lunchMeals,
      ..._dinnerMeals,
      ..._snackMeals
    ];

    if (allMeals.isEmpty) {
      return {'totalMeals': 0, 'message': 'Veri henüz yüklenmedi'};
    }

    final calories = allMeals.map((m) => m['calories'] as num).toList();
    final proteins = allMeals.map((m) => m['protein'] as num).toList();

    return {
      'breakfastMeals': _breakfastMeals.length,
      'lunchMeals': _lunchMeals.length,
      'dinnerMeals': _dinnerMeals.length,
      'snackMeals': _snackMeals.length,
      'totalMeals': allMeals.length,
      'calorieRange': {
        'min': calories.reduce((a, b) => a < b ? a : b),
        'max': calories.reduce((a, b) => a > b ? a : b),
        'avg': (calories.reduce((a, b) => a + b) / calories.length).round(),
      },
      'proteinRange': {
        'min': proteins.reduce((a, b) => a < b ? a : b),
        'max': proteins.reduce((a, b) => a > b ? a : b),
        'avg': (proteins.reduce((a, b) => a + b) / proteins.length).round(),
      }
    };
  }

  /// Öğün adından malzemeler üret (placeholder)
  static List<String> _generateIngredientsFromMeal(String mealName) {
    // Basit malzeme listesi oluştur
    return [
      'Malzemeler yükleniyor...',
      'Detaylar için doktorunuza danışın',
    ];
  }

  /// Öğün adından talimatlar üret (placeholder)
  static List<String> _generateInstructionsFromMeal(String mealName) {
    return [
      'Tarifin detayları veritabanında yüklenmekte...',
      'Sağlıklı beslenme için dengeli öğünler tüketin.',
    ];
  }
}
