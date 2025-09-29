import 'dart:convert'; // jsonDecode için gerekli
import '../utils/json_parser.dart';

class MealPlan {
  final String planTitle;
  final String summary;
  final List<DailyPlan> dailyPlan;

  MealPlan(
      {required this.planTitle,
      required this.summary,
      required this.dailyPlan});

  int get totalCalories =>
      dailyPlan.fold(0, (sum, day) => sum + day.totalCaloriesForDay);
  int get totalProtein =>
      dailyPlan.fold(0, (sum, day) => sum + day.totalProteinForDay);
  int get totalCarbs =>
      dailyPlan.fold(0, (sum, day) => sum + day.totalCarbsForDay);
  int get totalFat => dailyPlan.fold(0, (sum, day) => sum + day.totalFatForDay);

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    // Backend'den gelen format: weeklyPlan, dailyPlan veya data.meals
    List<dynamic> dailyPlanData;
    if (json.containsKey('weeklyPlan')) {
      dailyPlanData = json['weeklyPlan'] as List<dynamic>? ?? [];
    } else if (json.containsKey('dailyPlan')) {
      dailyPlanData = json['dailyPlan'] as List<dynamic>? ?? [];
    } else if (json.containsKey('data') &&
        json['data'] is Map &&
        json['data'].containsKey('meals')) {
      // API'nin mevcut formatı: data.meals
      dailyPlanData = json['data']['meals'] as List<dynamic>? ?? [];
    } else {
      dailyPlanData = [];
    }

    return MealPlan(
      planTitle: json['planTitle'] as String? ?? 'Beslenme Planı',
      summary: json['summary'] as String? ?? '',
      dailyPlan:
          dailyPlanData.map((dayJson) => DailyPlan.fromJson(dayJson)).toList(),
    );
  }
}

// DailyPlan.fromJson'ı güncelliyoruz
class DailyPlan {
  final String day;
  final List<Meal> meals;

  DailyPlan({required this.day, required this.meals});

  int get totalCaloriesForDay =>
      meals.fold(0, (sum, meal) => sum + meal.totalCalories);
  int get totalProteinForDay =>
      meals.fold(0, (sum, meal) => sum + meal.totalProtein);
  int get totalCarbsForDay =>
      meals.fold(0, (sum, meal) => sum + meal.totalCarbs);
  int get totalFatForDay => meals.fold(0, (sum, meal) => sum + meal.totalFat);

  factory DailyPlan.fromJson(dynamic json) {
    // Gelen veri String ise, önce onu Map'e çevir
    if (json is String) {
      json = jsonDecode(json);
    }

    // Artık json'ın Map olduğundan eminiz
    final Map<String, dynamic> map = json as Map<String, dynamic>;

    // API'den gelen format: breakfast, snack1, lunch, snack2, dinner
    List<Meal> mealsList = [];

    // Breakfast
    if (map['breakfast'] != null) {
      mealsList.add(Meal.fromJson({
        'name': map['breakfast']['name'] ?? 'Kahvaltı',
        'items': [
          {
            'itemName': 'Kahvaltı',
            'quantity': 1,
            'unit': 'porsiyon',
            'calories': map['breakfast']['calories'] ?? 0,
            'protein': map['breakfast']['protein'] ?? 0,
            'carbs': map['breakfast']['carbs'] ?? 0,
            'fat': map['breakfast']['fat'] ?? 0,
          }
        ]
      }));
    }

    // Snack1
    if (map['snack1'] != null) {
      mealsList.add(Meal.fromJson({
        'name': map['snack1']['name'] ?? 'Sabah Ara Öğün',
        'items': [
          {
            'itemName': 'Sabah Ara Öğün',
            'quantity': 1,
            'unit': 'porsiyon',
            'calories': map['snack1']['calories'] ?? 0,
            'protein': map['snack1']['protein'] ?? 0,
            'carbs': map['snack1']['carbs'] ?? 0,
            'fat': map['snack1']['fat'] ?? 0,
          }
        ]
      }));
    }

    // Lunch
    if (map['lunch'] != null) {
      mealsList.add(Meal.fromJson({
        'name': map['lunch']['name'] ?? 'Öğle Yemeği',
        'items': [
          {
            'itemName': 'Öğle Yemeği',
            'quantity': 1,
            'unit': 'porsiyon',
            'calories': map['lunch']['calories'] ?? 0,
            'protein': map['lunch']['protein'] ?? 0,
            'carbs': map['lunch']['carbs'] ?? 0,
            'fat': map['lunch']['fat'] ?? 0,
          }
        ]
      }));
    }

    // Snack2
    if (map['snack2'] != null) {
      mealsList.add(Meal.fromJson({
        'name': map['snack2']['name'] ?? 'Akşam Ara Öğün',
        'items': [
          {
            'itemName': 'Akşam Ara Öğün',
            'quantity': 1,
            'unit': 'porsiyon',
            'calories': map['snack2']['calories'] ?? 0,
            'protein': map['snack2']['protein'] ?? 0,
            'carbs': map['snack2']['carbs'] ?? 0,
            'fat': map['snack2']['fat'] ?? 0,
          }
        ]
      }));
    }

    // Dinner
    if (map['dinner'] != null) {
      mealsList.add(Meal.fromJson({
        'name': map['dinner']['name'] ?? 'Akşam Yemeği',
        'items': [
          {
            'itemName': 'Akşam Yemeği',
            'quantity': 1,
            'unit': 'porsiyon',
            'calories': map['dinner']['calories'] ?? 0,
            'protein': map['dinner']['protein'] ?? 0,
            'carbs': map['dinner']['carbs'] ?? 0,
            'fat': map['dinner']['fat'] ?? 0,
          }
        ]
      }));
    }

    return DailyPlan(
      day: map['day']?.toString() ?? 'Bilinmeyen Gün',
      meals: mealsList,
    );
  }
}

// Meal.fromJson'ı güncelliyoruz
class Meal {
  final String name;
  final List<Ingredient> items;
  final String? notes;

  Meal({required this.name, required this.items, this.notes});

  int get totalCalories => items.fold(0, (sum, item) => sum + item.calories);
  int get totalProtein => items.fold(0, (sum, item) => sum + item.protein);
  int get totalCarbs => items.fold(0, (sum, item) => sum + item.carbs);
  int get totalFat => items.fold(0, (sum, item) => sum + item.fat);

  factory Meal.fromJson(dynamic json) {
    if (json is String) {
      json = jsonDecode(json);
    }
    final Map<String, dynamic> map = json as Map<String, dynamic>;

    return Meal(
      name: map['mealName'] as String? ?? map['name'] as String? ?? 'Öğün',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((itemJson) => Ingredient.fromJson(itemJson))
          .toList(),
      notes: map['notes']?.toString(),
    );
  }
}

class Ingredient {
  final String name;
  final int quantity;
  final String unit;
  final int calories, protein, carbs, fat;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory Ingredient.fromJson(dynamic json) {
    if (json is String) {
      json = jsonDecode(json);
    }
    final Map<String, dynamic> map = json as Map<String, dynamic>;

    return Ingredient(
      name: map['itemName'] as String? ?? '',
      quantity: safeParseInt(map['quantity']),
      unit: map['unit'] as String? ?? 'gram',
      calories: safeParseInt(map['calories']),
      protein: safeParseInt(map['protein']),
      carbs: safeParseInt(map['carbs']),
      fat: safeParseInt(map['fat']),
    );
  }
}
