import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/hybrid_meal_ai.dart';
import '../utils/logger.dart';
import '../utils/wire.dart';
import '../utils/json_safe.dart';
import 'meal_plan_display_screen.dart';
import 'workout_plan_display_screen.dart';

class PlanSelectionScreen extends StatelessWidget {
  final UserProfile profile;

  const PlanSelectionScreen({
    super.key,
    required this.profile,
  });

  // Kayıtlı beslenme planını yükle
  Future<Map<String, dynamic>?> _loadMealPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final planJson = prefs.getString('meal_plan');
      if (planJson != null) {
        return jsonDecode(planJson);
      }
    } catch (e) {
      print('Plan yüklenemedi: $e');
    }
    return null;
  }

  // Kayıtlı antrenman planını yükle
  Future<Map<String, dynamic>?> _loadWorkoutPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final planJson = prefs.getString('workout_plan');
      if (planJson != null) {
        return jsonDecode(planJson);
      }
    } catch (e) {
      print('Plan yüklenemedi: $e');
    }
    return null;
  }

  String _getFitnessLevel() {
    // Aktivite seviyesine göre fitness level belirle
    switch (profile.activity) {
      case Activity.sedentary:
      case Activity.light:
        return 'beginner';
      case Activity.moderate:
      case Activity.very_active:
        return 'advanced';
    }
  }

  // Kalori hesapla
  int _calculateCalories(UserProfile profile) {
    // BMR hesapla (Mifflin-St Jeor)
    double bmr;
    if (profile.sex == Sex.male) {
      bmr = (10 * profile.weightKg) +
          (6.25 * profile.heightCm) -
          (5 * profile.age) +
          5;
    } else {
      bmr = (10 * profile.weightKg) +
          (6.25 * profile.heightCm) -
          (5 * profile.age) -
          161;
    }

    // TDEE hesapla (aktivite çarpanı)
    double activityMultiplier;
    switch (profile.activity) {
      case Activity.sedentary:
        activityMultiplier = 1.375;
        break;
      case Activity.light:
        activityMultiplier = 1.55;
        break;
      case Activity.moderate:
        activityMultiplier = 1.725;
        break;
      case Activity.very_active:
        activityMultiplier = 1.9;
    }

    double tdee = bmr * activityMultiplier;

    // Hedefe göre kalori ayarla
    switch (profile.goal) {
      case Goal.cut:
      case Goal.gain_muscle_loss_fat:
        return (tdee * 0.8).round(); // %20 açık
      case Goal.bulk:
      case Goal.gain_muscle_gain_weight:
        return (tdee * 1.15).round(); // %15 fazla
      case Goal.gain_strength:
        return (tdee * 1.10).round(); // %10 fazla
      case Goal.maintain:
        return tdee.round();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planınızı Seçin'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Hangi planı oluşturmak istiyorsunuz?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Beslenme Planı Kartı
            Card(
              elevation: 8,
              child: InkWell(
                onTap: () async {
                  // Kayıtlı plan varsa onu göster
                  final savedPlan = await _loadMealPlan();
                  final prefs = await SharedPreferences.getInstance();
                  final profileJson = prefs.getString('user_profile');
                  Map<String, dynamic>? userProfile;
                  if (profileJson != null) {
                    userProfile = jsonDecode(profileJson);
                  }

                  if (savedPlan != null && savedPlan.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MealPlanDisplayScreen(
                          mealPlan: savedPlan,
                          userProfile: userProfile,
                        ),
                      ),
                    );
                  } else {
                    // Yeni plan oluştur
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Önce "HER İKİSİNİ DE OLUŞTUR" ile plan oluşturun'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 64,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Beslenme Planı',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kişiselleştirilmiş yemek planınızı oluşturun',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Antrenman Planı Kartı
            Card(
              elevation: 8,
              child: InkWell(
                onTap: () async {
                  // Kayıtlı plan varsa onu göster
                  final savedPlan = await _loadWorkoutPlan();
                  final prefs = await SharedPreferences.getInstance();
                  final profileJson = prefs.getString('user_profile');
                  Map<String, dynamic>? userProfile;
                  if (profileJson != null) {
                    userProfile = jsonDecode(profileJson);
                  }

                  if (savedPlan != null && savedPlan.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutPlanDisplayScreen(
                          workoutPlan: savedPlan,
                          userProfile: userProfile,
                        ),
                      ),
                    );
                  } else {
                    // Yeni plan oluştur
                    Logger.info('Antrenman Planı kartına tıklandı',
                        tag: 'PlanSelection');
                    try {
                      final apiService = context.read<ApiService>();
                      final payload = buildPlanRequest(profile);
                      payload['userId'] =
                          'user_${DateTime.now().millisecondsSinceEpoch}';
                      payload['height'] = profile.heightCm.toDouble();
                      payload['fitnessLevel'] = _getFitnessLevel();

                      final workoutPlan =
                          await apiService.generateWorkoutPlan(payload);

                      if (context.mounted) {
                        final prefs = await SharedPreferences.getInstance();
                        final profileJson = prefs.getString('user_profile');
                        Map<String, dynamic>? userProfile;
                        if (profileJson != null) {
                          userProfile = jsonDecode(profileJson);
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WorkoutPlanDisplayScreen(
                              workoutPlan: workoutPlan,
                              userProfile: userProfile,
                            ),
                          ),
                        );
                      }
                    } catch (e, st) {
                      debugPrint('🚨 Workout plan error: $e\n$st');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Antrenman planı oluşturulamadı: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: Colors.purple,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Antrenman Planı',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kişiselleştirilmiş antrenman programınızı oluşturun',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Her İkisi Butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Logger.info('Her İkisini Oluştur butonuna basıldı',
                      tag: 'PlanSelection');
                  // Basit loading göstergesi
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                  try {
                    final apiService = context.read<ApiService>();

                    // Kalori hesapla
                    final calories = _calculateCalories(profile);

                    print('🔥 HESAPLANAN KALORİ: $calories');
                    print(
                        '🎯 KULLANICI BİLGİLERİ: ${profile.weightKg}kg, ${profile.goal}');

                    // Beslenme planı oluştur - HİBRİT SİSTEM İLE
                    final payload = buildPlanRequest(profile);
                    payload['weight'] =
                        profile.weightKg; // Hem weight_kg hem weight gönder
                    payload['diet'] = profile.dietFlags.isNotEmpty
                        ? profile.dietFlags.first
                        : 'balanced';
                    payload['daysOfWeek'] = 7;
                    payload['calories'] = calories;
                    payload['primary_goal'] =
                        payload['goal']; // Ekstra güvenlik

                    final mealPlanResult =
                        await apiService.generateMealPlan(payload);

                    // İlk istek tamamlandı, loading'i kapat
                    if (context.mounted) Navigator.pop(context);

                    final prefs = await SharedPreferences.getInstance();
                    final profileJson = prefs.getString('user_profile');
                    Map<String, dynamic>? userProfile;
                    if (profileJson != null) {
                      userProfile = jsonDecode(profileJson);
                      if (userProfile != null) {
                        userProfile['target_calories'] = calories;
                      }
                    }

                    // result API'den dönen her şey olabilir (null/string/list/map)
                    final resMap = asMap(mealPlanResult);

                    // Hibrit bilgilerini al
                    final bool isFallback = resMap['isFallback'] ?? false;
                    final String? fallbackMessage = resMap['fallbackMessage'];

                    // Bazı backend'ler farklı kök anahtar kullanır:
                    final planMap = asMap(
                        resMap['plan'] ?? resMap['data'] ?? resMap['result']);

                    // PLAN NULL İSE → LOKAL FALLBACK (AI KAPALI DB-ENGINE)
                    print('🔍 planMap kontrolü: $planMap');
                    print('🔍 planMap.isEmpty: ${planMap.isEmpty}');

                    if (planMap.isEmpty) {
                      print(
                          '✅ fallback çalışıyor - generateMealPlan çağırılıyor');
                      final localPlanResponse =
                          await HybridMealAI().generateMealPlan(profile);
                      print('🔍 localPlanResponse: $localPlanResponse');

                      // HybridMealAI response'u mealPlan içine sarılı: {success: true, mealPlan: {...}}
                      final actualMealPlan =
                          localPlanResponse['mealPlan'] ?? localPlanResponse;
                      print('🔍 actualMealPlan: $actualMealPlan');

                      _openLocalPlan(context, actualMealPlan, profile);
                      return;
                    }

                    final Map<String, dynamic> mealPlan = planMap;
                    print('✅ normal flow - mealPlan: $mealPlan');

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MealPlanDisplayScreen(
                          mealPlan: mealPlan,
                          userProfile: userProfile,
                          isFallback: isFallback, // YENİ
                          fallbackMessage: fallbackMessage, // YENİ
                        ),
                      ),
                    );

                    // Sonra antrenman planını oluştur
                    if (context.mounted) {
                      final workoutPlan = await apiService.generateWorkoutPlan({
                        'userId':
                            'user_${DateTime.now().millisecondsSinceEpoch}',
                        'age': profile.age,
                        'gender': profile.sex,
                        'weight': profile.weightKg,
                        'height': profile.heightCm.toDouble(),
                        'fitnessLevel': _getFitnessLevel(),
                        'goal': profile.goal.toString().split('.').last,
                        'mode':
                            profile.training.mode.toString().split('.').last,
                        'daysPerWeek': profile.training.daysPerWeek,
                        'preferredSplit': profile.training.splitPreference
                            .toString()
                            .split('.')
                            .last
                            .toLowerCase(),
                      });

                      final prefs = await SharedPreferences.getInstance();
                      final profileJson = prefs.getString('user_profile');
                      Map<String, dynamic>? userProfile;
                      if (profileJson != null) {
                        userProfile = jsonDecode(profileJson);
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutPlanDisplayScreen(
                            workoutPlan: workoutPlan,
                            userProfile: userProfile,
                          ),
                        ),
                      );
                    }
                  } catch (e, st) {
                    debugPrint('🚨 Meal plan error: $e\n$st');
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Plan oluşturulamadı: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.all_inclusive),
                label: const Text(
                  'HER İKİSİNİ DE OLUŞTUR',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // LOCAL FALLBACK HELPER
  static void _openLocalPlan(BuildContext context,
      Map<String, dynamic> mealPlan, UserProfile profile) {
    
    // Profile'i target calories ile expand et
    final userProfile = profile.toJson();
    userProfile['target_calories'] = profile.targetKcal().round();
    userProfile['primary_goal'] = profile.goal.toString().split('.').last;
    userProfile['weight'] = profile.weightKg;
    userProfile['diet_type'] = profile.dietFlags.isNotEmpty ? profile.dietFlags.first : 'Dengeli';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealPlanDisplayScreen(
          mealPlan: mealPlan,
          userProfile: userProfile,
          isFallback: true,
          fallbackMessage: "AI servisi kullanılamadı, yerel plan oluşturuldu",
        ),
      ),
    );
  }
}
