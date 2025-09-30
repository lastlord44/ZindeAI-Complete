import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';
import 'meal_plan_display_screen.dart';
import 'workout_plan_display_screen.dart';

class PlanSelectionScreen extends StatelessWidget {
  final UserProfile profile;

  const PlanSelectionScreen({
    super.key,
    required this.profile,
  });

  String _getFitnessLevel() {
    // Aktivite seviyesine göre fitness level belirle
    switch (profile.activity) {
      case 'low':
        return 'beginner';
      case 'high':
        return 'advanced';
      default:
        return 'intermediate';
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MealPlanDisplayScreen(mealPlan: {}),
                    ),
                  );
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
                  Logger.info('Antrenman Planı kartına tıklandı',
                      tag: 'PlanSelection');
                  // Antrenman planı oluştur
                  try {
                    final apiService = context.read<ApiService>();
                    final workoutPlan = await apiService.generateWorkoutPlan({
                      'userId': 'user_${DateTime.now().millisecondsSinceEpoch}',
                      'age': profile.age,
                      'gender': profile.sex,
                      'weight': profile.weightKg,
                      'height': profile.heightCm.toDouble(),
                      'fitnessLevel': _getFitnessLevel(),
                      'goal': profile.goal,
                      'mode': profile.training.mode,
                      'daysPerWeek': profile.training.daysPerWeek,
                      'preferredSplit':
                          profile.training.splitPreference == 'AUTO'
                              ? null
                              : profile.training.splitPreference.toLowerCase(),
                    });

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutPlanDisplayScreen(
                              workoutPlan: workoutPlan),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Antrenman planı oluşturulamadı: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
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

                    // Beslenme planı oluştur
                    final mealPlan = await apiService.generateMealPlan({
                      'weight': profile.weightKg,
                      'height': profile.heightCm,
                      'age': profile.age,
                      'gender': profile.sex == 'male' ? 'Erkek' : 'Kadın',
                      'primary_goal': profile.goal,
                      'diet_type': profile.dietFlags.isNotEmpty
                          ? profile.dietFlags.first
                          : 'Normal',
                      'preserve_muscle': profile.goal == 'lose_weight',
                    });

                    // İlk istek tamamlandı, loading'i kapat
                    if (context.mounted) Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MealPlanDisplayScreen(mealPlan: mealPlan),
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
                        'goal': profile.goal,
                        'mode': profile.training.mode,
                        'daysPerWeek': profile.training.daysPerWeek,
                        'preferredSplit': profile.training.splitPreference ==
                                'AUTO'
                            ? null
                            : profile.training.splitPreference.toLowerCase(),
                      });

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutPlanDisplayScreen(
                              workoutPlan: workoutPlan),
                        ),
                      );
                    }
                  } catch (e) {
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
}
