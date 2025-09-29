import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MealTrackerScreen extends StatefulWidget {
  final Map<String, dynamic> mealPlan;
  
  MealTrackerScreen({required this.mealPlan});
  
  @override
  _MealTrackerScreenState createState() => _MealTrackerScreenState();
}

class _MealTrackerScreenState extends State<MealTrackerScreen> {
  Map<String, Map<String, bool>> weeklyProgress = {};
  
  @override
  void initState() {
    super.initState();
    _loadProgress();
    _checkWeeklyReset();
  }
  
  // Pazar günü kontrolü ve sıfırlama
  void _checkWeeklyReset() {
    final now = DateTime.now();
    if (now.weekday == DateTime.sunday && now.hour == 23 && now.minute >= 45) {
      _resetWeeklyProgress();
    }
  }
  
  Future<void> _resetWeeklyProgress() async {
    setState(() => weeklyProgress.clear());
    await _saveProgress();
    
    // Haftalık rapor oluştur
    _generateWeeklyReport();
  }
  
  void _generateWeeklyReport() {
    int totalMeals = 0;
    int completedMeals = 0;
    
    weeklyProgress.forEach((day, meals) {
      meals.forEach((meal, completed) {
        totalMeals++;
        if (completed) completedMeals++;
      });
    });
    
    final completionRate = (completedMeals / totalMeals * 100).toStringAsFixed(1);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('📊 Haftalık Rapor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tamamlama Oranı: %$completionRate'),
            Text('Yenilen Öğünler: $completedMeals/$totalMeals'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _shareReport(completionRate),
              child: Text('Raporu Paylaş'),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _toggleMealCompletion(String day, String mealName) async {
    // Onay dialogu göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Öğün Tamamlandı mı?'),
        content: Text('$mealName öğününü yediniz mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hayır'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Evet'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      setState(() {
        weeklyProgress[day] ??= {};
        weeklyProgress[day]![mealName] = true;
      });
      
      await _saveProgress();
      
      // Başarı animasyonu
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $mealName tamamlandı!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('meal_progress');
      
      if (progressJson != null) {
        setState(() {
          weeklyProgress = Map<String, Map<String, bool>>.from(
            jsonDecode(progressJson)
          );
        });
      }
    } catch (e) {
      print('Progress yükleme hatası: $e');
    }
  }
  
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('meal_progress', jsonEncode(weeklyProgress));
    } catch (e) {
      print('Progress kaydetme hatası: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final today = days[DateTime.now().weekday - 1];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Öğün Takibi'),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: _showWeeklyStats,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: days.length,
        itemBuilder: (context, dayIndex) {
          final day = days[dayIndex];
          final isToday = day == today;
          final dayMeals = widget.mealPlan['days'][dayIndex]['meals'];
          
          return Card(
            color: isToday ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
            margin: EdgeInsets.all(8),
            child: ExpansionTile(
              title: Row(
                children: [
                  if (isToday) Icon(Icons.today, color: Theme.of(context).primaryColor),
                  SizedBox(width: 8),
                  Text(day, style: TextStyle(fontWeight: FontWeight.bold)),
                  Spacer(),
                  _buildDayProgress(day, dayMeals),
                ],
              ),
              children: dayMeals.map<Widget>((meal) {
                final isCompleted = weeklyProgress[day]?[meal['name']] ?? false;
                
                return ListTile(
                  leading: Checkbox(
                    value: isCompleted,
                    onChanged: isCompleted ? null : (_) {
                      _toggleMealCompletion(day, meal['name']);
                    },
                  ),
                  title: Text(
                    meal['name'],
                    style: TextStyle(
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Text('${meal['calories']} kcal'),
                  trailing: isCompleted 
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : Icon(Icons.circle_outlined, color: Colors.grey),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildDayProgress(String day, List meals) {
    final completed = meals.where((meal) => 
      weeklyProgress[day]?[meal['name']] ?? false
    ).length;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: completed == meals.length ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$completed/${meals.length}',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
  
  void _showWeeklyStats() {
    // Haftalık istatistikleri göster
    int totalDays = 0;
    int perfectDays = 0;
    
    weeklyProgress.forEach((day, meals) {
      totalDays++;
      if (meals.values.every((completed) => completed)) {
        perfectDays++;
      }
    });
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('📈 Haftalık İstatistikler'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Mükemmel Günler', '$perfectDays/$totalDays'),
            _buildStatRow('Toplam Öğünler', _calculateTotalMeals().toString()),
            _buildStatRow('Uyum Oranı', _calculateComplianceRate()),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  int _calculateTotalMeals() {
    int total = 0;
    weeklyProgress.forEach((day, meals) {
      total += meals.values.where((v) => v).length;
    });
    return total;
  }
  
  String _calculateComplianceRate() {
    // Uyum oranı hesaplama
    return '85%'; // Gerçek hesaplama eklenecek
  }
  
  void _shareReport(String rate) {
    // Rapor paylaşma işlevi
  }
}