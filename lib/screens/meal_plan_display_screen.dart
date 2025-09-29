import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as app;

class MealPlanDisplayScreen extends StatefulWidget {
  final UserProfile profile;

  const MealPlanDisplayScreen({
    super.key,
    required this.profile,
  });

  @override
  State<MealPlanDisplayScreen> createState() => _MealPlanDisplayScreenState();
}

class _MealPlanDisplayScreenState extends State<MealPlanDisplayScreen> {
  MealPlan? _mealPlan;
  bool _isLoading = true;
  String? _error;
  int _selectedDay = DateTime.now().weekday; // 1=Pazartesi, 7=Pazar

  // Öğün takip durumu
  Map<String, bool> _mealConsumed = {}; // "day_meal" -> true/false

  @override
  void initState() {
    super.initState();
    _loadMealPlan();
  }

  Future<void> _loadMealPlan() async {
    try {
      final apiService = ApiService();

      // Kalori hesapla
      final bmr = _calculateBMR();
      final tdee = _calculateTDEE(bmr);
      final targetCalories = _getTargetCalories(tdee);

      final plan = await apiService.createMealPlan(
        calories: targetCalories,
        goal: _getMealGoal(),
        diet: _getDietType(),
        daysPerWeek: 7,
        preferences: widget.profile.dietFlags.isNotEmpty
            ? {for (var flag in widget.profile.dietFlags) flag: true}
            : {},
        // Profil bilgileri
        age: widget.profile.age,
        sex: widget.profile.sex,
        weight: widget.profile.weightKg,
        height: widget.profile.heightCm.toDouble(),
        activity: widget.profile.activity,
      );

      setState(() {
        _mealPlan = plan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  double _calculateBMR() {
    if (widget.profile.sex == 'male') {
      return 88.362 +
          (13.397 * widget.profile.weightKg) +
          (4.799 * widget.profile.heightCm) -
          (5.677 * widget.profile.age);
    } else {
      return 447.593 +
          (9.247 * widget.profile.weightKg) +
          (4.330 * widget.profile.heightCm) -
          (4.330 * widget.profile.age);
    }
  }

  double _calculateTDEE(double bmr) {
    switch (widget.profile.activity) {
      case 'low':
        return bmr * 1.2;
      case 'moderate':
        return bmr * 1.55;
      case 'high':
        return bmr * 1.9;
      default:
        return bmr * 1.375;
    }
  }

  int _getTargetCalories(double tdee) {
    switch (widget.profile.goal) {
      case 'fat_loss':
        return (tdee * 0.8).round();
      case 'muscle_gain':
        return (tdee * 1.2).round();
      default:
        return tdee.round();
    }
  }

  String _getMealGoal() {
    switch (widget.profile.goal) {
      case 'fat_loss':
        return 'lose_weight';
      case 'muscle_gain':
        return 'gain_weight';
      default:
        return 'maintain';
    }
  }

  String _getDietType() {
    if (widget.profile.dietFlags.contains('vegan')) return 'vegan';
    if (widget.profile.dietFlags.contains('vegetarian')) return 'vegetarian';
    return 'balanced';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beslenme Planınız'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? app.ErrorWidget(
                  message: _error!,
                  onRetry: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _loadMealPlan();
                  },
                )
              : _mealPlan != null
                  ? _MealPlanView(plan: _mealPlan!)
                  : const Center(child: Text('Beslenme planı bulunamadı')),
    );
  }
}

class _MealPlanView extends StatefulWidget {
  final MealPlan plan;

  const _MealPlanView({required this.plan});

  @override
  State<_MealPlanView> createState() => _MealPlanViewState();
}

class _MealPlanViewState extends State<_MealPlanView> {
  int _selectedDay = DateTime.now().weekday; // 1=Pazartesi, 7=Pazar

