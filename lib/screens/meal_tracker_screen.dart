import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MealTrackerScreen extends StatefulWidget {
  final Map<String, dynamic> mealPlan;

  const MealTrackerScreen({Key? key, required this.mealPlan}) : super(key: key);

  @override
  _MealTrackerScreenState createState() => _MealTrackerScreenState();
}

class _MealTrackerScreenState extends State<MealTrackerScreen> {
  Map<String, bool> mealStatus = {}; // meal_id -> eaten status
  Map<String, DateTime?> mealTimes = {}; // meal_id -> eaten time
  late int selectedDayIndex;
  late DateTime currentDate;
  
  @override
  void initState() {
    super.initState();
    currentDate = DateTime.now();
    selectedDayIndex = currentDate.weekday - 1; // 0-6 index
    if (selectedDayIndex > 6) selectedDayIndex = 0;
    _loadMealStatus();
  }
  
  // Meal status'ları yükle
  Future<void> _loadMealStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? statusJson = prefs.getString('meal_status');
    final String? timesJson = prefs.getString('meal_times');
    
    if (statusJson != null) {
      setState(() {
        Map<String, dynamic> decoded = json.decode(statusJson);
        mealStatus = decoded.map((key, value) => MapEntry(key, value as bool));
      });
    }
    
