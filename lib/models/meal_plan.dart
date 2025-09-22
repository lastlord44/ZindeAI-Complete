import '../utils/json_parser.dart';

class MealPlan {
  final String planTitle;
  final String summary;
  final List<Meal> meals; // Eski format için backward compatibility
  final List<WeeklyDay>? weeklyPlan; // Eski format için backward compatibility
  final List<DailyPlan>? dailyPlan; // YENİ: AI'ın gönderdiği format
  final String? notes;

  MealPlan({
    required this.planTitle,
    required this.summary,
    required this.meals,
    this.weeklyPlan,
    this.dailyPlan, // YENİ
    this.notes,
  });

  // HESAPLAMALI GETTER'LAR - AI'ın hesaplama hatası yerine kendi hesaplamamızı kullanıyoruz
  int get totalCalories {
    if (dailyPlan != null && dailyPlan!.isNotEmpty) {
      // Yeni format: dailyPlan'dan hesapla
      return dailyPlan!.fold(0, (sum, day) => sum + day.totalCaloriesForDay);
    } else if (weeklyPlan != null && weeklyPlan!.isNotEmpty) {
      // Eski format: weeklyPlan'dan hesapla
      return weeklyPlan!.fold(0, (sum, day) => sum + day.totalCaloriesForDay);
    } else {
      // Fallback: meals'dan hesapla
      return meals.fold(0, (sum, meal) => sum + meal.calories);
    }
  }

  int get totalProtein {
    if (dailyPlan != null && dailyPlan!.isNotEmpty) {
      return dailyPlan!.fold(0, (sum, day) => sum + day.totalProteinForDay);
    } else if (weeklyPlan != null && weeklyPlan!.isNotEmpty) {
      return weeklyPlan!.fold(0, (sum, day) => sum + day.totalProteinForDay);
    } else {
      return meals.fold(0, (sum, meal) => sum + meal.protein);
    }
  }

  int get totalCarbs {
    if (dailyPlan != null && dailyPlan!.isNotEmpty) {
      return dailyPlan!.fold(0, (sum, day) => sum + day.totalCarbsForDay);
    } else if (weeklyPlan != null && weeklyPlan!.isNotEmpty) {
      return weeklyPlan!.fold(0, (sum, day) => sum + day.totalCarbsForDay);
    } else {
      return meals.fold(0, (sum, meal) => sum + meal.carbs);
    }
  }

  int get totalFat {
    if (dailyPlan != null && dailyPlan!.isNotEmpty) {
      return dailyPlan!.fold(0, (sum, day) => sum + day.totalFatForDay);
    } else if (weeklyPlan != null && weeklyPlan!.isNotEmpty) {
      return weeklyPlan!.fold(0, (sum, day) => sum + day.totalFatForDay);
    } else {
      return meals.fold(0, (sum, meal) => sum + meal.fat);
    }
  }

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      planTitle: safeParseString(json['planTitle']),
      summary: safeParseString(json['summary']),
      // AI'dan gelen total değerleri görmezden geliyoruz, kendi hesaplamamızı kullanıyoruz
      meals: safeParseList(json['meals'], (meal) => Meal.fromJson(meal)),
      weeklyPlan:
          safeParseList(json['weeklyPlan'], (day) => WeeklyDay.fromJson(day)),
      dailyPlan: safeParseList(
          json['dailyPlan'], (day) => DailyPlan.fromJson(day)), // YENİ
      notes: json['notes']?.toString(),
    );
  }
}

class WeeklyDay {
  final String day;
  final List<Meal> meals;

  WeeklyDay({
    required this.day,
    required this.meals,
  });

  // HESAPLAMALI GETTER'LAR
  int get totalCaloriesForDay =>
      meals.fold(0, (sum, meal) => sum + meal.calories);
  int get totalProteinForDay =>
      meals.fold(0, (sum, meal) => sum + meal.protein);
  int get totalCarbsForDay => meals.fold(0, (sum, meal) => sum + meal.carbs);
  int get totalFatForDay => meals.fold(0, (sum, meal) => sum + meal.fat);

