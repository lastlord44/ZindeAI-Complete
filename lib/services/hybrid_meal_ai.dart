import 'package:dio/dio.dart';
import 'meal_database.dart';

class HybridMealAI {
  final Dio _dio;
  final MealDatabase _localDB;
  final String supabaseUrl;
  bool _isUsingFallback = false;

  // Global meal trackers (no-repeat için)
  static Set<String> _globalUsedMealIds = {};
  static int _currentWeekNumber = -1;

  HybridMealAI({
    required Dio dio,
    required this.supabaseUrl,
  })  : _dio = dio,
        _localDB = MealDatabase();

  /// Ana fonksiyon - GEMINI DEVRE DIŞI, HER ZAMAN LOCAL DB KULLAN
  Future<Map<String, dynamic>> generateMealPlan({
    required Map<String, dynamic> userProfile,
  }) async {
    // GEMINI DEVRE DIŞI - HER ZAMAN LOCAL DB KULLAN
    print('⚡ GEMINI OFF - Local database kullanılıyor...');
    _isUsingFallback = true;
    return await _generateLocalMealPlan(userProfile);
  }

  /// Gemini API çağrısı - DEVRE DIŞI
  Future<Map<String, dynamic>> _callGeminiAPI(
    Map<String, dynamic> userProfile,
  ) async {
    // GEMINI DEVRE DIŞI
    throw Exception('Gemini API devre dışı');

    /*final response = await _dio.post(
      '$supabaseUrl/functions/v1/zindeai-router',
      data: {
        'requestType': 'plan',
        'data': userProfile,
      },
      options: Options(
        headers: {'Content-Type': 'application/json'},
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );

    if (response.statusCode == 200) {
      return response.data as Map<String, dynamic>;
    } else {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'HTTP ${response.statusCode}',
      );
    }*/
  }

  /// Optimized Local Database Meal Plan Generation
  Future<Map<String, dynamic>> _generateLocalMealPlan(
    Map<String, dynamic> userProfile,
  ) async {
    _isUsingFallback = true;

    // Parse user profile data
    final int age = userProfile['age'] ?? 25;
    final String sex = userProfile['sex'] ?? 'male';
    final double weightKg =
        (userProfile['weight_kg'] ?? userProfile['weight'] ?? 70).toDouble();
    final double heightCm = (userProfile['height_cm'] ?? 170).toDouble();
    final String activity =
        userProfile['activity'] ?? userProfile['activity_level'] ?? 'moderate';
    final String goal = userProfile['goal'] ?? 'maintain';
    final List<String> dietFlags =
        List<String>.from(userProfile['diet_flags'] ?? []);
    final int trainingDays = userProfile['trainingDays'] ??
        (userProfile['training']?['days_per_week'] ?? 3);

    // STEP 1: Mifflin-St Jeor TDEE Calculation
    final int targetCalories = userProfile['calories'] ??
        _calculateMifflinTDEE(weightKg, heightCm, age, sex, activity, goal);

    // STEP 2: Optimized Protein Calculation
    final double targetProtein = _calculateOptimizedProtein(weightKg, goal);

    // STEP 3: Macro Distribution
    final Map<String, double> macroTargets = _calculateMacroTargets(
      totalCalories: targetCalories.toDouble(),
      proteinGrams: targetProtein,
      goal: goal,
    );

    print(
        '🎯 OPTIMIZED TARGETS: ${targetCalories}kcal | ${targetProtein.toStringAsFixed(1)}g protein');
    print(
        '📊 MACRO BREAKDOWN: ${macroTargets['protein']}g protein | ${macroTargets['carbs']}g carbs | ${macroTargets['fat']}g fat');

    // 7 günlük plan oluştur
    final days = <Map<String, dynamic>>[];

    for (int i = 0; i < 7; i++) {
      final dayName = _getDayName(i);
      final meals = await _generateDayMeals(
        targetCalories: targetCalories.toDouble(),
        targetProtein: targetProtein.toDouble(),
        dayIndex: i, // Gün index'ini ver
        userProfile: userProfile, // Profil bilgilerini ver
      );

      // Günlük toplamları hesapla
      int dayCalories = 0;
      int dayProtein = 0;
      int dayCarbs = 0;
      int dayFat = 0;

      for (var meal in meals) {
        dayCalories += (meal['totalCalories'] as num).toInt();
        dayProtein += (meal['totalProtein'] as num).toInt();
        dayCarbs += (meal['carbs'] as num?)?.toInt() ?? 0;
        dayFat += (meal['fat'] as num?)?.toInt() ?? 0;
      }

      days.add({
        'day': i + 1,
        'dayName': dayName,
        'meals': meals,
        'dailyTotals': {
          'calories': dayCalories,
          'protein': dayProtein,
          'carbs': dayCarbs,
          'fat': dayFat,
          'targetCalories': targetCalories,
          'targetProtein': targetProtein.toInt(),
          'calorieAccuracy': ((dayCalories / targetCalories) * 100).round(),
          'proteinAccuracy': ((dayProtein / targetProtein) * 100).round(),
        },
      });
    }

    final plan = {
      'planTitle': 'Offline Beslenme Planı (Local Database)',
      'totalDays': 7,
      'dailyCalorieGoal': targetCalories,
      'dailyProteinGoal': targetProtein,
      'days': days,
    };

    return {
      'success': true,
      'plan': plan,
      'source': 'local_database',
      'fallback': true,
      'fallback_message':
          '⚠️ AI servisi şu an kullanılamıyor. Öğün veritabanımızdan size özel oluşturulmuş plan gösteriliyor.',
    };
  }

