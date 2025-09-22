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
    return MealPlan(
      planTitle: json['planTitle'] as String? ?? 'Beslenme Planı',
      summary: json['summary'] as String? ?? '',
      dailyPlan: (json['dailyPlan'] as List<dynamic>? ?? [])
          .map((dayJson) => DailyPlan.fromJson(dayJson))
          .toList(),
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

    return DailyPlan(
      day: map['day'] as String? ?? 'Bilinmeyen Gün',
      meals: (map['meals'] as List<dynamic>? ?? [])
          .map((mealJson) => Meal.fromJson(mealJson))
          .toList(),
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
      name: map['mealName'] as String? ?? 'Öğün',
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
