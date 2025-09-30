import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/meal_plan.dart';
import '../widgets/error_widget.dart' as app;

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  MealPlan? _result;
  String? _error;

  // Form değerleri
  int _calories = 2000;
  String _goal = 'maintain';
  String _diet = 'balanced';
  int _daysPerWeek = 7; // Varsayılan 7 gün

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yemek Planı Test'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Form Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'POST /plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Divider(),

                      // Kalori Slider
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Günlük Kalori: $_calories kcal'),
                          Slider(
                            value: _calories.toDouble(),
                            min: 1200,
                            max: 4000,
                            divisions: 28,
                            label: '$_calories kcal',
                            onChanged: (value) {
                              setState(() => _calories = value.round());
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Hedef
                      DropdownButtonFormField<String>(
                        initialValue: _goal,
                        decoration: const InputDecoration(
                          labelText: 'Hedef',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'lose',
                            child: Text('Kilo Verme'),
                          ),
                          DropdownMenuItem(
                            value: 'maintain',
                            child: Text('Kilo Koruma'),
                          ),
                          DropdownMenuItem(
                            value: 'gain',
                            child: Text('Kilo Alma'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _goal = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Diyet Tipi
                      DropdownButtonFormField<String>(
                        initialValue: _diet,
                        decoration: const InputDecoration(
                          labelText: 'Diyet Tipi',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.restaurant),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'balanced',
                            child: Text('Dengeli'),
                          ),
                          DropdownMenuItem(
                            value: 'low_carb',
                            child: Text('Düşük Karbonhidrat'),
                          ),
                          DropdownMenuItem(
                            value: 'high_protein',
                            child: Text('Yüksek Protein'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _diet = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Kaç Günlük Plan
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kaç Günlük Plan: $_daysPerWeek gün',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Slider(
                            value: _daysPerWeek.toDouble(),
                            min: 1,
                            max: 7,
                            divisions: 6,
                            label: '$_daysPerWeek gün',
                            onChanged: (value) {
                              setState(() => _daysPerWeek = value.round());
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Test Butonu
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _testMealPlan,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                            _isLoading ? 'Gönderiliyor...' : 'Plan Oluştur',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Hata Mesajı
            if (_error != null) ...[
              const SizedBox(height: 16),
              app.ErrorWidget(message: _error!),
            ],

            // Sonuç
            if (_result != null) ...[
              const SizedBox(height: 16),
              _MealPlanResult(plan: _result!),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _testMealPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _result = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final result = await apiService.generateMealPlan({
        'calories': _calories,
        'goal': _goal,
        'diet': _diet,
        'daysPerWeek': _daysPerWeek,
      });

      setState(() {
        _result = result as MealPlan?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
}

class _MealPlanResult extends StatelessWidget {
  final MealPlan plan;

  const _MealPlanResult({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Yemek Planı Oluşturuldu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),

            // Özet Bilgiler
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _SummaryRow(
                    'Toplam Kalori',
                    '${plan.totalCalories} kcal',
                    Icons.local_fire_department,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    'Protein',
                    '${plan.totalProtein}g',
                    Icons.fitness_center,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    'Karbonhidrat',
                    '${plan.totalCarbs}g',
                    Icons.bakery_dining,
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    'Yağ',
                    '${plan.totalFat}g',
                    Icons.opacity,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text(
              'Öğünler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Öğünler - Yeni modelde dailyPlan kullanıyoruz
            ...plan.dailyPlan
                .expand((day) => day.meals)
                .map((meal) => _MealCard(meal: meal)),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;

  const _MealCard({required this.meal});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getMealIcon(meal.name), // 'type' yerine 'name' kullan
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  '${meal.totalCalories} kcal', // 'calories' yerine 'totalCalories' kullan
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...meal.items.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 28, top: 4),
                  child: Row(
                    children: [
                      const Text('• '),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black),
                            children: [
                              TextSpan(
                                text:
                                    '${item.quantity} ${item.unit} ', // Miktar ve birim
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: item.name), // Malzeme adı
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  IconData _getMealIcon(String name) {
    // 'type' yerine 'name' parametresi
    name = name.toLowerCase();
    if (name.contains('kahvaltı')) return Icons.breakfast_dining;
    if (name.contains('öğle')) return Icons.lunch_dining;
    if (name.contains('akşam')) return Icons.dinner_dining;
    if (name.contains('ara')) return Icons.cookie;
    return Icons.restaurant;
  }
}
