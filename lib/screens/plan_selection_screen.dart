import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'meal_plan_display_screen.dart';
import 'workout_plan_display_screen.dart';

class PlanSelectionScreen extends StatelessWidget {
  final UserProfile profile;

  const PlanSelectionScreen({
    super.key,
    required this.profile,
  });

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
                      builder: (_) => MealPlanDisplayScreen(profile: profile),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WorkoutPlanDisplayScreen(profile: profile),
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
                  // Önce beslenme planını göster
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MealPlanDisplayScreen(profile: profile),
                    ),
                  );

                  // Sonra antrenman planını göster
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WorkoutPlanDisplayScreen(profile: profile),
                      ),
                    );
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