  // Öğün takip durumu
  Map<String, bool> _mealConsumed = {}; // "day_meal" -> true/false

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Haftalık Takvim
        _buildWeeklyCalendar(),
        const SizedBox(height: 16),
        // Seçili Günün Detayları
        Expanded(
          child: _buildSelectedDayDetails(),
        ),
      ],
    );
  }

  Widget _buildWeeklyCalendar() {
    final days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Haftalık Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final dayNumber = index + 1;
              final isSelected = _selectedDay == dayNumber;
              final dayName = days[index];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDay = dayNumber;
                  });
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        dayName.substring(0, 3),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  int _getDayNumber(String dayString) {
    // Gün adını sayıya çevir
    switch (dayString.toLowerCase()) {
      case 'pazartesi':
      case 'monday':
      case '1':
        return 1;
      case 'salı':
      case 'tuesday':
      case '2':
        return 2;
      case 'çarşamba':
      case 'wednesday':
      case '3':
        return 3;
      case 'perşembe':
      case 'thursday':
      case '4':
        return 4;
      case 'cuma':
      case 'friday':
      case '5':
        return 5;
      case 'cumartesi':
      case 'saturday':
      case '6':
        return 6;
      case 'pazar':
      case 'sunday':
      case '7':
        return 7;
      default:
        // Sayı olarak parse etmeyi dene
        try {
          return int.parse(dayString);
        } catch (e) {
          return 1; // Varsayılan olarak Pazartesi
        }
    }
  }

  Widget _buildSelectedDayDetails() {
    // API'den gelen day değeri 1-7 arası int, _selectedDay de 1-7 arası
    final selectedDayPlan = widget.plan.dailyPlan.firstWhere(
      (day) => _getDayNumber(day.day) == _selectedDay,
      orElse: () => widget.plan.dailyPlan.first,
    );

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Günlük Özet
        _buildDailySummary(selectedDayPlan),
        const SizedBox(height: 16),
        // Öğün Detayları
        ...selectedDayPlan.meals.map((meal) => _buildMealCard(meal)),
      ],
    );
  }

  Widget _buildDailySummary(DailyPlan dayPlan) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gün ${dayPlan.day} - Günlük Özet',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                    'Kalori', '${dayPlan.totalCaloriesForDay}', 'kcal'),
                _buildSummaryItem(
                    'Protein', '${dayPlan.totalProteinForDay}', 'g'),
                _buildSummaryItem(
                    'Karbonhidrat', '${dayPlan.totalCarbsForDay}', 'g'),
                _buildSummaryItem('Yağ', '${dayPlan.totalFatForDay}', 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        Text(
          '$label ($unit)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(Meal meal) {
    final mealKey = '${_selectedDay}_${meal.name}';
    final isConsumed = _mealConsumed[mealKey] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meal.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            // Yemek tarifi - Collapsible
            if (meal.recipe != null && meal.recipe!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(bottom: 8.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👨‍🍳 Tarif:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(maxHeight: 200), // Max height
                      child: SingleChildScrollView(
                        child: Text(
                          meal.recipe!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Malzemeler
            Text('📝 Malzemeler:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              constraints: BoxConstraints(maxHeight: 150), // Max height
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: meal.items
                      .map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Text(
                                '- ${item.name} (${item.quantity} ${item.unit})'),
                          ))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Makrolar
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroChip('Protein', meal.totalProtein),
                _buildMacroChip('Karb', meal.totalCarbs),
                _buildMacroChip('Yağ', meal.totalFat),
              ],
            ),
            const SizedBox(height: 12),
            // Yedim/Yemedim butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConsumed
                        ? null
                        : () {
                            setState(() {
                              _mealConsumed[mealKey] = true;
                            });
                          },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('✔ Öğünümü Yedim'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.green.shade300,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: !isConsumed
                        ? null
                        : () {
                            setState(() {
                              _mealConsumed[mealKey] = false;
                            });
                          },
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('X Öğünümü Yemedim'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.red.shade300,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChip(String label, dynamic value) {
    return Chip(
      label: Text('$label: ${value ?? 0}g'),
      backgroundColor: Colors.blue.shade50,
    );
  }
}
