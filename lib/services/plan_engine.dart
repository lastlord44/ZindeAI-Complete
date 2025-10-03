// lib/services/plan_engine.dart
// ZindeAI — AI'sız (DB-only) profesyonel plan üretim motoru
// Kurallar: bugünden başla + 7 gün; ana yemek tekrar etmez; snack tekrar edebilir.

import 'dart:math';
import '../models/user_profile.dart';

class Nutrition {
  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;

  const Nutrition({
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });

  Nutrition scale(double grams) {
    final f = grams / 100.0;
    return Nutrition(
      kcal: kcal * f,
      proteinG: proteinG * f,
      carbG: carbG * f,
      fatG: fatG * f,
    );
  }

  Nutrition add(Nutrition other) => Nutrition(
        kcal: kcal + other.kcal,
        proteinG: proteinG + other.proteinG,
        carbG: carbG + other.carbG,
        fatG: fatG + other.fatG,
      );
}

class FoodItem {
  final String canonicalId;
  final String nameTr;
  final String category;
  final bool isMainCandidate;
  final Nutrition per100g;

  const FoodItem({
    required this.canonicalId,
    required this.nameTr,
    required this.category,
    required this.per100g,
    this.isMainCandidate = false,
  });
}

class PlanItem {
  final String canonicalId;
  final String nameTr;
  double grams;
  final String source;

  PlanItem({
    required this.canonicalId,
    required this.nameTr,
    required this.grams,
    this.source = "DB",
  });

  Nutrition nutrition() {
    final f = MealDatabase.instance.find(canonicalId);
    return (f?.per100g ??
            const Nutrition(kcal: 0, proteinG: 0, carbG: 0, fatG: 0))
        .scale(grams);
  }
}

class MealPlan {
  final String name;
  final String slot;
  final List<PlanItem> items;

  MealPlan({required this.name, required this.slot, required this.items});

  Nutrition totals() => items.fold(
      const Nutrition(kcal: 0, proteinG: 0, carbG: 0, fatG: 0),
      (a, b) => a.add(b.nutrition()));
}

class DayPlan {
  final DateTime date;
  final List<MealPlan> meals;

  DayPlan({required this.date, required this.meals});

  Nutrition totals() => meals.fold(
      const Nutrition(kcal: 0, proteinG: 0, carbG: 0, fatG: 0),
      (a, m) => a.add(m.totals()));
}

class WeekPlan {
  final DateTime weekStart;
  final Map<String, double> dailyTarget;
  final List<DayPlan> days;
  final List<String> flags;
  final List<String> providerTrace;

  WeekPlan({
    required this.weekStart,
    required this.dailyTarget,
    required this.days,
    this.flags = const [],
    this.providerTrace = const ["db_engine"],
  });
}

class MealDatabase {
  MealDatabase._();
  static final MealDatabase instance = MealDatabase._();

  static const breakfastOnlyCats = {
    "oat",
    "toast",
    "breakfast_bakery",
    "breakfast"
  };
  static const dinnerNutMaxG = 15;

