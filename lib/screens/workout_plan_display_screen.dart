import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WorkoutPlanDisplayScreen extends StatefulWidget {
  final Map<String, dynamic> workoutPlan;
  final Map<String, dynamic>? userProfile;

  WorkoutPlanDisplayScreen({required this.workoutPlan, this.userProfile});

  @override
  _WorkoutPlanDisplayScreenState createState() =>
      _WorkoutPlanDisplayScreenState();
}

class _WorkoutPlanDisplayScreenState extends State<WorkoutPlanDisplayScreen> {
  int selectedDayIndex = 0;
  List<Map<String, dynamic>> weeklySchedule = [];

  @override
  void initState() {
    super.initState();
    _createWeeklySchedule();
    _savePlan();
  }

  // Planı kaydet
  Future<void> _savePlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('workout_plan', jsonEncode(widget.workoutPlan));
    } catch (e) {
      print('Plan kaydedilemedi: $e');
    }
  }

  // Haftalık takvim oluştur - antrenman günleri + dinlenme günleri
  void _createWeeklySchedule() {
    final trainingPlan =
        widget.workoutPlan['trainingPlan'] ?? widget.workoutPlan;
    final workoutDays = trainingPlan['days'] ?? [];
    final daysPerWeek = trainingPlan['frequency'] ?? workoutDays.length;

    final weekDays = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar'
    ];

    // Haftalık planı oluştur
    int workoutIndex = 0;

    if (daysPerWeek == 3) {
      // 3 gün: Pazartesi, Çarşamba, Cuma
      for (int i = 0; i < 7; i++) {
        if (i == 0 || i == 2 || i == 4) {
          // Pazartesi, Çarşamba, Cuma
          weeklySchedule.add({
            'dayName': weekDays[i],
            'isRestDay': false,
            'workout': workoutIndex < workoutDays.length
                ? workoutDays[workoutIndex]
                : null,
          });
          workoutIndex++;
        } else {
          weeklySchedule.add({
            'dayName': weekDays[i],
            'isRestDay': true,
          });
        }
      }
    } else if (daysPerWeek == 4) {
      // 4 gün: Pazartesi, Salı, Perşembe, Cuma
      for (int i = 0; i < 7; i++) {
        if (i == 0 || i == 1 || i == 3 || i == 4) {
          weeklySchedule.add({
            'dayName': weekDays[i],
            'isRestDay': false,
            'workout': workoutIndex < workoutDays.length
                ? workoutDays[workoutIndex]
                : null,
          });
          workoutIndex++;
        } else {
          weeklySchedule.add({
            'dayName': weekDays[i],
            'isRestDay': true,
          });
        }
      }
    } else if (daysPerWeek == 5) {
      // 5 gün: Pazartesi-Cuma
      for (int i = 0; i < 7; i++) {
        if (i < 5) {
          weeklySchedule.add({
            'dayName': weekDays[i],
            'isRestDay': false,
            'workout': workoutIndex < workoutDays.length
                ? workoutDays[workoutIndex]
                : null,
          });
          workoutIndex++;
        } else {
          weeklySchedule.add({
            'dayName': weekDays[i],
            'isRestDay': true,
          });
        }
      }
    } else if (daysPerWeek == 6) {
      // 6 gün: Pazartesi-Cumartesi
      for (int i = 0; i < 7; i++) {
        if (i < 6) {
          weeklySchedule.add({
            'dayName': weekDays[i],
            'isRestDay': false,
            'workout': workoutIndex < workoutDays.length
                ? workoutDays[workoutIndex]
                : null,
          });
          workoutIndex++;
        } else {
          weeklySchedule.add({
            'dayName': weekDays[i],
            'isRestDay': true,
          });
        }
      }
    }
  }

  String _formatDuration(String? duration) {
    if (duration == null) return '1 Hafta';

    // Sadece "1 Hafta" göster çünkü bu haftalık programdır
    return '1 Hafta';
  }

  @override
  Widget build(BuildContext context) {
    // trainingPlan objesini al
    final trainingPlan =
        widget.workoutPlan['trainingPlan'] ?? widget.workoutPlan;

    if (weeklySchedule.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Antrenman Planı')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('Antrenman planı yüklenemedi'),
              Text('Lütfen tekrar deneyin',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final currentDaySchedule = weeklySchedule[selectedDayIndex];
    final isRestDay = currentDaySchedule['isRestDay'] ?? false;

    // Bugünün gününü al
    final today = DateTime.now();
    final todayIndex = (today.weekday - 1) % 7; // 0=Pazartesi, 6=Pazar

    return Scaffold(
      appBar: AppBar(
        title: Text(trainingPlan['programName'] ?? 'Antrenman Programı'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Profil özeti
          if (widget.userProfile != null)
            Container(
              padding: EdgeInsets.all(12),
              color: Colors.purple[50],
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildProfileChip(
                        Icons.flag,
                        widget.userProfile!['primary_goal'] ?? 'Hedef',
                        Colors.purple),
                    SizedBox(width: 8),
                    _buildProfileChip(
                        Icons.fitness_center,
                        '${widget.userProfile!['workout_days'] ?? 3} gün',
                        Colors.blue),
                    SizedBox(width: 8),
                    _buildProfileChip(Icons.monitor_weight,
                        '${widget.userProfile!['weight'] ?? 0}kg', Colors.green),
                    SizedBox(width: 8),
                    _buildProfileChip(
                        Icons.trending_up,
                        widget.userProfile!['fitness_level'] ?? 'Seviye',
                        Colors.orange),
                  ],
                ),
              ),
            ),

          // Program bilgileri
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoChip(
                        'Seviye', trainingPlan['level'] ?? 'Beginner'),
                    _buildInfoChip(
                        'Süre', _formatDuration(trainingPlan['duration'])),
                    _buildInfoChip(
                        'Sıklık', '${trainingPlan['frequency'] ?? 3} gün'),
                    _buildInfoChip(
                        'Split', trainingPlan['split'] ?? 'Full Body'),
                  ],
                ),
              ],
            ),
          ),

          // Haftalık takvim
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: weeklySchedule.length,
              itemBuilder: (context, index) {
                final daySchedule = weeklySchedule[index];
                final isSelected = index == selectedDayIndex;
                final isRest = daySchedule['isRestDay'] ?? false;
                final isToday = index == todayIndex;

                // Tarihi hesapla (bugünden başlayarak)
                final dayDate = today.add(Duration(days: index - todayIndex));
                final dateStr = '${dayDate.day}/${dayDate.month}';

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDayIndex = index;
                    });
                  },
                  child: Container(
                    width: 110,
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isToday
                          ? (isRest ? Colors.green[300] : Colors.green[400])
                          : (isRest
                              ? (isSelected
                                  ? Colors.grey[600]
                                  : Colors.grey[300])
                              : (isSelected ? Colors.blue : Colors.blue[100])),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isToday
                            ? Colors.green[900]!
                            : (isSelected
                                ? Colors.blue[700]!
                                : Colors.transparent),
                        width: isToday ? 3 : 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          daySchedule['dayName'],
                          style: TextStyle(
                            color: (isSelected || isToday)
                                ? Colors.white
                                : (isRest
                                    ? Colors.grey[700]
                                    : Colors.blue[900]),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 2),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: (isSelected || isToday)
                                ? Colors.white70
                                : Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                        SizedBox(height: 4),
                        Icon(
                          isRest ? Icons.bed : Icons.fitness_center,
                          color: (isSelected || isToday)
                              ? Colors.white
                              : (isRest ? Colors.grey[700] : Colors.blue[900]),
                          size: 20,
                        ),
                        SizedBox(height: 2),
                        Text(
                          isRest ? 'DİNLENME' : 'Antrenman',
                          style: TextStyle(
                            color: (isSelected || isToday)
                                ? Colors.white
                                : (isRest
                                    ? Colors.grey[700]
                                    : Colors.blue[900]),
                            fontSize: 9,
                          ),
                        ),
                        if (isToday)
                          Container(
                            margin: EdgeInsets.only(top: 2),
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'BUGÜN',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Günün detayları
          if (isRestDay)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.self_improvement,
                        size: 80, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'DİNLENME GÜNÜ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Vücudunuzun toparlanması için dinlenme çok önemlidir. İyi bir uyku alın, bol su için ve hafif aktiviteler (yürüyüş, esneme) yapın.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentDaySchedule['workout']['name'] ?? 'Antrenman Günü',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Odak: ${currentDaySchedule['workout']['focus'] ?? 'Genel'}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Isınma: ${currentDaySchedule['workout']['warmup'] ?? '5-10 dk hafif kardiyo'}',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Egzersizler listesi (sadece antrenman günlerinde)
          if (!isRestDay)
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount:
                    (currentDaySchedule['workout']['exercises'] ?? []).length,
                itemBuilder: (context, index) {
                  final exercise =
                      currentDaySchedule['workout']['exercises'][index];
                  return _buildExerciseCard(exercise, index + 1);
                },
              ),
            ),

          // Soğuma bilgisi
          if (!isRestDay && currentDaySchedule['workout']['cooldown'] != null)
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.self_improvement, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Soğuma: ${currentDaySchedule['workout']['cooldown']}',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileChip(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int orderNumber) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            '$orderNumber',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          exercise['name'] ?? 'Egzersiz',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          exercise['targetMuscle'] ?? '',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Set ve tekrar bilgisi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildExerciseDetail(
                      Icons.repeat,
                      '${exercise['sets'] ?? 3} set',
                      Colors.blue,
                    ),
                    _buildExerciseDetail(
                      Icons.fitness_center,
                      '${exercise['reps'] ?? '8-10'} tekrar',
                      Colors.green,
                    ),
                    _buildExerciseDetail(
                      Icons.timer,
                      '${exercise['rest'] ?? 90}sn',
                      Colors.orange,
                    ),
                    _buildExerciseDetail(
                      Icons.speed,
                      'RPE ${exercise['rpe'] ?? 7}',
                      Colors.red,
                    ),
                  ],
                ),

                // Tempo bilgisi
                if (exercise['tempo'] != null)
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.music_note,
                            size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          'Tempo: ${exercise['tempo']}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                // Form ipucu
                if (exercise['formTip'] != null)
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.yellow[700]!.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 16, color: Colors.yellow[700]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            exercise['formTip'],
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Notlar
                if (exercise['notes'] != null)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    child: Text(
                      exercise['notes'],
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetail(IconData icon, String text, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
