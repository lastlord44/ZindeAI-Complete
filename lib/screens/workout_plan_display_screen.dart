// ============================================
// 5. WORKOUT PLAN DISPLAY SCREEN DÜZELTMESİ
// lib/screens/workout_plan_display_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WorkoutPlanDisplayScreen extends StatefulWidget {
  final Map<String, dynamic> workoutPlanData;

  const WorkoutPlanDisplayScreen({Key? key, required this.workoutPlanData})
      : super(key: key);

  @override
  _WorkoutPlanDisplayScreenState createState() =>
      _WorkoutPlanDisplayScreenState();
}

class _WorkoutPlanDisplayScreenState extends State<WorkoutPlanDisplayScreen> {
  late int _selectedDay;
  Map<String, Map<String, bool>> _exerciseCompletion =
      {}; // day -> exercise -> completed

  @override
  void initState() {
    super.initState();
    // Bugünün gününü belirle (0-indexed)
    _selectedDay = 0; // Default olarak ilk gün
    _initializeExerciseCompletion();
  }

  void _initializeExerciseCompletion() {
    final workoutPlan = widget.workoutPlanData['workoutPlan'];
    if (workoutPlan != null && workoutPlan['days'] != null) {
      for (var day in workoutPlan['days']) {
        String dayKey = 'day_${day['day']}';
        _exerciseCompletion[dayKey] = {};
        for (var exercise in day['exercises']) {
          _exerciseCompletion[dayKey]![exercise['name']] = false;
        }
      }
    }
  }

  Map<String, dynamic>? _getCurrentDayData() {
    try {
      final workoutPlan = widget.workoutPlanData['workoutPlan'];
      if (workoutPlan == null || workoutPlan['days'] == null) return null;

      final days = workoutPlan['days'] as List;

      // Seçili günü bul
      final currentDay = days.firstWhere(
        (day) => day['day'] == _selectedDay + 1,
        orElse: () => null,
      );

      return currentDay as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting current day data: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutPlan = widget.workoutPlanData['workoutPlan'];
    final dayData = _getCurrentDayData();

    if (workoutPlan == null || dayData == null) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Antrenman Planı'),
        ),
        body: Center(
          child: Text('Antrenman planı verisi bulunamadı'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Antrenman Planı'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () => _showPlanInfo(workoutPlan),
          ),
        ],
      ),
      body: Column(
        children: [
          // Plan Başlığı
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
                  workoutPlan['planName'] ?? 'Antrenman Programı',
                  style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
                SizedBox(height: 8),
          Row(
            children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                    SizedBox(width: 4),
                    Text(
                      'Haftalık ${workoutPlan['weeklyFrequency']} gün',
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.fitness_center, size: 16, color: Colors.white70),
                    SizedBox(width: 4),
                    Text(
                      workoutPlan['programType'] ?? '',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Gün Seçici
          _buildDaySelector(workoutPlan['days']),

          // Gün Başlığı
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Text(
              dayData['name'] ?? 'Antrenman Günü',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Egzersizler Listesi
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(bottom: 20),
              itemCount: (dayData['exercises'] as List).length,
              itemBuilder: (context, index) {
                final exercise = dayData['exercises'][index];
                return _buildExerciseCard(exercise, 'day_${dayData['day']}');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(List days) {
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          bool isSelected = _selectedDay == index;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDay = index);
              HapticFeedback.selectionClick();
            },
            child: Container(
              width: 100,
              margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
                color:
                    isSelected ? Theme.of(context).primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Gün ${day['day']}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${(day['exercises'] as List).length} egzersiz',
                      style: TextStyle(
                        color: isSelected ? Colors.white70 : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
                ),
              );
        },
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, String dayKey) {
    bool isCompleted = _exerciseCompletion[dayKey]?[exercise['name']] ?? false;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Checkbox(
            value: isCompleted,
            onChanged: (value) {
              setState(() {
                _exerciseCompletion[dayKey]![exercise['name']] = value ?? false;
              });
              if (value == true) {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${exercise['name']} tamamlandı! 💪'),
                    duration: Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            activeColor: Colors.green,
          ),
          title: Text(
            exercise['name'] ?? 'Egzersiz',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey : Colors.black87,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Row(
                children: [
                  _buildExerciseInfo(Icons.repeat, '${exercise['sets']} set'),
                  SizedBox(width: 16),
                  _buildExerciseInfo(Icons.fitness_center, exercise['reps']),
                  SizedBox(width: 16),
                  _buildExerciseInfo(Icons.timer, exercise['restTime']),
                ],
              ),
              SizedBox(height: 8),
              // RPE (Zorluk) Göstergesi
              Row(
                children: [
                  Text('Zorluk: ',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  ...List.generate(10, (index) {
                    return Icon(
                      Icons.circle,
                      size: 12,
                      color: index < (exercise['rpe'] ?? 7)
                          ? _getRPEColor(exercise['rpe'] ?? 7)
                          : Colors.grey[300],
                    );
                  }),
                  SizedBox(width: 8),
                  Text(
                    'RPE ${exercise['rpe'] ?? 7}/10',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getRPEColor(exercise['rpe'] ?? 7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hedef Kaslar
                  if (exercise['targetMuscles'] != null)
                    _buildDetailSection(
                      'Hedef Kaslar',
                      Icons.accessibility_new,
                      Wrap(
                        spacing: 8,
                        children:
                            (exercise['targetMuscles'] as List).map((muscle) {
                          return Chip(
                            label: Text(
                              muscle,
                              style: TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.blue[50],
                          );
                        }).toList(),
                      ),
                    ),

                  SizedBox(height: 16),

                  // Doğru Form İpuçları
                  if (exercise['executionTips'] != null)
                    _buildDetailSection(
                      'Doğru Form İçin İpuçları',
                      Icons.check_circle_outline,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            (exercise['executionTips'] as List).map((tip) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check,
                                    size: 16, color: Colors.green),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  SizedBox(height: 16),

                  // Sık Yapılan Hatalar
                  if (exercise['commonMistakes'] != null)
                    _buildDetailSection(
                      'Sık Yapılan Hatalar',
                      Icons.warning_amber_outlined,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            (exercise['commonMistakes'] as List).map((mistake) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.close, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    mistake,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, IconData icon, Widget content) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        content,
      ],
    );
  }

  Color _getRPEColor(int rpe) {
    if (rpe <= 3) return Colors.green;
    if (rpe <= 5) return Colors.lightGreen;
    if (rpe <= 7) return Colors.orange;
    if (rpe <= 9) return Colors.deepOrange;
    return Colors.red;
  }

  void _showPlanInfo(Map<String, dynamic> workoutPlan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Plan Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
                'Program Tipi', workoutPlan['programType'] ?? 'Belirtilmemiş'),
            _buildInfoRow(
                'Haftalık Sıklık', '${workoutPlan['weeklyFrequency']} gün'),
            _buildInfoRow('Hedef', workoutPlan['goal'] ?? 'Belirtilmemiş'),
            SizedBox(height: 16),
            Text(
              'RPE (Rate of Perceived Exertion)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('6-7: Orta zorluk'),
            Text('8-9: Zor'),
            Text('10: Maksimum efor'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
      children: [
        Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