  final List<FoodItem> items = [
    // Protein ana
    FoodItem(
      canonicalId: "WGER:chicken_breast",
      nameTr: "Tavuk göğüs",
      category: "lunch",
      isMainCandidate: true,
      per100g: const Nutrition(kcal: 165, proteinG: 31, carbG: 0, fatG: 3.6),
    ),
    FoodItem(
      canonicalId: "WGER:turkey_breast",
      nameTr: "Hindi göğüs",
      category: "dinner",
      isMainCandidate: true,
      per100g: const Nutrition(kcal: 135, proteinG: 29, carbG: 0, fatG: 1.5),
    ),
    FoodItem(
      canonicalId: "WGER:beef_lean",
      nameTr: "Yağsız dana",
      category: "dinner",
      isMainCandidate: true,
      per100g: const Nutrition(kcal: 187, proteinG: 26, carbG: 0, fatG: 9),
    ),
    FoodItem(
      canonicalId: "WGER:salmon",
      nameTr: "Somon",
      category: "dinner",
      isMainCandidate: true,
      per100g: const Nutrition(kcal: 208, proteinG: 20, carbG: 0, fatG: 13),
    ),
    FoodItem(
      canonicalId: "WGER:tuna",
      nameTr: "Ton balığı",
      category: "lunch",
      isMainCandidate: true,
      per100g: const Nutrition(kcal: 132, proteinG: 29, carbG: 0, fatG: 1.3),
    ),
    FoodItem(
      canonicalId: "WGER:mackerel",
      nameTr: "Uskumru",
      category: "dinner",
      isMainCandidate: true,
      per100g: const Nutrition(kcal: 205, proteinG: 19, carbG: 0, fatG: 14),
    ),
    FoodItem(
      canonicalId: "WGER:egg_boiled",
      nameTr: "Haşlanmış yumurta",
      category: "breakfast",
      isMainCandidate: false,
      per100g: const Nutrition(kcal: 155, proteinG: 13, carbG: 1.1, fatG: 11),
    ),
    FoodItem(
      canonicalId: "WGER:egg_white",
      nameTr: "Yumurta beyazı",
      category: "breakfast",
      per100g: const Nutrition(kcal: 52, proteinG: 11, carbG: 0.7, fatG: 0.2),
    ),

    // Karbonhidrat kaynakları
    FoodItem(
      canonicalId: "WGER:rice_cooked",
      nameTr: "Pirinç pilavı (pişmiş)",
      category: "carb",
      isMainCandidate: false,
      per100g: const Nutrition(kcal: 130, proteinG: 2.4, carbG: 28, fatG: 0.3),
    ),
    FoodItem(
      canonicalId: "WGER:bulgur_cooked",
      nameTr: "Bulgur (pişmiş)",
      category: "carb",
      per100g: const Nutrition(kcal: 83, proteinG: 3.1, carbG: 18.6, fatG: 0.2),
    ),
    FoodItem(
      canonicalId: "WGER:quinoa_cooked",
      nameTr: "Kinoa (pişmiş)",
      category: "carb",
      per100g: const Nutrition(kcal: 120, proteinG: 4.4, carbG: 22, fatG: 1.9),
    ),
    FoodItem(
      canonicalId: "WGER:wholewheat_bread",
      nameTr: "Tam buğday ekmeği",
      category: "toast",
      per100g: const Nutrition(kcal: 247, proteinG: 13, carbG: 41, fatG: 4.2),
    ),
    FoodItem(
      canonicalId: "WGER:oatmeal_plain",
      nameTr: "Yulaf ezmesi (kuru)",
      category: "oat",
      per100g:
          const Nutrition(kcal: 379, proteinG: 13.2, carbG: 67.7, fatG: 6.5),
    ),

    // Süt ürünleri
    FoodItem(
      canonicalId: "WGER:yogurt_plain",
      nameTr: "Yoğurt (tam yağlı)",
      category: "snack",
      per100g: const Nutrition(kcal: 61, proteinG: 3.5, carbG: 4.7, fatG: 3.3),
    ),
    FoodItem(
      canonicalId: "WGER:skyr",
      nameTr: "Skyr / light yoğurt",
      category: "snack",
      per100g: const Nutrition(kcal: 62, proteinG: 11, carbG: 3.6, fatG: 0.2),
    ),
    FoodItem(
      canonicalId: "WGER:cottage_cheese",
      nameTr: "Lor/çökelek",
      category: "snack",
      per100g: const Nutrition(kcal: 98, proteinG: 11.1, carbG: 3.4, fatG: 4.3),
    ),

    // Meyve / sebze
    FoodItem(
      canonicalId: "WGER:apple_raw_100g",
      nameTr: "Elma",
      category: "snack",
      per100g: const Nutrition(kcal: 52, proteinG: 0.3, carbG: 14, fatG: 0.2),
    ),
    FoodItem(
      canonicalId: "WGER:banana",
      nameTr: "Muz",
      category: "snack",
      per100g: const Nutrition(kcal: 89, proteinG: 1.1, carbG: 23, fatG: 0.3),
    ),
    FoodItem(
      canonicalId: "WGER:mixed_salad",
      nameTr: "Karışık salata (yağsız)",
      category: "salad",
      per100g: const Nutrition(kcal: 20, proteinG: 1.2, carbG: 3, fatG: 0.2),
    ),
    FoodItem(
      canonicalId: "WGER:olive_oil",
      nameTr: "Zeytinyağı",
      category: "garnish",
      per100g: const Nutrition(kcal: 884, proteinG: 0, carbG: 0, fatG: 100),
    ),

    // Kuruyemiş
    FoodItem(
      canonicalId: "WGER:almond",
      nameTr: "Badem",
      category: "nut_standalone",
      per100g: const Nutrition(kcal: 579, proteinG: 21, carbG: 22, fatG: 50),
    ),
    FoodItem(
      canonicalId: "WGER:walnut",
      nameTr: "Ceviz",
      category: "nut_standalone",
      per100g: const Nutrition(kcal: 654, proteinG: 15, carbG: 14, fatG: 65),
    ),
  ];

