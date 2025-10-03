// lib/services/hybrid_meal_ai.dart
// ZindeAI — Hibrit katman (AI opsiyonel). İstendiğinde AI %100 PASİF.
// Bu dosya, UI veya diğer servislerin tek giriş noktasıdır.

import '../models/user_profile.dart';
import 'plan_engine.dart';

class AIConfig {
  // AI'yı tamamen kapatmak için false bırak.
  static const bool aiEnabled = false; // İSTEK ÜZERİNE TAMAMEN PASİF
}

class HybridMealAI {
  final _engine = PlanEngine();

  Future<Map<String, dynamic>> generateMealPlan(UserProfile profile,
      {int? duration}) async {
    // AI kapalı: doğrudan DB-only motoru kullan
    if (!AIConfig.aiEnabled) {
      final plan = _engine.generate(profile);

      // Uyumlu format'a çevir
      return _convertToLegacyFormat(plan);
    }

    // İleride AI açmak istersek (Generator+Referee) buraya eklenecek.
    // Şimdilik, her zaman DB-only:
    final plan = _engine.generate(profile);
    return _convertToLegacyFormat(plan);
  }

  // Legacy UI format line dönüştürme
  Map<String, dynamic> _convertToLegacyFormat(WeekPlan plan) {
    final days = <Map<String, dynamic>>[];

    for (int i = 0; i < plan.days.length && i < 7; i++) {
      final day = plan.days[i];
      final meals = <Map<String, dynamic>>[];
      final dailyTotals = day.totals();

      for (final meal in day.meals) {
        final mealNutrients = <Map<String, dynamic>>[];
        final mealTotal = meal.totals();

        for (final item in meal.items) {
          final nutrients = item.nutrition();
          mealNutrients.add({
            'name': item.nameTr,
            'grams': item.grams,
            'portion_text': '${item.grams.round()} g porsiyon',
            'calories': nutrients.kcal,
            'protein': nutrients.proteinG,
            'carbs': nutrients.carbG,
            'fat': nutrients.fatG,
            'ingredients': [item.nameTr], // Simplified
            'instructions': ['Tarif hazır'], // Simplified
          });
        }

        meals.add({
          'mealName': meal.name,
          'time': _getTimeBySlot(meal.slot),
          'totalCalories': mealTotal.kcal,
          'totalProtein': mealTotal.proteinG,
          'carbs': mealTotal.carbG,
          'fat': mealTotal.fatG,
          'recipeName': meal.name,
          'grams': mealTotal.kcal, // Total calories
          'portion_text': '${mealTotal.kcal.round()} kcal öğün',
          'ingredients': mealNutrients.map((n) => '${n['name']} - ${n['grams'].toStringAsFixed(0)}g (${n['protein'].toStringAsFixed(1)}g protein)').toList(),
          'instructions': ['Tarif hazır'],
          'slot': meal.slot,
          'targetCalories': mealTotal.kcal,
          'targetProtein': mealTotal.proteinG,
          'actualCalories': mealTotal.kcal,
          'actualProtein': mealTotal.proteinG,
          'isConsumed': false,
          'nutrients': mealNutrients,
        });
      }

      days.add({
        'day': i + 1,
        'dayName': _getDayName(i),
        'date': day.date.toIso8601String(),
        'meals': meals,
        'dailyTotals': {
          'cu calories': dailyTotals.kcal,
          'protein': dailyTotals.proteinG,
          'carbs': dailyTotals.carbG,
          'fat': dailyTotals.fatG,
        },
        'target': plan.dailyTarget,
      });
    }

    return {
      'success': true,
      'mealPlan': {
        'planType': 'db_only_optimized',
        'duration': 7,
        'days': days,
      },
      'fallbackUsed': true,
      'provider': 'plan_engine',
      'flags': plan.flags,
      'providerTrace': plan.providerTrace,
    };
  }

  String _getTimeBySlot(String slot) {
    switch (slot) {
      case 'breakfast':
        return '08:00';
      case 'snack':
        return '15:00';
      case 'lunch':
        return '12:00';
      case 'dinner':
        return '18:00';
      default:
        return '12:00';
    }
  }

  String _getDayName(int dayIndex) {
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];
    return days[dayIndex % 7];
  }
}
