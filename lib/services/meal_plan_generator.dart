import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<Map<String, dynamic>> generateMealPlan(BuildContext context) async {
  try {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user == null) {
      throw Exception('Kullanıcı girişi yapılmamış');
    }

    // Loading dialog göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text('Beslenme planınız hazırlanıyor...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Kullanıcı profilini al
    final profileResponse = await supabase
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    // Edge Function'ı çağır
    final response = await supabase.functions.invoke(
      'zindeai-router',
      body: {
        'action': 'generate-meal-plan',
        'userId': user.id,
        'data': {
          'profile': profileResponse,
          'goal': profileResponse?['goal'] ?? 'maintain',
          'diet': profileResponse?['diet_flags'] ?? [],
          'calories': profileResponse?['daily_calorie_target'] ?? 2000,
        }
      },
    );

    // Dialog'u kapat
    Navigator.of(context).pop();

    if (response.status == 200 && response.data != null) {
      final responseData = response.data;
      
      if (responseData['success'] == true && responseData['data'] != null) {
        // Başarılı
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Beslenme planınız hazır!'),
            backgroundColor: Colors.green,
          ),
        );
        
        return responseData['data'];
      } else {
        throw Exception(responseData['error'] ?? 'Bilinmeyen hata');
      }
    } else {
      throw Exception('API hatası: ${response.status}');
    }

  } catch (e) {
    // Dialog açıksa kapat
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    // Hata mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hata: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );

    print('Meal plan generation error: $e');
    rethrow;
  }
}

// Meal plan detaylarını göstermek için yardımcı fonksiyon
void showMealPlanDetails(BuildContext context, Map<String, dynamic> mealPlan) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Haftalık Beslenme Planınız',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Expanded(
            child: DefaultTabController(
              length: 7,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Pzt'),
                      Tab(text: 'Sal'),
                      Tab(text: 'Çar'),
                      Tab(text: 'Per'),
                      Tab(text: 'Cum'),
                      Tab(text: 'Cmt'),
                      Tab(text: 'Paz'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: _buildDayViews(mealPlan),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

List<Widget> _buildDayViews(Map<String, dynamic> mealPlan) {
  final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
  final weeklyPlan = mealPlan['weekly_plan'] ?? {};
  
  return days.map((day) {
    final dayPlan = weeklyPlan[day];
    if (dayPlan == null) {
      return Center(child: Text('Bu gün için plan yok'));
    }
    
    final meals = dayPlan['meals'] as List<dynamic>? ?? [];
    final dayTotals = dayPlan['dayTotals'] ?? {};
    
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        // Günlük toplam
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                Text('Günlük Toplam', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMacroInfo('Kalori', '${dayTotals['calories'] ?? 0}'),
                    _buildMacroInfo('Protein', '${dayTotals['protein'] ?? 0}g'),
                    _buildMacroInfo('Karb', '${dayTotals['carbs'] ?? 0}g'),
                    _buildMacroInfo('Yağ', '${dayTotals['fat'] ?? 0}g'),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        // Öğünler
        ...meals.map((meal) => _buildMealCard(meal)).toList(),
      ],
    );
  }).toList();
}

Widget _buildMealCard(dynamic meal) {
  final foods = meal['foods'] as List<dynamic>? ?? [];
  
  return Card(
    margin: EdgeInsets.only(bottom: 12),
    child: ExpansionTile(
      title: Text(
        meal['name'] ?? 'Öğün',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${meal['totalCalories'] ?? 0} kcal',
        style: TextStyle(color: Colors.grey),
      ),
      children: [
        ...foods.map((food) => ListTile(
          dense: true,
          title: Text(food['name'] ?? ''),
          subtitle: Text(food['amount'] ?? ''),
          trailing: Text('${food['calories'] ?? 0} kcal'),
        )).toList(),
        Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroChip('P', '${meal['totalProtein'] ?? 0}g', Colors.red),
              _buildMacroChip('K', '${meal['totalCarbs'] ?? 0}g', Colors.blue),
              _buildMacroChip('Y', '${meal['totalFat'] ?? 0}g', Colors.orange),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildMacroInfo(String label, String value) {
  return Column(
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _buildMacroChip(String label, String value, Color color) {
  return Chip(
    label: Text('$label: $value'),
    backgroundColor: color.withOpacity(0.2),
    labelStyle: TextStyle(color: color.shade700, fontSize: 12),
    visualDensity: VisualDensity.compact,
  );
}