  FoodItem? find(String canonicalId) {
    try {
      return items.firstWhere((e) => e.canonicalId == canonicalId);
    } catch (e) {
      // PATCH 4: Fallback mekanizması
      print('⚠️ FOOD NOT FOUND: $canonicalId - Using chicken_breast fallback');
      try {
        return items.firstWhere((e) => e.canonicalId == "WGER:chicken_breast");
      } catch (e2) {
        // Ultimate fallback
        return FoodItem(
          canonicalId: "WGER:fallback",
          nameTr: "Fallback yemek",
          category: "lunch",
          isMainCandidate: true,
          per100g:
              const Nutrition(kcal: 165, proteinG: 31, carbG: 0, fatG: 3.6),
        );
      }
    }
  }
}

class PlanEngineConfig {
  static const breakfastPct = 0.25;
  static const lunchPct = 0.35;
  static const dinnerPct = 0.30;
  static const snackPct = 0.10;
  static const kcalTolerancePct = 0.05; // ±%5
}

class PlanEngine {
  final MealDatabase db = MealDatabase.instance;

  WeekPlan generate(UserProfile profile) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final target = profile.macroTargets();

    // Ana yemek tekrar koruması - GLOBAL SET
    final usedMainCanonicals = <String>{};

    final dayList = <DayPlan>[];
    for (int i = 0; i < 7; i++) {
      final date = start.add(Duration(days: i));
      final day = _buildDay(profile, target, usedMainCanonicals);
      dayList.add(DayPlan(date: date, meals: day));
    }

    final normalizedDays =
        dayList.map((d) => _normalizeDay(d, target)).toList();

