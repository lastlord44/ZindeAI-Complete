import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meal_plan.dart';

class MealTrackerScreen extends StatefulWidget {
  final MealPlan mealPlan;

  const MealTrackerScreen({super.key, required this.mealPlan});

  @override
  State<MealTrackerScreen> createState() => _MealTrackerScreenState();
}

class _MealTrackerScreenState extends State<MealTrackerScreen> {
  DateTime selectedDate = DateTime.now();
  Map<String, bool> mealStatus = {}; // Öğün durumları

  @override
  Widget build(BuildContext context) {
    // Bugünün öğünlerini al
    final todayMeals = _getTodayMeals();
    final consumedCalories = _calculateConsumedCalories();
    final consumedProtein = _calculateConsumedProtein();
    final consumedCarbs = _calculateConsumedCarbs();
    final consumedFat = _calculateConsumedFat();

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3460),
        title: const Text('Beslenme programı'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // TARİH VE HAFTALIK TAKVİM
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  DateFormat('d MMMM yyyy', 'tr_TR').format(selectedDate),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildWeekCalendar(),
                const SizedBox(height: 16),
                _buildMacroProgress(consumedCalories, consumedProtein,
                    consumedCarbs, consumedFat),
              ],
            ),
          ),

          // ÖĞÜN LİSTESİ
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: todayMeals.length,
              itemBuilder: (context, index) {
                final meal = todayMeals[index];
                final isConsumed = mealStatus[meal.name] ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    leading: Icon(
                      _getMealIcon(meal.name),
                      color: isConsumed ? Colors.green : Colors.orange,
                    ),
                    title: Text(
                      meal.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration:
                            isConsumed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text('${meal.totalCalories} kcal'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ...meal.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                      '• ${item.quantity} ${item.unit} ${item.name}'),
                                )),
                            const SizedBox(height: 16),
                            _buildMealMacros(meal),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: isConsumed
                                      ? null
                                      : () {
                                          setState(() {
                                            mealStatus[meal.name] = true;
                                          });
                                        },
                                  icon: const Icon(Icons.check,
                                      color: Colors.white),
                                  label: const Text('Öğünümü Yedim'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: !isConsumed
                                      ? null
                                      : () {
                                          setState(() {
                                            mealStatus[meal.name] = false;
                                          });
                                        },
                                  icon: const Icon(Icons.close,
                                      color: Colors.red),
                                  label: const Text('Öğünümü Yemedim'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'PROFİL'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'ANTRENMAN'),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant), label: 'BESLENME'),
          BottomNavigationBarItem(
              icon: Icon(Icons.support), label: 'SUPPLEMENT'),
        ],
        onTap: (index) {
          // Navigation logic
        },
      ),
    );
  }

  Widget _buildWeekCalendar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final date = DateTime.now()
            .subtract(Duration(days: DateTime.now().weekday - 1 - index));
        final isToday = date.day == DateTime.now().day;
        final dayName =
            ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'][index];

        return GestureDetector(
          onTap: () => setState(() => selectedDate = date),
          child: Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isToday ? Colors.orange : Colors.grey[300],
                child: Text(
                  date.day.toString(),
                  style: TextStyle(
                    color: isToday ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dayName,
                style: TextStyle(
                  fontSize: 12,
                  color: isToday ? Colors.orange : Colors.grey,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMacroProgress(int calories, int protein, int carbs, int fat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMacroItem(
              'Kalori', calories, widget.mealPlan.totalCalories, Colors.orange),
          _buildMacroItem(
              'Karb.', carbs, widget.mealPlan.totalCarbs, Colors.blue),
          _buildMacroItem(
              'Prot.', protein, widget.mealPlan.totalProtein, Colors.green),
          _buildMacroItem('Yağ', fat, widget.mealPlan.totalFat, Colors.yellow),
        ],
      ),
    );
  }

  Widget _buildMacroItem(String label, int current, int total, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '$current',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          'gr',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            value: total > 0 ? current / total : 0.0,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMealMacros(Meal meal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMacroChip('Kalori', meal.totalCalories, Colors.orange),
        _buildMacroChip('Karb.', meal.totalCarbs, Colors.blue),
        _buildMacroChip('Protein', meal.totalProtein, Colors.green),
        _buildMacroChip('Yağ', meal.totalFat, Colors.yellow),
      ],
    );
  }

  Widget _buildMacroChip(String label, int value, Color color) {
    return Chip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          Text('$value',
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  IconData _getMealIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('kahvaltı')) return Icons.free_breakfast;
    if (name.contains('öğle')) return Icons.lunch_dining;
    if (name.contains('akşam')) return Icons.dinner_dining;
    if (name.contains('ara')) return Icons.cookie;
    return Icons.restaurant;
  }

  List<Meal> _getTodayMeals() {
    // Bugünün öğünlerini getir
    if (widget.mealPlan.dailyPlan.isNotEmpty) {
      final dayIndex = selectedDate.weekday - 1;
      if (dayIndex < widget.mealPlan.dailyPlan.length) {
        return widget.mealPlan.dailyPlan[dayIndex].meals;
      }
    }
    return [];
  }

  int _calculateConsumedCalories() {
    final meals = _getTodayMeals();
    return meals
        .where((meal) => mealStatus[meal.name] ?? false)
        .fold(0, (sum, meal) => sum + meal.totalCalories);
  }

  int _calculateConsumedProtein() {
    final meals = _getTodayMeals();
    return meals
        .where((meal) => mealStatus[meal.name] ?? false)
        .fold(0, (sum, meal) => sum + meal.totalProtein);
  }

  int _calculateConsumedCarbs() {
    final meals = _getTodayMeals();
    return meals
        .where((meal) => mealStatus[meal.name] ?? false)
        .fold(0, (sum, meal) => sum + meal.totalCarbs);
  }

  int _calculateConsumedFat() {
    final meals = _getTodayMeals();
    return meals
        .where((meal) => mealStatus[meal.name] ?? false)
        .fold(0, (sum, meal) => sum + meal.totalFat);
  }
}
