import 'package:flutter/material.dart';
import '../models/workout_plan.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart' as app;

class WorkoutPlanDisplayScreen extends StatefulWidget {
  final UserProfile profile;

  const WorkoutPlanDisplayScreen({
    super.key,
    required this.profile,
  });

  @override
  State<WorkoutPlanDisplayScreen> createState() =>
      _WorkoutPlanDisplayScreenState();
}

class _WorkoutPlanDisplayScreenState extends State<WorkoutPlanDisplayScreen> {
  WorkoutPlan? _workoutPlan;
  bool _isLoading = true;
  String? _error;
  int _selectedDay = DateTime.now().weekday; // 1=Pazartesi, 7=Pazar

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlan();
  }

  Future<void> _loadWorkoutPlan() async {
    try {
      final apiService = ApiService();

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getFitnessLevel() {
    switch (widget.profile.activity) {
      case 'sedentary':
        return 'beginner';
      case 'lightly_active':
        return 'beginner';
      case 'moderately_active':
        return 'intermediate';
      case 'very_active':
        return 'advanced';
      case 'super_active':
        return 'expert';
      default:
        return 'intermediate';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenman Planınız'),
        backgroundColor: Colors.purple,
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
                    _loadWorkoutPlan();
                  },
                )
              : _workoutPlan != null
                  ? _WorkoutPlanView(
                      plan: _workoutPlan!,
                      selectedDay: _selectedDay,
                      onDaySelected: (day) {
                        setState(() {
                          _selectedDay = day;
                        });
                      })
                  : const Center(child: Text('Antrenman planı bulunamadı')),
    );
  }
}

class _WorkoutPlanView extends StatefulWidget {
  final WorkoutPlan plan;
  final int selectedDay;
  final ValueChanged<int> onDaySelected;

  const _WorkoutPlanView(
      {required this.plan,
      required this.selectedDay,
      required this.onDaySelected});

  @override
  State<_WorkoutPlanView> createState() => _WorkoutPlanViewState();
}

class _WorkoutPlanViewState extends State<_WorkoutPlanView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Plan Özeti
        _buildPlanSummary(),
        const SizedBox(height: 16),
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

  Widget _buildPlanSummary() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.purple,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hafta ${widget.plan.weekNumber}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Hedef', widget.plan.goal, Colors.white),
              _buildSummaryItem('Mod', widget.plan.mode, Colors.white),
              _buildSummaryItem(
                  'Gün Sayısı', '${widget.plan.days.length}', Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.8),
          ),
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
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
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
            'Haftalık Antrenman',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final dayNumber = index + 1;
              final dayName = days[index];
              final hasWorkout = widget.plan.days
                  .any((day) => _getDayNumber(day.day) == dayNumber);
              final isSelected = widget.selectedDay == dayNumber;

              return GestureDetector(
                onTap: () {
                  widget.onDaySelected(dayNumber);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.purple
                        : (hasWorkout
                            ? Colors.purple.withValues(alpha: 0.6)
                            : Colors.grey[200]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNumber.toString(),
                        style: TextStyle(
                          color: isSelected || hasWorkout
                              ? Colors.white
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        dayName.substring(0, 3),
                        style: TextStyle(
                          color: isSelected || hasWorkout
                              ? Colors.white
                              : Colors.grey[600],
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

  Widget _buildSelectedDayDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Antrenman Detayları',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const SizedBox(height: 16),
          // Seçili günün antrenmanını göster
          _buildSelectedDayWorkout(),
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

  Widget _buildSelectedDayWorkout() {
    final selectedDayWorkout = widget.plan.days.firstWhere(
      (day) => _getDayNumber(day.day) == widget.selectedDay,
      orElse: () => WorkoutDay(
          day: widget.selectedDay.toString(),
          focus: 'Dinlenme Günü',
          exercises: []),
    );

    // Debug: Seçili gün ve antrenman bilgilerini logla
    print('=== ANTRENMAN PLANI DEBUG ===');
    print('Selected day: ${widget.selectedDay}');
    print('Available days: ${widget.plan.days.map((d) => d.day).toList()}');
    print(
        'Selected workout: ${selectedDayWorkout.day} - ${selectedDayWorkout.focus}');
    print('Exercises count: ${selectedDayWorkout.exercises.length}');
    print(
        'All workouts: ${widget.plan.days.map((d) => '${d.day}: ${d.focus} (${d.exercises.length} egzersiz)').toList()}');
    print('=============================');

    if (selectedDayWorkout.exercises.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Bugün dinlenme günü veya antrenman bulunamadı.'),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gün ${selectedDayWorkout.day} - ${selectedDayWorkout.focus}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Egzersizler:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...selectedDayWorkout.exercises
                .map((exercise) => _buildExerciseCard(exercise)),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildExerciseStat('Setler', exercise.sets.toString()),
                _buildExerciseStat('Tekrarlar', exercise.reps.toString()),
                _buildExerciseStat('Dinlenme', exercise.rest.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