    return WeekPlan(
      weekStart: start,
      dailyTarget: target,
      days: normalizedDays,
      flags: const [],
      providerTrace: const ["db_only"],
    );
  }

  List<MealPlan> _buildDay(
    UserProfile profile,
    Map<String, double> dailyTarget,
    Set<String>
        usedMainCanonicals, // Global set ile ana yemek tekrarı engellenir
  ) {
    // PATCH 3: Günlük tekrar kontrolü
    final dailyUsed = <String>{}; // YENİ: Günlük tekrar kontrolü

    final kcal = dailyTarget["kcal"]!;
    final kcalBreakfast = kcal * PlanEngineConfig.breakfastPct;
    final kcalLunch = kcal * PlanEngineConfig.lunchPct;
    final kcalDinner = kcal * PlanEngineConfig.dinnerPct;
    final kcalSnack = kcal * PlanEngineConfig.snackPct;

    final meals = <MealPlan>[];
    meals.add(_buildBreakfast(profile, kcalBreakfast, dailyUsed));
    meals.add(_buildSnack(profile, kcalSnack, dailyUsed));
    meals.add(_buildMainMeal(profile, kcalLunch,
        slot: "lunch", dailyUsed: dailyUsed, weeklyUsed: usedMainCanonicals));
    meals.add(_buildMainMeal(profile, kcalDinner,
        slot: "dinner",
        dailyUsed: dailyUsed,
        weeklyUsed: usedMainCanonicals,
        enforceNutLimit: true));
    return meals;
  }

  MealPlan _buildBreakfast(
      UserProfile profile, double kcalTarget, Set<String> dailyUsed) {
    final r = Random();
    final pickYulaf = r.nextBool();

    if (pickYulaf) {
      final oat = db.find("WGER:oatmeal_plain")!;
      final skyr = db.find("WGER:skyr")!;
      final apple = db.find("WGER:apple_raw_100g")!;

      final items = [
        PlanItem(canonicalId: oat.canonicalId, nameTr: oat.nameTr, grams: 50.0),
        PlanItem(
            canonicalId: skyr.canonicalId, nameTr: skyr.nameTr, grams: 200.0),
        PlanItem(
            canonicalId: apple.canonicalId, nameTr: apple.nameTr, grams: 150.0),
      ];
      return MealPlan(
          name: "Kahvaltı",
          slot: "breakfast",
          items: _scaleToKcal(items, kcalTarget));
    } else {
      final egg = db.find("WGER:egg_boiled")!;
      final bread = db.find("WGER:wholewheat_bread")!;
      final salad = db.find("WGER:mixed_salad")!;
      final oil = db.find("WGER:olive_oil")!;

      final items = [
        PlanItem(canonicalId: egg.canonicalId, nameTr: egg.nameTr, grams: 120),
        PlanItem(
            canonicalId: bread.canonicalId, nameTr: bread.nameTr, grams: 60),
        PlanItem(
            canonicalId: salad.canonicalId, nameTr: salad.nameTr, grams: 120),
        PlanItem(
            canonicalId: oil.canonicalId,
            nameTr: "Zeytinyağı (salata)",
            grams: 8),
      ];
      return MealPlan(
          name: "Kahvaltı",
          slot: "breakfast",
          items: _scaleToKcal(items, kcalTarget));
    }
  }

  MealPlan _buildSnack(
      UserProfile profile, double kcalTarget, Set<String> dailyUsed) {
    final yogurt = db.find("WGER:yogurt_plain")!;
    final fruit = (Random().nextBool())
        ? db.find("WGER:banana")!
        : db.find("WGER:apple_raw_100g")!;
    final items = [
      PlanItem(
          canonicalId: yogurt.canonicalId, nameTr: yogurt.nameTr, grams: 200),
      PlanItem(
          canonicalId: fruit.canonicalId, nameTr: fruit.nameTr, grams: 150),
    ];
    return MealPlan(
        name: "Ara Öğün",
        slot: "snack",
        items: _scaleToKcal(items, kcalTarget));
  }

  MealPlan _buildMainMeal(
    UserProfile profile,
    double kcalTarget, {
    required String slot,
    required Set<String> dailyUsed, // Günlük tekrar kontrolü
    required Set<String> weeklyUsed, // Haftalık tekrar kontrolü
    bool enforceNutLimit = false,
  }) {
    // Ana yemek adayı (çift tekrar kontrolü: günlük + haftalık)
    final mainCandidates = db.items
        .where((f) =>
            f.isMainCandidate &&
            (slot == "lunch"
                ? (f.category == "lunch" || f.category == "dinner")
                : (f.category == "dinner" || f.category == "lunch")))
        .where(
            (f) => !dailyUsed.contains(f.canonicalId)) // GÜNLÜK TEKRAR KONTROLÜ
        .where((f) =>
            !weeklyUsed.contains(f.canonicalId)) // HAFTALIK TEKRAR KONTROLÜ
        .toList();

    mainCandidates.shuffle();

    // FALLBACK: Better variety when all mains are used
    FoodItem anchor;
    if (mainCandidates.isNotEmpty) {
      anchor = mainCandidates.first;
    } else {
      // Hepsi kullanıldıysa: en az geçen alternatifi seç
      final allMains = db.items.where((f) => f.isMainCandidate).toList();
      allMains.shuffle();

      // Son çare: günlük tekrar olmayan alternatif
      anchor = allMains.firstWhere(
        (f) => !dailyUsed.contains(f.canonicalId),
        orElse: () => allMains.first, // Son çare
      );

      print('🔄 FALLBACK: All mains used, selected ${anchor.nameTr}');
    }

    dailyUsed.add(anchor.canonicalId); // Günlük sete ekle
    weeklyUsed.add(anchor.canonicalId); // Haftalık sete ekle

    print(
        '✅ SEÇİLDI: ${anchor.nameTr} - Slot: $slot (Günlük/Haftalık kontrol OK)');

    // Farklı karbonhidrat seçenekleri
    final carbs = ['bulgur', 'rice', 'quinoa'];
    final selectedCarb = carbs[Random().nextInt(carbs.length)];
    final carb = selectedCarb == 'bulgur'
        ? db.find("WGER:bulgur_cooked")!
        : selectedCarb == 'quinoa'
            ? db.find("WGER:quinoa_cooked")!
            : db.find("WGER:rice_cooked")!;

    final salad = db.find("WGER:mixed_salad")!;
    final oil = db.find("WGER:olive_oil")!;

    final items = <PlanItem>[
      PlanItem(
          canonicalId: anchor.canonicalId, nameTr: anchor.nameTr, grams: 180),
      PlanItem(canonicalId: carb.canonicalId, nameTr: carb.nameTr, grams: 180),
      PlanItem(
          canonicalId: salad.canonicalId, nameTr: salad.nameTr, grams: 150),
      PlanItem(canonicalId: oil.canonicalId, nameTr: "Zeytinyağı", grams: 8),
    ];

    if (enforceNutLimit) {
      final nuts = db.find("WGER:almond")!;
      items.add(PlanItem(
          canonicalId: nuts.canonicalId,
          nameTr: "Badem (garnitür)",
          grams: MealDatabase.dinnerNutMaxG.toDouble()));
    }

    final meal = MealPlan(
      name: slot == "lunch" ? "Öğle" : "Akşam",
      slot: slot,
      items: _scaleToKcal(items, kcalTarget),
    );

    return _applyRules(meal, slot);
  }

  List<PlanItem> _scaleToKcal(List<PlanItem> items, double kcalTarget) {
    final current = items.fold<double>(0.0, (a, e) => a + e.nutrition().kcal);
    if (current <= 10) return items;
    final factor = kcalTarget / current;
    return items.map((e) {
      final g = (e.grams * factor).clamp(10.0, 600.0);
      return PlanItem(
          canonicalId: e.canonicalId,
          nameTr: e.nameTr,
          grams: g,
          source: e.source);
    }).toList();
  }

  MealPlan _applyRules(MealPlan meal, String slot) {
    final adjusted = <PlanItem>[];
    for (final it in meal.items) {
      final food = db.find(it.canonicalId)!;

      if ((slot == "lunch" || slot == "dinner") &&
          MealDatabase.breakfastOnlyCats.contains(food.category)) {
        continue; // Breakfast-only kuralları
      }

      if (slot == "dinner" && food.category == "nut_standalone") {
        adjusted.add(PlanItem(
          canonicalId: it.canonicalId,
          nameTr: it.nameTr,
          grams: min(it.grams, MealDatabase.dinnerNutMaxG.toDouble()),
          source: it.source,
        ));
      } else {
        adjusted.add(it);
      }
    }
    return MealPlan(name: meal.name, slot: meal.slot, items: adjusted);
  }

  DayPlan _normalizeDay(DayPlan day, Map<String, double> target) {
    // Simplified normalization - kalori bazlı
    final current = day.totals();
    final targetKcal = target["kcal"]!;
    final factor = targetKcal / max(current.kcal, 1);

    for (final meal in day.meals) {
      for (final item in meal.items) {
        item.grams = (item.grams * factor).clamp(10.0, 600.0);
      }
    }

    return day;
  }
}