  factory WeeklyDay.fromJson(Map<String, dynamic> json) {
    return WeeklyDay(
      day: safeParseString(json['day']),
      meals: safeParseList(json['meals'], (meal) => Meal.fromJson(meal)),
    );
  }
}

// YENİ: Ingredient sınıfı - AI'dan gelen detaylı malzeme bilgileri için
class Ingredient {
  final String name;
  final int quantity;
  final String unit;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  Ingredient({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      name: safeParseString(json['itemName']),
      quantity: safeParseInt(json['quantity']),
      unit: safeParseString(json['unit']),
      calories: safeParseInt(json['calories']),
      protein: safeParseInt(json['protein']),
      carbs: safeParseInt(json['carbs']),
      fat: safeParseInt(json['fat']),
    );
  }
}

// Geriye dönük uyumluluk için MealItem sınıfı
class MealItem {
  final String name;
  final String quantity;

  MealItem({required this.name, required this.quantity});

  factory MealItem.fromJson(Map<String, dynamic> json) {
    return MealItem(
      name: json['itemName'] as String? ?? '',
      quantity: json['quantity'] as String? ?? '',
    );
  }
}

class Meal {
  final String name;
  final String type;
  final int calories;
  final int protein; // YENİ
  final int carbs; // YENİ
  final int fat; // YENİ
  final List<MealItem> items; // String'den MealItem'a değiştirildi
  final List<Ingredient>? ingredients; // YENİ: Detaylı malzeme listesi
  final String? notes;

  Meal({
    required this.name,
    required this.type,
    required this.calories,
    required this.protein, // YENİ
    required this.carbs, // YENİ
    required this.fat, // YENİ
    required this.items,
    this.ingredients, // YENİ
    this.notes,
  });

  // Öğünün toplamlarını kendi içinde hesaplayan getter'lar
  int get totalCalories {
    if (ingredients != null && ingredients!.isNotEmpty) {
      return ingredients!
          .fold(0, (sum, ingredient) => sum + ingredient.calories);
    }
    return calories;
  }

  int get totalProtein {
    if (ingredients != null && ingredients!.isNotEmpty) {
      return ingredients!
          .fold(0, (sum, ingredient) => sum + ingredient.protein);
    }
    return protein;
  }

  int get totalCarbs {
    if (ingredients != null && ingredients!.isNotEmpty) {
      return ingredients!.fold(0, (sum, ingredient) => sum + ingredient.carbs);
    }
    return carbs;
  }

  int get totalFat {
    if (ingredients != null && ingredients!.isNotEmpty) {
      return ingredients!.fold(0, (sum, ingredient) => sum + ingredient.fat);
    }
    return fat;
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      name: safeParseString(
          json['name'] ?? json['mealName']), // mealName de destekleniyor
      type: safeParseString(json['type']),
      calories: safeParseInt(json['calories']),
      protein: safeParseInt(json['protein']), // YENİ
      carbs: safeParseInt(json['carbs']), // YENİ
      fat: safeParseInt(json['fat']), // YENİ
      // items listesini yeni MealItem sınıfını kullanarak parse et
      items: safeParseList(
          json['items'], (itemJson) => MealItem.fromJson(itemJson)),
      // YENİ: ingredients listesini parse et
      ingredients: safeParseList(
          json['items'], (itemJson) => Ingredient.fromJson(itemJson)),
      notes: json['notes']?.toString(),
    );
  }
}

// YENİ: DailyPlan sınıfı - AI'ın gönderdiği yeni format için
class DailyPlan {
  final int day;
  final List<Meal> meals;

  DailyPlan({
    required this.day,
    required this.meals,
  });

  // HESAPLAMALI GETTER'LAR
  int get totalCaloriesForDay =>
      meals.fold(0, (sum, meal) => sum + meal.calories);
  int get totalProteinForDay =>
      meals.fold(0, (sum, meal) => sum + meal.protein);
  int get totalCarbsForDay => meals.fold(0, (sum, meal) => sum + meal.carbs);
  int get totalFatForDay => meals.fold(0, (sum, meal) => sum + meal.fat);

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    return DailyPlan(
      day: safeParseInt(json['day']),
      meals: safeParseList(json['meals'], (meal) => Meal.fromJson(meal)),
    );
  }
}