  /// Günün öğünlerini oluştur (5 öğün)
  Future<List<Map<String, dynamic>>> _generateDayMeals({
    required double targetCalories,
    required double targetProtein,
    required int dayIndex,
    required Map<String, dynamic> userProfile,
  }) async {
    // OPTIMIZED: Slot-based distribution (goal-specific)
    final distribution = _getOptimizedSlots(userProfile['goal'] ?? 'maintain');

    final meals = <Map<String, dynamic>>[];
    final times = ['08:00', '11:00', '13:00', '16:00', '19:00'];
    int timeIndex = 0;

    // HER GÜN İÇİN FARKLI SEED + NO-REPEAT CHECK
    final localDB = MealDatabase.withSeed(dayIndex);

    // Hafta kontrolü (yeni hafta başlangıcında reset)
    final currentWeek = DateTime.now().day ~/ 7;
    if (_currentWeekNumber != currentWeek) {
      _globalUsedMealIds.clear();
      _currentWeekNumber = currentWeek;
      print('🔄 YENİ HAFTA: Meal tekrar kontrolü sıfırlandı');
    }

    for (final entry in distribution.entries) {
      final slot =
          entry.key; // 'breakfast', 'snack1', 'lunch', 'snack2', 'dinner'
      final mealCalories = (targetCalories * entry.value).round();
      final mealProtein = (targetProtein * entry.value).round();

      Map<String, dynamic> selectedMeal;

      // NO-REPEAT: Slot'a göre kategori seçimi (usedIds check ile)
      if (slot == 'lunch') {
        selectedMeal = await localDB.getLunchMeal(
          targetCalories: mealCalories.toDouble(),
          targetProtein: mealProtein.toDouble(),
          tolerance: 150,
        );
      } else if (slot == 'dinner') {
        selectedMeal = await localDB.getDinnerMeal(
          targetCalories: mealCalories.toDouble(),
          targetProtein: mealProtein.toDouble(),
          tolerance: 100,
        );
      } else if (slot == 'breakfast') {
        selectedMeal = await localDB.getBreakfastMeal(
          targetCalories: mealCalories.toDouble(),
          targetProtein: mealProtein.toDouble(),
          tolerance: 100,
        );
      } else {
        // Ara öğünler için (snack repeat OK)
        selectedMeal = await localDB.getSnackMeal(
          targetCalories: mealCalories.toDouble(),
          targetProtein: mealProtein.toDouble(),
          tolerance: 50,
        );
      }

      // Geçici debug: Meal tekrarını log et
      final mealId = selectedMeal['meal_id'] ?? '';
      final isRepeat = _globalUsedMealIds.contains(mealId);

      if (isRepeat && slot != 'snack1' && slot != 'snack2') {
        print('⚠️ MEAL TEKRARI TESPIT: ${selectedMeal['name']} - Slot: $slot');
      }

      _globalUsedMealIds.add(mealId);

      meals.add({
        'mealName': _getTurkishMealName(slot),
        'time': times[timeIndex++],
        'totalCalories': selectedMeal['calories'],
        'totalProtein': selectedMeal['protein'],
        'carbs': selectedMeal['carbs'],
        'fat': selectedMeal['fat'],
        'recipeName': selectedMeal['name'],
        'grams': selectedMeal['grams'] ?? 200.0,
        'portion_text': selectedMeal['portion_text'] ?? '200 g porsiyon',
        'ingredients':
            selectedMeal['ingredients'] ?? ['Malzemeler yükleniyor...'],
        'instructions': selectedMeal['instructions'] ?? ['Tarif yükleniyor...'],
        'slot': slot,
        'targetCalories': mealCalories,
        'targetProtein': mealProtein,
        'actualCalories': selectedMeal['calories'],
        'actualProtein': selectedMeal['protein'],
        'isConsumed': false,
      });
    }

    return meals;
  }

  /// STEP 1: Mifflin-St Jeor Equation TDEE Calculation
  int _calculateMifflinTDEE(double weight, double height, int age, String sex,
      String activity, String goal) {
    // BMR hesapla (Mifflin-St Jeor)
    double bmr;
    if (sex == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // Activity Multipliers
    final activityMultipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'very_active': 1.725,
      'extra_active': 1.9,
    };
    final tdee = bmr * (activityMultipliers[activity] ?? 1.55);

    // Goal-based Calorie Adjustments
    switch (goal) {
      case 'lose':
        return (tdee * 0.80).round(); // -20%
      case 'gain':
        return (tdee * 1.15).round(); // +15%
      case 'gain_muscle_gain_weight':
        return (tdee * 1.20).round(); // +20% kas+kilo için en yüksek surplus
      case 'gain_muscle_loss_fat':
        return (tdee * 1.00).round(); // ±0-5% nötr
      case 'gain_strength':
        return (tdee * 1.10).round(); // +10%
      default: // maintain
        return tdee.round();
    }
  }

