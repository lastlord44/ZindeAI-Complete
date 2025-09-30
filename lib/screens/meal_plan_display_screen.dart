import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'meal_tracker_screen.dart';
import 'shopping_list_screen.dart';

class MealPlanDisplayScreen extends StatefulWidget {
  final Map<String, dynamic> mealPlan;

  MealPlanDisplayScreen({required this.mealPlan});

  @override
  _MealPlanDisplayScreenState createState() => _MealPlanDisplayScreenState();
}

class _MealPlanDisplayScreenState extends State<MealPlanDisplayScreen> {
  int selectedDayIndex = 0;
  Map<String, bool> mealStatus = {};

  @override
  void initState() {
    super.initState();
    loadMealStatus();
  }

  void loadMealStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Öğün durumlarını yükle
      widget.mealPlan['days']?.forEach((day) {
        final dayName = day['dayName'] ?? 'Gün ${day['day']}';
        ['sabah', 'ara_ogun_1', 'ogle', 'ara_ogun_2', 'aksam'].forEach((meal) {
          final key = '${dayName}_$meal';
          mealStatus[key] = prefs.getBool(key) ?? false;
        });
      });
    });
  }

  void toggleMealStatus(String dayName, String mealType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${dayName}_$mealType';

    setState(() {
      mealStatus[key] = !(mealStatus[key] ?? false);
    });

    await prefs.setBool(key, mealStatus[key]!);

    // Görsel feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(mealStatus[key]! ? '✅ Öğün tamamlandı!' : '⏰ Öğün bekleniyor'),
        duration: Duration(seconds: 1),
        backgroundColor: mealStatus[key]! ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.mealPlan['days'] ?? [];

    if (days.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Beslenme Planı')),
        body: Center(child: Text('Beslenme planı bulunamadı')),
      );
    }

    final currentDay = days[selectedDayIndex];
    final meals = currentDay['meals'] ?? {};
    final dayName = currentDay['dayName'] ?? 'Gün ${currentDay['day']}';

    return Scaffold(
      appBar: AppBar(
        title: Text('7 Günlük Beslenme Planı'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: Icon(Icons.restaurant_menu),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MealTrackerScreen(mealPlan: widget.mealPlan),
                ),
              );
            },
            tooltip: 'Öğün Takibi',
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ShoppingListScreen(mealPlan: widget.mealPlan),
                ),
              );
            },
            tooltip: 'Alışveriş Listesi',
          ),
        ],
      ),
      body: Column(
        children: [
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
                    width: 100,
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        day['dayName'] ?? 'Gün ${day['day']}',
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

          // Günlük özet
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.green[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroCard(
                    'Kalori', '${currentDay['totalCalories'] ?? 0}', 'kcal'),
                _buildMacroCard(
                    'Protein', '${currentDay['macros']?['protein'] ?? 0}', 'g'),
                _buildMacroCard(
                    'Karb', '${currentDay['macros']?['carbs'] ?? 0}', 'g'),
                _buildMacroCard(
                    'Yağ', '${currentDay['macros']?['fats'] ?? 0}', 'g'),
              ],
            ),
          ),

          // Öğünler listesi
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildMealCard('Sabah', meals['sabah'], dayName),
                SizedBox(height: 12),
                _buildMealCard('Ara Öğün 1', meals['ara_ogun_1'], dayName),
                SizedBox(height: 12),
                _buildMealCard('Öğle', meals['ogle'], dayName),
                SizedBox(height: 12),
                _buildMealCard('Ara Öğün 2', meals['ara_ogun_2'], dayName),
                SizedBox(height: 12),
                _buildMealCard('Akşam', meals['aksam'], dayName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String title, String value, String unit) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text('$value',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(unit, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMealCard(
      String mealTitle, Map<String, dynamic>? meal, String dayName) {
    if (meal == null) return Container();

    final mealKey =
        '${dayName}_${mealTitle.toLowerCase().replaceAll(' ', '_')}';
    final isConsumed = mealStatus[mealKey] ?? false;

    return Card(
      elevation: 4,
      color: isConsumed ? Colors.green[50] : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve checkbox
          ListTile(
            title: Text(
              mealTitle,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            subtitle: Text(
              meal['name'] ?? '',
              style: TextStyle(fontSize: 14),
            ),
            trailing: IconButton(
              icon: Icon(
                isConsumed ? Icons.check_circle : Icons.circle_outlined,
                color: isConsumed ? Colors.green : Colors.grey,
                size: 30,
              ),
              onPressed: () {
                toggleMealStatus(
                    dayName, mealTitle.toLowerCase().replaceAll(' ', '_'));
              },
            ),
          ),

          // Besin değerleri
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientBadge(
                    '${meal['calories'] ?? 0} kcal', Colors.orange),
                _buildNutrientBadge('P: ${meal['protein'] ?? 0}g', Colors.red),
                _buildNutrientBadge('K: ${meal['carbs'] ?? 0}g', Colors.blue),
                _buildNutrientBadge('Y: ${meal['fats'] ?? 0}g', Colors.purple),
              ],
            ),
          ),

          // Malzemeler
          if (meal['ingredients'] != null)
            ExpansionTile(
              title: Text('Malzemeler', style: TextStyle(fontSize: 14)),
              children: [
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Alerjen uyarısı
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.red, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Alerjen Uyarısı: Bu öğünde gluten, süt, yumurta, fındık gibi alerjenler bulunabilir. Alerjiniz varsa malzemeleri kontrol edin.',
                                style: TextStyle(fontSize: 12, color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),
                      // Malzemeler listesi
                      ...(meal['ingredients'] as List).map((ingredient) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.arrow_right,
                                  size: 16, color: Colors.grey),
                              SizedBox(width: 4),
                              Text(
                                '${ingredient['name']} - ${ingredient['amount']}',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNutrientBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
