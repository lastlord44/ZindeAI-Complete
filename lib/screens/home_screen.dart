import 'package:flutter/material.dart';
import 'meal_plan_screen.dart';
import 'workout_plan_screen.dart';
import 'media_test_screen.dart';
import 'health_check_screen.dart';
import 'batch_test_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZindeAI Test Merkezi'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfileScreen(),
            ),
          );
        },
        icon: const Icon(Icons.person),
        label: const Text('Profil'),
        backgroundColor: Colors.purple,
        heroTag: 'profile',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Logo ve Başlık
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.fitness_center,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ZindeAI Router Worker',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Endpoint Test Uygulaması',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Test Butonları
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _TestCard(
                    title: 'Yemek Planı',
                    subtitle: 'POST /plan',
                    icon: Icons.restaurant_menu,
                    color: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MealPlanScreen(),
                      ),
                    ),
                  ),
                  _TestCard(
                    title: 'Antrenman',
                    subtitle: 'POST /antrenman',
                    icon: Icons.sports_gymnastics,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkoutPlanScreen(),
                      ),
                    ),
                  ),
                  _TestCard(
                    title: 'Media Test',
                    subtitle: 'GIF/MP4/WebP',
                    icon: Icons.image,
                    color: Colors.purple,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MediaTestScreen(),
                      ),
                    ),
                  ),
                  _TestCard(
                    title: 'Sağlık Kontrolü',
                    subtitle: 'GET /health',
                    icon: Icons.monitor_heart,
                    color: Colors.red,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HealthCheckScreen(),
                      ),
                    ),
                  ),
                  _TestCard(
                    title: 'Batch Test',
                    subtitle: 'POST /exercises/check',
                    icon: Icons.checklist,
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BatchTestScreen(),
                      ),
                    ),
                  ),
                  _TestCard(
                    title: 'API Durumu',
                    subtitle: baseUrl,
                    icon: Icons.api,
                    color: Colors.green,
                    onTap: () => _showApiInfo(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Base URL:'),
            SizedBox(height: 4),
            SelectableText(
              'https://zindeai-router.polfules.workers.dev',
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            SizedBox(height: 16),
            Text('Durum: ✅ Aktif'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  static const String baseUrl = 'https://zindeai-router.polfules.workers.dev';
}

class _TestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _TestCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
