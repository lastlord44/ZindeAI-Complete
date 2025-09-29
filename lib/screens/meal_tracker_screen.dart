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
  Map<String, Map<String, bool>> mealStatus = {};
  
  @override
  void initState() {
    super.initState();
    initializeMealStatus();
    loadMealStatus();
  }
  
  void initializeMealStatus() {
    // Null kontrolü ile başlat
    if (widget.mealPlan != null && 
        widget.mealPlan['days'] != null &&
        widget.mealPlan['days'] is List) {
      
      for (int i = 0; i < widget.mealPlan['days'].length; i++) {
        var day = widget.mealPlan['days'][i];
        if (day != null && day['meals'] != null) {
          day['meals'].forEach((mealType, meal) {
            if (meal != null) {
              String key = 'day_${i}_$mealType';
              if (!mealStatus.containsKey(key)) {
                mealStatus[key] = {'eaten': false};
              }
            }
          });
        }
      }
    }
  }
  
  Future<void> loadMealStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('meal_status');
      if (data != null) {
        final decoded = json.decode(data);
        setState(() {
          mealStatus = Map<String, Map<String, bool>>.from(
            decoded.map((key, value) => MapEntry(
              key, 
              Map<String, bool>.from(value)
            ))
          );
        });
      }
    } catch (e) {
      print('Error loading meal status: $e');
    }
  }
  
  Future<void> saveMealStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('meal_status', json.encode(mealStatus));
    } catch (e) {
      print('Error saving meal status: $e');
    }
  }
  
  void updateMealStatus(String key, bool value) {
    setState(() {
      if (!mealStatus.containsKey(key)) {
        mealStatus[key] = {};
      }
      mealStatus[key]!['eaten'] = value;
    });
    saveMealStatus();
    
    // Visual feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Öğün tamamlandı! ✅' : 'Öğün iptal edildi ❌'),
        duration: Duration(seconds: 2),
        backgroundColor: value ? Colors.green : Colors.orange,
      ),
    );
  }
  
  Widget buildMealCard(int dayIndex, String mealType, Map<String, dynamic> meal) {
    // Null kontrolleri ekle
    if (meal == null) {
      return Container(
        margin: EdgeInsets.all(8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('Öğün bilgisi bulunamadı'),
      );
    }
    
    String key = 'day_${dayIndex}_$mealType';
    bool isEaten = mealStatus[key]?['eaten'] ?? false;
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    meal['name'] ?? 'Öğün',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: isEaten ? TextDecoration.lineThrough : null,
                      color: isEaten ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isEaten ? Colors.green[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${meal['calories'] ?? 0} kcal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isEaten ? Colors.green[700] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (meal['ingredients'] != null && (meal['ingredients'] as List).isNotEmpty)
              Text(
                'Malzemeler: ${(meal['ingredients'] as List).map((ing) => ing['name'] ?? '').join(', ')}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isEaten ? null : () => updateMealStatus(key, true),
                    icon: Icon(Icons.check, size: 16),
                    label: Text('Yedim'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEaten ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isEaten ? null : () => updateMealStatus(key, false),
                    icon: Icon(Icons.close, size: 16),
                    label: Text('Yemedim'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 8),
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Öğün Takibi'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: widget.mealPlan == null || widget.mealPlan['days'] == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Öğün planı bulunamadı',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.only(bottom: 20),
              itemCount: (widget.mealPlan['days'] as List).length,
              itemBuilder: (context, dayIndex) {
                var day = widget.mealPlan['days'][dayIndex];
                if (day == null || day['meals'] == null) {
                  return Container();
                }
                
                return ExpansionTile(
                  title: Text(
                    'Gün ${day['day'] ?? dayIndex + 1}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${day['meals'].length} öğün'),
                  children: [
                    ...day['meals'].entries.map((entry) {
                      return buildMealCard(dayIndex, entry.key, entry.value);
                    }).toList(),
                  ],
                );
              },
            ),
    );
  }
}