  /// STEP 2: Optimized Protein Calculation
  double _calculateOptimizedProtein(double weightKg, String goal) {
    double proteinPerKg;
    switch (goal) {
      case 'lose':
        proteinPerKg = 2.0; // 2.0-2.2 g/kg
      case 'gain':
        proteinPerKg = 2.0; // ≥2.0 g/kg base
      case 'gain_muscle_gain_weight':
        proteinPerKg = 2.3; // 2.2-2.4 g/kg kas+kilo için yüksek protein
      case 'gain_muscle_loss_fat':
        proteinPerKg = 2.0; // ≥2.0 g/kg recomp
      case 'gain_strength':
        proteinPerKg = 2.2; // 2.1-2.3 g/kg
      default: // maintain
        proteinPerKg = 2.0;
    }
    return weightKg * proteinPerKg;
  }

  /// STEP 3: Smart Macro Distribution
  Map<String, double> _calculateMacroTargets({
    required double totalCalories,
    required double proteinGrams,
    required String goal,
  }) {
    // Protein kaloriyi bul
    final proteinCalories = proteinGrams * 4;

    // Yağ ve carb dağılımı
    final Map<String, double> fatCarbSplit;
    switch (goal) {
      case 'lose':
        // Yağ ağırlıklı, düşük carb
        fatCarbSplit = {'fat': 0.35, 'carbs': 0.25};
      case 'gain':
        // Carb ağırlıklı, orta yağ
        fatCarbSplit = {'fat': 0.25, 'carbs': 0.45};
      case 'gain_muscle_gain_weight':
        // Kas+kilo için ultra yüksek carb
        fatCarbSplit = {'fat': 0.20, 'carbs': 0.50};
      case 'gain_muscle_loss_fat':
        // Dengeli macro
        fatCarbSplit = {'fat': 0.30, 'carbs': 0.35};
      case 'gain_strength':
        // Güç için dengeli macro
        fatCarbSplit = {'fat': 0.28, 'carbs': 0.37};
      default:
        fatCarbSplit = {'fat': 0.30, 'carbs': 0.35};
    }

    // Kalan kalorileri dağıt
    final remainingCalories = totalCalories - proteinCalories;
    final carbsCalories = remainingCalories * fatCarbSplit['carbs']!;
    final fatCalories = remainingCalories * fatCarbSplit['fat']!;

    return {
      'protein': proteinGrams,
      'carbs': carbsCalories / 4, // carb = 4 kcal/g
      'fat': fatCalories / 9, // fat = 9 kcal/g
    };
  }

  /// Legacy calorie calculation (backup)
  int _calculateCalories(double weight, double height, int age, String sex,
      String activity, String goal) {
    return _calculateMifflinTDEE(weight, height, age, sex, activity, goal);
  }

  /// Goal-based slot distribution (simplified)
  Map<String, double> _getOptimizedSlots(String goal) {
    switch (goal) {
      case 'lose':
        // Lose: 25/10/40/25 (breakfast/snack/lunch/dinner)
        return {
          'breakfast': 0.25,
          'snack1': 0.10,
          'lunch': 0.40,
          'snack2': 0.10,
          'dinner': 0.15,
        };
      case 'gain':
        // Gain: 22/13/40/25 (breakfast/snack/lunch/dinner)
        return {
          'breakfast': 0.22,
          'snack1': 0.13,
          'lunch': 0.40,
          'snack2': 0.13,
          'dinner': 0.12,
        };
      case 'gain_muscle_gain_weight':
        // Kas+kilo: ultra yüksek kalori ara öğünlerle
        return {
          'breakfast': 0.20,
          'snack1': 0.15,
          'lunch': 0.35,
          'snack2': 0.15,
          'dinner': 0.15,
        };
      default:
        // Maintain/default
        return {
          'breakfast': 0.25,
          'snack1': 0.10,
          'lunch': 0.35,
          'snack2': 0.10,
          'dinner': 0.20,
        };
    }
  }

  /// Gün adını getir
  String _getDayName(int index) {
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];
    return days[index % 7];
  }

  /// Slot'dan Türkçe öğün ismi
  String _getTurkishMealName(String slot) {
    switch (slot) {
      case 'breakfast':
        return 'Kahvaltı';
      case 'lunch':
        return 'Öğle Yemeği';
      case 'dinner':
        return 'Akşam Yemeği';
      case 'snack1':
        return 'Ara Öğün 1';
      case 'snack2':
        return 'Ara Öğün 2';
      default:
        return 'Bilinmeyen Öğün';
    }
  }

  /// Fallback durumunu kontrol et
  bool get isUsingFallback => _isUsingFallback;
}