    if (timesJson != null) {
      setState(() {
        Map<String, dynamic> decoded = json.decode(timesJson);
        mealTimes = decoded.map((key, value) => 
          MapEntry(key, value != null ? DateTime.parse(value) : null));
      });
    }
  }
  
  // Meal status'ları kaydet
  Future<void> _saveMealStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('meal_status', json.encode(mealStatus));
    
    Map<String, String?> timesMap = mealTimes.map((key, value) =>
      MapEntry(key, value?.toIso8601String()));
    await prefs.setString('meal_times', json.encode(timesMap));
  }
  
  // Öğün ID oluştur
  String _getMealId(int dayIndex, int mealIndex) {
    return 'day${dayIndex}_meal$mealIndex';
  }
  
  // Öğün durumunu güncelle
  void _updateMealStatus(String mealId, bool eaten) {
    setState(() {
      mealStatus[mealId] = eaten;
      mealTimes[mealId] = eaten ? DateTime.now() : null;
    });
    _saveMealStatus();
    
    // Feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          eaten ? '✅ Öğün tamamlandı!' : '❌ Öğün iptal edildi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: eaten ? Colors.green : Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // NULL KONTROLÜ VE YENİ FORMAT UYUMU
    final days = widget.mealPlan['days'] as List<dynamic>?;
    
    if (days == null || days.isEmpty) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Öğün Takibi'),
          backgroundColor: Colors.green,
        ),
        body: Center(
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
              children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Beslenme planı bulunamadı!',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 8),
                Text(
                'Lütfen önce beslenme planı oluşturun.',
                style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
      );
    }
    
    // Geçerli günü al
    final currentDay = selectedDayIndex < days.length 
        ? days[selectedDayIndex] as Map<String, dynamic>
        : days.first as Map<String, dynamic>;
    
    final meals = currentDay['meals'] as List<dynamic>? ?? [];
    final dayTotals = currentDay['totals'] as Map<String, dynamic>?;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Günlük Öğün Takibi'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green, Colors.green.shade50],
            stops: [0.0, 0.3],
          ),
        ),
                        child: Column(
                          children: [
            // Gün seçici
            _buildDaySelector(days),
            
            // Günlük özet
            if (dayTotals != null) _buildDailySummary(dayTotals, meals),
            
            // Öğün listesi
            Expanded(
              child: meals.isEmpty
                  ? Center(
                                  child: Text(
                        'Bu gün için öğün planı yok',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: meals.length,
                      itemBuilder: (context, index) {
                        final meal = meals[index] as Map<String, dynamic>;
                        final mealId = _getMealId(selectedDayIndex, index);
                        final isEaten = mealStatus[mealId] ?? false;
                        final eatenTime = mealTimes[mealId];
                        
                        return _buildMealCard(meal, mealId, isEaten, eatenTime);
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  // Gün seçici widget
  Widget _buildDaySelector(List<dynamic> days) {
    return Container(
      height: 100,
      padding: EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index] as Map<String, dynamic>;
          final dayName = day['day'] ?? 'Gün ${index + 1}';
          final isSelected = index == selectedDayIndex;
          final isToday = index == (DateTime.now().weekday - 1);

        return GestureDetector(
            onTap: () {
              setState(() {
                selectedDayIndex = index;
              });
            },
            child: Container(
              width: 80,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.green 
                    : isToday 
                        ? Colors.green.shade100 
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isToday ? Colors.green : Colors.grey.shade300,
                  width: isToday ? 2 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ] : [],
              ),
          child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
            children: [
                  if (isToday)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                child: Text(
                        'BUGÜN',
                  style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
                  SizedBox(height: 4),
                  Text(
                    dayName.length > 3 ? dayName.substring(0, 3) : dayName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
              Text(
                    '${index + 1}',
                style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // Günlük özet widget
  Widget _buildDailySummary(Map<String, dynamic> totals, List<dynamic> meals) {
    // Yenilen öğün sayısı
    int eatenCount = 0;
    for (int i = 0; i < meals.length; i++) {
      final mealId = _getMealId(selectedDayIndex, i);
      if (mealStatus[mealId] == true) eatenCount++;
    }
    
    // Yenilen kalori hesapla
    double eatenCalories = 0;
    double eatenProtein = 0;
    for (int i = 0; i < meals.length; i++) {
      final mealId = _getMealId(selectedDayIndex, i);
      if (mealStatus[mealId] == true) {
        final meal = meals[i] as Map<String, dynamic>;
        eatenCalories += (meal['calories'] ?? 0).toDouble();
        eatenProtein += (meal['protein'] ?? 0).toDouble();
      }
    }
    
    final totalCalories = (totals['calories'] ?? 0).toDouble();
    final totalProtein = (totals['protein'] ?? 0).toDouble();
    final progress = totalCalories > 0 ? eatenCalories / totalCalories : 0.0;
    
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
              _buildSummaryItem(
                'Öğünler',
                '$eatenCount / ${meals.length}',
                Icons.restaurant,
                Colors.blue,
              ),
              _buildSummaryItem(
                'Kalori',
                '${eatenCalories.toStringAsFixed(0)} / ${totalCalories.toStringAsFixed(0)}',
                Icons.local_fire_department,
                Colors.orange,
              ),
              _buildSummaryItem(
                'Protein',
                '${eatenProtein.toStringAsFixed(0)}g / ${totalProtein.toStringAsFixed(0)}g',
                Icons.fitness_center,
                Colors.red,
              ),
            ],
          ),
          SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.9 ? Colors.green : 
                progress >= 0.6 ? Colors.orange : 
                Colors.red,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% Tamamlandı',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: progress >= 0.9 ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Öğün kartı widget
  Widget _buildMealCard(Map<String, dynamic> meal, String mealId, bool isEaten, DateTime? eatenTime) {
    final mealName = meal['name'] ?? 'Öğün';
    final mealTime = meal['time'] ?? '';
    final calories = meal['calories'] ?? 0;
    final protein = meal['protein'] ?? 0;
    final carbs = meal['carbs'] ?? 0;
    final fat = meal['fat'] ?? 0;
    final ingredients = meal['ingredients'] as List<dynamic>? ?? [];
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isEaten ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEaten ? Colors.green : Colors.grey.shade200,
          width: isEaten ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isEaten 
                ? Colors.green.withOpacity(0.2) 
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: EdgeInsets.all(16),
            leading: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isEaten ? Colors.green : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEaten ? Icons.check_circle : Icons.restaurant,
                color: Colors.white,
                size: 28,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    mealName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: isEaten ? TextDecoration.lineThrough : null,
                      color: isEaten ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
                if (mealTime.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      mealTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                Row(
                  children: [
                    _buildMacroChip('🔥 $calories kcal', Colors.orange),
                    SizedBox(width: 8),
                    _buildMacroChip('💪 ${protein}g', Colors.red),
                  ],
                ),
                if (isEaten && eatenTime != null) ...[
                  SizedBox(height: 8),
                  Text(
                    '✅ ${_formatTime(eatenTime)} yenildi',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            children: [
              // Makro detayları
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroDetail('Kalori', '$calories kcal', Colors.orange),
                    _buildMacroDetail('Protein', '${protein}g', Colors.red),
                    _buildMacroDetail('Karb', '${carbs}g', Colors.blue),
                    _buildMacroDetail('Yağ', '${fat}g', Colors.purple),
                  ],
                ),
              ),
              
              // Malzemeler
              if (ingredients.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Malzemeler:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                ...ingredients.map((ingredient) {
                  final name = ingredient['name'] ?? '';
                  final amount = ingredient['amount'] ?? '';
                  final unit = ingredient['unit'] ?? '';
                  
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: Row(
      children: [
                        Icon(Icons.check_circle_outline, 
                             size: 16, 
                             color: isEaten ? Colors.green : Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          '$name - $amount $unit',
                          style: TextStyle(
                            decoration: isEaten ? TextDecoration.lineThrough : null,
                            color: isEaten ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
              
              // Aksiyon butonları
              SizedBox(height: 16),
              Row(
        children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isEaten ? null : () => _updateMealStatus(mealId, true),
                      icon: Icon(Icons.check_circle),
                      label: Text('YEDİM'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: !isEaten ? null : () => _updateMealStatus(mealId, false),
                      icon: Icon(Icons.cancel),
                      label: Text('İPTAL'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMacroChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildMacroDetail(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}