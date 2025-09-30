import 'package:flutter/material.dart';

class WorkoutPlanDisplayScreen extends StatefulWidget {
  final Map<String, dynamic> workoutPlan;

  WorkoutPlanDisplayScreen({required this.workoutPlan});

  @override
  _WorkoutPlanDisplayScreenState createState() =>
      _WorkoutPlanDisplayScreenState();
}

class _WorkoutPlanDisplayScreenState extends State<WorkoutPlanDisplayScreen> {
  int selectedDayIndex = 0;

  String _formatDuration(String? duration) {
    if (duration == null) return '8 hafta';
    
    // Eğer "8 hafta" formatındaysa, takvim formatına çevir
    if (duration.contains('hafta')) {
      final weeks = int.tryParse(duration.split(' ')[0]) ?? 8;
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: weeks * 7));
      
      return '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}';
    }
    
    return duration;
  }

  @override
  Widget build(BuildContext context) {
    // trainingPlan objesini al
    final trainingPlan =
        widget.workoutPlan['trainingPlan'] ?? widget.workoutPlan;
    final days = trainingPlan['days'] ?? [];

    if (days.isEmpty) {
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

    final currentDay = days[selectedDayIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(trainingPlan['programName'] ?? 'Antrenman Programı'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
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

          // Gün seçici
          Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final isSelected = index == selectedDayIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedDayIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        'Gün ${day['day']}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Günün detayları
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentDay['name'] ?? 'Antrenman Günü',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Odak: ${currentDay['focus'] ?? 'Genel'}',
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
                          'Isınma: ${currentDay['warmup'] ?? '5-10 dk hafif kardiyo'}',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Egzersizler listesi
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: (currentDay['exercises'] ?? []).length,
              itemBuilder: (context, index) {
                final exercise = currentDay['exercises'][index];
                return _buildExerciseCard(exercise, index + 1);
              },
            ),
          ),

          // Soğuma bilgisi
          if (currentDay['cooldown'] != null)
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
                      'Soğuma: ${currentDay['cooldown']}',
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
