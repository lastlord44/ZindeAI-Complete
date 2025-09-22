import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user_profile.dart';
import '../models/workout_plan.dart';
import '../models/meal_plan.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as app;

class WeeklyPlanScreen extends StatefulWidget {
  final UserProfile profile;

  const WeeklyPlanScreen({
    super.key,
    required this.profile,
  });

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  WorkoutPlan? _workoutPlan;
  MealPlan? _mealPlan;
  bool _isLoadingWorkout = true;
  bool _isLoadingMeal = true;
  String? _workoutError;
  String? _mealError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final apiService = context.read<ApiService>();

    // Antrenman planı yükle
    _loadWorkoutPlan(apiService);

    // Yemek planı yükle
    _loadMealPlan(apiService);
  }

  Future<void> _loadWorkoutPlan(ApiService apiService) async {
    try {
      final plan = await apiService.createWorkoutPlan(
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        age: widget.profile.age,
        gender: widget.profile.sex,
        weight: widget.profile.weightKg,
        height: widget.profile.heightCm.toDouble(),
        fitnessLevel: _getFitnessLevel(),
        goal: widget.profile.goal,
        mode: widget.profile.training.mode,
        daysPerWeek: widget.profile.training.daysPerWeek,
        preferredSplit: widget.profile.training.splitPreference == 'AUTO'
            ? null
            : widget.profile.training.splitPreference.toLowerCase(),
      );

      setState(() {
        _workoutPlan = plan;
        _isLoadingWorkout = false;
      });
    } catch (e) {
      setState(() {
        _workoutError = e.toString();
        _isLoadingWorkout = false;
      });
    }
  }

  Future<void> _loadMealPlan(ApiService apiService) async {
    try {
      // Kalori hesapla
      final bmr = _calculateBMR();
      final tdee = _calculateTDEE(bmr);
      final targetCalories = _getTargetCalories(tdee);

      // API'ye gönder - AI oradan plan oluşturacak
      final plan = await apiService.createMealPlan(
        calories: targetCalories, // Bu değer API'ye gidiyor
        goal: _getMealGoal(), // API bunu AI'ya veriyor
        diet: _getDietType(), // Groq/Gemini buna göre plan yapıyor
        preferences: widget.profile.dietFlags.isNotEmpty
            ? {for (var flag in widget.profile.dietFlags) flag: true}
            : null,
      );

      setState(() {
        _mealPlan = plan; // AI'dan gelen plan
        _isLoadingMeal = false;
      });
    } catch (e) {
      setState(() {
        _mealError = e.toString();
        _isLoadingMeal = false;
      });
    }
  }

  String _getFitnessLevel() {
    // Aktivite seviyesine göre fitness level belirle
    switch (widget.profile.activity) {
      case 'low':
        return 'beginner';
      case 'high':
        return 'advanced';
      default:
        return 'intermediate';
    }
  }

  double _calculateBMR() {
    // Mifflin-St Jeor Equation
    if (widget.profile.sex == 'male') {
      return (10 * widget.profile.weightKg) +
          (6.25 * widget.profile.heightCm) -
          (5 * widget.profile.age) +
          5;
    } else {
      return (10 * widget.profile.weightKg) +
          (6.25 * widget.profile.heightCm) -
          (5 * widget.profile.age) -
          161;
    }
  }

  double _calculateTDEE(double bmr) {
    // Activity multiplier
    switch (widget.profile.activity) {
      case 'low':
        return bmr * 1.2;
      case 'high':
        return bmr * 1.725;
      default:
        return bmr * 1.55;
    }
  }

  int _getTargetCalories(double tdee) {
    switch (widget.profile.goal) {
      case 'fat_loss':
        return (tdee * 0.8).round(); // %20 deficit
      case 'muscle_gain':
        return (tdee * 1.1).round(); // %10 surplus
      default:
        return tdee.round();
    }
  }

  String _getMealGoal() {
    switch (widget.profile.goal) {
      case 'fat_loss':
        return 'lose';
      case 'muscle_gain':
        return 'gain';
      default:
        return 'maintain';
    }
  }

  String _getDietType() {
    if (widget.profile.goal == 'muscle_gain' ||
        widget.profile.goal == 'strength') {
      return 'high_protein';
    } else if (widget.profile.goal == 'fat_loss') {
      return 'low_carb';
    }
    return 'balanced';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Haftalık Planınız'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.fitness_center), text: 'Antrenman'),
            Tab(icon: Icon(Icons.restaurant), text: 'Beslenme'),
          ],
          indicatorColor: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Antrenman Planı
          _isLoadingWorkout
              ? const Center(
                  child:
                      LoadingWidget(message: 'Antrenman planı hazırlanıyor...'))
              : _workoutError != null
                  ? Center(
                      child: app.ErrorWidget(
                      message: _workoutError!,
                      onRetry: () {
                        setState(() {
                          _isLoadingWorkout = true;
                          _workoutError = null;
                        });
                        _loadWorkoutPlan(context.read<ApiService>());
                      },
                    ))
                  : _workoutPlan != null 
                      ? _WorkoutPlanView(plan: _workoutPlan!)
                      : const Center(child: Text('Antrenman planı bulunamadı')),

          // Yemek Planı
          _isLoadingMeal
              ? const Center(
                  child:
                      LoadingWidget(message: 'Beslenme planı hazırlanıyor...'))
              : _mealError != null
                  ? Center(
                      child: app.ErrorWidget(
                      message: _mealError!,
                      onRetry: () {
                        setState(() {
                          _isLoadingMeal = true;
                          _mealError = null;
                        });
                        _loadMealPlan(context.read<ApiService>());
                      },
                    ))
                  : _mealPlan != null 
                      ? _MealPlanView(plan: _mealPlan!)
                      : const Center(child: Text('Beslenme planı bulunamadı')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Antrenman planı görünümü widget'ı buraya eklenecek
class _WorkoutPlanView extends StatelessWidget {
  final WorkoutPlan plan;

  const _WorkoutPlanView({required this.plan});

  @override
  Widget build(BuildContext context) {
    // Mevcut workout plan görünümünüzü kullanın
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Plan özeti
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Hafta ${plan.weekNumber}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(plan.splitType.toUpperCase()),
                    backgroundColor: Theme.of(context).primaryColor,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Günlük antrenmanlar
          ...plan.days.map((day) => _DayCard(day: day)),

          // İlerleme notları
          if (plan.progressionNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'İlerleme Notları',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(plan.progressionNotes),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final WorkoutDay day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          '${day.day} - ${day.focus}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${day.exercises.length} egzersiz'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (day.warmup != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.whatshot,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Isınma: ${day.warmup}')),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                ...day.exercises.map((exercise) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300] ?? Colors.grey),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  exercise.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (exercise.gif != null)
                                const Icon(Icons.play_circle_outline,
                                    color: Colors.green),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Hedef Kas: ${exercise.targetMuscle}',
                            style: TextStyle(
                                color: Colors.grey[600] ?? Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Chip(
                                label: Text('${exercise.sets} set'),
                                backgroundColor: Colors.blue[50] ?? Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text('${exercise.reps} tekrar'),
                                backgroundColor: Colors.green[50] ?? Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text('${exercise.rest}s dinlenme'),
                                backgroundColor: Colors.orange[50] ?? Colors.orange,
                              ),
                            ],
                          ),
                          if (exercise.notes != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              exercise.notes!,
                              style: const TextStyle(
                                  fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                    )),
                if (day.cooldown != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.ac_unit, color: Colors.blue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Soğuma: ${day.cooldown}')),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Yemek planı görünümü
class _MealPlanView extends StatelessWidget {
  final MealPlan plan;
  const _MealPlanView({required this.plan});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Günlük özet
          Card(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Günlük Özet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NutrientCard(
                        label: 'Kalori',
                        value: '${plan.totalCalories}',
                        unit: 'kcal',
                        color: Colors.orange,
                        icon: Icons.local_fire_department,
                      ),
                      _NutrientCard(
                        label: 'Protein',
                        value: '${plan.totalProtein}',
                        unit: 'g',
                        color: Colors.red,
                        icon: Icons.fitness_center,
                      ),
                      _NutrientCard(
                        label: 'Karb',
                        value: '${plan.totalCarbs}',
                        unit: 'g',
                        color: Colors.blue,
                        icon: Icons.bakery_dining,
                      ),
                      _NutrientCard(
                        label: 'Yağ',
                        value: '${plan.totalFat}',
                        unit: 'g',
                        color: Colors.green,
                        icon: Icons.water_drop,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sadece dailyPlan formatını kullan
          if (plan.dailyPlan.isNotEmpty) ...[
            ...plan.dailyPlan.map((day) => _DailyPlanCard(day: day)),
          ] else ...[
            // Hiç plan yoksa
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Henüz yemek planı oluşturulmamış',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NutrientCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _NutrientCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 16,
            color: color.withOpacity(0.7),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final Meal meal;
  const _MealCard({required this.meal});

  IconData _getMealIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('kahvaltı')) return Icons.breakfast_dining;
    if (name.contains('öğle')) return Icons.lunch_dining;
    if (name.contains('akşam')) return Icons.dinner_dining;
    if (name.contains('ara')) return Icons.cookie;
    return Icons.restaurant;
  }

  Color _getMealColor(String name) {
    name = name.toLowerCase();
    if (name.contains('kahvaltı')) return Colors.orange;
    if (name.contains('öğle')) return Colors.blue;
    if (name.contains('akşam')) return Colors.purple;
    if (name.contains('ara')) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final mealColor =
        _getMealColor(meal.name); // 'type' yerine 'name' kullanıyoruz
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: mealColor, width: 4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getMealIcon(meal.name),
                      color: mealColor), // 'type' yerine 'name'
                  const SizedBox(width: 8),
                  Text(
                    meal.name, // 'name' alanı
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: mealColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${meal.totalCalories} kcal', // 'calories' yerine yeni 'totalCalories' getter'ı
                      style: TextStyle(
                        color: mealColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              // Malzemeleri (Ingredient) gösteren döngü
              ...meal.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.grey[400] ?? Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.black),
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
                        const SizedBox(width: 8),
                        // Malzeme makrolarını göster
                        Text(
                          '${item.calories}kcal',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600] ?? Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )),
              // Öğün toplam makrolarını göster
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50] ?? Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MacroItem(
                      label: 'Prot',
                      value: meal.totalProtein,
                      color: Colors.red,
                    ),
                    _MacroItem(
                      label: 'Karb',
                      value: meal.totalCarbs,
                      color: Colors.blue,
                    ),
                    _MacroItem(
                      label: 'Yağ',
                      value: meal.totalFat,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
              // Notlar varsa göster
              if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meal.notes ?? 'Not yok',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// WeeklyDayCard kaldırıldı - artık sadece DailyPlan kullanıyoruz

// YENİ: DailyPlan için widget
class _DailyPlanCard extends StatelessWidget {
  final DailyPlan day;
  const _DailyPlanCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final dayNames = [
      'Pazar',
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi'
    ];
    final dayName = day.day; // day.day zaten String, direkt kullan

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  dayName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${day.totalCaloriesForDay} kcal',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...day.meals.map((meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MealCard(meal: meal),
                )),
          ],
        ),
      ),
    );
  }
}

// YARDIMCI WIDGET - MAKRO DEĞERLERİNİ GÖSTERMEK İÇİN
class _MacroItem extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _MacroItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value}g',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600 ?? Colors.grey),
        ),
      ],
    );
  }
}
